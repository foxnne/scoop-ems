const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const components = game.components;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.pair(ecs.id(components.Target), ecs.id(components.Direction)) };
    desc.query.filter.terms[1] = .{ .id = ecs.pair(ecs.id(components.Turn), ecs.id(components.Cooldown)) };
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.Direction, 1)) |targets| {
                if (ecs.field(it, components.Cooldown, 2)) |cooldowns| {
                    const t = cooldowns[i].current / cooldowns[i].end;

                    const target_x = targets[i].x() * 32.0;
                    const current_x = game.state.camera.position[0];

                    game.state.camera.previous_position = game.state.camera.position;
                    game.state.camera.position[0] = game.math.ease(current_x, target_x, t, .ease_in);
                    game.state.camera.velocity = game.state.camera.position[0] - game.state.camera.previous_position[0];
                }
            }
        }
    }
}
