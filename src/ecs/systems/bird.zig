const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Position) };
    desc.query.filter.terms[1] = .{ .id = ecs.id(components.Direction) };
    desc.query.filter.terms[2] = .{ .id = ecs.id(components.SpriteRenderer) };
    desc.query.filter.terms[3] = .{ .id = ecs.id(components.Bird) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.Position, 1)) |positions| {
                if (ecs.field(it, components.Direction, 2)) |directions| {
                    if (ecs.field(it, components.SpriteRenderer, 3)) |renderers| {
                        if (ecs.field(it, components.Bird, 4)) |birds| {
                            if (birds[i].state == .idle_home) {
                                birds[i].elapsed += it.delta_time;

                                if (birds[i].elapsed >= birds[i].wait_home) {
                                    birds[i].state = .fly_tree;
                                    birds[i].elapsed = 0.0;
                                }
                            }

                            if (birds[i].state == .fly_tree or birds[i].state == .fly_home) {
                                if (birds[i].progress < 1.0) {
                                    birds[i].progress = std.math.clamp(birds[i].progress + it.delta_time * birds[i].speed, 0.0, 1.0);
                                } else {
                                    birds[i].progress = 0.0;
                                    birds[i].state = switch (birds[i].state) {
                                        .fly_tree => .idle_tree,
                                        .fly_home => .idle_home,
                                        else => .idle_home,
                                    };
                                }

                                const p1 = switch (birds[i].state) {
                                    .fly_home, .idle_tree => birds[i].tree,
                                    .fly_tree, .idle_home => birds[i].home,

                                    else => birds[i].tree,
                                };
                                const p2 = switch (birds[i].state) {
                                    .fly_home, .idle_tree => birds[i].home,
                                    .fly_tree, .idle_home => birds[i].tree,

                                    else => birds[i].home,
                                };

                                directions[i] = game.math.Direction.find(4, p2[0] - p1[0], 0.0);

                                renderers[i].flip_x = switch (directions[i]) {
                                    .e => true,
                                    else => false,
                                };

                                positions[i].x = game.math.ease(p1[0], p2[0], birds[i].progress, .ease_out);
                                positions[i].y = game.math.ease(p1[1], p2[1], birds[i].progress, .ease_out);

                                birds[i].elapsed += it.delta_time;
                                if (birds[i].elapsed > (1.0 / @as(f32, @floatFromInt(birds[i].fps)))) {
                                    birds[i].elapsed = 0.0;

                                    if (birds[i].frame < birds[i].animation.len - 1) {
                                        birds[i].frame += 1;
                                    } else birds[i].frame = 0;
                                }
                                renderers[i].index = birds[i].animation[birds[i].frame];
                            }

                            if (birds[i].state == .idle_tree) {
                                //birds[i].elapsed += it.delta_time

                                if (ecs.has_pair(it.world, game.state.entities.player, ecs.id(components.Scoop), ecs.id(components.Cooldown))) {
                                    birds[i].state = .fly_home;
                                    birds[i].progress = 0.0;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
