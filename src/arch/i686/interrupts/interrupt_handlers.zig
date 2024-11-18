const std = @import("std");
const root = @import("root");
const std_writer = @import("../io/io_writer.zig").std_writer;

pub fn div_by_zero() callconv(.Interrupt) noreturn {
    std_writer.printf("divide by zero exception occured\n", .{});
    root.k_hlt();
}
pub fn default_signal_handler() callconv(.Interrupt) noreturn {
    std_writer.printf("general exception occured", .{});
    root.k_hlt();
}
