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
    desc.query.filter.terms[3] = .{ .id = ecs.pair(ecs.id(components.Cooldown), ecs.id(components.Turn)) };
    desc.query.filter.terms[4] = .{ .id = ecs.id(components.ParticleRenderer) };
    desc.query.filter.terms[5] = .{ .id = ecs.id(components.ExcavatorState) };
    desc.query.filter.terms[6] = .{ .id = ecs.pair(ecs.id(components.Cooldown), ecs.id(components.Scoop)), .oper = ecs.oper_kind_t.Not };
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
                            if (ecs.field(it, components.ParticleRenderer, 5)) |particles| {
                                if (ecs.field(it, components.ExcavatorState, 6)) |states| {
                                    const t = cooldowns[i].current / cooldowns[i].end;

                                    const step = cooldowns[i].end / 4.0;

                                    if (cooldowns[i].end - cooldowns[i].current <= step + 0.1) continue;

                                    const target_x = targets[i].x();

                                    const x = game.math.ease(directions[i].x(), target_x, t, .linear);
                                    const y: f32 = if (t <= step or t >= cooldowns[i].end - step * 2.0) 0.0 else -1.0;

                                    directions[i] = game.math.Direction.find(8, x, y);

                                    switch (directions[i]) {
                                        .e => {
                                            renderers[i].index = if (states[i] == .empty) game.assets.scoopems_atlas.Excavator_rotate_empty_0_Frame else game.assets.scoopems_atlas.Excavator_rotate_full_0_Frame;
                                            renderers[i].flip_x = true;
                                            particles[i].offset = .{ -23.0, 46.0, 0, 0 };
                                        },
                                        .se => {
                                            renderers[i].index = if (states[i] == .empty) game.assets.scoopems_atlas.Excavator_rotate_empty_1_Frame else game.assets.scoopems_atlas.Excavator_rotate_full_1_Frame;
                                            renderers[i].flip_x = true;
                                            particles[i].offset = .{ -16.0, 46.0, 0, 0 };
                                        },
                                        .s => {
                                            renderers[i].index = if (states[i] == .empty) game.assets.scoopems_atlas.Excavator_rotate_empty_2_Frame else game.assets.scoopems_atlas.Excavator_rotate_full_2_Frame;
                                            renderers[i].flip_x = false;
                                            particles[i].offset = .{ 8.0, 46.0, 0, 0 };
                                        },
                                        .sw => {
                                            renderers[i].index = if (states[i] == .empty) game.assets.scoopems_atlas.Excavator_rotate_empty_1_Frame else game.assets.scoopems_atlas.Excavator_rotate_full_1_Frame;
                                            renderers[i].flip_x = false;
                                            particles[i].offset = .{ 16.0, 46.0, 0, 0 };
                                        },
                                        .w => {
                                            renderers[i].index = if (states[i] == .empty) game.assets.scoopems_atlas.Excavator_rotate_empty_0_Frame else game.assets.scoopems_atlas.Excavator_rotate_full_0_Frame;
                                            renderers[i].flip_x = false;
                                            particles[i].offset = .{ 23.0, 46.0, 0, 0 };
                                        },
                                        else => {},
                                    }

                                    if (ecs.get_mut(it.world, game.state.entities.character, components.SpriteRenderer)) |renderer| {
                                        renderer.flip_x = renderers[i].flip_x;
                                        renderer.index = switch (renderers[i].index) {
                                            game.assets.scoopems_atlas.Excavator_rotate_empty_0_Frame => game.assets.scoopems_atlas.Excavator_rotate_empty_0_Arlynn,
                                            game.assets.scoopems_atlas.Excavator_rotate_empty_1_Frame => game.assets.scoopems_atlas.Excavator_rotate_empty_1_Arlynn,
                                            game.assets.scoopems_atlas.Excavator_rotate_empty_2_Frame => game.assets.scoopems_atlas.Excavator_rotate_empty_2_Arlynn,
                                            game.assets.scoopems_atlas.Excavator_rotate_full_0_Frame => game.assets.scoopems_atlas.Excavator_rotate_full_0_Arlynn,
                                            game.assets.scoopems_atlas.Excavator_rotate_full_1_Frame => game.assets.scoopems_atlas.Excavator_rotate_full_1_Arlynn,
                                            game.assets.scoopems_atlas.Excavator_rotate_full_2_Frame => game.assets.scoopems_atlas.Excavator_rotate_full_2_Arlynn,
                                            else => game.assets.scoopems_atlas.Excavator_rotate_empty_0_Arlynn,
                                        };
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
