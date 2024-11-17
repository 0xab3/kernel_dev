const std = @import("std");
const uart = @import("../../i686/io/io_writer.zig");

const log = std.log;

pub fn uart_log_func(
    comptime message_level: log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    const writer = std.io.Writer(void, error{}, uart.uart_writer_cb){ .context = {} };
    writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
}
