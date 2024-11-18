const std = @import("std");
const gdt = @import("./arch/i686/gdt.zig");
const uart = @import("./arch/i686/serial/uart.zig");
const log = @import("./arch/std/debug/log.zig");
const std_writer = @import("./arch/i686/io/io_writer.zig").std_writer;
const interrupt_handler = @import("./arch/i686/interrupts/interrupt_handlers.zig");
const interrupt = @import("./arch/i686/interrupts/interrupt.zig");

const multiboot = @cImport("./include/multiboot.h");

const gdt_entry = gdt.gdt_entry;
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
    std_writer.printf("paniced with {s}", .{msg});
    k_hlt();
}

const multiboot_info_ptr: *multiboot.multiboot_info = undefined;

fn setup_gdt() void {
    const gdt_0: u64 = 0;
    const gdt_1: u64 = gdt_entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x9A, .flags = 0xc });
    const gdt_2: u64 = gdt_entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x92, .flags = 0xc });
    //note(shahzad): equivalent to static keyword in c
    const table = struct {
        var table: [3]u64 = undefined;
    };
    table.table[0] = gdt_0;
    table.table[1] = gdt_1;
    table.table[2] = gdt_2;

    var gdt_table: gdt.gdt_description = .{ .size = (@sizeOf(u64) * 3) - 1, .offset = &table.table[0] };
    gdt.init(&gdt_table);
}

//todo(shahzad): please impl an alloc or we die
var idt_offset_table: [255]interrupt.idt_gate_t = undefined;
fn setup_interrupts() void {
    const gate_0: interrupt.idt_gate_t = interrupt.idt_gate_new(@intFromPtr(&interrupt_handler.default_signal_handler), 0x8, interrupt.gate_t.interrupt_gate_32, 0x00);
    for (0..255) |i| {
        idt_offset_table[i] = gate_0;
    }
    //note(shahzad): divide by zero exception is 0th in idt
    idt_offset_table[0] = interrupt.idt_gate_new(@intFromPtr(&interrupt_handler.div_by_zero), 0x8, interrupt.gate_t.interrupt_gate_32, 0x00);

    var idt_table: interrupt.idt_description = .{
        .size = @sizeOf(interrupt.idt_gate_t) * 255 - 1,
        .offset = &idt_offset_table[0],
    };

    interrupt.init(&idt_table);
}

export fn kernel_main() callconv(.C) void {
    const ret = uart.init();
    if (ret == false) {
        return;
    }
    setup_gdt();
    setup_interrupts();

    var res: i32 = undefined;
    //note(shahzad): triggering divide by zero exception
    asm volatile (
        \\mov $2, %eax
        \\mov $0, %ebx
        \\xor %edx, %edx 
        \\div %ebx
        \\ mov %eax, %[ret]
        : [ret] "=m" (res),
    );
    std.log.debug("{}", .{res});
}
