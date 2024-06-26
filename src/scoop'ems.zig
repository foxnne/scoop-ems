const std = @import("std");
const build_options = @import("build-options");

const mach = @import("mach");
const core = mach.core;
const gpu = mach.gpu;

pub const use_sysgpu = build_options.use_sysgpu;

const zstbi = @import("zstbi");
const zmath = @import("zmath");
const ecs = @import("zflecs");

const sysaudio = mach.sysaudio;
const Opus = mach.Audio.Opus;

pub const App = @This();

timer: core.Timer,

pub const name: [:0]const u8 = "Scoop'ems";
pub const version: std.SemanticVersion = .{ .major = 0, .minor = 1, .patch = 0 };

pub const assets = @import("assets.zig");
pub const animations = @import("animations.zig");
pub const shaders = @import("shaders.zig");
pub const settings = @import("settings.zig");

pub const fs = @import("tools/fs.zig");
pub const fa = @import("tools/font_awesome.zig");
pub const math = @import("math/math.zig");
pub const gfx = @import("gfx/gfx.zig");
pub const input = @import("input/input.zig");

pub const map = @import("map/map.zig");

pub const components = @import("ecs/components/components.zig");

test {
    _ = zstbi;
    _ = math;
    _ = gfx;
    _ = input;
}

pub var state: *GameState = undefined;
pub var content_scale: [2]f32 = undefined;
pub var window_size: [2]f32 = undefined;
pub var framebuffer_size: [2]f32 = undefined;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

/// Holds the global game state.
pub const GameState = struct {
    allocator: std.mem.Allocator = undefined,
    hotkeys: input.Hotkeys = undefined,
    mouse: input.Mouse = undefined,
    root_path: [:0]const u8 = undefined,
    camera: gfx.Camera = undefined,
    atlas: gfx.Atlas = undefined,
    diffusemap: gfx.Texture = undefined,
    palette: gfx.Texture = undefined,
    bind_group_diffuse: *gpu.BindGroup = undefined,
    pipeline_diffuse: *gpu.RenderPipeline = undefined,
    bind_group_final: *gpu.BindGroup = undefined,
    pipeline_final: *gpu.RenderPipeline = undefined,
    uniform_buffer_diffuse: *gpu.Buffer = undefined,
    uniform_buffer_final: *gpu.Buffer = undefined,
    output_diffuse: gfx.Texture = undefined,
    output_channel: Channel = .final,
    delta_time: f32 = 0.0,
    time: f32 = 0.0,
    batcher: gfx.Batcher = undefined,
    world: *ecs.world_t = undefined,
    entities: Entities = .{},
    sounds: Sounds = .{},
};

pub const Entities = struct {
    player: usize = 0,
    character: usize = 0,
    ground_west: usize = 0,
    ground_east: usize = 0,
};

pub const Sounds = struct {
    player: sysaudio.Player = undefined,
    ctx: sysaudio.Context = undefined,
    device: sysaudio.Device = undefined,
    engine_idle: Opus = undefined,
    engine_rev_1: Opus = undefined,
    engine_rev_2: Opus = undefined,
    engine_rev_3: Opus = undefined,
    engine_rev_4: Opus = undefined,
    engine_release: Opus = undefined,
    play_engine_rev: bool = false,
    play_engine_release: bool = false,
    play_sparkles: bool = false,
    birds_idle: Opus = undefined,
    sparkles: Opus = undefined,
    music: Opus = undefined,
};

pub const Channel = enum(i32) {
    final = 0,
};

/// Registers all public declarations within the passed type
/// as components.
fn register(world: *ecs.world_t, comptime T: type) void {
    const decls = comptime std.meta.declarations(T);
    inline for (decls) |decl| {
        const Type = @field(T, decl.name);
        if (@TypeOf(Type) == type) {
            if (@sizeOf(Type) > 0) {
                ecs.COMPONENT(world, Type);
            } else ecs.TAG(world, Type);
        }
    }
}

