[bits 16]
[org 0]

start:
    cli
	mov ax, 07C0h	    	; Set up 4K stack space after this bootloader
	add ax, 288		        ; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096
    sti

	mov ax, 07C0h		    ; Set data segment to where we're loaded
	mov ds, ax

    mov [boot_drive], dl    ; Save boot device number

    ; Initialize stage 2
    mov bx, 0x1000         ; Buffer address (0x1000:0x0000)
    xor ax, ax
    mov es, ax

    mov ah, 02h          ; BIOS function to read sectors
    mov al, 1            ; Read 1 sector
    mov ch, 0            ; Cylinder 0
    mov cl, 2            ; Sector 2 (logical sector 1)
    mov dh, 0            ; Head 0
    mov dl, [boot_drive] ; Boot drive number
    int 0x13             ; Call BIOS interrupt to read sector
    jc disk_error  ; Check for errors

    ; Success: jump to loaded code at 0x1000:0x0000
	jmp 0x0000:0x1000

disk_error:
    mov si, err_msg
    call print_string

hang:
    hlt
    jmp hang

; Includes

%include "routines/print_string.asm"

; Variable declarations

err_msg    db 'Disk read error!', 0
boot_msg   db 'Bootloader Initialization Verified', 0
boot_drive db 0

times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
dw 0AA55h		; The standard PC boot signature