const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.SpriteRenderer) };
    desc.query.filter.terms[1] = .{ .id = ecs.id(components.Hitpoints) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.SpriteRenderer, 1)) |renderers| {
                if (ecs.field(it, components.Hitpoints, 2)) |hitpoints| {
                    const animation = game.animations.Ground_dig_Layer_0;
                    renderers[i].index = animation[hitpoints[i].value];
                }
            }
        }
    }
}
