const std = @import("std");
const builtin = @import("builtin");
const gdt = @import("./arch/i686/gdt.zig");
const uart = @import("./arch/i686/serial/uart.zig");
const log = @import("./debug/log.zig");
const stdout_writer = @import("./stdout_writer.zig").stdout_writer;
const isr = @import("./arch/i686/interrupts/isr.zig");
const idt = @import("./arch/i686/interrupts/idt.zig");
const io = @import("./arch/i686/io/io.zig");
const pic = @import("./arch/i686/interrupts/pic.zig");
const csrc = @import("./debug/hacks.zig").csrc;
const multiboot = @import("./multiboot.zig");
const paging = @import("./arch/i686/memory/paging.zig");
comptime {
    _ = @import("./arch/i686/pre_kernel.zig");
}
pub const KERNEL_VIRT_OFFSET = 0xC0000000;

const console = @import("console.zig");

pub const std_options: std.Options = .{
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
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);
    stdout_writer.print("panic: {s} \n", .{msg});
    k_hlt();
}

fn setup_gdt() void {
    const gdt_0: u64 = 0;
    const gdt_1: u64 = gdt.Entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x9A, .flags = 0xc });
    const gdt_2: u64 = gdt.Entry.to_anal_format(.{ .base = 0x00, .limit = 0xfffff, .access_byte = 0x92, .flags = 0xc });
    //note(shahzad): equivalent to static keyword in c
    const Table = struct {
        var table: [3]u64 = undefined;
    };
    Table.table[0] = gdt_0;
    Table.table[1] = gdt_1;
    Table.table[2] = gdt_2;

    var gdt_table: gdt.Description = .{ .size = (@sizeOf(u64) * 3) - 1, .offset = &Table.table[0] };
    gdt.init(&gdt_table);
}

extern const KERNEL_START: i32;
extern const KERNEL_END: i32;
extern const KERNEL_VIRT_START: i32;
extern const KERNEL_VIRT_END: i32;
extern const KERNEL_TEXT_START: i32;
extern const KERNEL_TEXT_END: i32;
extern const KERNEL_RO_START: i32;
extern const KERNEL_RO_END: i32;
extern const KERNEL_DATA_START: i32;
extern const KERNEL_DATA_END: i32;
extern const KERNEL_STACK_START: i32;
extern const KERNEL_STACK_END: i32;

fn setup_interrupts(allocator: *std.mem.Allocator) !void {
    const idt_offset_table = try allocator.alloc(idt.Gate, 256);
    const idt_table = idt.new_default(idt_offset_table);
    idt.init(@intFromPtr(&idt_table));
}
var kernel_allocator_buffer: [4 * 1024 * 1024]u8 = undefined;
fn init(allocator: *std.mem.Allocator) !void {
    pic.init();
    setup_gdt();
    try setup_interrupts(allocator);
}

pub export fn basic_log() noreturn {
    const buffer: [*]u16 = @ptrFromInt(0xb8000);
    buffer[0] = 'b' | (1 << 8);
    buffer[1] = 'l' | (1 << 8);
    buffer[2] = 'y' | (1 << 8);
    buffer[3] = 'a' | (1 << 8);
    buffer[4] = 't' | (1 << 8);
    k_hlt();
}
fn int(comptime num: u32) void {
    asm volatile (
        \\ int %[num]
        :
        : [num] "n" (num),
    );
}
const MemMap = struct {
    kernel_start: usize,
    kernel_end: usize,
    kernel_virt_start: usize,
    kernel_virt_end: usize,
    kernel_text_start: usize,
    kernel_text_end: usize,
    kernel_ro_start: usize,
    kernel_ro_end: usize,
    kernel_data_start: usize,
    kernel_data_end: usize,
    kernel_stack_start: usize,
    kernel_stack_end: usize,
    const Self = @This();
    var instance: Self = undefined;

    pub fn init() Self {
        MemMap.instance = .{
            .kernel_start = @intFromPtr(&KERNEL_START),
            .kernel_end = @intFromPtr(&KERNEL_END),
            .kernel_virt_start = @intFromPtr(&KERNEL_VIRT_START),
            .kernel_virt_end = @intFromPtr(&KERNEL_VIRT_END),
            .kernel_text_start = @intFromPtr(&KERNEL_TEXT_START),
            .kernel_text_end = @intFromPtr(&KERNEL_TEXT_END),
            .kernel_ro_start = @intFromPtr(&KERNEL_RO_START),
            .kernel_ro_end = @intFromPtr(&KERNEL_RO_END),
            .kernel_data_start = @intFromPtr(&KERNEL_DATA_START),
            .kernel_data_end = @intFromPtr(&KERNEL_DATA_END),
            .kernel_stack_start = @intFromPtr(&KERNEL_STACK_START),
            .kernel_stack_end = @intFromPtr(&KERNEL_STACK_END),
        };
        return MemMap.instance;
    }
};

export fn kernel_main(multiboot_info: *multiboot.multiboot_info_t) callconv(.C) noreturn {
    _ = multiboot_info; // autofix

    const mem_map = MemMap.init();
    _ = mem_map;
    var temp_alloc = std.heap.FixedBufferAllocator.init(&kernel_allocator_buffer);
    var alloc = temp_alloc.allocator();
    uart.init();
    std.log.debug("KERNEL START {}", .{&KERNEL_START});
    std.log.debug("KERNEL END {}", .{&KERNEL_END});

    init(&alloc) catch |err| {
        std.debug.panic("wot da heall man {}\n", .{err});
    };
    console.write("wot da heall\n");

    while (true) {}
}
