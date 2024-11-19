pub fn outb(port: u16, byte: u8) void {
    asm volatile (
        \\ outb  %[byte], %[port]
        :
        : [port] "{dx}" (port),
          [byte] "{al}" (byte),
    );
}
pub fn inb(port: u16) u8 {
    return asm volatile (
        \\outb %[ret], %[port]
        : [ret] "=r" (-> u8),
        : [port] "{dx}" (port),
    );
}
