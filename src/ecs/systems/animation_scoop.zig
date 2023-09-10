const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.SpriteAnimator) };
    desc.query.filter.terms[1] = .{ .id = ecs.id(components.SpriteRenderer) };
    desc.query.filter.terms[2] = .{ .id = ecs.pair(ecs.id(components.Scoop), ecs.id(components.Cooldown)) };
    desc.query.filter.terms[3] = .{ .id = ecs.id(components.ExcavatorAction) };
    desc.query.filter.terms[4] = .{ .id = ecs.id(components.Direction) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.SpriteAnimator, 1)) |animators| {
                if (ecs.field(it, components.SpriteRenderer, 2)) |renderers| {
                    if (ecs.field(it, components.ExcavatorAction, 4)) |actions| {
                        if (ecs.field(it, components.Direction, 5)) |directions| {
                            if (animators[i].state == .play) {
                                animators[i].elapsed += it.delta_time;

                                const interval = 1.0 / @as(f32, @floatFromInt(animators[i].fps));

                                if (animators[i].elapsed > interval) {
                                    animators[i].elapsed = 0.0;

                                    if (animators[i].frame < animators[i].animation.len - 1) {
                                        animators[i].frame += 1;
                                        if (animators[i].frame == @divTrunc(animators[i].animation.len, 2)) {
                                            const target = switch (directions[i]) {
                                                .e, .se, .s => game.state.entities.ground_east,
                                                else => game.state.entities.ground_west,
                                            };

                                            switch (actions[i]) {
                                                .scoop => {
                                                    if (ecs.get_mut(it.world, target, components.Hitpoints)) |hitpoints| {
                                                        if (hitpoints.value > 0)
                                                            hitpoints.value -= 1;
                                                    }
                                                },
                                                .release => {
                                                    if (ecs.get_mut(it.world, target, components.Hitpoints)) |hitpoints| {
                                                        if (hitpoints.value < 4)
                                                            hitpoints.value += 1;
                                                    }
                                                },
                                            }
                                        }
                                    } else {
                                        animators[i].state = .pause;
                                        animators[i].frame = animators[i].animation.len - 1;
                                    }
                                }
                                renderers[i].index = animators[i].animation[animators[i].frame];
                            }
                        }
                    }
                }
            }
        }
    }
}
