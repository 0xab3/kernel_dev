//note(shahzad): i don't understand any of this shit
const std = @import("std");
const serial = @import("./serial.zig");
const fmt = std.fmt;
const outb = serial.outb;
const inb = serial.inb;

const COM1 = 0x3F8;

//note(shahzad): to send data to this port DLAB should be set to 0
const INTERRUPT_ENABLE_REGISTER = COM1 + 0x1;
// Bit 7-4	Bit 3	         Bit 2	                 Bit 1	                                Bit 0
// Reserved	Modem Status	Receiver Line Status	Transmitter Holding Register Empty	Received Data Available

const FIFO_CONTROL_REGISTER = COM1 + 0x2;
// Bits 7-6	                Bits 5-4	Bit 3            Bit 2	                Bit 1	                Bit 0
// Interrupt Trigger Level	Reserved	DMA Mode Select	 Clear Transmit FIFO	Clear Receive FIFO	Enable FIFO

const LINE_CONTROL_REGISTER = COM1 + 0x3;
//Divisor Latch Access Bit	Break Enable Bit	Parity Bits	Stop Bits	Data Bits
//Bit 7	                        Bit 6	                Bits 5-3	Bit 2	        Bits 1-0

const MODEM_CONTROL_REGISTER = COM1 + 4;
// 0	Data Terminal Ready (DTR)   Controls the Data Terminal Ready Pin
// 1	Request to Send (RTS)	    Controls the Request to Send Pin
// 2	Out 1	                    Controls a hardware pin (OUT1) which is unused in PC implementations
// 3	Out 2	                    Controls a hardware pin (OUT2) which is used to enable the IRQ in PC implementations
// 4	Loop	                    Provides a local loopback feature for diagnostic testing of the UART
// 5	0	Unused
// 6	0	Unused
// 7	0	Unused

const LINE_STATUS_REGISTER = COM1 + 5;
// 0    Data ready (DR)	        Set if there is data that can be read
// 1	Overrun error (OE)	Set if there has been data lost
// 2	Parity error (PE)	Set if there was an error in the transmission as detected by parity
// 3	Framing error (FE)	Set if a stop bit was missing
// 4	Break indicator (BI)	Set if there is a break in data input
// 5	Transmitter holding register empty (THRE)	Set if the transmission buffer is empty (i.e. data can be sent)
// 6	Transmitter empty (TEMT)	Set if the transmitter is not doing anything
// 7	Impending Error	Set if there is an error with a word in the input buffer

const THRE = 0x20;

// todo(shahzad): save state of this shit
pub fn init() bool {
    outb(INTERRUPT_ENABLE_REGISTER, 0x00); // Disable all interrupts

    // NOTE: To set the divisor to the controller:
    //
    // Set the most significant bit of the Line Control Register. This is the DLAB bit, and allows access to the divisor registers.
    // Send the least significant byte of the divisor value to [PORT + 0].
    // Send the most significant byte of the divisor value to [PORT + 1].
    // Clear the most significant bit of the Line Control Register.
    outb(LINE_CONTROL_REGISTER, 0x80); // Enable DLAB (set baud rate divisor)
    outb(COM1 + 0, 0x03); // Set divisor to 3 (lo byte) 38400 baud
    outb(COM1 + 1, 0x00); // (hi byte)

    outb(LINE_CONTROL_REGISTER, 0x03); // clear DLAB, 8 bits, no parity, one stop bit
    outb(FIFO_CONTROL_REGISTER, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
    outb(MODEM_CONTROL_REGISTER, 0x0B); // IRQs enabled, RTS/DTR set
    outb(MODEM_CONTROL_REGISTER, 0x1E); // Set in loopback mode, test the serial chip
    outb(COM1 + 0, 0xAE); // Test serial chip (send byte 0xAE and check if serial returns same byte)

    // Check if serial is faulty (i.e: not same byte as sent)
    if (inb(COM1 + 0) != 0xAE) {
        return false;
    }

    // If serial is not faulty set it in normal operation mode
    // (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
    outb(MODEM_CONTROL_REGISTER, 0x0B);
    return true;
}

fn is_transmitter_holding_register() bool {
    return (inb(LINE_STATUS_REGISTER) & THRE) != 0;
}
pub fn write(data: []const u8) void {
    while (is_transmitter_holding_register() == false) {}
    for (data) |byte| {
        outb(COM1, byte);
    }
}
pub fn write_callback(_: void, string: []const u8) error{}!usize {
    write(string);
    return string.len;
}
