const game = @import("../../scoop'ems.zig");
const gfx = game.gfx;
const math = game.math;
const zm = @import("zmath");

pub const ParticleRenderer = struct {
    particles: []Particle,
    frag_mode: gfx.Batcher.SpriteOptions.FragRenderMode = .standard,
    offset: [4]f32 = .{ 0.0, 0.0, 0.0, 0.0 },

    pub const Particle = struct {
        life: f32 = 0.0,
        position: [3]f32 = .{ 0.0, 0.0, 0.0 },
        velocity: [2]f32 = .{ 0.0, 0.0 },
        index: usize = 0,
        color: [4]f32 = math.Colors.white.toSlice(),

        pub fn alive(self: Particle) bool {
            return self.life > 0.0;
        }
    };
};

pub const ParticleAnimator = struct {
    animation: []usize,
    time_since_emit: f32 = 0.0,
    rate: f32 = 1.0,
    start_life: f32 = 1.0,
    velocity_min: [2]f32,
    velocity_max: [2]f32,
    start_color: [4]f32 = math.Colors.white.toSlice(),
    end_color: [4]f32 = math.Colors.white.toSlice(),
    random_start_frag_color: u8 = 0,
    random_end_frag_color: u8 = 1,
    state: State = .play,

    pub const State = enum {
        pause,
        play,
    };
};
