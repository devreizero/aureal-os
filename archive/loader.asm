; loader.asm - stage2
[ORG 0x1000]
[bits 16]

start:
    cli

    ; Load kernel 32-bit dari sektor 4 ke 0x2000
    mov bx, 0x0000
    mov ax, 0x2000
    mov es, ax
load_kernel:
    mov ah, 0x02
    mov al, 1
    mov ch, 0
    mov ax, 4
    add ax, bx
    mov cl, al
    mov dh, 0
    mov dl, 0x80
    int 0x13
    jc fail
    add si, 512
    inc bx
    cmp bx, 4      ; 4 sectors kernel
    jl load_kernel

    ; Setup GDT minimal
    lgdt [gdt_desc]

    ; enable protected mode
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump untuk flush prefetch queue
    jmp CODE_SEG:init_pm

fail:
    hlt

; GDT setup
gdt_start:
    dq 0x0000000000000000   ; null
    dq 0x00CF9A000000FFFF   ; code
    dq 0x00CF92000000FFFF   ; data
gdt_end:

gdt_desc:
    dw gdt_end - gdt_start - 1
    dd gdt_start

[bits 32]
CODE_SEG equ 0x08

init_pm:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x90000        ; stack

    ; Panggil kernel yang sudah 32-bit
    jmp 0x2000             ; pastikan kernel di-link ke 0x2000

hang:
    hlt
    jmp hang
