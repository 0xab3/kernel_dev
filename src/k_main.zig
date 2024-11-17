const std = @import("std");
const gdt = @import("./arch/i686/gdt.zig");
const uart = @import("./arch/i686/serial/uart.zig");
const log = @import("./arch/std/debug/log.zig");
const std_writer = @import("./arch/i686/io/io_writer.zig").std_writer;

const multiboot = @cImport("./include/multiboot.h");

const gdt_entry = gdt.gdt_entry;
const builtin = std.builtin;

pub const std_options = .{
    .log_level = .debug,
    .logFn = log.uart_log_func,
};

// todo(shahzad): add stack trace?
pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace, ret_addr: ?usize) noreturn {
    std_writer.printf("paniced with {s}", .{msg});
    asm volatile (
        \\hlt
    );
    while (true) {}
    _ = ret_addr;
    _ = error_return_trace;
}

const multiboot_info_ptr: *multiboot.multiboot_info = undefined;

fn setup_gdt() void {
    const gdt_0: u64 = 0;
    const gdt_1: u64 = gdt_entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x9A, .flags = 0xc });
    const gdt_2: u64 = gdt_entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x92, .flags = 0xc });
    const table: [3]u64 = .{ gdt_0, gdt_1, gdt_2 };
    var gdt_table: gdt.gdt_description = .{ .size = (@sizeOf(u64) * 3) - 1, .offset = &table[0] };
    gdt.init(&gdt_table);
}

fn setup_interrupts() void {}

export fn kernel_main() callconv(.C) void {
    const ret = uart.init();
}
