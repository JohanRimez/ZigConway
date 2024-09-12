const std = @import("std");
//SDL constants
pub const sdl = @import("SDLimport.zig");
pub const pWindow = *sdl.SDL_Window;
pub const pRenderer = *sdl.SDL_Renderer;
pub const pSurface = *sdl.SDL_Surface;

// App constants
pub const WINDOW_TITLE = "Conway clock";
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub const allocator = gpa.allocator();
pub const refreshrate = 100; // [ms]

// Conway constants
pub const cellSize = 5;
