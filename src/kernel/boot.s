.set ALIGN,       1<<0                        
.set MEMINFO,     1<<1                       
.set FLAGS,       (ALIGN | MEMINFO)
.set MAGIC,       0x1BADB002     
.set CHECKSUM,    -(MAGIC + FLAGS)

.section .data.multiboot, "a"
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM
.section .bss
.section .paging.rodata
.section .text.multiboot

.section .text
  push %ebx
  call kernel_main
	cli
1:	hlt
	jmp 1b

