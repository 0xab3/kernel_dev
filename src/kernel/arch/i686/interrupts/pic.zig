const io = @import("../io/io.zig");
const PIC1 = 0x20;
const PIC2 = 0xA0;
const PIC1_COMMAND = PIC1;
const PIC1_DATA = (PIC1 + 1);
const PIC2_COMMAND = PIC2;
const PIC2_DATA = (PIC2 + 1);

pub fn disable() void {
    io.outb(PIC1_DATA, 0xff);
    io.outb(PIC2_DATA, 0xff);
}
