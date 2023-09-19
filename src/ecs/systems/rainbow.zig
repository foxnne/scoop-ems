const std = @import("std");
const zm = @import("zmath");
const game = @import("../../scoop'ems.zig");
const components = game.components;
const ecs = @import("zflecs");

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Rainbow) };
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
            if (ecs.field(it, components.Rainbow, 1)) |rainbows| {
                if (ecs.field(it, components.SpriteRenderer, 2)) |renderers| {
                    if (ecs.field(it, components.Direction, 3)) |directions| {
                        if (ecs.get_pair(it.world, game.state.entities.player, ecs.id(components.Trigger), ecs.id(components.Rainbow), components.Trigger)) |trigger| {
                            const animators = ecs.field(it, components.ParticleAnimator, 4);
                            if (trigger.direction == directions[i]) {
                                if (rainbows[i].elapsed < rainbows[i].end) {
                                    if (rainbows[i].progress < 1.0) {
                                        if (animators) |anims| {
                                            anims[i].state = .play;
                                        }
                                        rainbows[i].progress += if (rainbows[i].state == .foreground) it.delta_time * 2.0 else it.delta_time * 0.5;
                                        renderers[i].scale[1] = game.math.ease(0.0, rainbows[i].target_scale, rainbows[i].progress, .ease_in);
                                    } else {
                                        rainbows[i].progress = 1.0;
                                        renderers[i].scale[1] = rainbows[i].target_scale;
                                    }
                                } else {
                                    if (rainbows[i].progress > it.delta_time) {
                                        rainbows[i].progress -= it.delta_time;
                                        renderers[i].color[3] = rainbows[i].progress * 0.7;
                                    } else {
                                        rainbows[i].progress = 0;
                                        renderers[i].scale[1] = 0.0;
                                        renderers[i].color[3] = 0.7;
                                        rainbows[i].elapsed = 0.0;
                                        if (animators) |anims| {
                                            anims[i].state = .pause;
                                        }
                                        ecs.remove_pair(it.world, game.state.entities.player, ecs.id(components.Trigger), ecs.id(components.Rainbow));
                                    }
                                }

                                rainbows[i].elapsed += it.delta_time;
                                game.state.sounds.play_sparkes = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
