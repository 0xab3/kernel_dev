#include "./include/mbvdriver.h"
#include "./include/multiboot.h"
#include "include/gdt.h"
#include <stdint.h>

struct multiboot_info *multiboot_info_ptr;
// todo(shahzad): make this efficient
// int k_memcpy(void *__restrict dest, void *__restrict src, int32_t size) {
//   int i = 0;
//   while (i < size) {
//     *((char *)dest + i) = *((char *)src + i);
//     i++;
//   }
//   return i;
// }
// int k_strlen(char *str) {
//   int len = 0;
//   while (*str)
//     len++;
//   return len;
// }
// static char image_data[] = {
// #include "./image.raw.h"
// };

void setup_gdb() {
  gdt_format_t gdt_0 = 0;
  gdt_format_t gdt_1 = gdt_to_anal_format((struct gdt_entry){
      .base = 0x00, .limit = 0xfffff, .access_byte = 0x9A, .flags = 0xc});
  gdt_format_t gdt_2 = gdt_to_anal_format((struct gdt_entry){
      .base = 0x00, .limit = 0xfffff, .access_byte = 0x92, .flags = 0xc});

  static gdt_format_t table[3] = {0};

  table[0] = gdt_0;
  table[1] = gdt_1;
  table[2] = gdt_2;

  static struct gdt_description gdt_table = {
      .size = (sizeof(gdt_format_t) * 3) - 1, .offset = &table[0]};
  gdt_init(&gdt_table);
};

void kernel_main() { setup_gdb(); }
