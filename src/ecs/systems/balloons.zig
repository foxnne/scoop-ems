const std = @import("std");
const zm = @import("zmath");
const game = @import("../../scoop'ems.zig");
const components = game.components;
const ecs = @import("zflecs");

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Balloons) };
    desc.query.filter.terms[1] = .{ .id = ecs.id(components.SpriteRenderer) };
    desc.query.filter.terms[2] = .{ .id = ecs.id(components.Direction) };
    desc.query.filter.terms[3] = .{ .id = ecs.id(components.ParticleAnimator), .oper = ecs.oper_kind_t.Optional };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.SpriteRenderer, 2)) |renderers| {
                _ = renderers;
                if (ecs.field(it, components.Direction, 3)) |directions| {
                    if (ecs.get_pair(it.world, game.state.entities.player, ecs.id(components.Trigger), ecs.id(components.Balloons), components.Trigger)) |trigger| {
                        const animators = ecs.field(it, components.ParticleAnimator, 4);
                        _ = animators;
                        if (trigger.direction == directions[i]) {}
                    }
                }
            }
        }
    }
}
