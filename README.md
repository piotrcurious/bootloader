# i386 Bootloader Project

This project contains two functional x86 bootloaders and a demonstration kernel.

## Components

1.  **Basic Bootloader (`boot.asm`)**: A NASM assembly bootloader that loads a simple C kernel from the second sector of the disk using BIOS LBA extensions.
2.  **Linux Bootloader (`boot_linux.asm`)**: A specialized bootloader that implements the Linux Boot Protocol. It enables the A20 line, enters "Unreal Mode" to load the kernel to the 1MB mark, initializes the Zero Page (boot parameters), and jumps to a 32-bit or 64-bit Linux `bzImage` kernel.
3.  **Simple Kernel (`kernel_c.c`)**: A 16-bit C kernel that prints "Hello from Kernel!" to the COM1 serial port and VGA buffer.

## Build and Run

### Basic Bootloader and Kernel
To build the basic bootloader and demo kernel:
```bash
./build.sh
```
To run in QEMU:
```bash
qemu-system-i386 -hda disk.img -serial stdio -display none
```

### Linux Bootloader
To build a disk image with a real Linux kernel (automatically downloads a generic kernel if not present):
```bash
./build_linux.sh
```
To run in QEMU:
```bash
qemu-system-i386 -hda linux_disk.img -m 512 -serial stdio -display none
```
*Note: The Linux bootloader is verified to reach the kernel's setup code and begin initialization.*

## Requirements
- `nasm`
- `gcc` (with 16-bit support, usually standard on Linux)
- `binutils` (ld)
- `qemu-system-x86`
- `dd`, `wget` (for build scripts)
