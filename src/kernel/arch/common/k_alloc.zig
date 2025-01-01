const std = @import("std");
const multiboot = @import("../../multiboot.zig");
const hashmap = std.hash_map;
const csrc = @import("../../debug/hacks.zig").csrc;
const stdout_writer = @import("../../stdout_writer.zig").stdout_writer;
// note(shahzad): memory map for dump_allocator
//we support 512 allocations??
const memory_map_entry = struct {
    type: u16,
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

        fn get_remaining_chunk_after_alloc(alloc_len: usize, mem_align: usize, entry: memory_map_entry) memory_map_entry {
            if (alloc_len > entry.length) {
                std.debug.panic("{} unreachable", .{csrc(@src())});
            }

            const new_offset = std.mem.alignForward(usize, @as(usize, @intCast(entry.offset)) + alloc_len, mem_align);
            return .{
                .offset = new_offset,
                .length = entry.length - (new_offset - entry.offset), // very shit way of doing this
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
            const new_chunk = get_remaining_chunk_after_alloc(len, ptr_align, previous_chunk);
            const used_chunk: memory_map_entry = .{
                .offset = previous_chunk.offset,
                .length = new_chunk.offset - previous_chunk.offset,
                .type = multiboot.MULTIBOOT_MEMORY_AVAILABLE,
            };

            const addr: u32 = @intCast(used_chunk.offset);
            self.free_list.items[smallest_chunk_idx] = new_chunk;

            self.used_list.append(used_chunk) catch |err| {
                std.log.debug("k_malloc.alloc: failed to append to allocation to used_list! {any}\n", .{err});
            };
            std.log.debug("current of free list", .{});
            std.log.debug("------------------------------", .{});
            for (self.free_list.items) |value| {
                std.log.debug("{}", .{value});
            }
            std.log.debug("------------------------------", .{});

            std.log.debug("current of used list", .{});
            std.log.debug("------------------------------", .{});
            for (self.used_list.items) |value| {
                std.log.debug("{}", .{value});
            }
            std.log.debug("------------------------------", .{});
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
            if (index != -1) {
                return @intCast(index);
            }
            return error.OutOfMemory;
        }
        fn free_list_from_multiboot_mem_map(self: *Self, multiboot_mem_map: []multiboot.multiboot_memory_map_t) !void {
            for (
                multiboot_mem_map,
            ) |entry| {
                if (entry.type != multiboot.MULTIBOOT_MEMORY_AVAILABLE) {
                    //todo(shahzad)!!: handle memory that is not available
                    std.log.debug("ignoring memory map as it is not available {}\n", .{entry});
                    continue;
                }

                if (entry.addr == 0) {
                    //todo(shahzad)!!!: this is very bad and should be fixed
                    try self.free_list.append(.{ .offset = entry.addr + 4, .length = entry.len, .type = @intCast(entry.type) });
                    continue;
                }
                try self.free_list.append(.{ .offset = entry.addr, .length = entry.len, .type = @intCast(entry.type) });
            }
        }

        // note(shahzad): ik this config should be comptime but idk the memory map provided by the boot loader at comptime
        pub fn allocator(self: *Self, cfg: config) !std.mem.Allocator {
            // note(shahzad): idk how to compress these two in a single line
            const mmap_ptr: [*]multiboot.multiboot_memory_map_t = @ptrFromInt(cfg.multiboot_memory_map);
            self.free_list = std.ArrayList(memory_map_entry).init(free_list_fixed_buff_alloc);
            try self.free_list_from_multiboot_mem_map(mmap_ptr[0..cfg.multiboot_memory_map_len]);
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
