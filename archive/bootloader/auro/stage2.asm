; stage2_pm.asm - assemble as flat binary and place after boot sectors
; nasm -f bin stage2_pm.asm -o stage2.bin

[BITS 32]
[org 0x0000]

%define GDT_KCODE_SEGMENT 0x08
%define GDT_KDATA_SEGMENT 0x10

start_pm:
    call init_idt
    ; lea eax, [idt_descriptor]
    ; add eax, 0x10000
    ; mov [tmp_descriptor], eax
    ; lidt [tmp_descriptor]

    ; write "STAGE2 PM" at top-left by directly writing to VGA memory 0xB8000
    mov edi, 0xb8000
    mov ax, 'Z' | ('e' << 8)
    stosw

    ;sti
    jmp hang32

init_idt:
    lea edi, [idt_start]
    mov eax, dummy_handler
    mov bx, ax
    shr eax, 16
    mov cx, 256

.loop:
    mov [edi], ax
    mov [edi+6], eax
    add edi, 8
    dec cx
    jnz .loop
    
.init_descriptor:
    lea eax, [idt_end]
    sub eax, idt_start
    dec eax
    mov word [idt_descriptor], ax
    mov dword [idt_descriptor+2], idt_start
    ret

dummy_handler:
    cli
hang32:
    hlt
    jmp hang32


; =====================================================================================================================
; DATA

idt_start:
%assign idt_entry 0
%rep 256
    dw 0                          ; Offset Low
    dw GDT_KCODE_SEGMENT
    db 0                          ; RESERVED
    db 0x8E                       ; Type/Attributea
    dw 0                          ; Offset High
    %assign idt_entry idt_entry+1
%endrep
idt_end:
idt_descriptor:
    dw 0
    dd 0
tmp_descriptor:
    dw 0
    dd 0