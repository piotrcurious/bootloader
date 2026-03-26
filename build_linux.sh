#!/bin/bash
set -e

# Assemble bootloader
nasm -f bin boot_linux.asm -o boot_linux.bin

# Check if vmlinuz exists
if [ ! -f vmlinuz ]; then
    echo "vmlinuz not found. Attempting to download..."
    apt-get download linux-image-generic
    dpkg-deb -x linux-image-generic_*.deb extracted_kernel
    cp extracted_kernel/boot/vmlinuz-* vmlinuz
    rm -rf extracted_kernel linux-image-generic_*.deb
fi

# Create disk image
dd if=boot_linux.bin of=linux_disk.img bs=512 count=1
dd if=vmlinuz of=linux_disk.img bs=512 seek=1 conv=notrunc

echo "Linux disk image 'linux_disk.img' created successfully."
