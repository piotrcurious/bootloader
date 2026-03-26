[bits 16]
[org 0x7C00]

; --- Refined Linux Bootloader ---
; Implements Linux Boot Protocol for bzImage

_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [dr], dl
    cld

    ; 1. Enable A20 (Fast A20)
    in al, 0x92
    or al, 2
    out 0x92, al

    ; 2. Enter Unreal Mode
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

    ; 3. Load Setup Code/Header to 0x9000:0000
    ; 64 sectors should be enough for any modern setup code
    mov si, d_s
    mov ah, 0x42
    mov dl, [dr]
    int 0x13
    jc $ ; Hang on error

    ; 4. Check Magic "HdrS" at 0x9000:0202
    mov ax, 0x9000
    mov es, ax
    cmp dword [es:0x202], 0x53726448
    jne $

    ; 5. Load Protected-Mode Kernel to 1MB
    ; Kernel LBA = 1 (vmlinuz start) + 1 (boot sect) + setup_sects (offset 0x1F1)
    movzx ecx, byte [es:0x1F1]
    test cl, cl
    jnz .s_ok
    mov cl, 4
.s_ok:
    add ecx, 2 ; Result in ECX
    mov [d_k_l], ecx

    ; Dynamically determine how many sectors to load
    ; bzImage protected mode size is at offset 0x1F4
    mov eax, [es:0x1F4]
    add eax, 511
    shr eax, 9 ; Total sectors
    mov [k_sects], eax

    mov edi, 0x100000 ; 1MB
.l:
    mov eax, [k_sects]
    test eax, eax
    jz .d

    cmp eax, 127
    jbe .last
    mov eax, 127
.last:
    mov [d_k_s], ax

    mov si, d_k
    mov ah, 0x42
    mov dl, [dr]
    int 0x13
    jc .d

    ; Move to 1MB
    push ds
    mov ax, 0x1000
    mov ds, ax
    xor esi, esi
    movzx ecx, word [d_k_s]
    shl ecx, 9
    shr ecx, 2
    rep movsd
    pop ds

    movzx eax, word [d_k_s]
    add [d_k_l], eax
    sub [k_sects], eax
    jmp .l
.d:

    ; 6. Finalize Zero Page at 0x9000:0000
    ; DO NOT zero out the header we just loaded!
    ; Only clear parts before 0x1F1 and after the header
    ; For simplicity, we assume the header we loaded is correct.

    mov byte [es:0x0210], 0xFF ; type_of_loader
    mov byte [es:0x0211], 0x81 ; loadflags
    mov word [es:0x0224], 0xDE00 ; heap_end_ptr
    mov dword [es:0x0228], 0x98000 ; cmd_line_ptr

    ; Copy Cmdline to 0x98000
    mov si, cmd
    mov di, 0x8000
    mov cx, cmd_len
    rep movsb

    ; 7. Jump to setup code at 0x9020:0000
    mov dl, [0x7C00 + (dr - _start)]
    mov ax, 0x9000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE
    jmp 0x9020:0000

cmd db "console=ttyS0 earlyprintk=ttyS0", 0
cmd_len equ $ - cmd
dr db 0
k_sects dd 0

align 8
gdt: dq 0, 0x00CF92000000FFFF
gptr: dw 15
      dd gdt

d_s: db 0x10, 0
     dw 64, 0, 0x9000 ; 64 sectors to 0x9000:0000
     dq 1

d_k: db 0x10, 0
d_k_s: dw 127
     dw 0, 0x1000 ; buffer at 0x1000:0000
d_k_l: dq 0

times 510-($-$$) db 0
dw 0xAA55
