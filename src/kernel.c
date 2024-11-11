#include "./include/mbvdriver.h"
#include "./include/multiboot.h"
#include <stdint.h>

struct multiboot_info *multiboot_info_ptr;
// todo(shahzad): make this efficient
int k_memcpy(void *__restrict dest, void *__restrict src, int32_t size) {
  int i = 0;
  while (i < size) {
    *((char *)dest + i) = *((char *)src + i);
    i++;
  }
  return i;
}
int k_strlen(char *str) {
  int len = 0;
  while (*str)
    len++;
  return len;
}
static char image_data[] = {
#include "./image.raw.h"
};

void kernel_main() {
  mbv_device dev =
      mbv_device_new((int64_t *)multiboot_info_ptr->framebuffer_addr,
                     multiboot_info_ptr->framebuffer_pitch,
                     multiboot_info_ptr->framebuffer_width,
                     multiboot_info_ptr->framebuffer_height,
                     multiboot_info_ptr->framebuffer_bpp);
  mbv_put_sprite(&dev, image_data, 0, 0, 480, 640, 640 * 3);
}
