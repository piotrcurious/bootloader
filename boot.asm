[bits 16]
[org 0x7C00]

_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov [0x500], dl

    mov ah, 0x42
    mov dl, [0x500]
    mov si, dap
    int 0x13
    jmp 0x0000:0x8000

dap db 0x10, 0
    dw 1, 0, 0x8000
    dq 1

times 510-($-$$) db 0
dw 0xAA55
