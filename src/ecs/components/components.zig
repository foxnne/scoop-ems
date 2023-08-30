const zmath = @import("zmath");
const game = @import("../../scoop'ems.zig");

pub const Visible = struct {};
pub const Player = struct {};

pub const Turn = struct {};
pub const Dig = struct {};
pub const Target = struct {};

pub const Direction = game.math.Direction;
pub const Rotation = struct { value: f32 = 0 };

pub const Cooldown = struct { current: f32 = 0.0, end: f32 = 1.0 };
pub const Parallax = struct { value: f32 = 0.0 }; // 1.0 means moves with camera

pub const Position = struct {
    x: f32 = 0.0,
    y: f32 = 0.0,
    z: f32 = 0.0,

    /// Returns the position as a vector.
    pub fn toF32x4(self: Position) zmath.F32x4 {
        return zmath.f32x4(self.x, self.y, self.z, 0.0);
    }
};

const sprites = @import("sprites.zig");
pub const SpriteRenderer = sprites.SpriteRenderer;
pub const SpriteAnimator = sprites.SpriteAnimator;
