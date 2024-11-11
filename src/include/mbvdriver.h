#ifndef MBVDRIVER_H_
#define MBVDRIVER_H_
#include <stdint.h>
#define MULTIBOOT_FRAMEBUFFER_TYPE_INDEXED 0
#define MULTIBOOT_FRAMEBUFFER_TYPE_RGB 1
#define MULTIBOOT_FRAMEBUFFER_TYPE_EGA_TEXT 2
// note(shahzad): don't wanna deal with boundary that's why alpha
struct RGBA888x {
  uint8_t R;
  uint8_t G;
  uint8_t B;
  uint8_t A;
};
typedef enum {
  MBV_COLOR_UNINIT,
  BGR555x,
  BGR888,
} mbv_color_type;

typedef struct {
  uint64_t *framebuffer_addr;
  uint32_t framebuffer_pitch;
  uint32_t framebuffer_width;
  uint32_t framebuffer_height;
  uint8_t framebuffer_bpp;
  uint8_t framebuffer_type;
  mbv_color_type mbv_color;
  union {
    struct {
      uint32_t framebuffer_palette_addr;
      uint16_t framebuffer_palette_num_colors;
    };
    struct {
      uint8_t framebuffer_red_field_position;
      uint8_t framebuffer_red_mask_size;
      uint8_t framebuffer_green_field_position;
      uint8_t framebuffer_green_mask_size;
      uint8_t framebuffer_blue_field_position;
      uint8_t framebuffer_blue_mask_size;
    };
  };
} mbv_device;

struct mbv_color {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
};
mbv_device mbv_device_new(void *framebuffer_addr, uint32_t framebuffer_pitch,
                          uint32_t framebuffer_width,
                          uint32_t framebuffer_height, uint8_t framebuffer_bpp);

void mbv_putpixel(mbv_device *mbv_device_handle, int x, int y,
                  struct RGBA888x pixel_color );
void mbv_put_sprite(mbv_device *mbv_device_handle, void *sprite, uint32_t x,
                    uint32_t y, uint32_t h, uint32_t w, uint32_t stride);
void clrscr(mbv_device *mbv_device_handle);
#endif
