const ecs = @import("zflecs");
const game = @import("../scoop'ems.zig");

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
}
