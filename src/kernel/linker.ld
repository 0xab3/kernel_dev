/* The bootloader will look at this image and start execution at the symbol
   designated as the entry point. */
ENTRY(_start)

/* Tell where the various sections of the object files will be put in the final
   kernel image. */
SECTIONS
{
	/* It used to be universally recommended to use 1M as a start offset,
	   as it was effectively guaranteed to be available under BIOS systems.
	   However, UEFI has made things more complicated, and experimental data
	   strongly suggests that 2M is a safer place to load. In 2016, a new
	   feature was introduced to the multiboot2 spec to inform bootloaders
	   that a kernel can be loaded anywhere within a range of addresses and
	   will be able to relocate itself to run from such a loader-selected
	   address, in order to give the loader freedom in selecting a span of
	   memory which is verified to be available by the firmware, in order to
	   work around this issue. This does not use that feature, so 2M was
	   chosen as a safer option than the traditional 1M. */
	. = 2M;
  KERNEL_START = .;
  KERNEL_VIRT_OFFSET = 0xC0000000;
  KERNEL_VIRT_START = KERNEL_VIRT_OFFSET;

  .data.multiboot : ALIGN(4K) {
    *(.data.multiboot)
  }

  .text.multiboot : ALIGN(4K) {
    *(.text.multiboot)
  }

  .paging.rodata : ALIGN(4K){
    *(.paging.rodata)
  }
  . += KERNEL_VIRT_OFFSET;

  .text ALIGN (4K) : AT (ADDR (.text) - KERNEL_VIRT_OFFSET)
	{
    KERNEL_TEXT_START = .;
		*(.text)
    KERNEL_TEXT_END = .;
	}

	/* Read Only data. */
	.rodata ALIGN (4K) : AT (ADDR (.rodata) - KERNEL_VIRT_OFFSET)
	{
    KERNEL_RO_START = .;
		*(.rodata)
    KERNEL_RO_END = .;
	}

	/* Read Write data. (Initialized) */
	.data ALIGN (4K) : AT (ADDR (.data) - KERNEL_VIRT_OFFSET)
	{
    KERNEL_DATA_START = .;
		*(.data)
    KERNEL_DATA_END = .;
	}

	/* Read Write data. (Uninitialized) */
	.bss ALIGN (4K) : AT (ADDR (.bss) - KERNEL_VIRT_OFFSET)
	{
		KEEP(*(.bss))
	}

  .bss.stack ALIGN(4K) : AT (ADDR(.bss.stack) - KERNEL_VIRT_OFFSET) 
  {
    KERNEL_STACK_START = .;
		KEEP(*(.bss.stack))
    KERNEL_STACK_END = .;
  }

  KERNEL_VIRT_END = .;
	KERNEL_END = . - KERNEL_VIRT_OFFSET;


	/* The compiler may produce other sections, by default it will put them in
	   a segment with the same name. Simply add stuff here as needed. */
}
