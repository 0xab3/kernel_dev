const std = @import("std");
const stdout_writer = @import("../../../stdout_writer.zig").stdout_writer;
const isr = @import("./isr.zig");
pub extern fn idt_init(arg: u32) callconv(.Stdcall) void;

//note(shahzad): idk why i am calling this function init but it is what it is
pub const init = idt_init;

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
    const src = @src();
    // todo(shahzad): impl allocator
    _ = size;
    _ = offset;

    std.debug.panic("unreachable. {s}():{} ", .{ src.fn_name, src.line });
    return .{};
}

// note(shahzad): 256 interrupts possible
pub fn new_default(idt_offset_table: []gate) description {
    for (0..256) |i| {
        idt_offset_table[i] = gate_new(@intFromPtr(&isr.general_isr), 0x8, gate_t.interrupt_gate_32, 0x00);
    }
    //note(shahzad): divide by zero exception is 0th in idt
    idt_offset_table[0] = gate_new(@intFromPtr(&isr.div_by_zero), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[1] = gate_new(@intFromPtr(&isr.debug_fault), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[2] = gate_new(@intFromPtr(&isr.nmi), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[3] = gate_new(@intFromPtr(&isr.breakpoint), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[4] = gate_new(@intFromPtr(&isr.overflow), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[5] = gate_new(@intFromPtr(&isr.bound_range_exceeded), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[6] = gate_new(@intFromPtr(&isr.invalid_opcode), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[7] = gate_new(@intFromPtr(&isr.device_not_available), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[8] = gate_new(@intFromPtr(&isr.double_fault), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[9] = gate_new(@intFromPtr(&isr.coproc_segment_overrun), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0xA] = gate_new(@intFromPtr(&isr.invalid_tss), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0xB] = gate_new(@intFromPtr(&isr.segment_not_present), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0xC] = gate_new(@intFromPtr(&isr.stack_segment_fault), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0xD] = gate_new(@intFromPtr(&isr.general_protection_fault), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0xE] = gate_new(@intFromPtr(&isr.page_fault), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0xF] = gate_new(@intFromPtr(&isr.reserved), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x10] = gate_new(@intFromPtr(&isr.fpu_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x11] = gate_new(@intFromPtr(&isr.alignment_check), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x12] = gate_new(@intFromPtr(&isr.machine_check), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x13] = gate_new(@intFromPtr(&isr.simd_fpu_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x14] = gate_new(@intFromPtr(&isr.virtualization_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x15] = gate_new(@intFromPtr(&isr.control_protection_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x1C] = gate_new(@intFromPtr(&isr.hypervisor_injection_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x1D] = gate_new(@intFromPtr(&isr.vmm_communication_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x1E] = gate_new(@intFromPtr(&isr.security_exception), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x1F] = gate_new(@intFromPtr(&isr.reserved), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x20] = gate_new(@intFromPtr(&isr.IRQ_0), 0x8, gate_t.interrupt_gate_32, 0x00);
    idt_offset_table[0x21] = gate_new(@intFromPtr(&isr.IRQ_1), 0x8, gate_t.interrupt_gate_32, 0x00);
    const idt_table: description = .{
        .size = @sizeOf(gate) * 255 - 1,
        .offset = &idt_offset_table[0],
    };
    return idt_table;
}
