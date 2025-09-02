; MBR-aware boot sector (512 bytes)
; - org 0, but we set DS = 0x07C0 so DS:0x7C00 points to loaded boot sector
; - find active partition in MBR (offset 0x1BE)
; - read partition's VBR (first sector of partition) into 0x0000:0x7C00
; - verify 0xAA55 and jump to 0x0000:0x7C00
; - minimal error message if read fails
;
; Assemble: nasm -f bin boot.asm -o boot.bin
; Boot with QEMU: qemu-system-i386 -drive format=raw,file=boot.bin

[bits 16]
[org 0]

start:
    cli
    mov ax, 07C0h
    add ax, 288        ; (4096 + 512) / 16
    mov ss, ax
    mov sp, 4096
    sti

    ; set DS so that DS:offset refers to the BIOS-loaded boot sector (0x7C00)
    mov ax, 07C0h
    mov ds, ax

    ; save boot drive number (DL)
    mov [boot_drive], dl

    ; --- Get disk geometry (for CHS translation) ---
    mov ah, 08h
    int 13h
    jc geom_unknown        ; if BIOS returns error, we still can attempt basic read
    ; CX: CH (cylinder low), CL(sector + cyl high bits)
    ; sector per track = CL & 0x3F
    and cl, 3Fh
    mov [spt], cl          ; sectors per track (byte)
    ; heads = DH + 1
    mov dl, dh
    inc dl
    mov [heads], dl        ; store heads (byte)
    ; restore DL to boot drive value
    mov dl, [boot_drive]

    ; --- Parse partition table: 4 entries at offset 0x1BE ---
    mov bx, 0x01BE         ; partition table start (offset within sector)
    mov cx, 4              ; 4 entries to check
find_part:
    mov al, [bx]           ; boot flag
    test al, 0x80
    jnz part_found
    add bx, 0x10
    dec cx
    jnz find_part
    ; no active partition found -> error
    jmp no_part

part_found:
    ; bx points to partition entry base. LBA start at offset +8 (4 bytes, little endian)
    ; read dword LBA start into lba_start (dword)
    mov si, bx
    add si, 8
    ; load 32-bit little endian: low word then high word
    mov ax, [si]         ; low word
    mov [lba_lo], ax
    add si, 2
    mov ax, [si]         ; high word
    mov [lba_hi], ax

    ; combine into 32-bit number in DX:AX? We'll do 32-bit division by SPT*HEADS using
    ; 32-bit arithmetic manually. Simpler route: compute CHS from 32-bit LBA:
    ;   sector = (LBA % SPT) + 1
    ;   temp = LBA / SPT
    ;   head = temp % heads
    ;   cyl  = temp / heads
    ; We'll implement with 32-bit divide by 8/16-bit routine (small but fine).

    ; move LBA into DX:AX as 32-bit (DX = high, AX = low) for divide routine
    mov ax, [lba_lo]
    mov dx, [lba_hi]

    ; prepare divisor = SPT * HEADS (word) -> store in div_word
    mov al, [spt]
    mov ah, 0
    mov bx, ax            ; BX = SPT
    mov al, [heads]
    mov ah, 0
    mul al                ; AX = BX * AL  (cheap way: but we need word*byte->word)
    ; Actually above MUL clobbers AX; instead do proper:
    ; Recompute: div_word = SPT * HEADS
    movzx bx, byte [spt]  ; BX = SPT
    movzx cx, byte [heads]; CX = HEADS
    mov ax, bx
    mul cx                ; DX:AX = AX * CX, but AX will contain product because small values
    mov [div_word], ax

    ; Now do 32-bit DIV: compute temp = LBA / div_word
    ; We'll implement 32-bit / 16-bit -> AX = quotient low, DX = remainder using `div`.
    ; Set numerator in DX:AX pairs by shifting high word into DX:AX appropriately.
    ; Use helper routine 32div16 (DX:AX)/div_word -> returns quotient in BX:AX? (we keep it simple)

    ; store LBA high/low into memory to reuse (already in lba_hi/lba_lo)
    ; We'll implement repeated subtraction division (inefficient but short code):
    ; temp = LBA
    push dx
    push ax
    ; clear temp_high:temp_low in two words at temp_lo/temp_hi
    mov ax, [lba_lo]
    mov [temp_lo], ax
    mov ax, [lba_hi]
    mov [temp_hi], ax

    ; compute div_word in WORD [div_word] already
    ; compute quotient = 0
    xor ax, ax
    mov [quot_lo], ax
    mov [quot_hi], ax

div_loop:
    ; compare temp >= div_word (16-bit*?) -> we need to compare 32-bit temp with 16-bit product scaled
    ; to avoid complexity, if div_word fits in 16-bit and temp_hi == 0 and temp_lo >= div_word then subtract directly
    ; for most disks div_word small, so simplest approach:
    mov ax, [temp_hi]
    or ax, ax
    jne div_done           ; if temp_hi != 0 assume temp < div_word*65536 (skip)
    mov ax, [temp_lo]
    cmp ax, [div_word]
    jb div_done
    ; temp_lo -= div_word
    sub word ax, [div_word]
    ; increment quotient
    inc word [quot_lo]
    jmp div_loop

