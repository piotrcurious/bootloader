// Simple Kernel in C
#include <stdint.h>

#define COM1 0x3f8

void main() {
  const char *msg = "Hello from Kernel!\n";
  const char *p = msg;
  while (*p) {
    uint8_t status;
    do {
      __asm__ volatile("inb %1, %0" : "=a"(status) : "Nd"((uint16_t)(COM1 + 5)));
    } while (!(status & 0x20));
    __asm__ volatile("outb %0, %1" : : "a"(*p), "Nd"((uint16_t)COM1));
    p++;
  }
  while (1);
}
