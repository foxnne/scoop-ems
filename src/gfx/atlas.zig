const std = @import("std");
const builtin = @import("builtin");
const math = @import("../math/math.zig");
const fs = @import("../tools/fs.zig");

pub const Animation = struct {
    name: [:0]const u8,
    start: usize,
    length: usize,
    fps: usize,
};

pub const Sprite = struct {
    name: [:0]const u8,
    source: [4]u32,
    origin: [2]i32,
};

pub const Atlas = struct {
    sprites: []Sprite,
    animations: []Animation,

    pub fn initFromFile(allocator: std.mem.Allocator, file: [:0]const u8) !Atlas {
        const read = try fs.read(allocator, file);
        defer allocator.free(read);

        const options = std.json.ParseOptions{ .duplicate_field_behavior = .use_first, .ignore_unknown_fields = true };
        const parsed = try std.json.parseFromSlice(Atlas, allocator, read, options);
        defer parsed.deinit();

        return parsed.value;
    }
};
