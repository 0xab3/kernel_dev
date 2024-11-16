#ifndef GDT_H
#define GDT_H
#include "common.h"
#include <stdint.h>
typedef int64_t gdt_format_t;

struct __attribute__((packed)) gdt_description {
  int16_t size;
  gdt_format_t* offset;
};

// note(shahzad): no need to give a shit abt padding struct it's only for convenience
struct gdt_entry {
  uint32_t limit: 20;
  uint32_t base;
  int8_t access_byte;
  uint8_t flags: 4;
};

extern void gdt_init(struct gdt_description* arg);
gdt_format_t gdt_to_anal_format(struct gdt_entry entry);

#endif
