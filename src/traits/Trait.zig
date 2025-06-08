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
    comptime return std.fmt.comptimePrint("{}", .{t.diagnostic(T)});
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
test pass {
    const is_32_bytes = Trait.pass("is32Bytes", struct {
        pub fn is32Bytes(comptime T: type) bool {
            return @sizeOf(T) == 32;
        }
    }.is32Bytes);

    try is_32_bytes.expect([32]u8);
    try is_32_bytes.expect([16]u16);
    try is_32_bytes.expect(struct { u256 });

    try expectError(error.False, is_32_bytes.expect([31]u8));
    try expectError(error.False, is_32_bytes.expect(void));
}

pub const All = @import("All.zig");
pub fn all(comptime traits: []const Trait) Trait {
    return .from(All{ .traits = traits });
}
test all {
    const is_int_less_than_32 = Trait.all(&[_]Trait{ .pass("isInt", struct {
        pub fn isInt(comptime T: type) bool {
            return @typeInfo(T) == .int;
        }
    }.isInt), .pass("isLessThan32", struct {
        pub fn isLessThan32(comptime T: type) bool {
            return @bitSizeOf(T) <= 32;
        }
    }.isLessThan32) });

    try is_int_less_than_32.expect(u32);
    try is_int_less_than_32.expect(i8);

    try expectError(error.False, is_int_less_than_32.expect(u64));
    try expectError(error.False, is_int_less_than_32.expect(struct { u8 }));
}

pub const HasDeclaration = @import("HasDeclaration.zig");
pub fn hasDeclaration(comptime decl_name: []const u8) Trait {
    return .from(HasDeclaration{ .name = decl_name });
}
test hasDeclaration {
    try hasDeclaration("decl").expect(struct {
        pub const decl = undefined;
    });

    try hasDeclaration("another_decl").expect(enum {
        pub const another_decl = undefined;
    });

    try hasDeclaration("again").expect(opaque {
        pub var again = null;
    });

    try hasDeclaration("the last one").expect(union {
        pub const @"the last one" = unreachable;
    });

    try expectError(error.IsTuple, hasDeclaration("").expect(struct { u32 }));
    try expectError(error.MissingDeclaration, hasDeclaration("nope").expect(struct {
        const is_nope = false;
    }));
}

// === Specific Traits ===
pub const is_a_type = Trait.from(@import("is_a_type.zig"));
pub const is_container = Trait.from(@import("is_container.zig"){});
test is_container {
    try is_container.expect(struct {});
    try is_container.expect(union {});
    try is_container.expect(enum {});
    try is_container.expect(opaque {});

    try expectError(error.IsTuple, is_container.expect(struct { u8 }));
    try expectError(error.IsInt, is_container.expect(u8));
    try expectError(error.IsVoid, is_container.expect(void));
    try expectError(error.IsPointer, is_container.expect(*struct {}));
}

// === Utils ===
fn from(comptime impl: anytype) Trait {
    return Trait{ .impl = .from(impl) };
}

const expectError = std.testing.expectError;
const fmt = std.fmt.comptimePrint;
