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
color: bool = true,

const root = @import("../root.zig");
const std = @import("std");

const AnyValue = @import("../AnyValue.zig");
const Diagnostic = @import("Diagnostic.zig");
const Trait = @This();

// === Use Traits ===
pub inline fn diagnostic(comptime t: Trait, comptime T: type) Diagnostic {
    // TODO: use a `Diagnostic` instance to simulate traits usage
    // TODO: check that the diagnostic does have `T` as its `.type` field!
    comptime return t.impl.get().diagnostic(T);
}

pub inline fn expect(comptime t: Trait, comptime T: type) anyerror!void {
    // TODO: check that the diagnostic does have `T` as its `.type` field!
    comptime {
        if (t.diagnostic(T).error_code) |error_code|
            return error_code;
    }
}

pub inline fn message(comptime t: Trait, comptime T: type) []const u8 {
    comptime return std.fmt.comptimePrint(if (t.color) "{}" else "{no-color}", .{t.diagnostic(T)});
}

pub inline fn check(comptime t: Trait, comptime T: type) bool {
    // TODO: check that the diagnostic does have `T` as its `.type` field!
    comptime return t.diagnostic(T).error_code == null;
}

pub inline fn assert(comptime t: Trait, comptime T: type) void {
    comptime {
        if (!t.check(T)) @compileError(t.message(T));
    }
}

// === Make Traits ===
pub const Pass = @import("Pass.zig");
pub fn pass(comptime name: []const u8, comptime condition: fn (comptime type) bool) Trait {
    return .from(Pass{ .name = name, .condition = condition });
}

pub const All = @import("All.zig");
pub fn all(comptime traits: []const Trait) Trait {
    return .from(All{ .traits = traits });
}

pub const HasDecl = @import("HasDecl.zig");
pub fn hasDecl(comptime decl_name: []const u8) Trait {
    return .from(HasDecl{ .name = decl_name });
}

// === Specific Traits ===
pub const is_container = Trait.from(@import("is_container.zig"){});

// === Utils ===

fn from(comptime impl: anytype) Trait {
    return Trait{ .impl = .from(impl) };
}

const fmt = std.fmt.comptimePrint;
