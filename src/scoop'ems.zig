const std = @import("std");

const core = @import("core");
const gpu = core.gpu;

const zgui = @import("zgui").MachImgui(core);
const zstbi = @import("zstbi");
const zmath = @import("zmath");
const ecs = @import("zflecs");

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
    fonts: Fonts = .{},
    delta_time: f32 = 0.0,
    time: f32 = 0.0,
    batcher: gfx.Batcher = undefined,
    world: *ecs.world_t = undefined,
    entities: Entities = .{},
};

pub const Entities = struct {
    player: usize = 0,
    ground_west: usize = 0,
    ground_east: usize = 0,
};

pub const Channel = enum(i32) {
    final = 0,
};

pub const Fonts = struct {
    fa_standard_regular: zgui.Font = undefined,
    fa_standard_solid: zgui.Font = undefined,
    fa_small_regular: zgui.Font = undefined,
    fa_small_solid: zgui.Font = undefined,
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

    const scale_factor = content_scale[1];

    zstbi.init(allocator);

    state.allocator = allocator;
    state.palette = try gfx.Texture.loadFromFile(assets.scoopems_palette_png.path, .{});
    state.diffusemap = try gfx.Texture.loadFromFile(assets.scoopems_png.path, .{});
    state.atlas = try gfx.Atlas.loadFromFile(allocator, assets.scoopems_atlas.path);

    state.output_diffuse = try gfx.Texture.createEmpty(settings.design_width, settings.design_height, .{ .format = core.descriptor.format });

    state.hotkeys = try input.Hotkeys.initDefault(allocator);
    state.mouse = try input.Mouse.initDefault(allocator);

    state.camera = gfx.Camera.init(settings.design_size, zmath.f32x4(framebuffer_size[0], framebuffer_size[1], 0, 0), zmath.f32x4(-32.0, 0, 0, 0));

    state.batcher = try gfx.Batcher.init(allocator, 1000);

    app.* = .{
        .timer = try core.Timer.start(),
    };

    zgui.init(allocator);
    zgui.mach_backend.init(core.device, core.descriptor.format, .{});

    zgui.io.setIniFilename("imgui.ini");

    _ = zgui.io.addFontFromFile(assets.root ++ "fonts/CozetteVector.ttf", 12 * scale_factor);

    var config = zgui.FontConfig.init();
    config.merge_mode = true;
    const ranges: []const u16 = &.{ 0xf000, 0xf976, 0 };

    state.fonts.fa_standard_solid = zgui.io.addFontFromFileWithConfig(assets.root ++ "fonts/fa-solid-900.ttf", 12 * scale_factor, config, ranges.ptr);
    state.fonts.fa_standard_regular = zgui.io.addFontFromFileWithConfig(assets.root ++ "fonts/fa-regular-400.ttf", 12 * scale_factor, config, ranges.ptr);
    state.fonts.fa_small_solid = zgui.io.addFontFromFileWithConfig(assets.root ++ "fonts/fa-solid-900.ttf", 10 * scale_factor, config, ranges.ptr);
    state.fonts.fa_small_regular = zgui.io.addFontFromFileWithConfig(assets.root ++ "fonts/fa-regular-400.ttf", 10 * scale_factor, config, ranges.ptr);

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
    var parallax_system = @import("ecs/systems/parallax.zig").system();
    ecs.SYSTEM(state.world, "ParallaxSystem", ecs.OnUpdate, &parallax_system);

    // - Animation
    var animation_scoop_system = @import("ecs/systems/animation_scoop.zig").system();
    ecs.SYSTEM(state.world, "AnimationScoopSystem", ecs.OnUpdate, &animation_scoop_system);
    var bird_system = @import("ecs/systems/bird.zig").system();
    ecs.SYSTEM(state.world, "BirdSystem", ecs.OnUpdate, &bird_system);
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
}

pub fn updateMainThread(_: *App) !bool {
    return false;
}

pub fn update(app: *App) !bool {
    zgui.mach_backend.newFrame();
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
        zgui.mach_backend.passEvent(event, content_scale);
    }

    try input.process();

    _ = ecs.progress(state.world, 0);

    if (core.swap_chain.getCurrentTextureView()) |back_buffer_view| {
        defer back_buffer_view.release();

        const zgui_commands = commands: {
            const encoder = core.device.createCommandEncoder(null);
            defer encoder.release();

            const background: gpu.Color = .{
                .r = 0.0,
                .g = 0.0,
                .b = 0.0,
                .a = 1.0,
            };

            // Gui pass.
            {
                const color_attachment = gpu.RenderPassColorAttachment{
                    .view = back_buffer_view,
                    .clear_value = background,
                    .load_op = .clear,
                    .store_op = .store,
                };

                const render_pass_info = gpu.RenderPassDescriptor.init(.{
                    .color_attachments = &.{color_attachment},
                });
                const pass = encoder.beginRenderPass(&render_pass_info);

                zgui.mach_backend.draw(pass);
                pass.end();
                pass.release();
            }

            break :commands encoder.finish(null);
        };
        defer zgui_commands.release();

        const batcher_commands = try state.batcher.finish();
        defer batcher_commands.release();

        core.queue.submit(&.{ zgui_commands, batcher_commands });
        core.swap_chain.present();
    }

    for (state.hotkeys.hotkeys) |*hotkey| {
        hotkey.previous_state = hotkey.state;
    }

    for (state.mouse.buttons) |*button| {
        button.previous_state = button.state;
    }

    state.mouse.previous_position = state.mouse.position;

    return false;
}

pub fn deinit(_: *App) void {
    state.allocator.free(state.hotkeys.hotkeys);
    state.diffusemap.deinit();
    state.palette.deinit();
    state.output_diffuse.deinit();
    state.atlas.deinit(state.allocator);
    zgui.mach_backend.deinit();
    zgui.deinit();
    zstbi.deinit();
    state.allocator.free(state.root_path);
    state.allocator.destroy(state);
    core.deinit();
}
