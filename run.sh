#!/bin/bash
set -xe
zig build
mkdir -p isodir/boot/grub || true
cp ./zig-out/bin/kernel.elf ./isodir/boot/myos.bin
cp ./src/kernel/grub.cfg isodir/boot/grub/grub.cfg

objcopy --only-keep-debug ./zig-out/bin/kernel.elf ./zig-out/kernel.sym

mkdir isobuild || true
grub-mkrescue ./isodir -o isobuild/myos.iso
qemu-system-i386 -serial stdio -cdrom isobuild/myos.iso
