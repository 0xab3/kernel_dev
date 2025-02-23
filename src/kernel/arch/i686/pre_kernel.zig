const DIRECTORY_PRESENT: u32 = 0b1;
const DIRECTORY_READ_WRITE: u32 = 0b10;
const DIRECTORY_USER_SUPERVISOR: u32 = 0b100;
const DIRECTORY_USER_AVL: u32 = 0b1000000;
const DIRECTORY_PAGE_SIZE_4M: u32 = 0b10000000;

const KERNEL_VIRT_START: u32 = 0xC0000000;

pub export const paging_rodata: [1024]u32 align(4096) linksection(".paging.rodata") = blk: {
    @setEvalBranchQuota(1024);
    var PDE: [1024]u32 align(4096) = undefined;
    PDE[0] = DIRECTORY_PRESENT | DIRECTORY_READ_WRITE | DIRECTORY_PAGE_SIZE_4M;

    var idx = 0;
    // map the higher half kernel to memory
    for (KERNEL_VIRT_START / (4 * 1024 * 1024)..1024) |i| {
        PDE[i] = DIRECTORY_PRESENT | DIRECTORY_READ_WRITE | DIRECTORY_PAGE_SIZE_4M | idx << 22;
        idx += 1;
    }

    break :blk PDE;
};

export const kernel_stack: [1024 * 16]u8 align(16) linksection(".bss") = undefined;
extern const KERNEL_STACK_START: u32;
extern const KERNEL_STACK_END: u32;

export fn _start() linksection(".text.multiboot") callconv(.Naked) noreturn {
    asm volatile (
        \\.extern paging_rodata
        \\mov $paging_rodata, %ecx
        \\mov %ecx, %cr3
    );

    asm volatile (
        \\mov %cr4, %ecx
        \\or $0x00000010, %ecx
        \\mov %ecx, %cr4
    );

    asm volatile (
        \\ movl %cr0, %ecx
        \\ or $0x80000001, %ecx
        \\ movl %ecx, %cr0
    );

    asm volatile ("jmp stage_1");
}

export fn stage_1() callconv(.Naked) noreturn {
    // remove the kernel 1:1 mapping
    asm volatile ("invlpg (0)");
    asm volatile (
        \\ mov KERNEL_STACK_END, %ebp
        \\ mov KERNEL_STACK_END, %esp
    );
    const buffer: [*]u16 = @ptrFromInt(0xb8000);
    buffer[0] = 'b' | (1 << 8);
    buffer[1] = 'l' | (1 << 8);
    buffer[2] = 'y' | (1 << 8);
    buffer[3] = 'a' | (1 << 8);
    buffer[4] = 't' | (1 << 8);
    asm volatile (
        \\hlt
    );
}
