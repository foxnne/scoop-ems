const zmath = @import("zmath");
const game = @import("../../scoop'ems.zig");

pub const Visible = struct {};
pub const Player = struct {};

pub const Turn = struct {};
pub const Scoop = struct {};
pub const Target = struct {};
pub const Event = struct {};

pub const Trigger = struct { direction: game.math.Direction };
pub const Direction = game.math.Direction;
pub const Rotation = struct { value: f32 = 0 };

pub const Cooldown = struct { current: f32 = 0.0, end: f32 = 1.0 };
pub const Parallax = struct { value: f32 = 0.0 }; // 1.0 means moves with camera

pub const Hitpoints = struct { value: usize = 0 };

pub const ExcavatorState = enum {
    empty,
    full,
};

pub const ExcavatorAction = enum {
    scoop,
    release,
};

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

const particles = @import("particles.zig");
pub const ParticleRenderer = particles.ParticleRenderer;
pub const ParticleAnimator = particles.ParticleAnimator;

pub const Rainbow = struct {
    elapsed: f32 = 0.0,
    end: f32 = 10.0,
    progress: f32 = 0.0,
    target_scale: f32 = 10.0,
    state: State = .foreground,

    pub const State = enum {
        foreground,
        background,
    };
};

pub const Bird = struct {
    speed: f32 = 0.3,
    home: [3]f32 = .{ 0.0, 0.0, 0.0 },
    tree: [3]f32 = .{ 0.0, 0.0, 0.0 },
    sky: [3]f32 = .{ 0.0, 0.0, 0.0 },
    ground: [3]f32 = .{ 0.0, 0.0, 0.0 },
    state: State = .idle_home,
    wait_tree: f32 = 30.0,
    wait_home: f32 = 10.0,
    wait_action: f32 = 1.2,
    wait: f32 = 0.0,
    peck_chance: f32 = 0.4,
    peck_duration: f32 = 0.5,
    progress: f32 = 0.0,
    elapsed: f32 = 0.0,
    frame: usize = 0,
    animation: []usize = &game.animations.Redbird_flap_Layer_0,
    fps: usize = 12.0,

    pub const State = enum {
        fly_sky_from_tree,
        fly_sky_from_ground,
        fly_sky_from_home,
        fly_home_from_tree,
        fly_home_from_ground,
        fly_home_from_sky,
        fly_ground_from_tree,
        fly_ground_from_home,
        fly_ground_from_sky,
        fly_tree_from_home,
        fly_tree_from_ground,
        fly_tree_from_sky,
        idle_home,
        idle_ground,
        idle_tree,
        idle_sky,

        pub fn fly(self: State) bool {
            return switch (self) {
                .fly_sky_from_tree,
                .fly_sky_from_ground,
                .fly_sky_from_home,
                .fly_home_from_tree,
                .fly_home_from_ground,
                .fly_home_from_sky,
                .fly_ground_from_tree,
                .fly_ground_from_home,
                .fly_ground_from_sky,
                .fly_tree_from_home,
                .fly_tree_from_ground,
                .fly_tree_from_sky,
                => true,
                else => false,
            };
        }

        pub fn idle(self: State) bool {
            return switch (self) {
                .idle_home,
                .idle_ground,
                .idle_tree,
                .idle_sky,
                => true,
                else => false,
            };
        }

        pub fn fromHome(self: State) bool {
            return switch (self) {
                .fly_sky_from_home,
                .fly_ground_from_home,
                .fly_tree_from_home,
                => true,
                else => false,
            };
        }
    };
};
