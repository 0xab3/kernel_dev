const std = @import("std");
const gdt = @import("./arch/i686/gdt.zig");
const uart = @import("./arch/i686/serial/uart.zig");
const log = @import("./debug/log.zig");
const stdout_writer = @import("./stdout_writer.zig").stdout_writer;
const isr = @import("./arch/i686/interrupts/isr.zig");
const idt = @import("./arch/i686/interrupts/idt.zig");
const io = @import("./arch/i686/io/io.zig");
const pic = @import("./arch/i686/interrupts/pic.zig");
const is_data_ready = uart.is_data_ready;

const multiboot = @cImport("./include/multiboot.h");

const builtin = std.builtin;

pub const std_options = .{
    .log_level = .debug,
    .logFn = log.uart_log_func,
};

pub fn k_hlt() noreturn {
    asm volatile (
        \\cli
        \\hlt
    );
    while (true) {}
}
// todo(shahzad): add stack trace?
pub fn panic(msg: []const u8, _: ?*builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = ret_addr;
    stdout_writer.printf("paniced with {s}\n", .{msg});
    k_hlt();
}

const multiboot_info_ptr: *multiboot.multiboot_info = undefined;

fn setup_gdt() void {
    const gdt_0: u64 = 0;
    const gdt_1: u64 = gdt.entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x9A, .flags = 0xc });
    const gdt_2: u64 = gdt.entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x92, .flags = 0xc });
    //note(shahzad): equivalent to static keyword in c
    const table = struct {
        var table: [3]u64 = undefined;
    };
    table.table[0] = gdt_0;
    table.table[1] = gdt_1;
    table.table[2] = gdt_2;

    var gdt_table: gdt.description = .{ .size = (@sizeOf(u64) * 3) - 1, .offset = &table.table[0] };
    gdt.init(&gdt_table);
}

//todo(shahzad): please impl an alloc or we die
fn setup_interrupts() void {
    // todo(shahzad): impl allocator
    const table = struct {
        var idt_offset_table: [256]idt.gate = undefined;
    };
    const idt_table = idt.new_default(&table.idt_offset_table);
    idt.init(&idt_table);
}

export fn kernel_main() callconv(.C) void {
    const ret = uart.init();
    if (ret == false) {
        return;
    }
    setup_gdt();
    setup_interrupts();
    pic.disable();

    // note(shahzad): triggering divide by zero exception
    asm volatile (
        \\ int $0
    );
}
