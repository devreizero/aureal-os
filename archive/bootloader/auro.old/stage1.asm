[bits 16]
[org 0]

start:
    ; ======================================================================================================================
    ; SETTING UP 4KiB OF STACK
    cli             ; Clear Interrupt, We don't want any interruption from the BIOS when setting up the stack
    xor ax, ax      ; 
    mov ss, ax      ; Set up stack bottom address
    mov sp, 0x7C00  ; Set up stack top address
    sti             ; Start Interrupt
    ; =====================================================================================================================
    ; SETTING UP THE DATA SEGMENT
    mov ax, 0x07c0  ; |
    mov ds, ax      ; | Move the data segment to 0x07c0
    cld             ; Clear Direction Flag,
                    ; just to make sure that index related operation are incremented rather than decremented
   
    mov [boot_drive], dl ; Storing the BootDrive from dl to the boot_drive variable

    ; =====================================================================================================================
    ; INITIALIZATION OF STAGE 2
    mov bx, 0x1000          ; Stage 2 internal offset
    xor ax, ax              ; Zero-ify ax
    mov es, ax              ; ExtraSegment is now 0!
    xor ah, ah              ; |
    int 13h                 ; | Reset disk controller

    mov si, 3               ; Retry count

.try_load_stage2_loop:
    ; =====================================================================================================================
    ; It's a loop because the BIOS might fail to load our 2nd stage bootloader desppite our code being correct already
    mov ah, 02h             ; BIOS Function No. 2
    mov al, 4               ; Amount of sector to read (512 times AL)
    mov ch, 0               ; Cylinder 0
    mov cl, 2               ; Sector 2 (Logical Sector 1)
    mov dh, 0               ; Head 0
    mov dl, [boot_drive]    ; Move boot_drive to DL again, just to make sure

    int 13h                 ; BIOS Interrupt 13h (Category: Disk Management)
    jc .read_fail           ; If carry flag is set, there is an error when loading stage 2 to memory, jump to .read_fail
    jmp 0x0000:0x1000       ; Mirror stage 2 ORG

.read_fail:
    dec si
    jnz .try_load_stage2_loop

    ; If all tries fails:
    mov si, DISK_READ_TOTAL_FAILURE_ERROR
    call print_string

    ; Then we tries to re-boot:
    int 19h

hang: ; NOTE: This is a continuation
    hlt                 ; Halt the CPU
    jmp hang            ; Loop it

; =====================================================================================================================
; Includes List
%include "bootloader/auro/routines/print_string.asm"

; =====================================================================================================================
; Variables or Data
DISK_READ_TOTAL_FAILURE_ERROR db 'Failure when reading stage 2 into memory.', 0
boot_drive db 0

; =====================================================================================================================
; Padding
times 510-($-$$) db 0
dw 0aa55h