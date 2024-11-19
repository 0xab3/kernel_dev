const stdout_writer = @import("../../../stdout_writer.zig").stdout_writer;
// note(shahzad):entry is encoded from idt_gate to satisfy the shit format
// specified in the specs
pub const gate = packed struct {
    offset: u16,
    segment_selector: u16,
    reserved: u8 = 0,
    gate_type: u4,
    unused_bit: u1 = 0,
    dpl: u2,
    present_bit: u1 = 1,
    higher_offset: u16,
};

// note(shahzad): this this can only contain 256 entries, every entry is 8 byte
// long (the table is the same as gdt)
pub const description = packed struct {
    size: u16,
    offset: *const gate,
};
pub const gate_t = enum(u4) {
    task_gate = 0x5,
    interrupt_gate_16 = 0x6,
    trap_gate_16 = 0x7,
    interrupt_gate_32 = 0xe,
    trap_gate_32 = 0xf,
};

pub fn gate_new(offset: u32, segment_selector: u16, gate_type: gate_t, dpl: u2) gate {
    // todo(shahzad): impl this shit
    const off_low: u16 = @intCast(offset & 0xffff);
    const off_high: u16 = @intCast(offset >> 0x10);
    return .{
        .offset = off_low,
        .segment_selector = segment_selector,
        .gate_type = @intFromEnum(gate_type),
        .dpl = dpl,
        .higher_offset = off_high,
    };
}

fn new(size: u16, offset: *const gate_t) *gate_t {
    // todo(shahzad): impl allocator
    _ = size;
    _ = offset;

    return 0x0;
}
pub extern fn idt_init(arg: *const description) callconv(.Stdcall) void;

//note(shahzad): idk why i am calling this function init but it is what it is
pub const init = idt_init;
