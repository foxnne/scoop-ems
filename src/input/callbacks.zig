const std = @import("std");
const zglfw = @import("zglfw");
const game = @import("root");
const input = @import("input.zig");
const zgpu = @import("zgpu");
const zgui = @import("zgui");

pub fn cursor(_: *zglfw.Window, x: f64, y: f64) callconv(.C) void {
    game.state.controls.mouse.previous_position.x = game.state.controls.mouse.position.x;
    game.state.controls.mouse.previous_position.y = game.state.controls.mouse.position.y;
    game.state.controls.mouse.position.x = @as(f32, @floatCast(x));
    game.state.controls.mouse.position.y = @as(f32, @floatCast(y));
}

pub fn scroll(_: *zglfw.Window, x: f64, y: f64) callconv(.C) void {
    game.state.controls.mouse.scroll_x = @as(f32, @floatCast(x));
    game.state.controls.mouse.scroll_y = @as(f32, @floatCast(y));
}

pub fn button(_: *zglfw.Window, glfw_button: zglfw.MouseButton, action: zglfw.Action, _: zglfw.Mods) callconv(.C) void {
    if (glfw_button == game.state.controls.mouse.primary.button) {
        switch (action) {
            .release => {
                game.state.controls.mouse.primary.state = false;
            },
            .repeat, .press => {
                game.state.controls.mouse.primary.state = true;

                if (game.state.controls.mouse.primary.pressed()) {
                    game.state.controls.mouse.clicked_position = game.state.controls.mouse.position;
                }
            },
        }
    }

    if (glfw_button == game.state.controls.mouse.secondary.button) {
        switch (action) {
            .release => {
                game.state.controls.mouse.secondary.state = false;
            },
            .repeat, .press => {
                game.state.controls.mouse.secondary.state = true;
            },
        }
    }
}

pub fn key(_: *zglfw.Window, glfw_key: zglfw.Key, _: i32, action: zglfw.Action, mods: zglfw.Mods) callconv(.C) void {
    game.state.hotkeys.setHotkeyState(glfw_key, mods, action);
}
