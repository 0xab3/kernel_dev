#include "../../include/mbvdriver.h"
#include <stdint.h>

void mbv_putpixel(mbv_device *mbv_device_handle, int x, int y,
                  struct RGBA888x pixel_color) {
  uint32_t pixel;

  switch (mbv_device_handle->mbv_color) {

  case MBV_COLOR_UNINIT:
    // todo(shahzad): add log here
    return;
    break;
  case BGR555x:
    // note(shahzad): lol scaling normalized pixel is slow aspk when
    // converted to float then normailzed then scaled the image takes an
    // entire second to show
    pixel = ((pixel_color.R * 0x1f) / 0xff) << (5 * 2 + 1) |
            (((pixel_color.G * 0x1f) / 0xff)) << (5 * 1 + 1) |
            ((pixel_color.B * 0x1f) / 0xff) << (5 * 0 + 1);

    break;
  case BGR888:
    // note(shahzad): shifting 11bits as the bpp is 5, adding one to account
    // for unused bit
    pixel = pixel_color.R << (8 * 2) | pixel_color.G << (8 * 1) |
            pixel_color.B << (8 * 0);
    break;
  default:
    pixel = 0x00;
  }

  int8_t *framebuffer = (int8_t *)mbv_device_handle->framebuffer_addr;
  int64_t stride = mbv_device_handle->framebuffer_pitch;

  switch (mbv_device_handle->mbv_color) {
    // todo(shahzad): we can do this better
  case MBV_COLOR_UNINIT:
    // todo(shahzad): add log here
    return;
    break;
  case BGR555x:
    *(int16_t *)((int8_t *)(framebuffer + (x * 2)) + (stride * y)) =
        (int16_t)pixel;
    break;
  case BGR888:
    *(int32_t *)((int8_t *)(framebuffer + (x * 3)) + (stride * y)) = pixel;
    break;
  }
}
void clrscr(mbv_device *mbv_device_handle) {
  for (uint32_t i = 0; i < mbv_device_handle->framebuffer_height; i++) {
    for (uint32_t j = 0; j < mbv_device_handle->framebuffer_width; j++) {
      mbv_putpixel(mbv_device_handle, j, i, (struct RGBA888x){0});
    }
  }
}

// todo(shahzad)!: this assumes that the rgb in sprite is always 24bit
void mbv_put_sprite(mbv_device *mbv_device_handle, void *sprite, uint32_t x,
                    uint32_t y, uint32_t h, uint32_t w, uint32_t stride) {
  sprite = (int16_t *)((int8_t *)sprite + x + (y * stride));
  for (uint32_t i = 0; i < h; i++) {
    for (uint32_t j = 0; j < w; j++) {
      uint8_t *pixel = ((uint8_t *)((uint8_t *)sprite + (j * 3)) + stride * i);
      struct RGBA888x rgb_pixel = {
          .B = (*(pixel + 2)),
          .G = (*(pixel + 1)),
          .R = (*(pixel + 0)),
          .A = 0,
      };
      mbv_putpixel(mbv_device_handle, j, i, rgb_pixel);
    }
  }
}

mbv_device mbv_device_new(void *framebuffer_addr, uint32_t framebuffer_pitch,
                          uint32_t framebuffer_width,
                          uint32_t framebuffer_height,
                          uint8_t framebuffer_bpp) {
  mbv_color_type mbv_color;
  switch (framebuffer_bpp) {
  case 24:
    mbv_color = BGR888;
    break;
  case 16:
    mbv_color = BGR555x;
    break;
  default:
    mbv_color = BGR555x;
    break;
  }
  return (mbv_device){
      .framebuffer_addr = framebuffer_addr,
      .framebuffer_pitch = framebuffer_pitch,
      .framebuffer_width = framebuffer_width,
      .framebuffer_height = framebuffer_height,
      .framebuffer_bpp = framebuffer_bpp,
      .mbv_color = mbv_color,
  };
}
