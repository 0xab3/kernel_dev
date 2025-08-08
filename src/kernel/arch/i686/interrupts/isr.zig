const std = @import("std");
const io = @import("../io/io.zig");
const root = @import("root");
const pic = @import("./pic.zig");
const keyboard = @import("../io/ps2/keyboard.zig");
const stdout_writer = @import("../../../stdout_writer.zig").stdout_writer;

pub fn default_signal_handler() callconv(.Interrupt) noreturn {
    stdout_writer.print("general exception occured\n", .{});
    root.k_hlt();
}

// Division Error (0x0) - Divide by zero
pub fn div_by_zero() callconv(.Interrupt) noreturn {
    stdout_writer.print("Divide by zero exception occurred\n", .{});
    root.k_hlt();
}

// Debug (0x1) - Debug Trap
pub fn debug_fault() callconv(.Interrupt) noreturn {
    stdout_writer.print("Debug exception occurred\n", .{});
    root.k_hlt();
}

// Non-maskable Interrupt (0x2)
pub fn nmi() callconv(.Interrupt) noreturn {
    stdout_writer.print("Non-maskable interrupt occurred\n", .{});
    root.k_hlt();
}

// Breakpoint (0x3) - Breakpoint Trap
pub fn breakpoint() callconv(.Interrupt) noreturn {
    stdout_writer.print("Breakpoint exception occurred\n", .{});
    root.k_hlt();
}

// Overflow (0x4) - Overflow Trap
pub fn overflow() callconv(.Interrupt) noreturn {
    stdout_writer.print("Overflow exception occurred\n", .{});
    root.k_hlt();
}

// Bound Range Exceeded (0x5)
pub fn bound_range_exceeded() callconv(.Interrupt) noreturn {
    stdout_writer.print("Bound range exceeded exception occurred\n", .{});
    root.k_hlt();
}

// Invalid Opcode (0x6)
pub fn invalid_opcode() callconv(.Interrupt) noreturn {
    stdout_writer.print("Invalid opcode exception occurred\n", .{});
    root.k_hlt();
}

// Device Not Available (0x7)
pub fn device_not_available() callconv(.Interrupt) noreturn {
    stdout_writer.print("Device not available exception occurred\n", .{});
    root.k_hlt();
}

// Double Fault (0x8)
pub fn double_fault(code: *u32) callconv(.Interrupt) noreturn {
    stdout_writer.print("Double fault exception occurred {*}\n", .{code});
    root.k_hlt();
}

// Coprocessor Segment Overrun (0x9)
// note(shahzad): this shit is not used nowadays
pub fn coproc_segment_overrun() callconv(.Interrupt) noreturn {
    stdout_writer.print("Coprocessor segment overrun exception occurred\n", .{});
    root.k_hlt();
}

// Invalid TSS (0xA)
pub fn invalid_tss() callconv(.Interrupt) noreturn {
    stdout_writer.print("Invalid TSS exception occurred\n", .{});
    root.k_hlt();
}

// Segment Not Present (0xB)
pub fn segment_not_present() callconv(.Interrupt) noreturn {
    stdout_writer.print("Segment not present exception occurred\n", .{});
    root.k_hlt();
}

// Stack-Segment Fault (0xC)
pub fn stack_segment_fault() callconv(.Interrupt) noreturn {
    stdout_writer.print("Stack-segment fault exception occurred\n", .{});
    root.k_hlt();
}

// General Protection Fault (0xD)
pub fn general_protection_fault() callconv(.Interrupt) noreturn {
    stdout_writer.print("General protection fault exception occurred\n", .{});
    root.k_hlt();
}

// Page Fault (0xE)
pub fn page_fault() callconv(.Interrupt) noreturn {
    stdout_writer.print("Page fault exception occurred\n", .{});
    root.k_hlt();
}

// Reserved (0xF)
pub fn reserved() callconv(.Interrupt) noreturn {
    stdout_writer.print("Reserved exception occurred\n", .{});
    root.k_hlt();
}

// x87 Floating-Point Exception (0x10)
pub fn fpu_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("x87 floating-point exception occurred\n", .{});
    root.k_hlt();
}

// Alignment Check (0x11)
pub fn alignment_check() callconv(.Interrupt) noreturn {
    stdout_writer.print("Alignment check exception occurred\n", .{});
    root.k_hlt();
}

// Machine Check (0x12)
pub fn machine_check() callconv(.Interrupt) noreturn {
    stdout_writer.print("Machine check exception occurred\n", .{});
    root.k_hlt();
}

// SIMD Floating-Point Exception (0x13)
pub fn simd_fpu_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("SIMD floating-point exception occurred\n", .{});
    root.k_hlt();
}

// Virtualization Exception (0x14)
pub fn virtualization_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("Virtualization exception occurred\n", .{});
    root.k_hlt();
}

// Control Protection Exception (0x15)
pub fn control_protection_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("Control protection exception occurred\n", .{});
    root.k_hlt();
}

// Hypervisor Injection Exception (0x1C)
pub fn hypervisor_injection_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("Hypervisor injection exception occurred\n", .{});
    root.k_hlt();
}

// VMM Communication Exception (0x1D)
pub fn vmm_communication_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("VMM communication exception occurred\n", .{});
    root.k_hlt();
}

// Security Exception (0x1E)
pub fn security_exception() callconv(.Interrupt) noreturn {
    stdout_writer.print("Security exception occurred\n", .{});
    root.k_hlt();
}

// Triple Fault (special case)
pub fn triple_fault() callconv(.Interrupt) noreturn {
    stdout_writer.print("Triple fault occurred\n", .{});
    root.k_hlt();
}

// FPU Error Interrupt (IRQ 13)
pub fn fpu_error_interrupt() callconv(.Interrupt) noreturn {
    stdout_writer.print("FPU error interrupt occurred\n", .{});
    root.k_hlt();
}
pub fn IRQ_0() callconv(.Interrupt) void {
    pic.send_eoi(0);
}
//IRQ_1: keyboard
pub fn IRQ_1() callconv(.Interrupt) void {
    //todo(shahzad): read from the inner function instead of here
    const scancode = io.in(u8,0x60);
    keyboard.translate_key(scancode);
    pic.send_eoi(1);
}
pub fn general_isr() callconv(.Interrupt) noreturn {
    stdout_writer.print("general interrupt occured\n", .{});
    root.k_hlt();
}
