const std = @import("std");
const stdout_writer = @import("../../../../stdout_writer.zig").stdout_writer;
fn read_key() void {
    return;
}
const table = enum(u8) { esc = 0x01, @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"0", @"-", @"=", backspace, tab, q, w, e, r, t, y, u, i, o, p, @"[", @"]", enter, l_ctrl, a, s, d, f, g, h, j, k, l, @";", @"`", bruuuh, lshift, @"\\", z, x, c, v, b, n, m, @",", @".", @"/", r_shift, ignore_key_pad, l_alt, space, capslock, f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, num_lock, scroll_lock, keypad_0, keypad_1, keypad_2, keypad_3, keypad_4, keypad_5, keypad_6, keypad_7, keypad_8, keypad_9, keypad_10, keypad_11, keypad_12, f11 };
pub fn translate_key(scancode: u8) void {
    if (scancode == @intFromEnum(table.space)) {
        stdout_writer.printf(" ", .{});
        return;
    }
    inline for (std.meta.fields(table)) |variant| {
        if (variant.value == scancode) {
            stdout_writer.printf("{s}", .{variant.name});
        }
    }
}
