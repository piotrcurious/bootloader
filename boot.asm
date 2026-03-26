[bits 16]
[org 0x7C00]

_start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Save drive number from DL
    mov [drive_number], dl

    ; Clear direction flag for lodsb
    cld

    ; Print "Booting..."
    mov si, msg_booting
    call print_string

    ; Load kernel (LBA 1, 1 sector, to 0x8000)
    mov ah, 0x42
    mov dl, [drive_number]
    mov si, dap
    int 0x13
    jc disk_error

    ; Jump to kernel
    mov si, msg_jumping
    call print_string
    jmp 0x0000:0x8000

disk_error:
    mov si, msg_error
    call print_string
    jmp $

print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    call write_serial
    jmp .loop
.done:
    ret

write_serial:
    push dx
    mov dx, 0x3f8 + 5
.wait:
    in al, dx
    test al, 0x20
    jz .wait
    mov dx, 0x3f8
    mov al, [si-1]
    out dx, al
    pop dx
    ret

msg_booting db "Booting...", 13, 10, 0
msg_jumping db "Jumping...", 13, 10, 0
msg_error   db "Error!", 13, 10, 0
drive_number db 0

align 4
dap:
    db 0x10    ; size
    db 0       ; reserved
    dw 1       ; sectors
    dw 0x8000  ; offset
    dw 0       ; segment
    dq 1       ; LBA

times 510-($-$$) db 0
dw 0xAA55
