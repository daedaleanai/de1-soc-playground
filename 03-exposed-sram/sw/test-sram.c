
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define SRAM_BASE 0xc0000000
#define SRAM_SPAN 0x00040000

int main(int argc, char **argv) {
  int fd = open("/dev/mem", O_RDWR | O_SYNC);
  if (fd == -1) {
    perror("Opening /dev/mem");
    return 1;
  }

  uint8_t *buffer1 = (uint8_t*)malloc(SRAM_SPAN);
  if (buffer1 == NULL) {
    perror("Allocating buffer1");
    return 1;
  }

  uint8_t *buffer2 = (uint8_t*)malloc(SRAM_SPAN);
  if (buffer2 == NULL) {
    perror("Allocating buffer2");
    return 1;
  }

  for (uint32_t i = 0; i < SRAM_SPAN; ++i) {
    buffer1[i] = (uint8_t)i;
  }

  void *sram = mmap(NULL, SRAM_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, SRAM_BASE);
  if (sram == MAP_FAILED) {
    goto exit;
    return 1;
  }

  memcpy(sram, buffer1, SRAM_SPAN);
  memcpy(buffer2, sram, SRAM_SPAN);

  if (memcmp(buffer1, buffer2, SRAM_SPAN) == 0) {
    printf("Copied buffers match!\n");
  } else {
    printf("Copied buffers don't match!\n");
  }

exit:
  free(buffer1);
  free(buffer2);
  close(fd);
  return 0;
}
