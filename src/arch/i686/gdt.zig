const std = @import("std");
pub const gdt_description = packed struct {
    size: u16,
    offset: *u64,
};

// note(shahzad): no need to give a shit abt padding struct it's only for
// convenience
pub const gdt_entry = struct {
    limit: u20,
    base: u32,
    access_byte: u8,
    flags: u4,
    pub fn to_anal_format(entry: gdt_entry) u64 {
        var anal_formatted: u64 = 0;
        var target: [*]u8 = @ptrCast(&anal_formatted);
        if (entry.limit > 0xFFFFF) {
            @panic("GDT cannot encode limits larger than 0xFFFFF");
        }

        // Encode the limit
        target[0] = @intCast(entry.limit & 0xFF);
        target[1] = @intCast((entry.limit >> 8) & 0xFF);
        target[6] = @intCast((entry.limit >> 16) & 0x0F);

        // Encode the base
        target[2] = @intCast(entry.base & 0xFF);
        target[3] = @intCast((entry.base >> 8) & 0xFF);
        target[4] = @intCast((entry.base >> 16) & 0xFF);
        target[7] = @intCast((entry.base >> 24) & 0xFF);

        // Encode the access byte
        target[5] = @intCast(entry.access_byte);

        // Encode the flags
        target[6] |= @as(u8, entry.flags) << 4;
        return anal_formatted;
    }
};
pub extern fn gdt_init(arg: *gdt_description) void;

//note(shahzad): idk why i am calling this function init but it is what it is
pub const init = gdt_init;
