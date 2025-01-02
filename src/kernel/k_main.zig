const std = @import("std");
const gdt = @import("./arch/i686/gdt.zig");
const uart = @import("./arch/i686/serial/uart.zig");
const log = @import("./debug/log.zig");
const stdout_writer = @import("./stdout_writer.zig").stdout_writer;
const isr = @import("./arch/i686/interrupts/isr.zig");
const idt = @import("./arch/i686/interrupts/idt.zig");
const io = @import("./arch/i686/io/io.zig");
const pic = @import("./arch/i686/interrupts/pic.zig");
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
    stdout_writer.print("panic: {s} \n", .{msg});
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

extern const _kern_start: i32;
extern const _kern_end: i32;

//todo(shahzad): please impl an alloc or we die
fn setup_interrupts() void {
    // todo(shahzad): impl allocator
    const table = struct {
        var idt_offset_table: [256]idt.gate = undefined;
    };
    const idt_table = idt.new_default(&table.idt_offset_table);
    idt.init(&idt_table);
}

export fn kernel_main(multiboot_info: *multiboot.multiboot_info_t) callconv(.C) void {
    const kern_start = @intFromPtr(&_kern_start);
    const kern_end = @intFromPtr(&_kern_end);
    const multiboot_mem_map_len = multiboot_info.mmap_length / @sizeOf(multiboot.multiboot_memory_map_t);
    const ret = uart.init();
    if (ret == false) {
        return;
    }

    // normally you would give the config to the function while creating the type but
    // as it is comptime we give it to allocator
    var kalloc = allocator.arena_like_allocator(){};
    const allc = kalloc.allocator(.{
        .multiboot_memory_map_len = multiboot_mem_map_len,
        .multiboot_memory_map = multiboot_info.mmap_addr,
        .kern_start = kern_start,
        .kern_end = kern_end,
    }) catch |err| {
        std.debug.panic("{} failed to initialize allocator: {any}\n", .{ csrc(@src()), err });
    };

    const temp1 = allc.alloc(u32, 32) catch |e|
        {
        std.debug.panic("{any}\n", .{e});
    };

    const temp2 = allc.alloc(u32, 32) catch |e|
        {
        std.debug.panic("{any}\n", .{e});
    };
    allc.free(temp1);
    allc.free(temp2);
}
