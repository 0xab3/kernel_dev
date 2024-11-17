const std = @import("std");
const console_writer = @import("../../kernel/console.zig");
const uart_writer = @import("../serial/uart.zig");
const fmt = std.fmt;
pub const io_writer_config = struct {
    console_out: bool = true,
    uart_out: bool = true,
};
pub const io_writer = struct {
    console_writer: ?*const std.io.Writer(void, error{}, console_writer.write_callback),
    uart_writer: ?*const std.io.Writer(void, error{}, uart_writer.write_callback),
    // todo(shahzad): use allocator ig idk tho
    pub fn init(config: io_writer_config) io_writer {
        var writer = io_writer{ .console_writer = null, .uart_writer = null };
        if (config.console_out) {
            writer.console_writer = &std.io.Writer(void, error{}, console_writer.write_callback){ .context = {} };
        }
        if (config.uart_out) {
            writer.uart_writer = &std.io.Writer(void, error{}, uart_writer.write_callback){ .context = {} };
        }
        return writer;
    }

    pub fn printf(self: io_writer, comptime format: []const u8, args: anytype) void {
        if (self.console_writer) |writer| {
            std.fmt.format(writer, format, args) catch unreachable;
        }
        if (self.uart_writer) |writer| {
            std.fmt.format(writer, format, args) catch unreachable;
        }
    }
};
