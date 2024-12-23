const std = @import("std");
const gdt = @import("./arch/i686/gdt.zig");
const uart = @import("./arch/i686/serial/uart.zig");
const log = @import("./debug/log.zig");
const stdout_writer = @import("./stdout_writer.zig").stdout_writer;
const isr = @import("./arch/i686/interrupts/isr.zig");
const idt = @import("./arch/i686/interrupts/idt.zig");
const io = @import("./arch/i686/io/io.zig");
const pic = @import("./arch/i686/interrupts/pic.zig");
const memory = @import("./arch/i686/memory/memory.zig");
const allocator = @import("./arch/common/k_alloc.zig");
const is_data_ready = uart.is_data_ready;
const hacks = @import("./debug/hacks.zig");
const csrc = hacks.csrc;

const multiboot = @import("./multiboot.zig");

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
pub fn panic(msg: []const u8, _: ?*builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);
    stdout_writer.printf("panic: {s} \n", .{msg});
    k_hlt();
}

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
fn setup_memory() void {
    memory.init();
}

export fn kernel_main(multiboot_info: *multiboot.multiboot_info_t) callconv(.C) void {
    const ret = uart.init();
    if (ret == false) {
        return;
    }

    var kalloc = allocator.bump_allocator(){};
    const allc = kalloc.allocator(.{ .multiboot_memory_map_len = multiboot_info.mmap_length / @sizeOf(multiboot.multiboot_memory_map_t), .multiboot_memory_map = multiboot_info.mmap_addr }) catch |err| {
        std.debug.panic("{} failed to initialize allocator: {any}\n", .{ csrc(@src()), err });
    };
    const temp = allc.alloc(i32, 59) catch |e|
        {
        std.debug.panic("{any}\n", .{e});
    };
    const temp2 = allc.alloc(i32, 59) catch |e|
        {
        std.debug.panic("{any}\n", .{e});
    };
    allc.free(temp);
    allc.free(temp2);

    const temp1 = allc.alloc(i32, 59) catch |e|
        {
        std.debug.panic("{any}\n", .{e});
    };
    const temp3 = allc.alloc(i32, 59) catch |e|
        {
        std.debug.panic("{any}\n", .{e});
    };
    stdout_writer.printf("{*}\n", .{temp1.ptr});
    stdout_writer.printf("{*}\n", .{temp3.ptr});
    allc.free(temp1);
    allc.free(temp3);
}
