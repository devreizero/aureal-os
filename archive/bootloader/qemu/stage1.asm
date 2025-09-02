[bits 16]
[org 0]

BIOS13_EXTENDED_READ equ 0x42
BIOS15_QUERY_A20 equ 0x2403
BIOS15_A20_STATUS equ 0x2402
BIOS15_ENABLE_A20 equ 0x2401
GDT_KCODE_SEGMENT equ 0x08
GDT_KDATA_SEGMENT equ 0x10 ; Same as 16 in decimal, so don't be confused
SEGMENT_STACK equ 0x2000
SEGMENT_BUFFER equ 0x7000
STAGE2_SECTOR equ 1
STAGE2_SECTOR_COUNT equ 16
STAGE2_LOAD_SEG equ 0x1000
STAGE2_LOAD_OFFSET equ 0x0000
%define STAGE2_LOAD_ADDRESS STAGE2_LOAD_SEG:STAGE2_LOAD_OFFSET

%macro print 1
    mov si, absaddr(%1)
    call print_string
%endmacro

%define absaddr(addr) ((addr) - $$ + 0x7c00)
%define padto(addr) times ((addr) - ($ - $$)) db 0

global _start:
_start:
before_start:
    jmp after_bpb
    nop

    padto(4)

mode db 0
stage2_dap:
    sectors dd 0
    heads dd 0
    cylinder dw 0
    sector_start db 0
    head_start db 0
    cylinder_start dw 0

padto(62)

boot_drive db 0xFF
stage2_address dw 0x8000
stage2_sector dd 1
stage2_segment dw 0

after_bpb:
    cli

    test dl, 0x80
    jnz fjmp_start
    mov dl, 0x80

fjmp_start:
    jmp 0x0000:absaddr(start)
    
start:
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, SEGMENT_STACK
    sti

    mov al, [absaddr(boot_drive)]
    cmp al, 0xff
    je probe_drive
    mov dl, al

probe_drive:
    push dx
    print notification_message

    test dl, 0x80 ; 1000 0000b
    jz chs_mode

    ; CHECK LBA SUPPORT
    mov ah, 0x41
    mov bx, 0x55aa
    int 0x13

    ; dl may have been clobbered by INT 13, AH=41H.
	; This happens, for example, with AST BIOS 1.04.
    pop dx
    push dx

    jc chs_mode
    cmp bx, 0x55
    jne chs_mode
    and cx, 1
    jz chs_mode

lba_mode:
    mov ecx, [si+0x10]
    mov si, absaddr(stage2_dap)
    mov byte [si-1], 1
    mov ebx, absaddr(stage2_sector)

    mov word si, 0x0010                 ; Size of DAP packet, always 16 (0x0010)
    mov word [si+2], 1                  ; Amount of sector to read, 1 sector is 512 bytes
    mov dword [si+8], ebx               ; SI (Offset): Lower 32-bits
    mov word [si+6], SEGMENT_BUFFER    ; ES (Segment): Segment of buffer

    xor dword eax, eax
    mov word [si+4], ax                 ; Reserved
    mov dword [si+12], eax              ; SI (Offset): Upper 32-bits

    ; BIOS call "INT 0x13 Function 0x42" to read sectors from disk into memory
    ;	Call with	AH = 0x42
    ; 			DL = drive number
    ;			DS:SI = segment:offset of disk address packet
    ;	Return:
    ;			AL = 0x0 on success; error code on failure
    mov ah, 0x42
    int 0x13
    
    jc chs_mode    ; LBA Read isn't supported, stupid BIOS
    mov bx, SEGMENT_BUFFER
    jmp copy_buffer

chs_mode:
    mov ah, 0x8
    int 0x13
    jnc final_init

    test dl, 0x80
    jz floppy_probe
    jmp hdd_probe_error

final_init:
    mov si, absaddr(sectors)
    mov byte [si-1], 0

	xor	eax, eax
	mov	al, dh
	inc	ax
	mov	[si+4], eax

	xor	dx, dx
	mov	dl, cl
    shl	dx, 2
	mov	al, ch
	mov	ah, dh

    inc	ax
	mov	[si+8], ax

	xor ax, ax
	mov	al, dl
    shr	al, 2

    mov si, [eax]

setup_sectors:
    mov	eax, absaddr(stage2_sector)
	xor	edx, edx
	div dword [si]

    mov [si+10], dl

    xor edx, edx
    div dword [si+4]

    mov [si+11], dl
    mov word [si+12], ax

    cmp ax, [si+8]
	jge	geometry_error

    mov dl, [si+13]
    
    shl dl, 6
    mov cl, [si+10]
    
    inc cl
    or cl, dl
    mov ch, [si+12]
    
	pop	dx
	
    mov dh, [si+11]

    ; BIOS call "INT 0x13 Function 0x2" to read sectors from disk into memory
    ;	 Call with	%ah = 0x2
    ;			%al = number of sectors
    ;			%ch = cylinder
    ;			%cl = sector (bits 6-7 are high bits of "cylinder")
    ;			%dh = head
    ;			%dl = drive (0x80 for hard disk, 0x0 for floppy disk)
    ;			%es:%bx = segment:offset of buffer
    ;	Return:
    ;			%al = 0x0 on success; err code on failure

    mov bx, SEGMENT_BUFFER
    mov es, bx

    xor bx, bx
    mov ax, 0x0201
	int	0x13

	jc read_error

	mov	bx, es

copy_buffer:
    mov ax, absaddr(stage2_segment)
    mov es, ax

	; We need to save CX and SI because the startup code in
	; stage2 uses them without initializing them.
	
	pusha
	push ds
	
    mov cx, 0x100
    mov ds, bx
    xor si, si
    xor di, di
	
	cld
	
	rep movsw

	pop ds
	popa

	jmp	[stage2_address]

geometry_error:
    print geometry_error_message
    jmp general_error

hdd_probe_error:
    print hdd_probe_error_message
    jmp general_error

read_error:
    print read_error_message

general_error:
    print general_error_message

stop:
    jmp stop

notification_message db "AURO ", 0
geometry_error_message db "Geom", 0
hdd_probe_error_message db "Hard Disk", 0
read_error_message db "Read", 0
general_error_message db " Error", 0

actual_printer:
    mov bx, 0x0001
    mov ah, 0xe
    int 0x10

print_string:
    lodsb
    cmp al, 0
    jne actual_printer
    ret

padto(440)
nt_magic:
    dd 0
    dw 0

part_start:
    padto(446)

probe_values db 36, 18, 15, 9, 0

floppy_probe:
    mov si, absaddr(probe_values - 1)

probe_loop:
    xor ax, ax
    int 0x13

    inc si
    mov cl, [si]

    cmp cl, 0
    jne try_disk_read

    print fd_probe_error_message
    jmp general_error

fd_probe_error_message db "Floppy", 0

try_disk_read:
    mov bx, SEGMENT_BUFFER
    mov ax, 0x201
    mov dh, 0
    mov ch, 0
    int 0x13

    jc probe_loop

    mov dh, 1
    mov ch, 79

    jmp final_init

padto(510)
dw 0xaa55