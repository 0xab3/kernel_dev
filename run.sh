#!/bin/bash
zig build
mkdir -p isodir/boot/grub
cp ./zig-out/bin/kernel.elf ./isodir/boot/myos.bin
cp ./src/grub.cfg isodir/boot/grub/grub.cfg

objcopy --only-keep-debug ./zig-out/bin/kernel.elf ./zig-out/kernel.sym
objcopy --strip-debug ./zig-out/bin/kernel.elf

grub-mkrescue -o iosbuild/myos.iso isodir
# qemu-system-i386 -s -S -cdrom iosbuild/myos.iso
qemu-system-i386 -serial stdio -cdrom iosbuild/myos.iso
