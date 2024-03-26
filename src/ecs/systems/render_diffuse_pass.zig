const std = @import("std");
const zm = @import("zmath");
const ecs = @import("zflecs");
const game = @import("../../scoop'ems.zig");
const gfx = game.gfx;
const math = game.math;
const components = game.components;

const mach = @import("mach");
const core = mach.core;

pub fn system() ecs.system_desc_t {
    var desc: ecs.system_desc_t = .{};
    desc.query.filter.terms[0] = .{ .id = ecs.id(components.Position) };
    desc.query.filter.terms[1] = .{ .id = ecs.id(components.Rotation), .oper = ecs.oper_kind_t.Optional };
    desc.query.filter.terms[2] = .{ .id = ecs.id(components.SpriteRenderer), .oper = ecs.oper_kind_t.Optional };
    desc.query.filter.terms[3] = .{ .id = ecs.id(components.ParticleRenderer), .oper = ecs.oper_kind_t.Optional };
    desc.query.order_by_component = ecs.id(components.Position);
    desc.query.order_by = orderBy;
    desc.run = run;
    return desc;
}

pub fn run(it: *ecs.iter_t) callconv(.C) void {
    const uniforms = gfx.UniformBufferObject{ .mvp = zm.transpose(game.state.camera.renderTextureMatrix()) };

    const background: core.gpu.Color = .{
        .r = 0.0,
        .g = 0.8,
        .b = 1.0,
        .a = 0.0,
    };

    // Draw diffuse texture sprites using diffuse pipeline
    game.state.batcher.begin(.{
        .pipeline_handle = game.state.pipeline_diffuse,
        .bind_group_handle = game.state.bind_group_diffuse,
        .output_handle = game.state.output_diffuse.view_handle,
        .clear_color = background,
    }) catch unreachable;

    while (ecs.query_next(it)) {
        var i: usize = 0;
        while (i < it.count()) : (i += 1) {
            if (ecs.field(it, components.Position, 1)) |positions| {
                const rotation = if (ecs.field(it, components.Rotation, 2)) |rotations| rotations[i].value else 0.0;
                const position = positions[i].toF32x4();

                if (ecs.field(it, components.SpriteRenderer, 3)) |renderers| {
                    game.state.batcher.sprite(
                        position,
                        &game.state.diffusemap,
                        game.state.atlas.sprites[renderers[i].index],
                        .{
                            .color = renderers[i].color,
                            .vert_mode = renderers[i].vert_mode,
                            .frag_mode = renderers[i].frag_mode,
                            .time = game.state.time + @as(f32, @floatFromInt(renderers[i].order)) + position[0],
                            .flip_x = renderers[i].flip_x,
                            .flip_y = renderers[i].flip_y,
                            .scale = renderers[i].scale,
                            .rotation = rotation,
                        },
                    ) catch unreachable;
                }

                if (ecs.field(it, components.ParticleRenderer, 4)) |renderers| {
                    for (renderers[i].particles) |particle| {
                        if (particle.alive()) {
                            game.state.batcher.sprite(
                                zm.f32x4(particle.position[0], particle.position[1], particle.position[2], 0),
                                &game.state.diffusemap,
                                game.state.atlas.sprites[particle.index],
                                .{
                                    .frag_mode = renderers[i].frag_mode,
                                    .color = particle.color,
                                },
                            ) catch unreachable;
                        }
                    }
                }
            }
        }
    }

    game.state.batcher.end(uniforms, game.state.uniform_buffer_diffuse) catch unreachable;
}

fn orderBy(_: ecs.entity_t, c1: ?*const anyopaque, _: ecs.entity_t, c2: ?*const anyopaque) callconv(.C) c_int {
    const position_1 = ecs.cast(components.Position, c1);
    const position_2 = ecs.cast(components.Position, c2);
    return @as(c_int, @intCast(@intFromBool(position_1.z < position_2.z))) - @as(c_int, @intCast(@intFromBool(position_1.z > position_2.z)));
}
