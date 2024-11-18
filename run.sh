#!/bin/bash
zig build
mkdir -p isodir/boot/grub
cp ./zig-out/bin/kernel.elf ./isodir/boot/myos.bin
cp ./src/grub.cfg isodir/boot/grub/grub.cfg

objcopy --only-keep-debug ./zig-out/bin/kernel.elf ./zig-out/kernel.sym

mkdir isobuild
grub-mkrescue ./isodir -o isobuild/myos.iso
# qemu-system-i386 -s -S -cdrom isobuild/myos.iso
qemu-system-i386 -serial stdio -cdrom isobuild/myos.iso
