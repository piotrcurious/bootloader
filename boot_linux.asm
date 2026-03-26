[bits 16]
[org 0x7C00]

; Refined Linux Bootloader with Command Line Support
; Fits in 512 bytes

_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [dr], dl
    cld

    ; Enable A20
    in al, 0x92
    or al, 2
    out 0x92, al

    ; Unreal Mode
    lgdt [gptr]
    mov eax, cr0
    inc ax
    mov cr0, eax
    jmp $+2
    mov bx, 0x08
    mov ds, bx
    mov es, bx
    dec ax
    mov cr0, eax
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 1. Load Setup to 0x9000
    mov si, d_s
    mov ah, 0x42
    mov dl, [dr]
    int 0x13
    jc $

    ; 2. Magic Check
    mov ax, 0x9000
    mov es, ax
    cmp dword [es:0x202], 0x53726448
    jne $

    ; 3. Setup size
    movzx ecx, byte [es:0x1F1]
    test cl, cl
    jnz .ok
    mov cl, 4
.ok:
    add ecx, 2
    mov [d_k_l], ecx

    ; 4. Load Kernel to 1MB
    mov edi, 0x100000
    mov cx, 300
.l:
    push cx
    mov si, d_k
    mov ah, 0x42
    mov dl, [dr]
    int 0x13
    push ds
    mov ax, 0x1000
    mov ds, ax
    xor esi, esi
    mov ecx, (127*512)/4
    rep movsd
    pop ds
    add dword [d_k_l], 127
    pop cx
    loop .l

    ; 5. Params
    mov ax, 0x9000
    mov es, ax
    xor di, di
    mov cx, 1024
    rep stosb

    ; Mandatory fields
    mov byte [es:0x210], 0xFF
    mov byte [es:0x211], 0x81
    mov word [es:0x224], 0xDE00

    ; COMMAND LINE SUPPORT
    mov dword [es:0x228], 0x98000 ; cmd_line_ptr
    mov si, cmd
    mov di, 0x8000
    mov cx, 32
    rep movsb

    ; 6. Jump
    mov dl, [dr]
    mov ax, 0x9000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE
    jmp 0x9020:0000

cmd db "console=ttyS0 earlyprintk=ttyS0", 0
dr db 0
gdt: dq 0, 0x00CF92000000FFFF
gptr: dw 15
      dd gdt
d_s: db 0x10, 0
     dw 64, 0, 0x9000
     dq 1
d_k: db 0x10, 0
     dw 127, 0, 0x1000
d_k_l: dq 0

times 510-($-$$) db 0
dw 0xAA55
