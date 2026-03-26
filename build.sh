#!/bin/bash
set -e

# Compile bootloader assembly
nasm -f bin boot.asm -o boot.bin

# Compile kernel C
gcc -fno-PIC -fomit-frame-pointer -ffreestanding -m16 -Os -c kernel_c.c -o kernel.o
ld -m elf_i386 -T kernel_linker.ld kernel.o -o kernel.bin

# Create disk image
dd if=boot.bin of=disk.img bs=512 count=1 conv=notrunc
dd if=kernel.bin of=disk.img bs=512 seek=1 conv=notrunc

echo "Disk image 'disk.img' created successfully."
