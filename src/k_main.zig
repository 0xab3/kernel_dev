const multiboot = @cImport("./include/multiboot.h");
const gdt = @import("./arch/i686/gdt.zig");
const gdt_entry = gdt.gdt_entry;
const uart = @import("./arch/i686/serial/uart.zig");
const io_writer = @import("./arch/i686/io/io_writer.zig").io_writer;
const io_writer_config = @import("./arch/i686/io/io_writer.zig").io_writer_config;

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
    const ret = uart.init();
    const writer = io_writer.init(.{ .console_out = true, .uart_out = ret });
    if (ret == false) {
        writer.printf("failed to initialize serial port\n", .{});
    } else {
        writer.printf("serial port initialized successfully\n", .{});
    }
}
