# bootloader
i386 bootloaders dreamed by BingAI
To compile this code with gcc in linux, you need to do the following steps:

- Compile the C code with gcc using the `-fno-PIC -fomit-frame-pointer -ffreestanding -m16 -Os -c` flags. These flags will disable position-independent code, omit the frame pointer, indicate that there is no standard library, generate 16-bit code, and optimize for space. For example: `gcc -fno-PIC -fomit-frame-pointer -ffreestanding -m16 -Os -c test.c -o test.o`
- Compile the assembly code with nasm using the `-f elf32` flag. This flag will generate a 32-bit ELF object file. For example: `nasm -f elf32 hw.asm -o hw.o`
- Link the object files with ld using a linker script that specifies the output format as binary and the starting address as 0x7c00. The linker script can look like this:

```ld
OUTPUT_FORMAT (binary)
SECTIONS {
  . = 0x7c00;
  .text : {
    *(.text)
  }
  .data : {
    *(.data)
  }
  .bss : {
    *(.bss)
  }
}
```

- The command line for linking could appear as: `ld -T linker.ld hw.o test.o -o hw.bin`
- The output file hw.bin will be a raw binary file that can be written to a disk or run in an emulator.

¹²³

Source: Conversation with Bing, 6/15/2023
(1) gcc - Calling C code from a bootloader - Stack Overflow. https://stackoverflow.com/questions/9692787/calling-c-code-from-a-bootloader.
(2) gcc - Compile an asm bootloader with external c code - Stack Overflow. https://stackoverflow.com/questions/47249699/compile-an-asm-bootloader-with-external-c-code.
(3) Downloading GCC - GNU Project - GCC, the GNU Compiler Collection. https://gcc.gnu.org/install/download.html.
