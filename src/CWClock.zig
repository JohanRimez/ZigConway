const Canvas = @import("CWWindow.zig").Canvas;
const defs = @import("CWDefinitions.zig");

const SegLength = 15;
const SegThickness = 5;
const SegMargin = 2;
const SegSpacing = 9;
const ColonSpacing = 7;

const Num2Seg = [10]u8{
    0b0111111, //0
    0b0000110, //1
    0b1011011, //2
    0b1001111, //3
    0b1100110, //4
    0b1101101, //5
    0b1111101, //6
    0b0000111, //7
    0b1111111, //8
    0b1101111, //9
};

const DigX = [7]u8{ 0, 1, 1, 0, 0, 0, 0 };
const DigY = [7]u8{ 0, 0, 1, 2, 1, 0, 1 };
const DigD = [7]bool{ true, false, false, true, false, false, true };

const Segment = struct {
    canvas: *Canvas,
    w: u32,
    h: u32,
    anchorX: u32,
    anchorY: u32,
    values: []bool,
    pub fn init(canvas: *Canvas, xc: u32, yc: u32, dir: bool) !Segment {
        const w: u32 = if (dir) SegLength + 1 else SegThickness;
        const h: u32 = if (dir) SegThickness else SegLength + 1;
        const anchorX: u32 = if (dir) xc else xc - (w >> 1);
        const anchorY: u32 = if (dir) yc - (h >> 1) else yc;
        const xp1: u32 = if (dir) SegMargin else w >> 1;
        const yp1: u32 = if (dir) h >> 1 else SegMargin;
        const xp2: u32 = if (dir) SegLength - SegMargin else w >> 1;
        const yp2: u32 = if (dir) h >> 1 else SegLength - SegMargin;
        const values = try defs.allocator.alloc(bool, w * h);
        for (0..h) |y| {
            for (0..w) |x| {
                if (dir) {
                    values[y * w + x] = y + xp1 <= x + yp1 and y + x >= xp1 + yp1 and y + xp2 >= x + yp2 and y + x <= xp2 + yp2;
                } else values[y * w + x] = y + xp1 >= x + yp1 and y + x >= xp1 + yp1 and y + xp2 <= x + yp2 and y + x <= xp2 + yp2;
            }
        }
        return .{
            .canvas = canvas,
            .w = w,
            .h = h,
            .anchorX = anchorX,
            .anchorY = anchorY,
            .values = values,
        };
    }
    pub fn deinit(self: Segment) void {
        defs.allocator.free(self.values);
    }
    pub fn imprint(self: Segment) void {
        var cursorSource: u32 = 0;
        var cursorDest: u32 = self.anchorY * self.canvas.width + self.anchorX;
        const marginDest: u32 = self.canvas.width - self.w;
        for (0..self.h) |_| {
            for (0..self.w) |_| {
                if (self.values[cursorSource]) self.canvas.values[cursorDest] = true;
                cursorDest += 1;
                cursorSource += 1;
            }
            cursorDest += marginDest;
        }
    }
};

const Digit = struct {
    segments: [7]*Segment,
    anchorX: u32,
    anchorY: u32,
    pub fn init(canvas: *Canvas, xc: u32, yc: u32) !Digit {
        var segments: [7]*Segment = undefined;
        for (0..7) |index| {
            segments[index] = try defs.allocator.create(Segment);
            errdefer defs.allocator.destroy(segments[index]);
            segments[index].* = try Segment.init(
                canvas,
                xc + DigX[index] * SegLength,
                yc + DigY[index] * SegLength,
                DigD[index],
            );
            errdefer segments[index].deinit();
        }
        return .{
            .anchorX = xc,
            .anchorY = yc,
            .segments = segments,
        };
    }
    pub fn deinit(self: Digit) void {
        for (0..7) |index| {
            self.segments[index].deinit();
            defs.allocator.destroy(self.segments[index]);
        }
    }
    pub fn imprint(self: Digit, n: u8) void {
        const segs = Num2Seg[n];
        for (0..7) |index| {
            if (segs >> @intCast(index) & 1 == 1)
                self.segments[index].imprint();
        }
    }
};

