%macro _GDT_ACCESS 4
    db (%1 << 7) | (%2 << 5) | (%3 << 4) | %4
%endmacro

%macro _GDT_GRANULARITY 5
    db (%1 << 7) | (%2 << 6) | (%3 << 5) | (%4 << 4) | %5
%endmacro

_gdt:
    ; Global Descriptor Table to activate protected mode
    
    .start:
        dq 0 ; Null Segment

        ; Kernel-mode Code Segment
        dw 0xffff                          ; LimitLow
        dw 0x0000                          ; Base (low 16 bits)
        db 0x00                            ; Base (mid 8 bits)
        _GDT_ACCESS 1, 00b, 1, 1010b       ; Access
        _GDT_GRANULARITY 1, 0, 1, 0, 1010b ; Granularity
        db 0x00                            ; Base (high 8 bits)

        ; Kernel-mode Data Segment
        dw 0xffff
        dw 0x0000
        db 0x00
        _GDT_ACCESS 1, 00b, 1, 0010b
        _GDT_GRANULARITY 1, 0, 1, 0, 0011b
        db 0x00

        ; User-mode Code Segment
        dw 0xffff
        dw 0x0000
        db 0x00
        _GDT_ACCESS 1, 11b, 1, 1010b
        _GDT_GRANULARITY 1, 0, 1, 0, 1111b
        db 0x00b

        ; User-mode Data Segment
        dw 0xffff
        dw 0x0000
        db 0x00
        _GDT_ACCESS 1, 11b, 1, 0010b
        _GDT_GRANULARITY 1, 0, 1, 0, 1111b
        db 0x00

        ; TSS
        ; dw 0xffff       ; LimitLow
        ; dw 0x0000       ; Base (low 16 bits)
        ; db 0x00         ; Base (mid 8 bits)
        ; db 10000011b    ; Access
        ; db 11001111b    ; Granularity
        ; db 0x00         ; Base (high 8 bits)
    .end:

    .descriptor:
        dw .end - .start - 1
        dd .start

; =========================================================================================================================================================================
; REFERENCES
; Access: 7 6 5 4 3 2 1 0                                                       Granularity: 7 6 5 4 3 2 1 0
;    Bit 7 (P): Present bit                                                         Bit 7 (G): Granularity
;         1: segment is present in memory                                                0: limit is in bytes (max 1MB)
;         0: segment not present                                                         1: limit is in 4KB pages (max 4GB) → Recommended
;    Bit 6-5 (DPL): Descriptor Privilege Level                                      Bit 6 (D): Default operation size (for code segments) / Big
;         00: ring 0 → highest privilege (kernel)                                        0: 16-bit segment
;         01: ring 1                                                                     1: 32-bit segment → Recommended
;         10: ring 2                                                                Bit 5 (L): 64-bit code segment
;         11: ring 3 → lowest privilege (user)                                           0: 32-bit code segment
;    Bit 4 (S): Descriptor type                                                          1: 64-bit code segment (IA-32e / x86-64)
;         0: system segment (e.g., LDT, TSS, call gate, etc.)                       Bit 4 (AVL): Available for use by system software
;         1: code or data segment                                                        0: not available
;    Bit 3-0 (Type): Segment type → T 2 1 0                                              1: available
;         Data Segment: T = 0                                                       Bit 3-0: High bits of segment limit → Combined with low 16 bits to form 20-bit limit
;             Bit 2 (E): Expand-down
;             Bit 1 (W): Writable
;             Bit 0 (A): Accessed
;         Code Segment: T = 1
;             Bit 2 (C): Conforming
;             Bit 1 (R): Readable
;             Bit 0 (A): Accessed
; 
; =========================================================================================================================================================================