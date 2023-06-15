I'll try to modify the code. Here is a possible way to boot a kernel larger than a single sector:

- Change the KERNEL_SECTOR constant to the number of sectors that the kernel occupies. For example, if the kernel is 4 sectors long, change it to 4.

- Change the load_kernel function to use a loop to read each sector of the kernel and store it in consecutive memory locations. For example:

```c

// Load the kernel from the disk

void load_kernel() {

  // Set up the disk parameters packet for BIOS interrupt 13h, function 42h (extended read)

  struct disk_params {

    uint8_t size; // Size of this structure (16 bytes)

    uint8_t reserved; // Reserved (must be zero)

    uint16_t sectors; // Number of sectors to read (must be nonzero)

    uint16_t offset; // Offset in memory where to store the data (low word)

    uint16_t segment; // Segment in memory where to store the data (high word)

    uint64_t lba; // Logical block address of the first sector to read

  } __attribute__((packed)) params;

  params.size = sizeof(params); // Set the size of this structure

  params.reserved = 0; // Set reserved to zero

  params.sectors = 1; // Set number of sectors to read (one sector at a time)

  params.offset = (uint32_t)&kernel >> 4; // Set offset to where kernel is defined below (low word)

  params.segment = (uint32_t)&kernel >> 28; // Set segment to where kernel is defined below (high word)

  

  // Loop through each sector of the kernel

  for (int i = 0; i < KERNEL_SECTOR; i++) {

    params.lba = i + 1; // Set logical block address to where current sector starts on disk

    // Call BIOS interrupt 13h, function 42h (extended read) with the disk parameters packet in register esi

    __asm__ volatile(

      "movw $0x0000, %%ax\n" // Clear register ax (for error checking)

      "movw $0x0080, %%dx\n" // Set register dx to drive number (0x80 for first hard disk)

      "int $0x13\n"          // Call interrupt 13h

      "jnc .success\n"       // Jump to success label if carry flag is clear (no error)

      ".error:\n"            // Error label

      "movw $0x0001, %%ax\n" // Set register ax to 1 (error code)

      "jmp .done\n"          // Jump to done label

      ".success:\n"          // Success label

      "movw $0x0000, %%ax\n" // Set register ax to 0 (success code)

      ".done:\n"             // Done label

      :                      // No output operands

      : "S"(&params)         // Input operand: address of disk parameters packet in register esi

      : "cc", "memory", "eax", "edx" // Clobbered registers: flags, memory, eax, edx

    );

    // Check the value of register ax for error code

    if (*(uint16_t *)0x7c00 != 0) {

      // Print an error message and break the loop

      print("Error loading kernel.\n");

      break;

    } else {

      // Print a success message and increment the offset and segment by one sector size

      print("Kernel sector loaded.\n");

      params.offset += SECTOR_SIZE / sizeof(uint16_t);

      params.segment += SECTOR_SIZE / sizeof(uint32_t);

    }

  }

}

```
