const std = @import("std");
const multiboot = @import("../../multiboot.zig");
const hashmap = std.hash_map;
const csrc = @import("../../debug/hacks.zig").csrc;
const utils = @import("../../utils.zig");
const stdout_writer = @import("../../stdout_writer.zig").stdout_writer;
// note(shahzad): memory map for dump_allocator
//we support 512 allocations??
const memory_map_entry = struct {
    type: u16,
    len: u64,
    addr: u64,
};

const config = struct {
    multiboot_memory_map_len: u32,
    multiboot_memory_map: u32,
    kern_start: u32,
    kern_end: u32,
};
// note(shahzad): never have i ever thought i would need to actually impl something like this
pub fn arena_like_allocator() type {
    return struct {
        free_list: std.ArrayList(memory_map_entry) = undefined,
        used_list: std.ArrayList(memory_map_entry) = undefined,
        is_initialized: bool = false,

        var free_list_buffer: [256 * @sizeOf(memory_map_entry)]u8 = undefined;
        var used_list_buffer: [256 * @sizeOf(memory_map_entry)]u8 = undefined;

        var free_list_fixed_buff_alloc = free_list_fix_buf_alloc.allocator();
        var free_list_fix_buf_alloc = std.heap.FixedBufferAllocator.init(&free_list_buffer);

        var used_list_fixed_buff_alloc = used_list_fix_buf_alloc.allocator();
        var used_list_fix_buf_alloc = std.heap.FixedBufferAllocator.init(&used_list_buffer);

        const Self = @This();
        pub fn current_allocator(self: Self) std.mem.Allocator {
            return .{
                .ptr = self,
                .vtable = &.{
                    .alloc = alloc,
                    .resize = resize,
                    .free = free,
                },
            };
        }

        fn resize(ctx: *anyopaque, buf: []u8, buf_align: u8, new_len: usize, ret_addr: usize) bool {
            _ = ctx;
            _ = buf;
            _ = buf_align;
            _ = new_len;
            _ = ret_addr;
            @panic("bro this is an allocator i made you are expecting too much\n");
        }

        fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
            _ = buf_align;
            _ = ret_addr;
            const self: *Self = @ptrCast(@alignCast(ctx));
            for (self.used_list.items, 0..) |entry, i| {
                if (entry.addr == @intFromPtr(buf.ptr)) {
                    self.free_list.append(self.used_list.orderedRemove(i)) catch |err| {
                        std.log.debug("k_malloc.alloc: failed to append to allocation to free_list! {any}\n", .{err});
                    };
                    return;
                }
            }
            @panic("unreachable: k_malloc.free: used list doesn't contain allocation\n");
        }

        fn get_remaining_chunk_after_alloc(_: Self, alloc_len: usize, mem_align: usize, entry: memory_map_entry) memory_map_entry {
            if (alloc_len > entry.len) {
                std.debug.panic("{} unreachable", .{csrc(@src())});
            }

            const new_offset = std.mem.alignForward(usize, @as(usize, @intCast(entry.addr)) + alloc_len, mem_align);
            return .{
                .addr = new_offset,
                .len = entry.len - (new_offset - entry.addr), // very shit way of doing this
                .type = multiboot.MULTIBOOT_MEMORY_AVAILABLE,
            };
        }

        fn alloc(ctx: *anyopaque, len: usize, log2_ptr_align: u8, ret_addr: usize) ?[*]u8 {
            _ = ret_addr;
            const self: *Self = @ptrCast(@alignCast(ctx));

            // basically 1 << ptr_allignment, man zig is such an ass language
            const ptr_align: usize = @as(usize, 1) << @as(std.mem.Allocator.Log2Align, @intCast(log2_ptr_align));
            const smallest_chunk_idx = self.find_best_fit_chunk(@intCast(len)) catch {
                return null;
            };
            const previous_chunk = self.free_list.items[smallest_chunk_idx];
            const new_chunk = self.get_remaining_chunk_after_alloc(len, ptr_align, previous_chunk);
            const used_chunk: memory_map_entry = .{
                .addr = previous_chunk.addr,
                .len = new_chunk.addr - previous_chunk.addr,
                .type = multiboot.MULTIBOOT_MEMORY_AVAILABLE,
            };

            const addr: u32 = @intCast(used_chunk.addr);
            self.free_list.items[smallest_chunk_idx] = new_chunk;

            self.used_list.append(used_chunk) catch |err| {
                std.log.debug("k_malloc.alloc: failed to append to allocation to used_list! {any}\n", .{err});
            };
            return @ptrFromInt(std.mem.alignForward(usize, addr, ptr_align));
        }
        // find the smallest chuck that we can allocate in the free list and return the index
        fn find_best_fit_chunk(self: *Self, size: u64) !u16 {
            var index: i64 = -1;
            var cur_size: u64 = 0;

            for (self.free_list.items, 0..) |entry, idx| {
                if (entry.len > size and (cur_size == 0 or cur_size > size)) {
                    cur_size = size;
                    index = @intCast(idx);
                }
            }
            if (index != -1) {
                return @intCast(index);
            }
            return error.OutOfMemory;
        }

        fn free_list_from_multiboot_mem_map(self: *Self, cfg: config) !void {
            const mmap_ptr: [*]multiboot.multiboot_memory_map_t = @ptrFromInt(cfg.multiboot_memory_map);
            const multiboot_mem_map = mmap_ptr[0..cfg.multiboot_memory_map_len];
            for (
                multiboot_mem_map,
            ) |entry| {
                var is_kernel_in_memory = false;
                if (entry.type != multiboot.MULTIBOOT_MEMORY_AVAILABLE) {
                    //todo(shahzad)!!: handle memory that is not available
                    std.log.debug("ignoring memory map as it is not available {}\n", .{entry});
                    continue;
                }

                var mem_map_entry: memory_map_entry = .{ .addr = entry.addr, .len = entry.len, .type = @intCast(entry.type) };

                //check if kernel is part of the memory chunk
                if (utils.is_in_range(entry.addr, entry.addr + entry.len, cfg.kern_start)) {
                    @setCold(true);
                    const pre_kernel_memory: memory_map_entry = .{
                        .addr = mem_map_entry.addr,
                        .len = cfg.kern_start - mem_map_entry.addr,
                        .type = @intCast(entry.type),
                    };
                    if (pre_kernel_memory.len != 0) {
                        try self.free_list.append(pre_kernel_memory);
                        is_kernel_in_memory = true;
                    }
                }
                if (utils.is_in_range(entry.addr, entry.addr + entry.len, cfg.kern_end)) {
                    @setCold(true);
                    const post_kernel_memory: memory_map_entry = .{
                        .addr = cfg.kern_end,
                        .len = (mem_map_entry.addr + mem_map_entry.len) - cfg.kern_end,
                        .type = @intCast(entry.type),
                    };
                    if (post_kernel_memory.len != 0) {
                        try self.free_list.append(post_kernel_memory);
                        is_kernel_in_memory = true;
                    }
                }

                if (is_kernel_in_memory) {
                    continue;
                }

                //check if memory chunk is part of kernel
                if (utils.is_in_range(cfg.kern_start, cfg.kern_end, entry.addr) or utils.is_in_range(cfg.kern_start, cfg.kern_end, entry.addr + entry.len)) {
                    continue;
                }
                if (entry.addr == 0) {
                    //todo(shahzad)!!!: this is very bad and should be fixed
                    mem_map_entry.addr += 4;
                }
                try self.free_list.append(mem_map_entry);
            }
        }
        fn init(self: *Self, cfg: config) !void {
            self.free_list = std.ArrayList(memory_map_entry).init(free_list_fixed_buff_alloc);
            try self.free_list_from_multiboot_mem_map(cfg);
            self.used_list = std.ArrayList(memory_map_entry).init(used_list_fixed_buff_alloc);
            self.is_initialized = true;
        }

        // note(shahzad): ik this config should be comptime but idk the memory map provided by the boot loader at comptime
        pub fn allocator(self: *Self, cfg: config) !std.mem.Allocator {
            if (self.is_initialized == false) {
                try self.init(cfg);
            }

            // note(shahzad): idk how to compress these two in a single line
            return .{
                .ptr = self,
                .vtable = &.{
                    .alloc = alloc,
                    .resize = resize,
                    .free = free,
                },
            };
        }
    };
}
