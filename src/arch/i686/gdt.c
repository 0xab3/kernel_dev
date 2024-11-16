#include "../../include/gdt.h"

gdt_format_t gdt_to_anal_format(struct gdt_entry entry) {
  gdt_format_t anal_formatted = 0;
  int8_t *target = (int8_t *)&anal_formatted;
  if (entry.limit > 0xFFFFF) {
    // kerror("GDT cannot encode limits larger than 0xFFFFF");
  }

  // Encode the limit
  target[0] = entry.limit & 0xFF;
  target[1] = (entry.limit >> 8) & 0xFF;
  target[6] = (entry.limit >> 16) & 0x0F;

  // Encode the base
  target[2] = entry.base & 0xFF;
  target[3] = (entry.base >> 8) & 0xFF;
  target[4] = (entry.base >> 16) & 0xFF;
  target[7] = (entry.base >> 24) & 0xFF;

  // Encode the access byte
  target[5] = entry.access_byte;

  // Encode the flags
  target[6] |= (entry.flags << 4);
  return anal_formatted;
}
