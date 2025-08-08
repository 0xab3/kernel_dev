const std = @import("std");
const stdout_writer = @import("../../../stdout_writer.zig").stdout_writer;
const isr = @import("./isr.zig");
pub extern fn idt_init(arg: u32) callconv(.Stdcall) void;

//note(shahzad): idk why i am calling this function init but it is what it is
pub const init = idt_init;

// note(shahzad):entry is encoded from idt_gate to satisfy the shit format
// specified in the specs
pub const Gate = packed struct {
    offset: u16,
    segment_selector: u16,
    reserved: u8 = 0,
    gate_type: Type,
    unused_bit: u1 = 0,
    dpl: u2,
    present_bit: u1 = 1,
    higher_offset: u16,
    const Type = enum(u4) {
        task_gate = 0x5,
        interrupt_gate_16 = 0x6,
        trap_gate_16 = 0x7,
        interrupt_gate_32 = 0xe,
        trap_gate_32 = 0xf,
    };
    pub fn init(offset: u32, segment_selector: u16, gate_type: Gate.Type, dpl: u2) Gate {

        // todo(shahzad): impl this shit
        const off_low: u16 = @intCast(offset & 0xffff);
        const off_high: u16 = @intCast(offset >> 0x10);
        return .{
            .offset = off_low,
            .segment_selector = segment_selector,
            .gate_type = gate_type,
            .dpl = dpl,
            .higher_offset = off_high,
        };
    }
};

// note(shahzad): this this can only contain 256 entries, every entry is 8 byte
// long (the table is the same as gdt)
pub const Description = packed struct {
    size: u16,
    offset: *const Gate,
};

// note(shahzad): 256 interrupts possible
pub fn new_default(idt_offset_table: []Gate) Description {
    const general_isr_ptr = @intFromPtr(&isr.general_isr);
    const general_isr_ptr_hi: u16 = @intCast(general_isr_ptr & 0xffff);
    const general_isr_ptr_lo: u16 = @intCast(general_isr_ptr >> 0x10);
    for (0..256) |i| {
        idt_offset_table[i] = Gate{ .offset = general_isr_ptr_lo, .segment_selector = 0x8, .gate_type = Gate.Type.interrupt_gate_32, .dpl = 0x00, .higher_offset = general_isr_ptr_hi };
    }
    //note(shahzad): divide by zero exception is 0th in idt
    idt_offset_table[0] = Gate.init(@intFromPtr(&isr.div_by_zero), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[1] = Gate.init(@intFromPtr(&isr.debug_fault), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[2] = Gate.init(@intFromPtr(&isr.nmi), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[3] = Gate.init(@intFromPtr(&isr.breakpoint), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[4] = Gate.init(@intFromPtr(&isr.overflow), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[5] = Gate.init(@intFromPtr(&isr.bound_range_exceeded), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[6] = Gate.init(@intFromPtr(&isr.invalid_opcode), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[7] = Gate.init(@intFromPtr(&isr.device_not_available), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[8] = Gate.init(@intFromPtr(&isr.double_fault), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[9] = Gate.init(@intFromPtr(&isr.coproc_segment_overrun), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0xA] = Gate.init(@intFromPtr(&isr.invalid_tss), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0xB] = Gate.init(@intFromPtr(&isr.segment_not_present), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0xC] = Gate.init(@intFromPtr(&isr.stack_segment_fault), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0xD] = Gate.init(@intFromPtr(&isr.general_protection_fault), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0xE] = Gate.init(@intFromPtr(&isr.page_fault), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0xF] = Gate.init(@intFromPtr(&isr.reserved), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x10] = Gate.init(@intFromPtr(&isr.fpu_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x11] = Gate.init(@intFromPtr(&isr.alignment_check), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x12] = Gate.init(@intFromPtr(&isr.machine_check), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x13] = Gate.init(@intFromPtr(&isr.simd_fpu_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x14] = Gate.init(@intFromPtr(&isr.virtualization_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x15] = Gate.init(@intFromPtr(&isr.control_protection_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x1C] = Gate.init(@intFromPtr(&isr.hypervisor_injection_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x1D] = Gate.init(@intFromPtr(&isr.vmm_communication_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x1E] = Gate.init(@intFromPtr(&isr.security_exception), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x1F] = Gate.init(@intFromPtr(&isr.reserved), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x20] = Gate.init(@intFromPtr(&isr.IRQ_0), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    idt_offset_table[0x21] = Gate.init(@intFromPtr(&isr.IRQ_1), 0x8, Gate.Type.interrupt_gate_32, 0x00);
    const idt_table: Description = .{
        .size = @sizeOf(Gate) * 255 - 1,
        .offset = &idt_offset_table[0],
    };
    return idt_table;
}
