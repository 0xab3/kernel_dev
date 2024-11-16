build:
	python3 ./src/utils/bin2c.py ./src/image.raw -O ./src/image.raw.h
	i686-elf-as ./src/boot.s -o ./builddir/boot.o
	i686-elf-as ./src/arch/i686/gdt.s -o ./builddir/gdt.o -g
	i686-elf-gcc -c ./src/kernel.c -o ./builddir/kernel.o -std=gnu99 -ffreestanding -O0 -Wall -Wextra -g
	i686-elf-gcc -c ./src/arch/kernel/mbvdriver.c  -o ./builddir/mbvdriver.o -std=gnu99 -ffreestanding -O0 -Wall -Wextra -g
	i686-elf-gcc -c ./src/arch/i686/gdt.c  -o ./builddir/gdt_2.o -std=gnu99 -ffreestanding -O0 -Wall -Wextra -g
	i686-elf-gcc -T ./src/linker.ld -o ./builddir/myos.bin -ffreestanding -O0 -nostdlib ./builddir/boot.o ./builddir/kernel.o ./builddir/mbvdriver.o ./builddir/gdt.o ./builddir/gdt_2.o -lgcc -g
	@if grub-file --is-x86-multiboot ./builddir/myos.bin; then \
		echo "multiboot confirmed"; \
	else \
		echo "the file is not multiboot"; \
		exit; \
	fi
	mkdir -p isodir/boot/grub
	cp ./builddir/myos.bin isodir/boot/myos.bin
	cp ./src/grub.cfg isodir/boot/grub/grub.cfg

	#debug
	objcopy --only-keep-debug builddir/myos.bin ./builddir/kernel.sym
	objcopy --strip-debug builddir/myos.bin

	grub-mkrescue -o myos.iso isodir
	# qemu-system-i386 -s -S -cdrom myos.iso
	qemu-system-i386 -cdrom myos.iso
