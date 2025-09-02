; The routine used to print string

print_string:
    ; We would obviously love to have a string printing routine, especially for debugging
    mov ah, 0eh  ; BIOS print char function

.loop:
    lodsb        ; Gets 1 char from SI into AL, then increment SI
    test al, al  ; 
    jz .done     ; If AL is 0, it's done, since the string is null terminated
    int 10h      ; Calls function 0x0e (AH) from interrupt 0x10 (Video Interrupt)
    jmp .loop    ; Loop back

.done:
    ret          ; Return back because it's a routine, basically a function