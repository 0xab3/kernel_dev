.global gdt_init
.type gdt_init, @function

gdt_init:
  cli
  mov 4(%esp), %eax
  lgdt (%eax)
  ljmp $0x8,$reload_CS
reload_CS:
  mov %ax, 0x10 
  mov %ds, %ax
  mov %es, %ax
  mov %fs, %ax
  mov %gs, %ax
  mov %ss, %ax
  nop
  sti 
  ret
