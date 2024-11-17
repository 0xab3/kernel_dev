const multiboot = @cImport("./include/multiboot.h");
const gdt = @import("./arch/i686/gdt.zig");
const gdt_entry = gdt.gdt_entry;

const multiboot_info_ptr: *multiboot.multiboot_info = undefined;
fn setup_gdb() void {
    const gdt_0: u64 = 0;
    const gdt_1: u64 = gdt_entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x9A, .flags = 0xc });
    const gdt_2: u64 = gdt_entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x92, .flags = 0xc });

    var table: [3]u64 = undefined;

    table[0] = gdt_0;
    table[1] = gdt_1;
    table[2] = gdt_2;

    var gdt_table: gdt.gdt_description = .{ .size = (@sizeOf(u64) * 3) - 1, .offset = &table[0] };
    gdt.init(&gdt_table);
}
fn setup_interrupts() void {}

export fn kernel_main() callconv(.C) void {
    const ptr: *u8 = @ptrFromInt(0xb8000);
    setup_gdb();
    ptr.* = 'a';
}
