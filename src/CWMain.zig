const std = @import("std");
const defs = @import("CWDefinitions.zig");
const sdl = defs.sdl;
const ttf = defs.ttf;
const Window = @import("CWWindow.zig").Window;
const stdout = std.debug;
const LocalTime = @cImport(@cInclude("LocalTime.c"));

pub fn main() !void {
    stdout.print("[GrottoDive.exe - info & debug]\n", .{});
    // Initialise SDL
    if (sdl.SDL_Init(sdl.SDL_INIT_TIMER | sdl.SDL_INIT_JOYSTICK) != 0) {
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
        LocalTime.GetLocalTime(&hour, &minute, &second);
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
