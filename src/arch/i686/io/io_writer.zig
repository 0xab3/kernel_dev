const std = @import("std");
const console_writer = @import("../../kernel/console.zig");
const uart_writer = @import("../serial/uart.zig");
const fmt = std.fmt;
const io_writer_config = struct {
    console_out: bool = true,
    uart_out: bool = true,
};

pub fn console_writer_cb(_: void, string: []const u8) error{}!usize {
    console_writer.write(string);
    return string.len;
}
pub fn uart_writer_cb(_: void, string: []const u8) error{}!usize {
    uart_writer.write(string);
    return string.len;
}
pub const io_writer = struct {
    console_writer: ?*const std.io.Writer(void, error{}, console_writer_cb),
    uart_writer: ?*const std.io.Writer(void, error{}, uart_writer_cb),

    // todo(shahzad): use allocator ig idk tho
    pub fn init(config: io_writer_config) io_writer {
        var writer = io_writer{ .console_writer = null, .uart_writer = null };
        if (config.console_out) {
            writer.console_writer = &std.io.Writer(
                void,
                error{},
                console_writer_cb,
            ){ .context = {} };
        }
        if (config.uart_out) {
            writer.uart_writer = &std.io.Writer(void, error{}, uart_writer_cb){ .context = {} };
        }
        return writer;
    }

    pub fn printf(self: io_writer, comptime format: []const u8, args: anytype) void {
        if (self.console_writer) |writer| {
            std.fmt.format(writer.*, format, args) catch unreachable;
        }
        if (self.uart_writer) |writer| {
            std.fmt.format(writer.*, format, args) catch unreachable;
        }
    }
};
//todo(shahzad): rename this shit
pub const std_writer = io_writer.init(.{ .console_out = true, .uart_out = true });
