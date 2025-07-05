// MIT License
//
// Copyright (c) 2025 Dok8tavo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

const std = @import("std");

pub const Trait = @import("traits/Trait.zig");

pub const fmt = std.fmt.comptimePrint;

pub inline fn compileError(comptime format: []const u8, comptime args: anytype) noreturn {
    @compileError(std.fmt.comptimePrint(format, args));
}

pub const Comptype = struct {
    type: type,
    value: *const anyopaque,

    pub fn get(comptime c: Comptype, comptime t: Trait) c.type {
        t.assert(c.type);
        comptime return @ptrCast(@alignCast(c.value));
    }

    pub fn getOrErr(comptime c: Comptype, comptime t: Trait) anyerror!c.type {
        try t.expect(c.type);
        return c.type;
    }

    pub fn getOrNull(comptime c: Comptype, comptime t: Trait) ?c.type {
        return if (t.check(c.type)) c.type else null;
    }

    pub fn from(comptime anyvalue: anytype) Comptype {
        comptime return .{
            .type = @TypeOf(anyvalue.*),
            .value = anyvalue,
        };
    }
};

/// The purpose of this function is to consume less of the evaluation quota than the `std.mem.eql`
/// implementation.
pub inline fn eql(comptime T: type, comptime a: []const T, comptime b: []const T) bool {
    comptime {
        if (a.len != b.len) return false;
        if (a.ptr == b.ptr) return true;

        const V = @Vector(a.len, T);

        const a_vec: *const V = @alignCast(@ptrCast(a));
        const b_vec: *const V = @alignCast(@ptrCast(b));

        return @reduce(.And, @as(V, a_vec.*) == @as(V, b_vec.*));
    }
}
test eql {
    try std.testing.expect(comptime eql(u8, "Hello", "Hello"));
    try std.testing.expect(!comptime eql(u8, "Goodbye", "Tschüss!"));
}

pub fn Range(comptime fold: enum { inner, outer }) type {
    return struct {
        // first <= last
        first: ?comptime_int = null,
        last: ?comptime_int = null,

        pub fn from(comptime int: comptime_int) Range(fold) {
            comptime return switch (fold) {
                .inner => .{ .first = int },
                .outer => .{ .last = int },
            };
        }

        pub fn until(comptime int: comptime_int) Range(fold) {
            comptime return switch (fold) {
                .inner => .{ .last = int },
                .outer => .{ .first = int },
            };
        }

        pub fn range(comptime a: comptime_int, comptime b: comptime_int) Range(fold) {
            comptime return .{
                .first = @min(a, b),
                .last = @max(a, b),
            };
        }

        pub fn has(comptime r: Range(fold), comptime a: comptime_int) bool {
            comptime {
                if (fold == .outer)
                    return !(Range(.inner){ .first = r.first, .last = r.last }).has(a);
                if (r.first) |first|
                    if (a < first)
                        return false;
                if (r.last) |last|
                    if (last < a)
                        return false;
                return true;
            }
        }
    };
}

test {
    _ = Trait;
}
