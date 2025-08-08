pub fn out(port: u16, data: anytype) void {
    switch (@TypeOf(data)) {
        u8 => asm volatile (
            \\ outb  %[byte], %[port]
            :
            : [port] "{dx}" (port),
              [byte] "{al}" (data),
        ),
        u16 => asm volatile (
            \\ outw  %[byte], %[port]
            :
            : [port] "{dx}" (port),
              [byte] "{ax}" (data),
        ),

        u32 => asm volatile (
            \\ outl  %[byte], %[port]
            :
            : [port] "{dx}" (port),
              [byte] "{eax}" (data),
        ),
        else => {
            @compileLog("io.out type not working or smth {}\n", @TypeOf(data));
            @compileError("io.out only supports up to u32!");
        },
    }
}
pub fn in(Type: type, port: u16) Type {
    return switch (Type) {
        u8 => asm volatile (
            \\inb %[port], %[ret]
            : [ret] "=r" (-> u8),
            : [port] "N{dl}" (port),
        ),
        u16 => asm volatile (
            \\inw %[port], %[ret]
            : [ret] "=r" (-> u16),
            : [port] "N{dx}" (port),
        ),

        u32 => asm volatile (
            \\inl %[port], %[ret]
            : [ret] "=r" (-> u32),
            : [port] "N{dx}" (port),
        ),
        else => {
            @compileError("io.in only supports up to u32!");
        },
    };
}

//NOTE: wait a very small amount of time (1 to 4 microseconds, generally). Useful for implementing a small delay for PIC remapping on old hardware or generally as a simple but imprecise wait.
//NOTE!: you can do an IO operation on any unused port: the Linux kernel by default uses port 0x80, which is often used during POST to log information on the motherboard's hex display but almost always unused after boot.
pub fn wait() void {
    out(0x80, @as(u8, 0));
}
