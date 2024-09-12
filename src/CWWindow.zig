const std = @import("std");
const defs = @import("CWDefinitions.zig");
const sdl = defs.sdl;
const pWindow = defs.pWindow;
const pRenderer = defs.pRenderer;
const Clock = @import("CWClock.zig").Clock;

pub const Canvas = struct {
    width: u32,
    height: u32,
    values: []bool,
    pub fn init(width: u32, height: u32) !Canvas {
        const values = try defs.allocator.alloc(bool, width * height);
        for (0..width * height) |index| values[index] = false;
        return .{
            .width = width,
            .height = height,
            .values = values,
        };
    }
    pub fn reset(self: Canvas) void {
        for (0..self.width * self.height) |index| self.values[index] = false;
    }
    pub fn deinit(self: Canvas) void {
        defs.allocator.free(self.values);
    }
};

pub const Window = struct {
    window: pWindow,
    renderer: pRenderer,
    width: c_int,
    height: c_int,
    cols: u32,
    rows: u32,
    grid: *Canvas,
    temp: *Canvas,
    text: *Canvas,
    clock: Clock,
    pub fn init() !Window {
        var w: c_int = undefined;
        var h: c_int = undefined;
        const wnd: pWindow = sdl.SDL_CreateWindow(
            defs.WINDOW_TITLE,
            0,
            0,
            1600,
            900,
            sdl.SDL_WINDOW_FULLSCREEN_DESKTOP,
        ) orelse
            return error.SDLWindowNotInitialised;
        errdefer sdl.SDL_DestroyWindow(wnd);
        // Determine dimensions
        sdl.SDL_GetWindowSize(wnd, &w, &h);
        if (@mod(w, defs.cellSize) != 0 or @mod(h, defs.cellSize) != 0) return error.CellSizeError;
        const cols: u32 = @intCast(@divFloor(w, defs.cellSize));
        const rows: u32 = @intCast(@divFloor(h, defs.cellSize));
        // Get renderer
        const renderer = sdl.SDL_CreateRenderer(
            wnd,
            -1,
            sdl.SDL_RENDERER_ACCELERATED,
        ) orelse return error.SDLRendererNotInitialised;

        // Initialise cell grids
        const grid = try defs.allocator.create(Canvas);
        grid.* = try Canvas.init(cols, rows);
        errdefer grid.deinit();
        errdefer defs.allocator.destroy(grid);
        const temp = try defs.allocator.create(Canvas);
        temp.* = try Canvas.init(cols, rows);
        errdefer temp.deinit();
        errdefer defs.allocator.destroy(temp);
        const text = try defs.allocator.create(Canvas);
        text.* = try Canvas.init(cols, rows);
        errdefer text.deinit();
        errdefer defs.allocator.destroy(text);

        const clock = try Clock.init(text, cols, rows);

        return .{
            .window = wnd,
            .renderer = renderer,
            .width = w,
            .height = h,
            .cols = cols,
            .rows = rows,
            .grid = grid,
            .temp = temp,
            .text = text,
            .clock = clock,
        };
    }

    pub fn deinit(self: Window) void {
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        self.grid.deinit();
        defs.allocator.destroy(self.grid);
        self.temp.deinit();
        defs.allocator.destroy(self.temp);
        self.text.deinit();
        defs.allocator.destroy(self.text);
        self.clock.deinit();
    }

    pub fn GetNeighBours(self: Window, x: usize, y: usize) u8 {
        var sum: u8 = 0;
        const ym = (if (y == 0) self.rows - 1 else y - 1) * self.cols;
        const yc = y * self.cols;
        const yp = (if (y == self.rows - 1) 0 else y + 1) * self.cols;
        const xm = (if (x == 0) self.cols - 1 else x - 1);
        const xp = (if (x == self.cols - 1) 0 else x + 1);
        if (self.grid.values[ym + xm]) sum += 1;
        if (self.grid.values[ym + x]) sum += 1;
        if (self.grid.values[ym + xp]) sum += 1;
        if (self.grid.values[yc + xm]) sum += 1;
        if (self.grid.values[yc + xp]) sum += 1;
        if (self.grid.values[yp + xm]) sum += 1;
        if (self.grid.values[yp + x]) sum += 1;
        if (self.grid.values[yp + xp]) sum += 1;
        return sum;
    }

    pub fn Step(self: Window) void {
        var cursor: usize = 0;
        for (0..self.rows) |y| {
            for (0..self.cols) |x| {
                const neighbours = GetNeighBours(self, x, y);
                if (self.grid.values[cursor]) {
                    self.temp.values[cursor] = (neighbours == 2 or neighbours == 3 or self.text.values[cursor]);
                } else {
                    self.temp.values[cursor] = (neighbours == 3 or self.text.values[cursor]);
                }
                cursor += 1;
            }
        }
        @memcpy(self.grid.values, self.temp.values);
    }

    pub fn SetText(self: Window, hour: u8, minute: u8, second: u8) void {
        self.text.reset();
        self.clock.imprint(hour, minute, second);
    }

    pub fn Draw(self: Window) void {
        var cursor: usize = 0;
        var rectTarget = sdl.SDL_Rect{
            .x = 0,
            .y = 0,
            .w = defs.cellSize - 2,
            .h = defs.cellSize - 2,
        };
        for (0..self.rows) |y| {
            for (0..self.cols) |x| {
                if (self.grid.values[cursor]) {
                    rectTarget.x = @intCast(defs.cellSize * x + 1);
                    rectTarget.y = @intCast(defs.cellSize * y + 1);
                    if (self.text.values[cursor]) {
                        _ = sdl.SDL_SetRenderDrawColor(self.renderer, 200, 255, 200, 255);
                    } else _ = sdl.SDL_SetRenderDrawColor(self.renderer, 0, 255, 0, 255);
                    _ = sdl.SDL_RenderDrawRect(self.renderer, &rectTarget);
                }
                cursor += 1;
            }
        }
    }
};