pub fn init(app: *App) !void {
    const allocator = gpa.allocator();

    var buffer: [1024]u8 = undefined;
    const root_path = std.fs.selfExeDirPath(buffer[0..]) catch ".";

    state = try allocator.create(GameState);
    state.* = .{ .root_path = try allocator.dupeZ(u8, root_path) };

    try core.init(.{
        .title = name,
        .size = .{ .width = 1280, .height = 720 },
    });

    const descriptor = core.descriptor;
    window_size = .{ @floatFromInt(core.size().width), @floatFromInt(core.size().height) };
    framebuffer_size = .{ @floatFromInt(descriptor.width), @floatFromInt(descriptor.height) };
    content_scale = .{
        framebuffer_size[0] / window_size[0],
        framebuffer_size[1] / window_size[1],
    };

    zstbi.init(allocator);

    state.allocator = allocator;

    // Images
    {
        state.palette = try gfx.Texture.loadFromFile(assets.scoopems_palette_png.path, .{});
        state.diffusemap = try gfx.Texture.loadFromFile(assets.scoopems_png.path, .{});
        state.atlas = try gfx.Atlas.loadFromFile(allocator, assets.scoopems_atlas.path);
        state.output_diffuse = try gfx.Texture.createEmpty(settings.design_width, settings.design_height, .{ .format = core.descriptor.format });
    }

    // Sounds
    {
        state.sounds.ctx = try sysaudio.Context.init(null, allocator, .{});
        try state.sounds.ctx.refresh();

        state.sounds.device = state.sounds.ctx.defaultDevice(.playback) orelse return error.NoDevice;

        const engine_idle = try std.fs.cwd().openFile(assets.engine_idle_opus.path, .{});
        state.sounds.engine_idle = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = engine_idle });

        const engine_rev = try std.fs.cwd().openFile(assets.engine_dig_opus.path, .{});
        state.sounds.engine_rev_1 = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = engine_rev });

        const engine_rev_2 = try std.fs.cwd().openFile(assets.engine_dig_2_opus.path, .{});
        state.sounds.engine_rev_2 = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = engine_rev_2 });

        const engine_release = try std.fs.cwd().openFile(assets.engine_release_opus.path, .{});
        state.sounds.engine_release = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = engine_release });

        const birds_idle = try std.fs.cwd().openFile(assets.birds_opus.path, .{});
        state.sounds.birds_idle = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = birds_idle });

        const sparkles = try std.fs.cwd().openFile(assets.sparkles_opus.path, .{});
        state.sounds.sparkles = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = sparkles });

        const music = try std.fs.cwd().openFile(assets.music_opus.path, .{});
        state.sounds.music = try Opus.decodeStream(allocator, std.io.StreamSource{ .file = music });

        state.sounds.player = try state.sounds.ctx.createPlayer(state.sounds.device, writeCallback, .{});

        try state.sounds.player.start();
        try state.sounds.player.setVolume(0.5);
    }

    // Input and Rendering
    {
        state.hotkeys = try input.Hotkeys.initDefault(allocator);
        state.mouse = try input.Mouse.initDefault(allocator);
        state.camera = gfx.Camera.init(settings.design_size, zmath.f32x4(framebuffer_size[0], framebuffer_size[1], 0, 0), zmath.f32x4(-32.0, 0, 0, 0));
        state.batcher = try gfx.Batcher.init(allocator, 1000);
    }

    app.* = .{
        .timer = try core.Timer.start(),
    };

    const diffuse_shader_module = core.device.createShaderModuleWGSL("diffuse.wgsl", @embedFile("shaders/diffuse.wgsl"));
    const final_shader_module = core.device.createShaderModuleWGSL("final.wgsl", @embedFile("shaders/final.wgsl"));

    const vertex_attributes = [_]gpu.VertexAttribute{
        .{ .format = .float32x3, .offset = @offsetOf(gfx.Vertex, "position"), .shader_location = 0 },
        .{ .format = .float32x2, .offset = @offsetOf(gfx.Vertex, "uv"), .shader_location = 1 },
        .{ .format = .float32x4, .offset = @offsetOf(gfx.Vertex, "color"), .shader_location = 2 },
        .{ .format = .float32x3, .offset = @offsetOf(gfx.Vertex, "data"), .shader_location = 3 },
    };
    const vertex_buffer_layout = gpu.VertexBufferLayout.init(.{
        .array_stride = @sizeOf(gfx.Vertex),
        .step_mode = .vertex,
        .attributes = &vertex_attributes,
    });

    const blend = gpu.BlendState{
        .color = .{
            .operation = .add,
            .src_factor = .src_alpha,
            .dst_factor = .one_minus_src_alpha,
        },
        .alpha = .{
            .operation = .add,
            .src_factor = .src_alpha,
            .dst_factor = .one_minus_src_alpha,
        },
    };

    const diffuse_color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };
    const diffuse_fragment = gpu.FragmentState.init(.{
        .module = diffuse_shader_module,
        .entry_point = "frag_main",
        .targets = &.{diffuse_color_target},
    });

    const diffuse_pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &diffuse_fragment,
        .vertex = gpu.VertexState.init(.{ .module = diffuse_shader_module, .entry_point = "vert_main", .buffers = &.{vertex_buffer_layout} }),
    };

    state.pipeline_diffuse = core.device.createRenderPipeline(&diffuse_pipeline_descriptor);

    state.uniform_buffer_diffuse = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(gfx.UniformBufferObject),
        .mapped_at_creation = .false,
    });

    state.bind_group_diffuse = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = state.pipeline_diffuse.getBindGroupLayout(0),
            .entries = &.{
                if (use_sysgpu)
                    gpu.BindGroup.Entry.buffer(0, state.uniform_buffer_diffuse, 0, @sizeOf(gfx.UniformBufferObject), 0)
                else
                    gpu.BindGroup.Entry.buffer(0, state.uniform_buffer_diffuse, 0, @sizeOf(gfx.UniformBufferObject)),
                gpu.BindGroup.Entry.textureView(1, state.diffusemap.view_handle),
                gpu.BindGroup.Entry.textureView(2, state.palette.view_handle),
                gpu.BindGroup.Entry.sampler(3, state.diffusemap.sampler_handle),
            },
        }),
    );

    const final_color_target = gpu.ColorTargetState{
        .format = core.descriptor.format,
        .blend = &blend,
        .write_mask = gpu.ColorWriteMaskFlags.all,
    };

    const final_fragment = gpu.FragmentState.init(.{
        .module = final_shader_module,
        .entry_point = "frag_main",
        .targets = &.{final_color_target},
    });

    const final_pipeline_descriptor = gpu.RenderPipeline.Descriptor{
        .fragment = &final_fragment,
        .vertex = gpu.VertexState.init(.{ .module = final_shader_module, .entry_point = "vert_main", .buffers = &.{vertex_buffer_layout} }),
    };

    state.pipeline_final = core.device.createRenderPipeline(&final_pipeline_descriptor);

    const FinalUniformObject = @import("ecs/systems/render_final_pass.zig").FinalUniforms;

    state.uniform_buffer_final = core.device.createBuffer(&.{
        .usage = .{ .copy_dst = true, .uniform = true },
        .size = @sizeOf(FinalUniformObject),
        .mapped_at_creation = .false,
    });

    state.bind_group_final = core.device.createBindGroup(
        &gpu.BindGroup.Descriptor.init(.{
            .layout = state.pipeline_final.getBindGroupLayout(0),
            .entries = &.{
                if (use_sysgpu)
                    gpu.BindGroup.Entry.buffer(0, state.uniform_buffer_final, 0, @sizeOf(FinalUniformObject), 0)
                else
                    gpu.BindGroup.Entry.buffer(0, state.uniform_buffer_final, 0, @sizeOf(FinalUniformObject)),
                gpu.BindGroup.Entry.textureView(1, state.output_diffuse.view_handle),
                gpu.BindGroup.Entry.sampler(2, state.output_diffuse.sampler_handle),
            },
        }),
    );

    state.world = ecs.init();
    register(state.world, components);

    // - Input
    var input_direction_system = @import("ecs/systems/input_direction.zig").system();
    ecs.SYSTEM(state.world, "InputDirectionSystem", ecs.OnUpdate, &input_direction_system);
    var input_scoop_system = @import("ecs/systems/input_scoop.zig").system();
    ecs.SYSTEM(state.world, "InputScoopSystem", ecs.OnUpdate, &input_scoop_system);

    var cooldown_system = @import("ecs/systems/cooldown.zig").system();
    ecs.SYSTEM(state.world, "CooldownSystem", ecs.OnUpdate, &cooldown_system);
    var camera_system = @import("ecs/systems/camera.zig").system();
    ecs.SYSTEM(state.world, "CameraSystem", ecs.OnUpdate, &camera_system);

    // - Animation
    var animation_sprite_system = @import("ecs/systems/animation_sprite.zig").system();
    ecs.SYSTEM(state.world, "AnimationSpriteSystem", ecs.OnUpdate, &animation_sprite_system);
    var animation_scoop_system = @import("ecs/systems/animation_scoop.zig").system();
    ecs.SYSTEM(state.world, "AnimationScoopSystem", ecs.OnUpdate, &animation_scoop_system);
    var bird_system = @import("ecs/systems/bird.zig").system();
    ecs.SYSTEM(state.world, "BirdSystem", ecs.OnUpdate, &bird_system);
    var rainbow_system = @import("ecs/systems/rainbow.zig").system();
    ecs.SYSTEM(state.world, "RainbowSystem", ecs.OnUpdate, &rainbow_system);
    var animation_hitpoints_system = @import("ecs/systems/animation_hitpoints.zig").system();
    ecs.SYSTEM(state.world, "AnimationHitpointsSystem", ecs.OnUpdate, &animation_hitpoints_system);
    var animation_direction_system = @import("ecs/systems/animation_direction.zig").system();
    ecs.SYSTEM(state.world, "AnimationDirectionSystem", ecs.OnUpdate, &animation_direction_system);
    var animation_particle_system = @import("ecs/systems/animation_particle.zig").system();
    ecs.SYSTEM(state.world, "AnimationParticleSystem", ecs.OnUpdate, &animation_particle_system);

    // - Render
    var render_culling_system = @import("ecs/systems/render_culling.zig").system();
    ecs.SYSTEM(state.world, "RenderCullingSystem", ecs.PostUpdate, &render_culling_system);
    var render_diffuse_system = @import("ecs/systems/render_diffuse_pass.zig").system();
    ecs.SYSTEM(state.world, "RenderDiffuseSystem", ecs.PostUpdate, &render_diffuse_system);
    var render_final_system = @import("ecs/systems/render_final_pass.zig").system();
    ecs.SYSTEM(state.world, "RenderFinalSystem", ecs.PostUpdate, &render_final_system);

    var parallax_system = @import("ecs/systems/parallax.zig").system();
    ecs.SYSTEM(state.world, "ParallaxSystem", ecs.PostUpdate, &parallax_system);

    map.create();

    const tracks = ecs.new_id(state.world);
    _ = ecs.set(state.world, tracks, components.Position, .{ .x = 0.0, .y = settings.ground_height, .z = 1.0 });
    _ = ecs.set(state.world, tracks, components.SpriteRenderer, .{
        .index = assets.scoopems_atlas.Excavator_rotate_empty_0_Tracks,
    });

    state.entities.player = ecs.new_id(state.world);
    _ = ecs.add(state.world, state.entities.player, components.Player);
    _ = ecs.set(state.world, state.entities.player, components.Position, .{ .x = 0.0, .y = settings.ground_height, .z = 1.0 });
    _ = ecs.set(state.world, state.entities.player, components.SpriteRenderer, .{
        .index = assets.scoopems_atlas.Excavator_rotate_empty_0_Frame,
    });
    _ = ecs.set(state.world, state.entities.player, components.SpriteAnimator, .{
        .animation = &animations.Excavator_scoop_Frame,
        .fps = 12,
    });
    _ = ecs.set(state.world, state.entities.player, components.Direction, .w);
    _ = ecs.set(state.world, state.entities.player, components.ExcavatorState, .empty);
    _ = ecs.set_pair(state.world, state.entities.player, ecs.id(components.Target), ecs.id(components.Direction), components.Direction, .w);
    _ = ecs.set(state.world, state.entities.player, components.ParticleRenderer, .{
        .particles = try allocator.alloc(components.ParticleRenderer.Particle, 100),
        .offset = .{ 23.0, 46.0, 0.0, 0.0 },
    });

    _ = ecs.set(state.world, state.entities.player, components.ParticleAnimator, .{
        .animation = &animations.Smoke_Layer,
        .rate = 3.0,
        .velocity_min = .{ -2.0, 25.0 },
        .velocity_max = .{ 2.0, 50.0 },
        .start_life = 1.0,
        .start_color = .{ 0.6, 0.6, 0.6, 1.0 },
        .end_color = .{ 1.0, 1.0, 1.0, 0.5 },
    });

    state.entities.character = ecs.new_id(state.world);
    _ = ecs.set(state.world, state.entities.character, components.Position, .{ .x = 0.0, .y = settings.ground_height, .z = 0.5 });
    _ = ecs.set(state.world, state.entities.character, components.SpriteRenderer, .{
        .index = assets.scoopems_atlas.Excavator_rotate_empty_0_Arlynn,
    });
    _ = ecs.set(state.world, state.entities.character, components.SpriteAnimator, .{
        .animation = &animations.Excavator_scoop_Arlynn,
        .fps = 12,
    });
    _ = ecs.set(state.world, state.entities.character, components.Direction, .w);
}

