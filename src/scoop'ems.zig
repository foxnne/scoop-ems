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
pub const shaders = @import("shaders.zig");

pub const fs = @import("tools/fs.zig");
pub const fa = @import("tools/font_awesome.zig");
pub const math = @import("math/math.zig");
pub const gfx = @import("gfx/gfx.zig");
pub const input = @import("input/input.zig");

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
    fox_logo: gfx.Texture = undefined,
    atlas: gfx.Atlas = undefined,
    diffusemap: gfx.Texture = undefined,
    fonts: Fonts = .{},
    delta_time: f32 = 0.0,
    batcher: gfx.Batcher = undefined,
    world: *ecs.world_t = undefined,
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
        .size = .{ .width = 1920, .height = 1080 },
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
    state.fox_logo = try gfx.Texture.loadFromFile(assets.fox1024_png.path, .{});
    state.diffusemap = try gfx.Texture.loadFromFile(assets.scoopems_png.path, .{});
    state.atlas = try gfx.Atlas.loadFromFile(allocator, assets.scoopems_atlas.path);

    state.hotkeys = try input.Hotkeys.initDefault(allocator);
    state.mouse = try input.Mouse.initDefault(allocator);

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

    state.world = ecs.init();
    register(state.world, components);
}

pub fn updateMainThread(_: *App) !bool {
    return false;
}

pub fn update(app: *App) !bool {
    zgui.mach_backend.newFrame();
    state.delta_time = app.timer.lap();

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
                .g = 0.2,
                .b = 0.8,
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

        core.queue.submit(&.{zgui_commands});
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
    state.fox_logo.deinit();
    state.diffusemap.deinit();
    state.atlas.deinit(state.allocator);
    zgui.mach_backend.deinit();
    zgui.deinit();
    zstbi.deinit();
    state.allocator.free(state.root_path);
    state.allocator.destroy(state);
    core.deinit();
}