div_done:
    ; now temp (temp_lo/temp_hi) contains remainder, quotient in quot_lo (only low part used)
    ; temp currently = remainder. remainder = temp
    ; quotient = quot_lo (only low 16 bits)
    ; We'll treat temp as remainder, now compute:
    ; sector = (remainder % SPT) + 1   <--- but our remainder is already LBA % div_word
    ; temp2 = remainder / HEADS -> to get head and cyl we need another division by HEADS.
    ; Due to complexity and space, we'll use simpler approach: attempt to use BIOS CHS mapping as:
    ; Use known formulas when heads,sectors small; but here we choose to **call INT 13h LBA extension** path first if available,
    ; else we fallback to reading partition's first sector by using INT13 AH=02 with CH/CL/DH computed by naive method limited to small disks.
    ; For brevity in stage1, we'll *attempt LBA ext (AH=42) first*, fallback to CHS read by treating LBA low word as sector number (best-effort).

    pop ax
    pop dx

    ; Try INT13 extensions (check support)
    mov ah, 41h
    mov bx, 0x55AA
    int 13h
    jc use_chs_fallback
    cmp bx, 0xAA55
    jne use_chs_fallback

    ; Build DAP at disk_dap (16 bytes)
    ; We need sectors to read = 1
    ; buffer at 0x0000:0x7C00 (segment 0, offset 0x7C00)
    mov si, disk_dap
    mov byte [si], 0x10
    mov byte [si+1], 0
    mov word [si+2], 1         ; sectors to read
    mov word [si+4], 0x7C00    ; offset
    mov word [si+6], 0         ; segment = 0
    ; write LBA (qword) little endian from lba_lo/hi
    mov ax, [lba_lo]
    mov [si+8], ax
    mov ax, [lba_hi]
    mov [si+10], ax
    mov word [si+12], 0
    mov word [si+14], 0

    mov ah, 42h
    mov si, disk_dap
    int 13h
    jc disk_error
    ; verify signature at es:bx+510 (we loaded into 0:0x7C00)
    ; check word at 0x7C00+510
    mov bx, 0x7C00
    mov si, 510
    add si, bx
    mov ax, [si]        ; this reads from DS by default; we want ES:SI, so set ES=0
    ; but current DS=0x07C0; to read 0:address, set es=0 and use es:si
    push ds
    xor ax, ax
    mov es, ax
    mov si, bx
    add si, 510
    mov ax, [es:si]
    pop ds
    cmp ax, 0xAA55
    jne disk_error

    ; jump to partition VBR
    jmp 0x0000:0x7C00

use_chs_fallback:
    ; fallback: perform simple CHS calculation limited to small disks
    ; Here we will try a simple mapping assuming LBA fits in 24-bit and using SPT and HEADS stored earlier.
    ; Load LBA low word into AX (we use only low 16 bits; large disks may fail)
    mov ax, [lba_lo]
    ; compute sector = (ax % SPT) + 1
    mov bl, [spt]
    xor dx, dx
    div bl               ; AL = quotient, AH = remainder? Actually div by byte: AX / BL -> AL=quot, AH=rem
    mov ch, ah           ; remainder in AH -> sector-1
    inc ch
    ; temp = quotient in AL ; compute head = temp % heads
    mov al, al           ; AL has quotient
    mov bl, [heads]
    xor ah, ah
    div bl               ; AL=quotient (cyl), AH=remainder (head)
    mov dh, ah
    mov cl, ch
    mov ch, al           ; cyl low
    ; Now perform CHS read
    mov ah, 02h
    mov al, 1
    ; CH already in CH, CL sector in CL, DH head in DH
    mov dl, [boot_drive]
    mov bx, 0x7C00
    xor cx, cx
    mov es, cx
    int 13h
    jc disk_error

    ; verify signature at 0x7C00+510
    mov si, 0x7C00
    add si, 510
    mov ax, [es:si]
    cmp ax, 0xAA55
    jne disk_error

    jmp 0x0000:0x7C00

geom_unknown:
    ; geometry unknown - try simple CHS read at sector 2 as fallback (like floppy-style)
    mov bx, 0x7C00
    xor ax, ax
    mov es, ax
    mov ah, 02h
    mov al, 1
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, [boot_drive]
    int 13h
    jc disk_error
    ; verify
    mov si, 0x7C00
    add si, 510
    mov ax, [es:si]
    cmp ax, 0xAA55
    jne disk_error
    jmp 0x0000:0x7C00

no_part:
    ; no active partition -> error
    mov si, no_part_msg
    call print_string
    jmp $

; ----------------------
; print_string routine (DS:SI -> null terminated)
; ----------------------
print_string:
    mov ah, 0x0E
.loop_ps:
    lodsb
    test al, al
    jz .done_ps
    int 0x10
    jmp .loop_ps
.done_ps:
    ret

disk_error:
    mov si, err_msg
    call print_string

hang:
    hlt
    jmp hang

; ----------------------
; data
; ----------------------
boot_drive  db 0
spt         db 0
heads       db 0
lba_lo      dw 0
lba_hi      dw 0
div_word    dw 0
temp_lo     dw 0
temp_hi     dw 0
quot_lo     dw 0
quot_hi     dw 0
disk_dap    times 16 db 0

err_msg     db 'Disk read error!',0
no_part_msg db 'No active partition!',0

times 510-($-$$) db 0
dw 0xAA55