pub fn updateMainThread(_: *App) !bool {
    return false;
}

pub fn update(app: *App) !bool {
    state.delta_time = app.timer.lap();
    state.time += (state.delta_time);

    const descriptor = core.descriptor;
    window_size = .{ @floatFromInt(core.size().width), @floatFromInt(core.size().height) };
    framebuffer_size = .{ @floatFromInt(descriptor.width), @floatFromInt(descriptor.height) };
    content_scale = .{
        framebuffer_size[0] / window_size[0],
        framebuffer_size[1] / window_size[1],
    };

    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .key_press => |key_press| {
                state.hotkeys.setHotkeyState(key_press.key, key_press.mods, .press);
            },
            .key_repeat => |key_repeat| {
                state.hotkeys.setHotkeyState(key_repeat.key, key_repeat.mods, .repeat);
            },
            .key_release => |key_release| {
                state.hotkeys.setHotkeyState(key_release.key, key_release.mods, .release);
            },
            .mouse_scroll => |mouse_scroll| {
                state.mouse.scroll_x = mouse_scroll.xoffset;
                state.mouse.scroll_y = mouse_scroll.yoffset;
            },
            .mouse_motion => |mouse_motion| {
                state.mouse.position = .{ @floatCast(mouse_motion.pos.x * content_scale[0]), @floatCast(mouse_motion.pos.y * content_scale[1]) };
            },
            .mouse_press => |mouse_press| {
                state.mouse.setButtonState(mouse_press.button, mouse_press.mods, .press);
            },
            .mouse_release => |mouse_release| {
                state.mouse.setButtonState(mouse_release.button, mouse_release.mods, .release);
            },
            .close => {
                return true;
            },
            .framebuffer_resize => |size| {
                state.camera.window_size = zmath.f32x4(@floatFromInt(size.width), @floatFromInt(size.height), 0, 0);
            },
            else => {},
        }
    }

    _ = ecs.progress(state.world, 0);

    const batcher_commands = try state.batcher.finish();
    defer batcher_commands.release();

    core.queue.submit(&.{batcher_commands});
    core.swap_chain.present();

    for (state.hotkeys.hotkeys) |*hotkey| {
        hotkey.previous_state = hotkey.state;
    }

    for (state.mouse.buttons) |*button| {
        button.previous_state = button.state;
    }

    state.mouse.previous_position = state.mouse.position;

    state.sounds.play_sparkles = false;

    return false;
}

