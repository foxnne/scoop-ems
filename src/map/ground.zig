const ecs = @import("zflecs");
const game = @import("../scoop'ems.zig");

pub fn create() void {
    for (0..20) |index| {
        const i: f32 = @floatFromInt(index);
        const offset: f32 = (i - 10) * 32.0;
        const sprite_index: usize = if (@mod(index, 3) == 0) game.assets.scoopems_atlas.Ground_full_0_Layer_0 else game.assets.scoopems_atlas.Ground_full_1_Layer_0;

        const ground = ecs.new_id(game.state.world);
        _ = ecs.set(game.state.world, ground, game.components.Position, .{ .x = offset, .y = game.settings.ground_height });
        _ = ecs.set(game.state.world, ground, game.components.SpriteRenderer, .{
            .index = sprite_index,
        });
    }
}
