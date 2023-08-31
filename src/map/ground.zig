const ecs = @import("zflecs");
const game = @import("../scoop'ems.zig");
const math = game.math;

pub fn create() void {
    const count = 36;
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

    for (0..7) |i| {
        const tree_x: f32 = switch (i) {
            0 => -360.0,
            1 => -240.0,
            2 => -180.0,
            3 => 100.0,
            4 => 160.0,
            5 => 290.0,
            6 => 340.0,
            else => 0.0,
        };

        const tree_color = game.math.Color.initBytes(switch (i) {
            0, 2, 4, 6 => 6,
            1, 3, 5 => 7,
            else => 6,
        }, 0, 0, 1).toSlice();

        const tree_trunk_0 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_trunk_0, game.components.Position, .{ .x = tree_x + 10.0, .y = game.settings.ground_height + 4.0, .z = 210.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_trunk_0, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Trunk,
            .flip_x = false,
        });

        const tree_leaves_0_0 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_0, game.components.Position, .{ .x = tree_x + 10.0, .y = game.settings.ground_height + 4.0, .z = 196.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_0, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves01,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
        });

        const tree_leaves_0_1 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_1, game.components.Position, .{ .x = tree_x + 10.0, .y = game.settings.ground_height + 4.0, .z = 197.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_1, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves02,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
        });

        const tree_leaves_0_2 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_2, game.components.Position, .{ .x = tree_x + 10.0, .y = game.settings.ground_height + 4.0, .z = 198.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_2, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves03,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
        });

        const tree_leaves_0_3 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_3, game.components.Position, .{ .x = tree_x + 10.0, .y = game.settings.ground_height + 4.0, .z = 199.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_3, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves04,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
        });
    }

    const distance_1 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_1, game.components.Position, .{ .x = -45.0, .y = game.settings.ground_height - 10.0, .z = 300.0 });
    _ = ecs.set(game.state.world, distance_1, game.components.SpriteRenderer, .{
        .frag_mode = .palette,
        .index = game.assets.scoopems_atlas.distance_1_0_Layer_0,
        .flip_x = false,
        .color = distance_color,
    });
    _ = ecs.set(game.state.world, distance_1, game.components.Parallax, .{ .value = 0.25 });

    const distance_2 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_2, game.components.Position, .{ .x = -45.0, .y = game.settings.ground_height - 10.0, .z = 400.0 });
    _ = ecs.set(game.state.world, distance_2, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.distance_2_0_Layer_0,
        .frag_mode = .palette,
        .flip_x = false,
        .color = distance_color,
    });
    _ = ecs.set(game.state.world, distance_2, game.components.Parallax, .{ .value = 0.50 });

    const distance_3 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_3, game.components.Position, .{ .x = -45.0, .y = game.settings.ground_height + 5.0, .z = 500.0 });
    _ = ecs.set(game.state.world, distance_3, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.distance_3_0_Layer_0,
        .frag_mode = .palette,
        .flip_x = false,
        .color = distance_color,
    });
    _ = ecs.set(game.state.world, distance_3, game.components.Parallax, .{ .value = 0.75 });

    const clouds_static = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, clouds_static, game.components.Position, .{ .x = -140.0, .y = game.settings.ground_height + 10.0, .z = 600.0 });
    _ = ecs.set(game.state.world, clouds_static, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.clouds_0_Layer_0,
        .flip_x = false,
        .vert_mode = .top_sway,
        .color = .{ 1.0, 1.0, 1.0, 1.0 },
    });
    _ = ecs.set(game.state.world, clouds_static, game.components.Parallax, .{ .value = 1.0 });
}
