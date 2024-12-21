const std = @import("std");
const io = @import("../io/io.zig");
const PIC1 = 0x20;
const PIC2 = 0xA0;
//note(shahzad)!: command is only used to send eoi and init the chip
const PIC1_COMMAND = PIC1;
const PIC1_DATA = (PIC1 + 1);
const PIC2_COMMAND = PIC2;
const PIC2_DATA = (PIC2 + 1);
const PIC_EOI = 0x20;

//after sending init PIC waits for 3 "initialization" words on data port
//1. Interrupt vector entries offset
//Tell it how it is wired to master/slaves.
//Gives additional information about the environment.
const PIC_INIT = 0x11;
//note(shahzad): [https://pdos.csail.mit.edu/6.828/2014/readings/hardware/8259A.pdf] Page:19  Figure 11. Cascading the 8259A
const MASTER_TO_SLAVE_PIN = 0x4;
const PIC_MODE_8086 = 0x01;

pub fn disable() void {
    io.outb(PIC1_DATA, 0xff);
    io.outb(PIC2_DATA, 0xff);
}

// note(shahzad): setup the pic to point interrupts outside exceptions in idt(0..0x1f)
pub fn init() void {
    const mask_1 = io.inb(PIC1_DATA);
    const mask_2 = io.inb(PIC1_DATA);
    //note(shahzad): ignoring as we only want to enable keyboard for now
    _ = .{ mask_1, mask_2 };

    //note(shahzad): send init byte
    io.outb(PIC1_COMMAND, PIC_INIT); //note(shahzad)!: command is only used to send eoi and init the chip
    io.wait();
    io.outb(PIC2_COMMAND, PIC_INIT); //note(shahzad)!: command is only used to send eoi and init the chip
    io.wait();

    //note(shahzad): send vector table offset
    io.outb(PIC1_DATA, 0x20); //note(shahzad): 0x0..0x1f is proc exceptions so mapping it from 0x20
    io.wait();
    io.outb(PIC2_DATA, 0x28); //note(shahzad)!: command is only used to send eoi and init the chip
    io.wait();

    //note(shahzad): set the pin conifg
    io.outb(PIC1_DATA, MASTER_TO_SLAVE_PIN);
    io.outb(PIC2_DATA, 0x02); //tell the pic2 chip about it's own cascading 0b10 (need to study about this shit)??

    //note(shahzad): tell pic that it should use 8086 mode. Reason:[https://pdos.csail.mit.edu/6.828/2014/readings/hardware/8259A.pdf] Page:19  Figure 11. Cascading the 8259A
    io.outb(PIC1_DATA, PIC_MODE_8086);
    io.outb(PIC2_DATA, PIC_MODE_8086);

    //note(shahzad): set the interrupt mask
    io.outb(PIC1_DATA, 0);
    io.outb(PIC2_DATA, 0);
}

// after the IRQ has been handled we need to notify the PIC
pub fn send_eoi(irq_number: u8) void {
    //If the IRQ came from the Master PIC, it is sufficient to issue this command only to the Master PIC; however if the IRQ came from the Slave PIC, it is necessary to issue the command to both PIC chips.
    if (irq_number >= 8)
        io.outb(PIC2_COMMAND, PIC_EOI);
    io.outb(PIC1_COMMAND, PIC_EOI);
}
