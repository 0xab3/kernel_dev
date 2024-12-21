// this file contains some hacky stuff done because of my lack of knowledge about zig and programming in general and should go away

const std = @import("std");
// note(shahzad): wrapper over std.builtin.SourceLocation
const custom_source = struct {
    src: std.builtin.SourceLocation,
    pub fn format(
        self: @This(),
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s}:{}", .{ self.src.file, self.src.line });
    }
};
pub fn csrc(src: std.builtin.SourceLocation) custom_source {
    return custom_source{ .src = src };
}
