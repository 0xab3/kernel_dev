pub fn outb(port: u16, byte: u8) void {
    asm volatile (
        \\ outb  %[byte], %[port]
        :
        : [port] "{dx}" (port),
          [byte] "{al}" (byte),
    );
}
// (todo):shahzad make it generic over type inb, inw,indw
pub fn inb(port: u16) u8 {
    return asm volatile (
        \\inb %[port], %[ret]
        : [ret] "=r" (-> u8),
        : [port] "N{dx}" (port),
    );
}

//NOTE: wait a very small amount of time (1 to 4 microseconds, generally). Useful for implementing a small delay for PIC remapping on old hardware or generally as a simple but imprecise wait.
//NOTE!: you can do an IO operation on any unused port: the Linux kernel by default uses port 0x80, which is often used during POST to log information on the motherboard's hex display but almost always unused after boot.
pub fn wait() void {
    outb(0x80, 0);
}
