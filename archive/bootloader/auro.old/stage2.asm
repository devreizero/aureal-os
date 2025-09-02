[bits 16]
[org 0x1000]    ; This follows the BX in stage1, just make sure that the ES is set to 0:
                ;                                                           xor ax, ax
                ;                                                           mov es, ax

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

; =====================================================================================================================
; Padding
times (512 - (($ - $$) % 512)) % 512 db 0
