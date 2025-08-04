#!/bin/bash
set -xe
~/opt/zig/zig-linux-x86_64-0.13.0/zig build
mkdir -p isodir/boot/grub || true
cp ./zig-out/bin/kernel.elf ./isodir/boot/myos.bin
cp ./src/kernel/grub.cfg isodir/boot/grub/grub.cfg

objcopy --only-keep-debug ./zig-out/bin/kernel.elf ./zig-out/kernel.sym

mkdir isobuild || true
grub-mkrescue ./isodir -o isobuild/myos.iso
qemu-system-i386 -serial stdio -cdrom isobuild/myos.iso
#qemu-system-i386 -s -S -serial stdio -cdrom isobuild/myos.iso