pub fn deinit(_: *App) void {
    state.sounds.ctx.deinit();
    state.allocator.free(state.sounds.engine_idle.samples);
    state.sounds.player.deinit();
    state.allocator.free(state.hotkeys.hotkeys);
    state.diffusemap.deinit();
    state.palette.deinit();
    state.output_diffuse.deinit();
    state.atlas.deinit(state.allocator);
    zstbi.deinit();
    state.allocator.free(state.root_path);
    state.allocator.destroy(state);
    core.deinit();
}

var idle_i: usize = 0;
var rev_i: usize = 0;
var release_i: usize = 0;
var birds_i: usize = 0;
var sparkles_i: usize = 0;
var rev_swap: usize = 0;
var music_i: usize = 0;
fn writeCallback(_: ?*anyopaque, frames: []u8) void {
    for (frames, 0..) |_, fi| {
        _ = fi; // autofix
        const channels = state.sounds.engine_idle.channels;
        for (0..channels) |_| {
            birds_i += 1;
            if (state.sounds.play_sparkles)
                sparkles_i += 1;
            if (birds_i >= state.sounds.birds_idle.samples.len) birds_i = 0;
            if (sparkles_i >= state.sounds.sparkles.samples.len) sparkles_i = 0;
            idle_i += 1;
            if (idle_i >= state.sounds.engine_idle.samples.len) idle_i = 0;
            music_i += 1;
            if (music_i >= state.sounds.music.samples.len) music_i = 0;
        }

        if (state.sounds.play_engine_rev) {
            idle_i += 1;
            if (idle_i >= state.sounds.engine_idle.samples.len) idle_i = 0;
            const rev_sound = if (@mod(rev_swap, 2) == 0) state.sounds.engine_rev_1 else state.sounds.engine_rev_2;

            if (rev_i >= rev_sound.samples.len) {
                rev_i = 0;
                state.sounds.play_engine_rev = false;
            }

            const fade_in: f32 = @min(1.0, @as(f32, @floatFromInt(rev_i / 10)));
            const fade_out: f32 = 1.0 - @min(1.0, @as(f32, @floatFromInt(rev_i / rev_sound.samples.len)));

            for (0..channels) |ch| {
                _ = ch; // autofix
                var sample = rev_sound.samples[rev_i] * fade_in * fade_out + state.sounds.birds_idle.samples[birds_i] * 3.0 + state.sounds.engine_idle.samples[idle_i] * 2.0 + state.sounds.music.samples[music_i] * 0.5;
                if (state.sounds.play_sparkles) {
                    sample = rev_sound.samples[rev_i] * fade_in * fade_out + state.sounds.sparkles.samples[sparkles_i] + state.sounds.engine_idle.samples[idle_i] * 2.0 + state.sounds.music.samples[music_i] * 0.5;
                }
                //state.sounds.player.write(state.sounds.player.channels()[ch], fi, sample);
                rev_i += 1;
            }
            idle_i = 0;
            continue;
        }
        if (state.sounds.play_engine_release) {
            idle_i += 1;
            if (idle_i >= state.sounds.engine_idle.samples.len) idle_i = 0;
            const release_sound = state.sounds.engine_release;

            if (release_i >= release_sound.samples.len) {
                release_i = 0;
                state.sounds.play_engine_release = false;
            }

            const fade_in: f32 = @min(1.0, @as(f32, @floatFromInt(release_i / 10)));
            const fade_out: f32 = 1.0 - @min(1.0, @as(f32, @floatFromInt(release_i / release_sound.samples.len)));

            for (0..channels) |ch| {
                _ = ch; // autofix
                var sample = release_sound.samples[release_i] * fade_in * fade_out + state.sounds.birds_idle.samples[birds_i] * 3.0 + state.sounds.engine_idle.samples[idle_i] * 2.0 + state.sounds.music.samples[music_i] * 0.5;
                if (state.sounds.play_sparkles) {
                    sample = release_sound.samples[release_i] * fade_in * fade_out + state.sounds.sparkles.samples[sparkles_i] + state.sounds.engine_idle.samples[idle_i] * 2.0 + state.sounds.music.samples[music_i] * 0.5;
                }
                //state.sounds.player.write(state.sounds.player.channels()[ch], fi, sample);
                release_i += 1;
            }
            idle_i = 0;
            continue;
        }
        {
            rev_swap += 1;
            rev_i = 0;
            release_i = 0;
            for (0..channels) |ch| {
                _ = ch; // autofix
                var sample = state.sounds.engine_idle.samples[idle_i] * 0.35 + state.sounds.birds_idle.samples[birds_i] * 3.0 + state.sounds.music.samples[music_i] * 0.5;
                if (state.sounds.play_sparkles) {
                    sample = state.sounds.engine_idle.samples[idle_i] * 0.35 + state.sounds.sparkles.samples[sparkles_i] * 0.5 + state.sounds.music.samples[music_i] * 0.5;
                } else {
                    sparkles_i = 0;
                }

                //state.sounds.player.write(state.sounds.player.channels()[ch], fi, sample);
            }
        }
    }
}
