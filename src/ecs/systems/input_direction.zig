const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Direction) };
    desc.query.filter.terms[1] = .{ .id = ecs.pair(ecs.id(components.Target), ecs.id(components.Direction)) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.Direction, 1)) |current_directions| {
                _ = current_directions;
                if (ecs.field(it, components.Direction, 2)) |target_directions| {
                    const entity = it.entities()[i];
                    if (game.state.hotkeys.hotkey(.turn_left)) |hk| {
                        if (hk.pressed()) {
                            target_directions[i] = .w;
                            _ = ecs.set_pair(it.world, entity, ecs.id(components.Turn), ecs.id(components.Cooldown), components.Cooldown, .{});
                        }
                    }

                    if (game.state.hotkeys.hotkey(.turn_right)) |hk| {
                        if (hk.pressed()) {
                            target_directions[i] = .e;
                            _ = ecs.set_pair(it.world, entity, ecs.id(components.Turn), ecs.id(components.Cooldown), components.Cooldown, .{});
                        }
                    }
                }
            }
        }
    }
}
