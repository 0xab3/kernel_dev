// note(shahzad):entry is encoded from idt_gate to satisfy the shit format
// specified in the specs
const idt_gate_t = packed struct {
    offset: u16,
    segment_selector: u16,
    reserved: u8,
    gate_type: u4,
    unused_bit: u1,
    dpl: u2,
    present_bit: u1,
    higher_offset: u16,
};

// note(shahzad): this this can only contain 256 entries, every entry is 8 byte
// long (the table is the same as gdt)
const idt_description = packed struct {
    size: u16,
    offset: *idt_gate_t,
};
fn idt_gate_new(offset: u32, segment_selector: u16, gate_type: u8, dpl: u8, present_bit: u8) idt_gate_t {
    _ = offset;
    _ = segment_selector;
    _ = gate_type;
    _ = dpl;
    _ = present_bit;
    // todo(shahzad): impl this shit
    return .{};
}

fn idt_new() *idt_gate_t {
    // todo(shahzad): impl allocator
    return 0x0;
}
