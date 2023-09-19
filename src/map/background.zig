const ecs = @import("zflecs");
const game = @import("../scoop'ems.zig");
const math = game.math;

pub fn create() void {
    const count = 36;
    for (0..count + 1) |index| {
        const i: f32 = @floatFromInt(index);
        const offset: f32 = (i - @divExact(count, 2)) * 32.0;
        var sprite_index: usize = if (@mod(index, 2) == 0) game.assets.scoopems_atlas.Ground_full_0_Layer_0 else game.assets.scoopems_atlas.Ground_full_1_Layer_0;

        const ground = ecs.new_id(game.state.world);

        if (offset == 64.0 or offset == -64.0) {
            if (offset > 0) game.state.entities.ground_east = ground else game.state.entities.ground_west = ground;

            sprite_index = game.assets.scoopems_atlas.Ground_dig_4_Layer_0;
            const direction = math.Direction.find(4, offset, 0.0);
            _ = ecs.set(game.state.world, ground, game.components.Direction, direction);
            _ = ecs.set(game.state.world, ground, game.components.Hitpoints, .{ .value = 4 });

            const rainbow_foreground = ecs.new_id(game.state.world);
            _ = ecs.set(game.state.world, rainbow_foreground, game.components.Position, .{ .x = offset, .y = game.settings.ground_height - 26.0 });
            _ = ecs.set(game.state.world, rainbow_foreground, game.components.SpriteRenderer, .{
                .index = game.assets.scoopems_atlas.Rainbow_0_Layer_0,
                .scale = .{ 1.0, 0.0 },
                .color = game.math.Color.initBytes(255, 255, 255, 200).toSlice(),
            });
            _ = ecs.set(game.state.world, rainbow_foreground, game.components.Rainbow, .{});
            _ = ecs.set(game.state.world, rainbow_foreground, game.components.Direction, direction);
            _ = ecs.set(game.state.world, rainbow_foreground, game.components.ParticleRenderer, .{
                .particles = game.state.allocator.alloc(game.components.ParticleRenderer.Particle, 100) catch unreachable,
                .offset = .{ 0.0, 16.0, 0.0, 0.0 },
            });
            _ = ecs.set(game.state.world, rainbow_foreground, game.components.ParticleAnimator, .{
                .animation = &game.animations.Star_Layer,
                .rate = 10.0,
                .start_life = 0.5,
                .velocity_min = .{ -30.0, 40.5 },
                .velocity_max = .{ 30.0, 80.5 },
                .state = .pause,
            });

            const rainbow_background = ecs.new_id(game.state.world);
            _ = ecs.set(game.state.world, rainbow_background, game.components.Position, .{ .x = offset - (offset * 2.0), .y = 300.0, .z = 700.0 });
            _ = ecs.set(game.state.world, rainbow_background, game.components.SpriteRenderer, .{
                .index = game.assets.scoopems_atlas.Rainbow_0_Layer_0,
                .scale = .{ 0.5, 0.0 },
                .color = game.math.Color.initBytes(255, 255, 255, 200).toSlice(),
                .flip_x = true,
            });
            _ = ecs.set(game.state.world, rainbow_background, game.components.Rainbow, .{ .target_scale = -10.0, .state = .background });
            _ = ecs.set(game.state.world, rainbow_background, game.components.Parallax, .{ .value = 1.0 });
            _ = ecs.set(game.state.world, rainbow_background, game.components.Direction, direction);
        }

        _ = ecs.set(game.state.world, ground, game.components.Position, .{ .x = offset, .y = game.settings.ground_height });
        _ = ecs.set(game.state.world, ground, game.components.SpriteRenderer, .{
            .index = sprite_index,
            .flip_x = if (@mod(index, 4) == 0) true else false,
        });

        if (offset != 64.0 and offset != -64.0) {
            const grass_count = 6;
            for (0..grass_count) |grass_ind| {
                const grass_i: f32 = @floatFromInt(grass_ind);
                const grass_offset = (grass_i - @divExact(grass_count, 2)) * 4.0;

                const final_offset = offset + grass_offset;

                const grass_sprite_index = game.animations.Grass_Layer_0[grass_ind];

                const back: f32 = if (@mod(grass_i, 2) == 0) 20.0 else -20.0;

                const grass = ecs.new_id(game.state.world);
                _ = ecs.set(game.state.world, grass, game.components.Position, .{ .x = final_offset, .y = game.settings.ground_height, .z = back });
                _ = ecs.set(game.state.world, grass, game.components.SpriteRenderer, .{
                    .index = grass_sprite_index,
                    .flip_x = if (@mod(grass_i, 2) == 0) true else false,
                    .vert_mode = .top_sway,
                });
            }
        }
    }

    const distance_color = math.Color.initBytes(3, 0, 0, 255).toSlice();

    for (0..9) |i| {
        const tree_x: f32 = switch (i) {
            0 => -430.0,
            1 => -350.0,
            2 => -220.0,
            3 => -160.0,
            4 => 110.0,
            5 => 170.0,
            6 => 300.0,
            7 => 350.0,
            8 => 450.0,
            else => 0.0,
        };

        const bird_spawn: bool = switch (i) {
            0 => true,
            1 => false,
            2 => false,
            3 => true,
            4 => true,
            5 => true,
            6 => false,
            7 => true,
            8 => true,
            else => false,
        };

        if (bird_spawn) {
            const bird_y: f32 = switch (i) {
                0 => 42.0,
                1 => 29.0,
                2 => 37.0,
                3 => 51.0,
                4 => 31.0,
                5 => 47.0,
                6 => 54.0,
                7 => 39.0,
                8 => 32.0,
                else => 0.0,
            };

            const bird_color: u8 = switch (i) {
                0 => 17,
                1 => 18,
                2 => 19,
                3 => 17,
                4 => 18,
                5 => 19,
                6 => 17,
                7 => 18,
                8 => 19,
                else => 17,
            };
            const color = game.math.Color.initBytes(bird_color, 0, 0, 1);
            const bird = ecs.new_id(game.state.world);
            _ = ecs.set(game.state.world, bird, game.components.Position, .{ .x = tree_x * 3.0, .y = 400.0 - @fabs(tree_x), .z = -100 });
            _ = ecs.set(game.state.world, bird, game.components.Bird, .{
                .home = .{ tree_x * 2.0, 244.0, 0.0 },
                .sky = .{ -tree_x * 2.0, 228.0, 0.0 },
                .tree = .{ tree_x + (tree_x / 14.0), bird_y, 0.0 },
                .ground = .{ tree_x + (tree_x / 14.0), game.settings.ground_height + 2.0, 0.0 },
                .wait_home = @fabs(tree_x) / 20.0,
            });
            _ = ecs.set(game.state.world, bird, game.components.Direction, .e);
            _ = ecs.set(game.state.world, bird, game.components.SpriteRenderer, .{
                .index = game.assets.scoopems_atlas.Redbird_idle_0_Layer_0,
                .frag_mode = .palette,
                .color = color.toSlice(),
            });
        }

        const tree_color = game.math.Color.initBytes(switch (i) {
            0, 2, 4, 6, 7 => 6,
            1, 3, 5 => 7,
            else => 6,
        }, 0, 0, 1).toSlice();

        const tree_trunk_0 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_trunk_0, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height + 4.0, .z = 210.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_trunk_0, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Trunk,
            .flip_x = false,
        });

        const tree_leaves_0_0 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_0, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height + 4.0, .z = 196.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_0, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves01,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
            .order = 0,
        });

        const tree_leaves_0_1 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_1, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height + 4.0, .z = 197.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_1, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves02,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
            .order = 1,
        });

        const tree_leaves_0_2 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_2, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height + 4.0, .z = 198.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_2, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves03,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
            .order = 2,
        });

        const tree_leaves_0_3 = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, tree_leaves_0_3, game.components.Position, .{ .x = tree_x, .y = game.settings.ground_height + 4.0, .z = 199.0 + @as(f32, @floatFromInt(i)) * 5.0 });
        _ = ecs.set(game.state.world, tree_leaves_0_3, game.components.SpriteRenderer, .{
            .index = game.assets.scoopems_atlas.Oak_0_Leaves04,
            .vert_mode = .top_sway,
            .color = tree_color,
            .frag_mode = .palette,
            .flip_x = false,
            .order = 3,
        });
    }

    const distance_1 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_1, game.components.Position, .{ .x = -25.0, .y = game.settings.ground_height - 12.0, .z = 300.0 });
    _ = ecs.set(game.state.world, distance_1, game.components.SpriteRenderer, .{
        .frag_mode = .palette,
        .index = game.assets.scoopems_atlas.distance_1_0_Layer_0,
        .flip_x = false,
        .color = distance_color,
    });
    _ = ecs.set(game.state.world, distance_1, game.components.Parallax, .{ .value = 0.25 });

    const distance_2 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_2, game.components.Position, .{ .x = -25.0, .y = game.settings.ground_height - 10.0, .z = 400.0 });
    _ = ecs.set(game.state.world, distance_2, game.components.SpriteRenderer, .{
        .index = game.assets.scoopems_atlas.distance_2_0_Layer_0,
        .frag_mode = .palette,
        .flip_x = false,
        .color = distance_color,
    });
    _ = ecs.set(game.state.world, distance_2, game.components.Parallax, .{ .value = 0.50 });

    const distance_3 = ecs.new_id(game.state.world);
    _ = ecs.set(game.state.world, distance_3, game.components.Position, .{ .x = -25.0, .y = game.settings.ground_height + 5.0, .z = 500.0 });
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
        //.vert_mode = .top_sway,
        .color = .{ 1.0, 1.0, 1.0, 1.0 },
    });
    _ = ecs.set(game.state.world, clouds_static, game.components.Parallax, .{ .value = 1.0 });
}
