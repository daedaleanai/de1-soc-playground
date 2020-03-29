
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <linux/input.h>
#include <pthread.h>
#include <string.h>
#include <stdlib.h>

#define VGA_PIXEL_BASE 0xc8000000
#define VGA_PIXEL_SPAN 0x00080000
#define HW_REGS_BASE   0xff200000
#define HW_REGS_SPAN   0x00001000
#define KEY_OFFSET     0x00000000
#define BTN_PRESSED    1
#define BTN_RELEASED   0
#define SCREEN_WIDTH   640
#define SCREEN_HEIGHT  480

typedef struct {
  pthread_mutex_t lock;
  volatile uint8_t *vgaPixels;
  volatile uint8_t *buttons;
  uint8_t currentColor;
  uint8_t *buffer1;
  uint8_t *buffer2;
  int32_t cursor_x;
  int32_t cursor_y;
  uint8_t pressed;
  uint16_t pressed_x;
  uint16_t pressed_y;
} scene_t;

const uint8_t cursor[100] = {
  255,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    0, 255, 255,   0,   0,   0,   0,   0,   0,   0,
    0, 255, 255, 255, 255,   0,   0,   0,   0,   0,
    0,   0, 255, 255, 255, 255, 255,   0,   0,   0,
    0,   0, 255, 255, 255, 255, 255, 255, 255,   0,
    0,   0,   0, 255, 255, 255, 255, 255, 255, 255,
    0,   0,   0, 255, 255, 255, 255, 255, 255,   0,
    0,   0,   0,   0, 255, 255, 255, 255, 255, 250,
    0,   0,   0,   0, 255, 255, 255, 255, 255, 255,
    0,   0,   0,   0,   0, 255,   0, 255, 255,   0,
};


#define GET_PIXEL(ARR, X, Y) *((ARR) + ((uint32_t)(Y) << 10)+ (X))

int32_t trim(int32_t val, int32_t lowerBound, int32_t upperBound) {
  if (val < lowerBound) {
    return lowerBound;
  }

  if (val > upperBound) {
    return upperBound;
  }

  return val;
}

void *pollMouse(void *arg) {
  scene_t *scene = (scene_t*)arg;

  int fd = open("/dev/input/event0", O_RDWR);
  if(fd == -1) {
    perror("Opening /dev/input/event0");
    return NULL;
  }

  struct input_event ie;
  while(read(fd, &ie, sizeof(struct input_event))) {
    pthread_mutex_lock(&scene->lock);
    switch(ie.type) {
      case EV_REL:
        if (ie.code == REL_X) {
          scene->cursor_x += ie.value;
          scene->cursor_x = trim(scene->cursor_x, 0, SCREEN_WIDTH-1);
        }
        if (ie.code == REL_Y) {
          scene->cursor_y += ie.value;
          scene->cursor_y = trim(scene->cursor_y, 0, SCREEN_HEIGHT-1);
        }
        break;
      case EV_KEY:
        if (ie.code != BTN_LEFT) {
          break;
        }

        if (ie.value == BTN_PRESSED) {
          scene->pressed = 1;
        } else if (ie.value == BTN_RELEASED) {
          scene->pressed = 0;
        }
        break;
      default:
        break;
    }
    pthread_mutex_unlock(&scene->lock);
  }

  close(fd);
  return NULL;
}

void *pollButtons(void *arg) {
  scene_t *scene = (scene_t*)arg;
  while(1) {
    pthread_mutex_lock(&scene->lock);
    for (int i = 0; i < 4; ++i) {
      if (((*scene->buttons) >> i) == 1) {
        scene->currentColor = 0xf << (i*2);
        break;
      }
    }
    pthread_mutex_unlock(&scene->lock);
    usleep(100000);
  }
  return NULL;
}

void drawImage(uint8_t *buffer, uint16_t x, uint16_t y, const uint8_t *img, uint16_t width, uint16_t height) {
  if (x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) {
    return;
  }
  for (uint16_t i = 0; i < width && x + i < SCREEN_WIDTH; ++i) {
    for (uint16_t j = 0; j < height && y + j < SCREEN_HEIGHT; ++j) {
      uint8_t pixel = *(img + j * width + i);
      if (pixel) {
        GET_PIXEL(buffer, x + i, y + j) = *(img + j * width + i);
      }
    }
  }
}

