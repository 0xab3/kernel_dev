#include "common.h"
#include "multiboot.h"
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
// throw away function (termbuffer should start from 0xB8000)
void k_term_write(uint16_t *term_buffer, char *str) {
  int i = 0;
  while (*str) {
    term_buffer[i++] = ((15 << 8) | (uint16_t)*str);
    str++;
  }
}
int k_strlen(char *str) {
  int len = 0;
  while (*str)
    len++;
  return len;
}

void kernel_main() {
  uint16_t *terminal_buffer = (uint16_t *)0xB8000;

  *((int16_t *)multiboot_info_ptr->framebuffer_addr) = 0xffff;
  *((int16_t *)multiboot_info_ptr->framebuffer_addr + 1) = 0xffff;
  *((int16_t *)multiboot_info_ptr->framebuffer_addr + 2) = 0xffff;
  *((int16_t *)multiboot_info_ptr->framebuffer_addr + 3) = 0xffff;
}
