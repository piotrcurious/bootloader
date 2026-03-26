# i386 Bootloader Project

This project contains two functional x86 bootloaders, a demonstration kernel, and a BusyBox-compatible management tool.

## Components

1.  **Basic Bootloader (`boot.asm`)**: A NASM assembly bootloader that loads a simple C kernel from the second sector of the disk using BIOS LBA extensions.
2.  **Linux Bootloader (`boot_linux.asm`)**: A specialized bootloader that implements the Linux Boot Protocol. It enables the A20 line, enters "Unreal Mode" to load the kernel to the 1MB mark, and supports custom boot command lines.
3.  **Simple Kernel (`kernel_c.c`)**: A 16-bit C kernel that prints "Hello from Kernel!" to the COM1 serial port.
4.  **Boot Tool (`btl`)**: A BusyBox-compatible shell script for managing disk images and bootloader installations.

## Boot Management Tool (`btl`)

The `btl` script is designed for maximum portability using BusyBox.

### Usage
```bash
./btl image-create [file] [bootloader.bin] [kernel.bin]  # Create a bootable 10MB image
./btl boot-install [device/file] [bootloader.bin]      # Write bootloader to MBR
./btl kernel-update [device/file] [kernel.bin]          # Update kernel at LBA 1
```

## Build and Run

### Manual Build
To build the basic bootloader and demo kernel:
```bash
./build.sh
```

### Creating Images with `btl`
```bash
./btl image-create my_disk.img boot.bin kernel.bin
```

### Running in QEMU
```bash
qemu-system-i386 -hda my_disk.img -serial stdio -display none
```

## Requirements
- `nasm`
- `gcc` (with 16-bit support)
- `binutils` (ld)
- `qemu-system-x86`
- `busybox` (for `btl`)