pub const Colon = struct {
    canvas: *Canvas,
    w: u32,
    h: u32,
    anchorX: u32,
    anchorY: u32,
    values: []bool,
    pub fn init(canvas: *Canvas, xc: u32, yc: u32) !Colon {
        const w: u32 = SegThickness;
        const h: u32 = SegThickness + 2 * ColonSpacing;
        const anchorX: u32 = xc - SegThickness / 2;
        const anchorY: u32 = yc - SegThickness / 2 - ColonSpacing;
        const xp1: u32 = 0;
        const yp1: u32 = SegThickness / 2;
        const xp2: u32 = SegThickness;
        const yp2: u32 = SegThickness / 2;
        const values = try defs.allocator.alloc(bool, w * h);
        for (0..w) |y| {
            for (0..w) |x| {
                const result: bool = y + xp1 <= x + yp1 and y + x >= xp1 + yp1 and y + xp2 >= x + yp2 + 1 and y + x + 1 <= xp2 + yp2;
                values[y * w + x] = result;
                values[(y + 2 * ColonSpacing) * w + x] = result;
            }
        }
        return .{
            .canvas = canvas,
            .w = w,
            .h = h,
            .anchorX = anchorX,
            .anchorY = anchorY,
            .values = values,
        };
    }
    pub fn deinit(self: Colon) void {
        defs.allocator.free(self.values);
    }
    pub fn imprint(self: Colon) void {
        var cursorSource: u32 = 0;
        var cursorDest: u32 = self.anchorY * self.canvas.width + self.anchorX;
        const marginDest: u32 = self.canvas.width - self.w;
        for (0..self.h) |_| {
            for (0..self.w) |_| {
                if (self.values[cursorSource]) self.canvas.values[cursorDest] = true;
                cursorDest += 1;
                cursorSource += 1;
            }
            cursorDest += marginDest;
        }
    }
};

pub const Clock = struct {
    digits: [6]*Digit,
    colons: [2]*Colon,
    pub fn init(canvas: *Canvas, xc: u32, yc: u32) !Clock {
        const x = xc / 2 - 3 * SegLength - 3 * SegSpacing - SegSpacing / 2;
        const y = yc / 2 - SegLength;
        var digits: [6]*Digit = undefined;
        for (0..6) |index| {
            digits[index] = try defs.allocator.create(Digit);
            errdefer defs.allocator.destroy(digits[index]);
        }
        var colons: [2]*Colon = undefined;
        for (0..2) |index| {
            colons[index] = try defs.allocator.create(Colon);
            errdefer defs.allocator.destroy(colons[index]);
        }
        digits[0].* = try Digit.init(canvas, x, y);
        errdefer digits[0].deinit();
        digits[1].* = try Digit.init(canvas, x + 1 * SegLength + 1 * SegSpacing, y);
        errdefer digits[1].deinit();
        colons[0].* = try Colon.init(canvas, x + 2 * SegLength + 2 * SegSpacing, yc / 2);
        errdefer colons[0].deinit();
        digits[2].* = try Digit.init(canvas, x + 2 * SegLength + 3 * SegSpacing, y);
        errdefer digits[2].deinit();
        digits[3].* = try Digit.init(canvas, x + 3 * SegLength + 4 * SegSpacing, y);
        errdefer digits[3].deinit();
        colons[1].* = try Colon.init(canvas, x + 4 * SegLength + 5 * SegSpacing, yc / 2);
        errdefer colons[1].deinit();
        digits[4].* = try Digit.init(canvas, x + 4 * SegLength + 6 * SegSpacing, y);
        errdefer digits[4].deinit();
        digits[5].* = try Digit.init(canvas, x + 5 * SegLength + 7 * SegSpacing, y);
        errdefer digits[5].deinit();
        return .{ .digits = digits, .colons = colons };
    }
    pub fn deinit(self: Clock) void {
        for (0..6) |index| {
            self.digits[index].deinit();
            defs.allocator.destroy(self.digits[index]);
        }
        for (0..2) |index| {
            self.colons[index].deinit();
            defs.allocator.destroy(self.colons[index]);
        }
    }
    pub fn imprint(self: Clock, hour: u8, minute: u8, second: u8) void {
        self.digits[0].imprint(hour / 10);
        self.digits[1].imprint(hour % 10);
        self.digits[2].imprint(minute / 10);
        self.digits[3].imprint(minute % 10);
        self.digits[4].imprint(second / 10);
        self.digits[5].imprint(second % 10);
        self.colons[0].imprint();
        self.colons[1].imprint();
    }
};
