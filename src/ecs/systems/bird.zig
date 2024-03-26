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
                                    const x: u64 = @intFromFloat(it.delta_time * 10000000);
                                    var r = std.rand.DefaultPrng.init(x);
                                    const random = r.random();
                                    const state = random.enumValue(components.Bird.State);
                                    if (state.fromHome()) {
                                        birds[i].elapsed = 0.0;
                                        birds[i].state = state;

                                        var color: u8 = @intFromFloat(renderers[i].color[0] * 255.0);
                                        if (color < 19) {
                                            color += 1;
                                        } else {
                                            color = 17;
                                        }

                                        const color_full = game.math.Color.initBytes(color, 0, 0, 1);
                                        renderers[i].color = color_full.toSlice();
                                    }
                                }
                            }

                            if (birds[i].state.fly()) {
                                birds[i].animation = &game.animations.Redbird_flap_Layer_0;
                                if (birds[i].progress < 1.0) {
                                    birds[i].progress = std.math.clamp(birds[i].progress + it.delta_time * birds[i].speed, 0.0, 1.0);
                                } else {
                                    birds[i].progress = 0.0;
                                    birds[i].state = switch (birds[i].state) {
                                        .fly_tree_from_home, .fly_tree_from_ground, .fly_tree_from_sky => .idle_tree,
                                        .fly_home_from_tree, .fly_home_from_ground, .fly_home_from_sky => .idle_home,
                                        .fly_ground_from_tree, .fly_ground_from_sky, .fly_ground_from_home => .idle_ground,
                                        else => .idle_home,
                                    };
                                    continue;
                                }

                                const p1 = switch (birds[i].state) {
                                    .fly_sky_from_ground, .fly_tree_from_ground, .fly_home_from_ground => birds[i].ground,
                                    .fly_home_from_tree, .fly_sky_from_tree, .fly_ground_from_tree => birds[i].tree,
                                    .fly_sky_from_home, .fly_ground_from_home, .fly_tree_from_home => birds[i].home,
                                    .fly_home_from_sky, .fly_ground_from_sky, .fly_tree_from_sky => birds[i].sky,
                                    else => birds[i].tree,
                                };
                                const p2 = switch (birds[i].state) {
                                    .fly_sky_from_tree, .fly_sky_from_ground, .fly_sky_from_home => birds[i].sky,
                                    .fly_home_from_tree, .fly_home_from_ground, .fly_home_from_sky => birds[i].home,
                                    .fly_ground_from_tree, .fly_ground_from_home, .fly_ground_from_sky => birds[i].ground,
                                    .fly_tree_from_home, .fly_tree_from_ground, .fly_tree_from_sky => birds[i].tree,
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

                            if (birds[i].state.idle() and birds[i].state != .idle_home) {
                                if (ecs.has_pair(it.world, game.state.entities.player, ecs.id(components.Scoop), ecs.id(components.Cooldown))) {
                                    birds[i].state = switch (birds[i].state) {
                                        .idle_home => .idle_home,
                                        .idle_ground => .fly_home_from_ground,
                                        .idle_tree => .fly_home_from_tree,
                                        .idle_sky => .fly_home_from_sky,
                                        else => .idle_home,
                                    };
                                    birds[i].progress = 0.0;
                                }

                                if (birds[i].animation.len > 1) {
                                    birds[i].elapsed += it.delta_time;
                                    if (birds[i].elapsed > (1.0 / @as(f32, @floatFromInt(birds[i].fps)))) {
                                        birds[i].elapsed = 0.0;

                                        if (birds[i].frame < birds[i].animation.len - 1) {
                                            birds[i].frame += 1;
                                        } else {
                                            birds[i].animation = &game.animations.Redbird_idle_Layer_0;
                                            birds[i].frame = 0;
                                        }
                                    }
                                    renderers[i].index = birds[i].animation[birds[i].frame];
                                } else {
                                    birds[i].wait += it.delta_time;

                                    if (birds[i].wait > birds[i].wait_action) {
                                        birds[i].wait = 0.0;
                                        birds[i].animation = &game.animations.Redbird_peck_Layer_0;
                                        renderers[i].flip_x = !renderers[i].flip_x;
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
