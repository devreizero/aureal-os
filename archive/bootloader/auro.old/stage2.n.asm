[bits 16]
[org 0x1000]    ; This follows the BX in stage1, just make sure that the ES is set to 0:
                ;                                                           xor ax, ax
                ;                                                           mov es, ax

global stage2_start
global protected_mode_start
global dummy_handler
extern kmain

stage2_start:
    ; ======================================================================================================================
    ; The function name can be anything, it doesn't need to be stage2_start, it can even be just start like in stage1
    cli            ; Clear Interrupt, because we're setting up the DS and ES
    xor ax, ax     ; |
    mov ds, ax     ; | Reset DS and ES to 0 
    mov es, ax     ; | 

    mov ax, 0x2000 
    mov ss, ax     ; Set the stack base pointer
    mov sp, 0x2200 ; The stack size is (0x2200 - 0x2000: 512 bytes)
    sti            ; Start Interrupt
    
    mov [boot_drive], dl

    mov si, STAGE2_LOAD_MSG
    call print_string

    ; CONTEXT: Activating A20
    call check_a20

    ; Now activating A20 if haven't
    test bl, bl
    jz after_a20

    ; A20 Activation
a20_fast_a20_gate:
    ; Fast A20 Gate Method, supported since 386+
    in al, 0x92
    test al, 2
    jnz after_a20
    or al, 2
    and al, 0xFE
    out 0x92, al
    test bl, bl
    jz after_a20

a20_bios:
    mov ax, 2403h    ; AX is used instead of AH for the function because Interrupt 15h has so many functions that AH can't fit them
    int 15h          ; Check whether the BIOS supports checking A20 Activation
    jb a20_fail      ; The BIOS is also incapable of activating A20 Line
    cmp ah, 0        ;  ⇅
    jnz a20_fail     ; Same

    cmp al, 1
    jz after_a20     ; A20 is on already

    mov ax, 2401h
    int 15h          ; Activating A20 via BIOS
    jb a20_fail
    cmp ah, 0
    jnz a20_fail

after_a20:
    ; After A20 Line is ready, we're setting up
    ; mov ax, 0x0500  ; 0x0500:0x0000 is 0x0500 * 16 + 0x0000
    ; mov es, ax      ; which is 0x5000, our kernel's address
    ; xor bx, bx
    ;
    ; mov si, dap         ; DAP for:

    ;mov ax, dap
    ;mov es, ax
    ;xor bx, bx
    ;mov ah, 42h         ; BIOS Extended Read (LBA)
    ;int 13h             ;
    ;jc kernel_load_fail ; There's an error; Load GDT

    ;cli   ; Clear Interrupt since we don't need the BIOS. In fact, the BIOS shouldn't bother us

    ;xor ax, ax
    ;mov ds, ax ; This is a MUST, GDT expects it.
    ;lgdt [_gdt.descriptor]

    ; Enable protected mode
    ;mov eax, cr0
    ;or eax, 1
    ;mov cr0, eax

    ; Far jump ke code segment di GDT
    ;jmp 0x08:protected_mode_start
    jmp hang

kernel_load_fail:
    mov si, KERNEL_LOAD_FAIL_MSG
    call print_string
    jmp hang

a20_fail:
    mov si, A20_FAIL_ACTIVATE_MSG
    call print_string

hang:
    hlt
    jmp hang

;
; Routines that were internal
check_a20:
    ; Function: check_a20
    ;
    ; Purpose: to check the status of the a20 line in a completely self-contained state-preserving way.
    ;          The function can be modified as necessary by removing push's at the beginning and their
    ;          respective pop's at the end if complete self-containment is not required.
    ;
    ; Returns: 0 in ax if the a20 line is disabled (memory wraps around)
    ;          1 in ax if the a20 line is enabled (memory does not wrap around)
    ; (Source: https://wiki.osdev.org/A20_Line)

    ; ======================================================================================================================
    ; Storing flags, DS, and DI to stack because we don't want to change their value
    push ds
    push es
    pushf
    
    xor ax, ax   ; Zero-ify ES!
    mov es, ax   ; 

    dec ax       ; Set AX to 0xFFFF: 0 - 1 is 0xFFFF because of wraparound
    mov ds, ax   ;

    ; Address for the next step
    mov di, 0x0500
    mov si, 0x0510

    ; Store data in [es:di] and [ds:si] to stack before overwriting them
    mov al, byte [es:di]
    mov ah, byte [ds:si]
    push ax

    ; Overwrite the data, [ds:si] will wraparound and set [es:di] data to
    ; 0xFF instead if A20 Line was disabled 
    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF  ; The actual test

    ; Restore all previous data
    pop ax
    mov byte [es:di], al
    mov byte [ds:si], ah

    setnz bl  ; Set the test value into BL
    popf
    pop es
    pop ds

    ret

; =====================================================================================================================
; Includes List
%include "bootloader/auro/routines/print_string.asm"
%include "bootloader/auro/gdt.asm"
%include "bootloader/auro/idt.asm"

; =====================================================================================================================
; Variables or Data
STAGE2_LOAD_MSG db 'Stage 2 loaded.', 0dh, 0ah, 0
A20_FAIL_ACTIVATE_MSG db 'Cannot enable A20 Line.', 0dh, 0ah, 0
KERNEL_LOAD_FAIL_MSG db 'Cannot load kernel into memory.', 0dh, 0ah, 0

boot_drive db 0

dap:
    ; Disk Address Packet for loading kernel
    db 16         ; DAP length in bytes, normally always 16
    db 0          ; reserved
    dw 1          ; Amount of sector to read
    dw 0          ; Buffer offset (BX)
    dw 0          ; Buffer segment (ES)
    dq 6          ; Which sector to store the code into.
                  ; In CHS, it start from 1, but in LBA it starts from 0.
                  ; So, CHS sector 3 is LBA sector 2.


[bits 32]

; Protected Mode Codes
protected_mode_start:
    mov ax, 08h       ; Data Segment selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x090000

    ;call init_idt
    ;lidt [_idt.descriptor]

    mov edi, 0xB8000   ; VGA memory start
    mov eax, 0x0F58        ; 'X' (0x58) + attribute (0x0F = white on black)
    mov [edi], ax          ; store character + attribute
    
    sti
    jmp hang32

    ; jmp 0x08:0x00100000

init_idt:
    mov ecx, 32                ; count
    xor ebx, ebx               ; will hold index (0..31)

.init_loop:
    ; compute dest = _idt.start + ebx * 8
    mov edi, _idt.start
    mov eax, ebx
    shl eax, 3                 ; eax = ebx * 8
    add edi, eax               ; edi -> entry base

    ; load handler address
    mov eax, dummy_handler
    ; offset low (word)
    mov ax, ax                 ; ensure AX holds low 16 bits
    mov [edi + 0], ax          ; word
    ; selector
    mov word [edi + 2], 0x08
    ; zero byte
    mov byte [edi + 4], 0
    ; type/attr
    mov byte [edi + 5], 0x8E
    ; offset high (word)
    mov ax, dx                 ; clear ax
    mov edx, eax
    shr edx, 16
    mov ax, dx                 ; ax = high 16
    mov [edi + 6], ax

    inc ebx
    loop .init_loop
    ret

dummy_handler:
    cli

hang32:
    hlt
    jmp hang32

section .bss
align 16
stack_bottom:
    resb 8192
stack_top:

; =====================================================================================================================
; Padding
times (512 - (($ - $$) % 512)) % 512 db 0
