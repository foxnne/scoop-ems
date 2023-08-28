const ecs = @import("zflecs");
const game = @import("../scoop'ems.zig");
const math = game.math;

pub fn create() void {
    const count = 24;
    for (0..count + 1) |index| {
        const i: f32 = @floatFromInt(index);
        const offset: f32 = (i - @divExact(count, 2)) * 32.0;
        var sprite_index: usize = if (@mod(index, 2) == 0) game.assets.scoopems_atlas.Ground_full_0_Layer_0 else game.assets.scoopems_atlas.Ground_full_1_Layer_0;

        if (offset == 64.0 or offset == -64.0) sprite_index = game.assets.scoopems_atlas.Ground_dig_0_Layer_0;

        const ground = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, ground, game.components.Position, .{ .x = offset, .y = game.settings.ground_height });
        _ = ecs.set(game.state.world, ground, game.components.SpriteRenderer, .{
            .index = sprite_index,
            .flip_x = if (@mod(index, 4) == 0) true else false,
        });

        if (offset != 64.0 and offset != -64.0) {
            const grass_count = 6;
            for (0..grass_count) |grass_ind| {
                const grass_i: f32 = @floatFromInt(grass_ind);
                const grass_offset = (grass_i - @divExact(grass_count, 2)) * 8.0;

                const final_offset = offset + grass_offset;

                const grass_sprite_index = game.animations.Grass_Layer_0[grass_ind];

                const grass = ecs.new_id(game.state.world);
                _ = ecs.set(game.state.world, grass, game.components.Position, .{ .x = final_offset, .y = game.settings.ground_height, .z = 20.0 });
                _ = ecs.set(game.state.world, grass, game.components.SpriteRenderer, .{
                    .index = grass_sprite_index,
                    .flip_x = if (@mod(grass_i, 2) == 0) true else false,
                    .vert_mode = .top_sway,
                });
            }
        }
    }

    const distance_color = math.Color.initBytes(3, 0, 0, 255).toSlice();

    const distance_0 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_0, game.components.Position, .{ .x = 45.0, .y = game.settings.ground_height, .z = 200.0 });
    _ = ecs.set(game.state.world, distance_0, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.distance_0_0_Layer_0,
        .frag_mode = .palette,
        .flip_x = false,
        .color = distance_color,
    });

    const tree_x: f32 = 100.0;

    const distance_tree_trunk = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_tree_trunk, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height - 10, .z = 199.0 });
    _ = ecs.set(game.state.world, distance_tree_trunk, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.Pine_0_Trunk,
        .frag_mode = .palette,
        .vert_mode = .top_sway,
        .flip_x = false,
        .color = distance_color,
    });

    const distance_tree_needles = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_tree_needles, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height - 10, .z = 199.0 });
    _ = ecs.set(game.state.world, distance_tree_needles, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.Pine_0_Needles,
        .frag_mode = .palette,
        .vert_mode = .top_sway,
        .flip_x = false,
        .color = distance_color,
    });

    const distance_tree_trunk_2 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_tree_trunk_2, game.components.Position, .{ .x = -tree_x, .y = game.settings.ground_height - 10, .z = 199.0 });
    _ = ecs.set(game.state.world, distance_tree_trunk_2, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.Pine_0_Trunk,
        .frag_mode = .palette,
        .vert_mode = .top_sway,
        .flip_x = false,
        .color = distance_color,
    });

    const distance_tree_needles_2 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_tree_needles_2, game.components.Position, .{ .x = -tree_x, .y = game.settings.ground_height - 10, .z = 199.0 });
    _ = ecs.set(game.state.world, distance_tree_needles_2, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.Pine_0_Needles,
        .frag_mode = .palette,
        .vert_mode = .top_sway,
        .flip_x = false,
        .color = distance_color,
    });

    const distance_tree_trunk_3 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_tree_trunk_3, game.components.Position, .{ .x = -tree_x * 2.0, .y = game.settings.ground_height - 10, .z = 199.0 });
    _ = ecs.set(game.state.world, distance_tree_trunk_3, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.Pine_0_Trunk,
        .frag_mode = .palette,
        .vert_mode = .top_sway,
        .flip_x = true,
        .color = distance_color,
    });

    const distance_tree_needles_3 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_tree_needles_3, game.components.Position, .{ .x = -tree_x * 2.0, .y = game.settings.ground_height - 10, .z = 199.0 });
    _ = ecs.set(game.state.world, distance_tree_needles_3, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.Pine_0_Needles,
        .frag_mode = .palette,
        .vert_mode = .top_sway,
        .flip_x = true,
        .color = distance_color,
    });

    const distance_1 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_1, game.components.Position, .{ .x = 45.0, .y = game.settings.ground_height + 2.0, .z = 300.0 });
    _ = ecs.set(game.state.world, distance_1, game.components.SpriteRenderer, .{
        .frag_mode = .palette,
        .index = game.assets.scoopems_atlas.distance_1_0_Layer_0,
        .flip_x = false,
        .color = distance_color,
    });

    const distance_2 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_2, game.components.Position, .{ .x = -45.0, .y = game.settings.ground_height - 10.0, .z = 400.0 });
    _ = ecs.set(game.state.world, distance_2, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.distance_2_0_Layer_0,
        .frag_mode = .palette,
        .flip_x = false,
        .color = distance_color,
    });

    const distance_3 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_3, game.components.Position, .{ .x = -45.0, .y = game.settings.ground_height + 15.0, .z = 500.0 });
    _ = ecs.set(game.state.world, distance_3, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.distance_3_0_Layer_0,
        .frag_mode = .palette,
        .flip_x = false,
        .color = distance_color,
    });
}