void swapMonotonic(uint16_t *a, uint16_t *b) {
  if (*a <= *b) {
    return;
  }
  uint16_t tmp = *a;
  *a = *b;
  *b = tmp;
}

void drawRectangle(uint8_t *buffer, uint8_t color, uint16_t x1, uint16_t x2, uint16_t y1, uint16_t y2) {
  swapMonotonic(&x1, &x2);
  swapMonotonic(&y1, &y2);
  if (x1 >= SCREEN_WIDTH || x2 >= SCREEN_WIDTH || y1 >= SCREEN_HEIGHT || y2 >= SCREEN_HEIGHT) {
    return;
  }

  for (uint16_t i = x1; i <= x2; ++i) {
    for (uint16_t j = y1; j <= y2; ++j) {
      GET_PIXEL(buffer, i, j) = color;
    }
  }
}

void drawScene(scene_t *scene) {
  uint8_t wasPressed = 0;
  while(1) {
    pthread_mutex_lock(&scene->lock);
    memcpy(scene->buffer2, scene->buffer1, VGA_PIXEL_SPAN);

    if (!wasPressed && scene->pressed) {
       wasPressed = 1;
       scene->pressed_x = scene->cursor_x;
       scene->pressed_y = scene->cursor_y;
    }

    if (wasPressed && !scene->pressed) {
       wasPressed = 0;
       drawRectangle(scene->buffer1, scene->currentColor,
                     scene->pressed_x, scene->cursor_x,
                     scene->pressed_y, scene->cursor_y);

    }

    if (scene->pressed) {
       drawRectangle(scene->buffer2, scene->currentColor,
                     scene->pressed_x, scene->cursor_x,
                     scene->pressed_y, scene->cursor_y);
    }

    drawImage(scene->buffer2, scene->cursor_x, scene->cursor_y, cursor, 10, 10);

    memcpy((void*)scene->vgaPixels, scene->buffer2, VGA_PIXEL_SPAN);
    pthread_mutex_unlock(&scene->lock);;
    usleep(10000);
  }
}

int main(int argc, char **argv) {
  scene_t scene;
  memset(&scene, 0, sizeof(scene_t));
  pthread_mutex_init(&scene.lock, NULL);

  scene.buffer1 = (uint8_t*)malloc(VGA_PIXEL_SPAN);
  if (!scene.buffer1) {
    perror("Unable to allocate the buffer1");
    return 1;
  }

  scene.buffer2 = (uint8_t*)malloc(VGA_PIXEL_SPAN);
  if (!scene.buffer2) {
    perror("Unable to allocate the buffer2");
    return 1;
  }

  memset(scene.buffer1, 0, VGA_PIXEL_SPAN);
  memset(scene.buffer2, 0, VGA_PIXEL_SPAN);

  scene.cursor_x = SCREEN_WIDTH / 2;
  scene.cursor_y = SCREEN_HEIGHT / 2;

  int fd = open("/dev/mem", O_RDWR | O_SYNC);
  if (fd == -1) {
    perror("Opening /dev/mem");
    return 1;
  }

  volatile void *mem = mmap(NULL, VGA_PIXEL_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, VGA_PIXEL_BASE);
  if (mem == MAP_FAILED) {
    perror("Mapping pixel buffer");
    close(fd);
    return 1;
  }
  scene.vgaPixels = (volatile uint8_t *)mem;

  mem = mmap(NULL, HW_REGS_SPAN, PROT_READ | PROT_WRITE, MAP_SHARED, fd, HW_REGS_BASE);
  if (mem == MAP_FAILED) {
    perror("Mapping hw regs");
    close(fd);
    return 1;
  }
  scene.buttons = ((volatile uint8_t*)mem) + KEY_OFFSET;

  for (uint16_t x = 0; x < SCREEN_WIDTH; ++x) {
    for (uint16_t y = 0; y < SCREEN_HEIGHT; ++y) {
      GET_PIXEL(scene.vgaPixels, x, y) = 0;
    }
  }

  pthread_t threads[2];
  pthread_create(&threads[0], NULL, pollButtons, (void *)&scene);
  pthread_create(&threads[1], NULL, pollMouse, (void *)&scene);
  drawScene(&scene);

  // Never returns
  close(fd);
  return 0;
}
