build:
	python3 ./src/utils/bin2c.py ./src/parrot.raw -O ./src/parrot.raw.h
	i686-elf-as ./src/boot.s -o ./builddir/boot.o
	i686-elf-gcc -c ./src/kernel.c -o ./builddir/kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra -ggdb
	i686-elf-gcc -c ./src/arch/kernel/mbvdriver.c  -o ./builddir/mbvdriver.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra -ggdb
	i686-elf-gcc -T ./src/linker.ld -o ./builddir/myos.bin -ffreestanding -O2 -nostdlib ./builddir/boot.o ./builddir/kernel.o ./builddir/mbvdriver.o -lgcc -ggdb
	@if grub-file --is-x86-multiboot ./builddir/myos.bin; then \
		echo "multiboot confirmed"; \
	else \
		echo "the file is not multiboot"; \
		exit; \
	fi
	mkdir -p isodir/boot/grub
	cp ./builddir/myos.bin isodir/boot/myos.bin
	cp ./src/grub.cfg isodir/boot/grub/grub.cfg
	grub-mkrescue -o myos.iso isodir
	qemu-system-i386 -cdrom myos.iso
