_idt:
    ; Interrupt Descriptor Table (IDT) for 32-bit protected mode
    ; Each entry is 8 bytes: OffsetLow (2) | Selector (2) | Zero (1) | Type/Attr (1) | OffsetHigh (2)

    .start:
        ; Example entry: interrupt 0 (divide by zero)
        dw 0x0000       ; Offset low 16 bits of handler
        dw 0x08         ; Code segment selector (from GDT)
        db 0x00         ; Reserved, always 0
        db 10001110b    ; Type/Attr: P=1, DPL=0, 32-bit interrupt gate
        dw 0x0000       ; Offset high 16 bits of handler

        ; Next entries can be defined similarly
        ; For 256 entries, repeat structure as needed
        times 255 dq 0 ; Initialize remaining entries to zero
    .end:

    .descriptor:
        dw .end - .start - 1     ; Limit (size of IDT - 1)
        dd .start                ; Base address of IDT

; ================================================================================================================================
; REFERENCES
; Type/Attr: 8 bits
;    Bit 7 (P): Present
;         1 = interrupt handler present
;         0 = not present
;    Bit 6-5 (DPL): Descriptor Privilege Level
;         00 = Ring 0 (kernel)
;         11 = Ring 3 (user)
;    Bit 4: Reserved, always 0
;    Bit 3-0: Gate type
;         1110b = 32-bit interrupt gate
;         1111b = 32-bit trap gate
;
; IDT Entry Layout (8 bytes):
;    OffsetLow  (2 bytes) → Lower 16 bits of handler address
;    Selector   (2 bytes) → GDT code segment selector
;    Zero       (1 byte)  → Reserved
;    Type/Attr  (1 byte)  → Interrupt/trap gate, present, DPL
;    OffsetHigh (2 bytes) → Upper 16 bits of handler address
;
; Total entries: 256 (0x00 to 0xFF)
; ================================================================================================================================
