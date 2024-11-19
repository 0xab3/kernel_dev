const std = @import("std");
pub const description = packed struct {
    size: u16,
    offset: *const u64,
};

// note(shahzad): no need to give a shit abt padding struct it's only for
// convenience
pub const entry = struct {
    limit: u20,
    base: u32,
    access_byte: u8,
    flags: u4,
    pub fn to_anal_format(ent: entry) u64 {
        var anal_formatted: u64 = 0;
        var target: [*]u8 = @ptrCast(&anal_formatted);
        if (ent.limit > 0xFFFFF) {
            @panic("GDT cannot encode limits larger than 0xFFFFF");
        }

        // Encode the limit
        target[0] = @intCast(ent.limit & 0xFF);
        target[1] = @intCast((ent.limit >> 8) & 0xFF);
        target[6] = @intCast((ent.limit >> 16) & 0x0F);

        // Encode the base
        target[2] = @intCast(ent.base & 0xFF);
        target[3] = @intCast((ent.base >> 8) & 0xFF);
        target[4] = @intCast((ent.base >> 16) & 0xFF);
        target[7] = @intCast((ent.base >> 24) & 0xFF);

        // Encode the access byte
        target[5] = @intCast(ent.access_byte);

        // Encode the flags
        target[6] |= @as(u8, ent.flags) << 4;
        return anal_formatted;
    }
};
pub extern fn gdt_init(arg: *description) void;

//note(shahzad): idk why i am calling this function init but it is what it is
pub const init = gdt_init;
