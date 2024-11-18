.global idt_init
.type idt_init, @function

idt_init:
  cli
  mov 4(%esp), %eax
  lidt (%eax)
  sti 
  // clear the stack frame
  ret $4

