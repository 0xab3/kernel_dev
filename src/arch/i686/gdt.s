.global gdt_init
.type gdt_init, @function

gdt_init:
  mov  0x12( %ebp ), %eax 
  mov %al, 0xb8000
  ret
