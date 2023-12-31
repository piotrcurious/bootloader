// Bootloader for i386 pc in C
// Disclaimer: This is a generated code and may not work as expected.

// Define some constants
#define SECTOR_SIZE 512 // Size of a disk sector in bytes
#define BOOT_SIGNATURE 0xaa55 // Boot signature at the end of the bootloader
#define KERNEL_SECTOR 1 // Sector where the kernel starts

// Define some macros
#define outb(port, data) __asm__ volatile("outb %0, %1" : : "a"(data), "Nd"(port)) // Write a byte to a port
#define inb(port) ({ \
  unsigned char _v; \
  __asm__ volatile("inb %1, %0" : "=a"(_v) : "Nd"(port)); \
  _v; \
}) // Read a byte from a port

// Define some types
typedef unsigned char uint8_t; // 8-bit unsigned integer
typedef unsigned short uint16_t; // 16-bit unsigned integer
typedef unsigned long uint32_t; // 32-bit unsigned integer

// Declare some functions
void print(const char *str); // Print a string to the screen
void load_kernel(); // Load the kernel from the disk
void jump_kernel(); // Jump to the kernel entry point

// The entry point of the bootloader
void main() {
  // Print a message
  print("Booting...\n");

  // Load the kernel
  load_kernel();

  // Jump to the kernel
  jump_kernel();

  // Hang forever
  while (1);
}

// Print a string to the screen
void print(const char *str) {
  // Loop through each character
  while (*str) {
    // Write the character to the VGA text mode buffer at address 0xb8000
    *(uint16_t *)(0xb8000 + 160 * 24 + 2 * 0) = (uint16_t)(*str | (15 << 8));

    // Increment the cursor position by sending commands to the VGA controller ports
    uint8_t pos = inb(0x3d9); // Read the current cursor position
    pos++; // Increment it
    outb(0x3d8, 14); // Set the cursor high byte command
    outb(0x3d9, pos >> 8); // Send the high byte of the position
    outb(0x3d8, 15); // Set the cursor low byte command
    outb(0x3d9, pos & 0xff); // Send the low byte of the position

    // Move to the next character
    str++;
  }
}

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
  params.sectors = SECTOR_SIZE / sizeof(uint32_t); // Set number of sectors to read (one sector)
  params.offset = (uint32_t)&kernel >> 4; // Set offset to where kernel is defined below (low word)
  params.segment = (uint32_t)&kernel >> 28; // Set segment to where kernel is defined below (high word)
  params.lba = KERNEL_SECTOR; // Set logical block address to where kernel starts on disk

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
    // Print an error message
    print("Error loading kernel.\n");
  } else {
    // Print a success message
    print("Kernel loaded.\n");
  }
}

// Jump to the kernel entry point
void jump_kernel() {
  // Define a pointer to the kernel entry point
  void (*kernel_entry)() = (void (*)())&kernel;

  // Print a message
  print("Jumping to kernel...\n");

  // Disable interrupts
  __asm__ volatile("cli");

  // Jump to the kernel entry point
  kernel_entry();
}

// Define a placeholder for the kernel
uint32_t kernel[SECTOR_SIZE / sizeof(uint32_t)];

// Fill the remaining space with zeros
__attribute__((section(".fill")))
char fill[SECTOR_SIZE - (sizeof(kernel) + sizeof(uint16_t))];

// Append the boot signature at the end of the bootloader
__attribute__((section(".sig")))
uint16_t boot_signature = BOOT_SIGNATURE;
