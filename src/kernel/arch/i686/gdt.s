.global gdt_init
.type gdt_init, @function

gdt_init:
  cli
  mov 4(%esp), %eax
  lgdt (%eax)
  ljmp $0x8,$reload_CS
reload_CS:
  mov $0x10, %ax 
  mov %ax,%ds 
  mov %ax,%es 
  mov %ax,%fs 
  mov %ax,%gs 
  mov %ax,%ss 
  nop
  sti 
  ret $4
