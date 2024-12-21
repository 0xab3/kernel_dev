const std = @import("std");
const multiboot = @import("../../multiboot.zig");
const hashmap = std.hash_map;
const stdout_writer = @import("../../stdout_writer.zig").stdout_writer;
// note(shahzad): memory map for dump_allocator
//we support 512 allocations??
const memory_map_entry = struct {
    memory_idx: u16,
    length: u64,
    offset: u64, //offset inside the memory
};

const config = struct {
    multiboot_memory_map_len: u32,
    multiboot_memory_map: u32,
};
// note(shahzad): never have i ever thought i would need to actually impl something like this
pub fn bump_allocator() type {
    return struct {
        free_list: std.ArrayList(memory_map_entry) = undefined,
        used_list: std.ArrayList(memory_map_entry) = undefined,

        var free_list_buffer: [256 * @sizeOf(memory_map_entry)]u8 = undefined;
        var used_list_buffer: [256 * @sizeOf(memory_map_entry)]u8 = undefined;

        var free_list_fixed_buff_alloc = free_list_fix_buf_alloc.allocator();
        var free_list_fix_buf_alloc = std.heap.FixedBufferAllocator.init(&free_list_buffer);

        var used_list_fixed_buff_alloc = used_list_fix_buf_alloc.allocator();
        var used_list_fix_buf_alloc = std.heap.FixedBufferAllocator.init(&used_list_buffer);

        const Self = @This();

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
                if (entry.offset == @intFromPtr(buf.ptr)) {
                    self.free_list.append(self.used_list.orderedRemove(i)) catch |err| {
                        std.log.debug("k_malloc.alloc: failed to append to allocation to free_list! {any}\n", .{err});
                    };
                    return;
                }
            }
            @panic("unreachable: k_malloc.free: used list doesn't contain allocation\n");
        }
        // note: this is shit
        fn is_memory_used(self: Self, idx: u32) bool {
            for (self.free_list.items) |entry| {
                if (entry.memory_idx == idx) {
                    return true;
                }
            }
            return false;
        }
        // note(shahzad): return index in the multiboot memory map array
        // i know this shit shit but need to get started somewhere
        fn find_unint_memory(self: Self) !u16 {
            _ = self;
            return 0;
            // for (self.multiboot_mem_map, 0..) |_, idx| {
            //     if (!self.is_memory_used(idx)) {
            //         return @intCast(idx);
            //     }
            // }
            // return error.OutOfMemory;
        }

        fn alloc(ctx: *anyopaque, len: usize, log2_ptr_align: u8, ret_addr: usize) ?[*]u8 {
            const self: *Self = @ptrCast(@alignCast(ctx));

            // basically 1 << ptr_allignment, man zig is such an a
            const ptr_align: usize = @as(usize, 1) << @as(std.mem.Allocator.Log2Align, @intCast(log2_ptr_align));
            const smallest_chunk_idx = self.find_best_fit_chunk(@intCast(len)) catch {
                return null;
            };
            const addr: u32 = @intCast(self.free_list.items[smallest_chunk_idx].offset);
            _ = ret_addr;
            self.used_list.append(self.free_list.orderedRemove(smallest_chunk_idx)) catch |err| {
                std.log.debug("k_malloc.alloc: failed to append to allocation to used_list! {any}\n", .{err});
            };
            return @ptrFromInt(std.mem.alignForward(usize, addr, ptr_align));
        }
        // find the smallest chuck that we can allocate in the free list and return the index
        fn find_best_fit_chunk(self: *Self, size: u64) !u16 {
            var index: i64 = -1;
            var cur_size: u64 = 0;

            for (self.free_list.items, 0..) |entry, idx| {
                if (entry.length > size and (cur_size == 0 or cur_size > size)) {
                    cur_size = size;
                    index = @intCast(idx);
                }
            }
            stdout_writer.printf("{}\n", .{index});
            if (index != -1) {
                return @intCast(index);
            }
            return error.OutOfMemory;
        }
        fn free_list_from_multiboot_mem_map(self: *Self, multiboot_mem_map: []multiboot.multiboot_memory_map_t) !void {
            for (multiboot_mem_map, 0..) |entry, i| {
                if (entry.addr == 0) {
                    //todo(shahzad)!!!: this is very bad and should be fixed
                    try self.free_list.append(.{ .offset = entry.addr + 4, .memory_idx = @intCast(i), .length = entry.len });
                    continue;
                }
                try self.free_list.append(.{ .offset = entry.addr, .memory_idx = @intCast(i), .length = entry.len });
            }
        }

        // note(shahzad): ik this config should be comptime but idk the memory map provided by the boot loader at comptime
        pub fn allocator(self: *Self, cfg: config) !std.mem.Allocator {
            // note(shahzad): idk how to compress these two in a single line
            const mmap_ptr: [*]multiboot.multiboot_memory_map_t = @ptrFromInt(cfg.multiboot_memory_map);
            self.free_list = std.ArrayList(memory_map_entry).init(free_list_fixed_buff_alloc);
            var total_len: c_ulonglong = 0;
            for (mmap_ptr[0..cfg.multiboot_memory_map_len]) |value| {
                stdout_writer.printf("{}\n", .{value});
                total_len += value.len;
                stdout_writer.printf("{}\n", .{total_len});
            }
            try self.free_list_from_multiboot_mem_map(mmap_ptr[0..cfg.multiboot_memory_map_len]);
            for (self.free_list.items) |value| {
                stdout_writer.printf("{}\n", .{value});
            }

            self.used_list = std.ArrayList(memory_map_entry).init(used_list_fixed_buff_alloc);

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
