
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define HW_REGS_BASE 0xff200000
#define HW_REGS_SPAN 0x00001000
#define KEY_OFFSET   0x00000000

int main(int argc, char **argv) {
  int fd = open("/dev/mem", O_RDWR | O_SYNC);
  if (fd == -1) {
    perror("Opening /dev/mem");
    return 1;
  }

  void *mem = mmap(NULL, HW_REGS_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, HW_REGS_BASE);
  if (mem == MAP_FAILED) {
    perror("Mapping hw regs");
    close(fd);
    return 1;
  }

  volatile uint8_t *buttons = ((volatile uint8_t*)mem) + KEY_OFFSET;
  while(1) {
    printf("Contents of the register: %x\n", *buttons);
    usleep(250000);
  }

  // Never returns
  close(fd);
  return 0;
}
