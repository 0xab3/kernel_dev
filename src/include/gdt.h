#ifndef GDT_H
#define GDT_H
#include "common.h"
#include <stdint.h>
struct global_descriptor_table {};
extern void gdt_init(int32_t arg);
#endif
