const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Direction) };
    desc.query.filter.terms[1] = .{ .id = ecs.id(components.SpriteRenderer) };
    desc.query.filter.terms[2] = .{ .id = ecs.pair(ecs.id(components.Target), ecs.id(components.Direction)) };
    desc.query.filter.terms[3] = .{ .id = ecs.pair(ecs.id(components.Turn), ecs.id(components.Cooldown)) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.Direction, 1)) |directions| {
                if (ecs.field(it, components.SpriteRenderer, 2)) |renderers| {
                    if (ecs.field(it, components.Direction, 3)) |targets| {
                        if (ecs.field(it, components.Cooldown, 4)) |cooldowns| {
                            const t = cooldowns[i].current / cooldowns[i].end;

                            const step = cooldowns[i].end / 4.0;

                            const target_x = targets[i].x();

                            const x = game.math.ease(directions[i].x(), target_x, t, .linear);
                            const y: f32 = if (t <= step or t >= cooldowns[i].end - step * 2.0) 0.0 else -1.0;

                            directions[i] = game.math.Direction.find(8, x, y);

                            switch (directions[i]) {
                                .e => {
                                    renderers[i].index = game.assets.scoopems_atlas.Excavator_rotate_empty_0_Frame;
                                    renderers[i].flip_x = true;
                                },
                                .se => {
                                    renderers[i].index = game.assets.scoopems_atlas.Excavator_rotate_empty_1_Frame;
                                    renderers[i].flip_x = true;
                                },
                                .s => {
                                    renderers[i].index = game.assets.scoopems_atlas.Excavator_rotate_empty_2_Frame;
                                    renderers[i].flip_x = false;
                                },
                                .sw => {
                                    renderers[i].index = game.assets.scoopems_atlas.Excavator_rotate_empty_1_Frame;
                                    renderers[i].flip_x = false;
                                },
                                .w => {
                                    renderers[i].index = game.assets.scoopems_atlas.Excavator_rotate_empty_0_Frame;
                                    renderers[i].flip_x = false;
                                },
                                else => {},
                            }
                        }
                    }
                }
            }
        }
    }
}