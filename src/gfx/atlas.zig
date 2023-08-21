const std = @import("std");
const builtin = @import("builtin");
const math = @import("../math/math.zig");
const fs = @import("../tools/fs.zig");

const game = @import("../scoop'ems.zig");

pub const Atlas = struct {
    sprites: []game.gfx.Sprite,
    animations: []game.gfx.Animation,

    pub fn initFromFile(allocator: std.mem.Allocator, file: [:0]const u8) !Atlas {
        const read = try fs.read(allocator, file);
        defer allocator.free(read);

        const options = std.json.ParseOptions{ .duplicate_field_behavior = .use_first, .ignore_unknown_fields = true };
        const parsed = try std.json.parseFromSlice(Atlas, allocator, read, options);
        defer parsed.deinit();

        return parsed.value;
    }
};
