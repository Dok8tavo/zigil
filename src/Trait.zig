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

impl: AnyValue,
use_colors: bool = true,

const root = @import("root.zig");
const std = @import("std");

const AnyValue = @import("AnyValue.zig");
const Diagnostic = @import("Diagnostic.zig");
const Trait = @This();

// === Use Traits ===
pub fn diagnostic(comptime t: Trait, comptime T: type) Diagnostic {
    // TODO: use a `Diagnostic` instance to simulate traits usage
    // TODO: check that the diagnostic does have `T` as its `.type` field!
    return t.impl.get().diagnostic(T);
}

pub fn expect(comptime t: Trait, comptime T: type) anyerror!void {
    // TODO: check that the diagnostic does have `T` as its `.type` field!
    if (t.diagnostic(T).error_code) |error_code|
        return error_code;
}

pub fn message(comptime t: Trait, comptime T: type) []const u8 {
    return std.fmt.comptimePrint(if (t.use_colors) "{}" else "{no-color}", .{t.diagnostic(T)});
}

pub fn check(comptime t: Trait, comptime T: type) bool {
    // TODO: check that the diagnostic does have `T` as its `.type` field!
    return t.diagnostic(T).error_code == null;
}

pub inline fn assert(comptime t: Trait, comptime T: type) void {
    if (!t.check(T)) @compileError(t.message(T));
}

// === Make Traits ===
pub fn passCondition(comptime name: []const u8, comptime condition: fn (comptime type) bool) Trait {
    const Impl = struct {
        name: []const u8 = name,
        condition: fn (comptime type) bool = condition,
        expect: ?[]const u8 = null,
        status: ?[]const u8 = null,
        repair: ?[]const u8 = null,

        pub fn diagnostic(comptime impl: @This(), comptime T: type) Diagnostic {
            return if (impl.condition(T)) Diagnostic{
                .type = T,
                .trait = impl.name,
            } else Diagnostic{
                .type = T,
                .trait = impl.name,
                .error_code = error.False,
                .expect = impl.expect,
                .status = impl.status,
                .repair = impl.repair,
            };
        }
    };

    return .from(Impl{ .condition = condition });
}

fn from(comptime impl: anytype) Trait {
    return Trait{ .impl = .from(impl) };
}
