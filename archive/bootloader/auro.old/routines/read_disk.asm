; Routine: Read Disk Routine

read_disk:
    cmp [boot_drive], 0
    je .read_chs    ; If floppy, skip to CHS read
    mov ah, 41h
    mov bx, 55aah
    int 0x13       ; Read non-floppy disk
    jc .read_chs    ; If error, read CHS
    cmp bx, 055aah
    jne .read_chs   ; BIOS does not support LBA extension

    ; --- build DAP (Disk Address Packet) ---
    ; must be in memory below 1MB
    ; size = 16 bytes
    ; format:
    ;   0: size (10h)
    ;   1: reserved (0)
    ;   2: sectors to read (word)
    ;   4: buffer offset (word)
    ;   6: buffer segment (word)
    ;   8: LBA (qword)

    push ds
    mov si, .disk_dap
    mov byte [si], 10h          ; size
    mov byte [si+1], 0          ; reserved
    mov word [si+2], ax         ; sectors to read (AL)
    mov word [si+4], bx         ; offset
    mov word [si+6], es         ; segment
    mov word [si+8], dx         ; low LBA
    mov word [si+10], cx        ; high LBA (low 16)
    mov word [si+12], 0         ; higher LBA bits (unused)
    mov word [si+14], 0

    ; --- call int 13h extensions ---
    mov ah, 42h
    mov si, .disk_dap
    int 13h
    pop ds
    ret

.read_chs:
    mov ah, 02h ; BIOS function to read sectors
    int 0x13    ; Call BIOS interrupt to read sector
    ret

.disk_dap: times 16 db 0 ; Disk Address Packet (DAP) for LBA read
; The DAP is used for LBA reads, which allows reading sectors beyond the 1024 limit of CHS.