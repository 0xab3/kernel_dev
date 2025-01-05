const std = @import("std");
const DIRECTORY_PRESENT: u32 = 0b1;
const DIRECTORY_READ_WRITE: u32 = 0b10;
const DIRECTORY_USER_SUPERVISOR: u32 = 0b100;
const DIRECTORY_USER_AVL: u32 = 0b1000000;

const PAGE_PRESENT: u32 = 0b1;
const PAGE_READ_WRITE: u32 = 0b10;
const PAGE_USER_SUPERVISOR: u32 = 0b100;
const PAGE_GLOBAL: u32 = 0b100000000;

var pde: [1024]u32 align(4096) = undefined;
var pt: [1024][1024]u32 align(4096) = undefined;
const MAX_PAGE_LEN = 1024;

pub fn init() void {
    for (0..MAX_PAGE_LEN) |i| {
        for (0..MAX_PAGE_LEN) |value| {
            pt[i][value] = (@as(u32, @intCast(value)) << 12) | PAGE_PRESENT | PAGE_READ_WRITE | PAGE_USER_SUPERVISOR | PAGE_GLOBAL;
        }
        pde[i] = @intFromPtr(&pt[i][0]) | DIRECTORY_PRESENT | DIRECTORY_READ_WRITE | DIRECTORY_USER_SUPERVISOR | DIRECTORY_USER_AVL;
    }
    asm volatile (
        \\ mov %[directory_table_addr], %cr3
        :
        : [directory_table_addr] "N{dx}" (@intFromPtr(&pde[0])),
    );

    const cr0 = get_cr0();
    set_cr0(cr0 | 0x80000001);
    std.log.debug("paging enabled!", .{});
}

pub fn get_cr0() u32 {
    return asm volatile (
        \\ movl %cr0, %[ret]
        : [ret] "=r" (-> u32),
    );
}
pub fn set_cr0(new_flags: u32) void {
    asm volatile (
        \\ movl %[new_flags], %cr0
        :
        : [new_flags] "N{dx}" (new_flags),
    );
}
