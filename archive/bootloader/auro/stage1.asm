[bits 16]
[org 0]

%define BIOS13_EXTENDED_READ 0x42
%define BIOS15_QUERY_A20 0x2403
%define BIOS15_A20_STATUS 0x2402
%define BIOS15_ENABLE_A20 0x2401
%define GDT_KCODE_SEGMENT 0x08
%define GDT_KDATA_SEGMENT 0x10 ; Same as 16 in decimal, so don't be confused
%define SEGMENT_STACK 0x9000
%define SEGMENT_DATA 0x07c0
%define STAGE2_SECTOR 1
%define STAGE2_SECTOR_COUNT 16
%define STAGE2_LOAD_SEG 0x1000
%define STAGE2_LOAD_OFFSET 0x0000

start16:
    ; A bit of overkill for stack, but just so that the stack will never touch the code
    cli
    mov ax, SEGMENT_STACK
    mov ss, ax
    mov sp, 0xFFFF
    sti

    mov ax, SEGMENT_DATA
    mov ds, ax
    cld
    mov si, BOOT_START_MSG
    call print_string

    mov [boot_drive], dl
    call enable_A20


    ; Load 16 sectors
    mov cx, 3
load_stage2:
    push cx
    mov ah, 0
    int 13h
    
    jc .fail
    cmp ah, 0
    jnz .fail

    mov si, stage2_dap
    mov ah, BIOS13_EXTENDED_READ
    mov dl, [boot_drive]
    int 13h
    pop cx
    
    jc .fail
    cmp ah, 0
    jnz .fail
    jmp .success

.fail:
    dec cl
    jnz load_stage2
    mov si, STAGE2_LOAD_FAILED_MSG
    call print_string
    jmp error16

.success:
    mov ax, SEGMENT_DATA
    mov ds, ax

    call print_ok

prepare_gdt:
    cli
    lgdt [_gdt.descriptor]

enable_protected_mode:
    mov eax, cr0
    or  eax, 1
    mov cr0, eax

    jmp GDT_KCODE_SEGMENT:start32

error16:
    mov si, SYSHALT_MSG
    call print_string

hang16:
    cli
    hlt
    jmp hang16

[bits 32]

start32:
    mov ax, GDT_KDATA_SEGMENT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x9fc00
    mov esp, ebp

    mov al, 0xff
    out 0x21, al
    out 0xa1, al

    mov dl, [boot_drive]
    jmp STAGE2_LOAD_SEG:STAGE2_LOAD_OFFSET

hang32:
    cli
    hlt
    jmp hang32

; =====================================================================================================================
; SUBROUTINES

[bits 16]

enable_A20:
.a20_fast_gate:
    in al, 0x92
    test al, 2
    jnz .on
    or al, 2
    and al, 0xFE
    out 0x92, al
.bios_support:
    mov ax, BIOS15_QUERY_A20
    int 15h
    jc .on      ; CF is set: Blindly assumes that A20 is already active
    cmp ah, 0
    jne .on     ; AH != 0: Function not supported, blindly assumes that A20 is already active
    mov ax, BIOS15_ENABLE_A20
    int 15h
    jc .fail
.is_on:
    mov ax, BIOS15_A20_STATUS
    int 15h
    jc .fail
    test al, 1
    jz .fail
    jmp .on
.fail:
    mov si, A20_ENABLE_FAILED_MSG
    call print_string
    jmp error16
.on:
    ret

print_string:
    ; We would obviously love to have a string printing routine, especially for debugging
.loop:
    mov ah, 0eh  ; BIOS print char function
    lodsb        ; Gets 1 char from SI into AL, then increment SI
    test al, al  ; 
    jz .done     ; If AL is 0, it's done, since the string is null terminated
    int 10h      ; Calls function 0x0e (AH) from interrupt 0x10 (Video Interrupt)
    jmp .loop    ; Loop back

.done:
    ret          ; Return back because it's a routine, basically a function

print_ok:
    mov si, OK_MSG
    jmp print_string

; =====================================================================================================================
; DATA

boot_drive db 0

; strings
BOOT_START_MSG db "Boot Start!", 0dh, 0ah, 0
A20_ENABLE_FAILED_MSG db "A20 Line Enable Failed!", 0
STAGE2_LOAD_FAILED_MSG db "Stage 2 Load Failed!", 0
SYSHALT_MSG db " System Halted.", 0
OK_MSG db "OK", 0

; structs
stage2_dap:
    db 0x10          ; size of packet
    db 0x00          ; reserved
    dw STAGE2_SECTOR_COUNT
    dw STAGE2_LOAD_OFFSET
    dw STAGE2_LOAD_SEG
    dq STAGE2_SECTOR

_gdt:
.start:
    dq 0x0000000000000000    ; Null Segment

    ; Kernel Code Segment
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x9A        ; present, code, exec/read
    db 0xCF
    db 0x00

    ; Kernel Data Segment
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 0x92        ; present, data, read/write
    db 0xCF
    db 0x00
.end:
.descriptor:
    dw .end - .start - 1
    dd .start

times 510-($-$$) db 0
dw 0xaa55