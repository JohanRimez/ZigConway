const std = @import("std");
const defs = @import("CWDefinitions.zig");
const sdl = defs.sdl;
const ttf = defs.ttf;
const Window = @import("CWWindow.zig").Window;
const stdout = std.debug;

// from <time.h>
const tm = extern struct {
    tm_sec: c_int, // seconds after the minute - [0, 60] including leap second
    tm_min: c_int, // minutes after the hour - [0, 59]
    tm_hour: c_int, // hours since midnight - [0, 23]
    tm_mday: c_int, // day of the month - [1, 31]
    tm_mon: c_int, // months since January - [0, 11]
    tm_year: c_int, // years since 1900
    tm_wday: c_int, // days since Sunday - [0, 6]
    tm_yday: c_int, // days since January 1 - [0, 365]
    tm_isdst: c_int, // daylight savings time flag
};
const time_t = c_longlong;
extern fn time(*time_t) callconv(.C) time_t;
extern fn localtime(*time_t) callconv(.C) *tm;

fn GetLocalTime(hour: *u8, minute: *u8, second: *u8) void {
    var current: time_t = undefined;
    _ = time(&current);
    const localtm: *tm = localtime(&current);
    hour.* = @intCast(localtm.tm_hour);
    minute.* = @intCast(localtm.tm_min);
    second.* = @intCast(localtm.tm_sec);
}

pub fn main() !void {
    stdout.print("[Conway Life Game Clock - info & debug]\n", .{});
    // Initialise SDL
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_TIMER | sdl.SDL_INIT_JOYSTICK) != 0) {
        stdout.print("Error loading SDL: {s}\n", .{sdl.SDL_GetError()});
        return error.SDLNotInitialised;
    }
    defer sdl.SDL_Quit();
    // Initialise window
    const window = Window.init() catch |e| {
        stdout.print("Error initialising window: {s}", .{sdl.SDL_GetError()});
        return e;
    };
    defer window.deinit();
    stdout.print("Window dimensions: {} x {}\n", .{ window.width, window.height });
    stdout.print("Cell columns and rows: {} x {}\n", .{ window.cols, window.rows });
    var RenderInfo: sdl.SDL_RendererInfo = undefined;
    _ = sdl.SDL_GetRendererInfo(window.renderer, &RenderInfo);
    stdout.print("Renderer info: {s}\n", .{RenderInfo.name});

    // Hide mouse
    _ = sdl.SDL_ShowCursor(sdl.SDL_DISABLE);

    // InitC clock
    var hour: u8 = 0;
    var minute: u8 = 0;
    var second: u8 = 0;
    var prevsec: u8 = 60;

    // Main loop
    var timer = try std.time.Timer.start();
    var stopLoop: bool = false;
    var event: sdl.SDL_Event = undefined;
    while (true) {
        timer.reset();
        _ = sdl.SDL_RenderPresent(window.renderer);
        _ = sdl.SDL_SetRenderDrawColor(window.renderer, 0, 0, 0, 255);
        _ = sdl.SDL_RenderClear(window.renderer);
        GetLocalTime(&hour, &minute, &second);
        if (second != prevsec) {
            prevsec = second;
            window.SetText(hour, minute, second);
        }
        window.Step();
        window.Draw();
        while (sdl.SDL_PollEvent(&event) != 0) {
            if (event.type == sdl.SDL_KEYDOWN or event.type == sdl.SDL_MOUSEBUTTONDOWN) stopLoop = true;
        }
        if (stopLoop) break;
        const lap: u32 = @intCast(timer.read() / 1_000_000);
        if (lap < defs.refreshrate) sdl.SDL_Delay(defs.refreshrate - lap);
    }
}
