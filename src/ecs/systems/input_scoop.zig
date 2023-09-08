const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Player) };
    desc.query.filter.terms[1] = .{ .id = ecs.pair(ecs.id(components.Turn), ecs.id(components.Cooldown)), .oper = ecs.oper_kind_t.Not };
    desc.query.filter.terms[2] = .{ .id = ecs.pair(ecs.id(components.Scoop), ecs.id(components.Cooldown)), .oper = ecs.oper_kind_t.Not };
    desc.query.filter.terms[3] = .{ .id = ecs.id(components.SpriteAnimator) };
    desc.query.filter.terms[4] = .{ .id = ecs.id(components.ExcavatorState) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            const entity = it.entities()[i];
            if (ecs.field(it, components.SpriteAnimator, 4)) |animators| {
                if (ecs.field(it, components.ExcavatorState, 5)) |states| {
                    if (game.state.hotkeys.hotkey(.scoop)) |hk| {
                        if (hk.pressed()) {
                            if (states[i] == .empty) {
                                _ = ecs.set_pair(it.world, entity, ecs.id(components.Scoop), ecs.id(components.Cooldown), components.Cooldown, .{
                                    .end = 1.3,
                                });
                                animators[i].fps = 12;
                                animators[i].state = .play;
                                animators[i].frame = 0;
                                animators[i].animation = &game.animations.Excavator_scoop_Frame;
                                states[i] = .full;
                            } else {
                                _ = ecs.set_pair(it.world, entity, ecs.id(components.Scoop), ecs.id(components.Cooldown), components.Cooldown, .{
                                    .end = 1.0,
                                });
                                animators[i].fps = 8;
                                animators[i].state = .play;
                                animators[i].frame = 0;
                                animators[i].animation = &game.animations.Excavator_dump_Frame;
                                states[i] = .empty;
                            }
                        }
                    }
                }
            }
        }
    }
}
