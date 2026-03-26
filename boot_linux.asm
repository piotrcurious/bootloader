[bits 16]
[org 0x7C00]

COM1 equ 0x3f8

_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [dr], dl

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

    mov al, 'B'
    call pc

    ; 1. Load Setup/Header to 0x9000:0000
    mov si, d_s
    mov ah, 0x42
    mov dl, [dr]
    int 0x13
    jc err

    ; 2. Magic Check
    mov ax, 0x9000
    mov es, ax
    cmp dword [es:0x202], 0x53726448
    jne no_m
    mov al, 'M'
    call pc

    ; 3. Setup sects
    movzx ecx, byte [es:0x1F1]
    test cl, cl
    jnz .s_ok
    mov cl, 4
.s_ok:
    add ecx, 2 ; LBA of kernel = setup_sects + 2
    mov [d_k_l], ecx

    ; 4. Load Kernel to 1MB
    mov edi, 0x100000
    mov cx, 240 ; Load ~15MB
.l:
    push cx
    mov si, d_k
    mov ah, 0x42
    mov dl, [dr]
    int 0x13
    jc .d

    push ds
    mov ax, 0x1000
    mov ds, ax
    xor esi, esi
    mov ecx, (127 * 512) / 4
    rep movsd
    pop ds
    add dword [d_k_l], 127
    mov al, '.'
    call pc
    pop cx
    loop .l
.d:

    ; 5. Finalize Zero Page at 0x9000:0000
    mov ax, 0x9000
    mov es, ax
    ; Zero out non-header
    xor di, di
    mov cx, 0x1F1 / 2
    xor ax, ax
    rep stosw

    mov byte [es:0x0210], 0xFF
    mov byte [es:0x0211], 0x81
    mov word [es:0x0224], 0xDE00
    mov dword [es:0x0228], 0x98000

    ; Cmdline
    mov si, cmd
    mov di, 0x8000
    mov cx, cmd_len
    rep movsb

    ; E820
    mov byte [es:0x01E8], 1
    mov di, 0x02D0
    mov dword [es:di], 0
    mov dword [es:di+4], 0
    mov dword [es:di+8], 0x20000000 ; 512MB
    mov dword [es:di+12], 0
    mov dword [es:di+16], 1

    mov al, 'J'
    call pc

    ; 6. Jump
    mov dl, [dr]
    mov ax, 0x9000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE
    jmp 0x9020:0000

err: mov al, 'E'; call pc; jmp $
no_m: mov al, 'X'; call pc; jmp $

pc:
    push ax
    push dx
    mov dx, COM1 + 5
.w: in al, dx
    test al, 0x20
    jz .w
    pop dx
    pop ax
    push ax
    push dx
    mov dx, COM1
    out dx, al
    pop dx
    pop ax
    ; BIOS too
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    ret

cmd db "console=ttyS0 earlyprintk=serial,ttyS0,115200", 0
cmd_len equ $ - cmd
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
