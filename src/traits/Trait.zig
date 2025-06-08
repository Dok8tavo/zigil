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

pub inline fn expectError(comptime t: Trait, comptime T: type, comptime e: anyerror) anyerror!void {
    comptime {
        try std.testing.expectError(e, t.expect(T));
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

    try is_32_bytes.expectError([31]u8, error.False);
    try is_32_bytes.expectError(void, error.False);
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

    try is_int_less_than_32.expectError(u64, error.False);
    try is_int_less_than_32.expectError(struct { u8 }, error.False);
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
        pub const again = null;
    });

    try hasDeclaration("the last one").expect(union {
        pub const @"the last one" = "Hello";
    });

    try hasDeclaration("").expectError(struct { u32 }, error.IsTuple);
    try hasDeclaration("nope").expectError(struct {
        const is_nope = false;
    }, error.MissingDeclaration);
}

pub fn hasDeclarationThat(comptime decl_name: []const u8, comptime that: Trait) Trait {
    return .from(HasDeclaration{ .name = decl_name, .trait = that });
}
test hasDeclarationThat {
    try hasDeclarationThat("container", .is_container).expect(struct {
        pub const container = std.ArrayListUnmanaged(u8){};
    });

    try hasDeclarationThat("string", .is_a_type).expectError(fn () void, error.IsFunction);
    try hasDeclarationThat("missing_declaration", .is_container)
        .expectError(struct {
        pub const not_the_declaration = "Sorry!";
    }, error.MissingDeclaration);
    try hasDeclarationThat("Int", .pass("is_int", struct {
        pub fn isInt(comptime T: type) bool {
            return @typeInfo(T) == .int;
        }
    }.isInt)).expectError(struct {
        pub const Int = f32;
    }, error.False);
}

// === Specific Traits ===
pub const is_a_type = Trait.from(@import("is_a_type.zig"){});
pub const is_container = Trait.from(@import("is_container.zig"){});
test is_container {
    try is_container.expect(struct {});
    try is_container.expect(union {});
    try is_container.expect(enum {});
    try is_container.expect(opaque {});

    try is_container.expectError(struct { u8 }, error.IsTuple);
    try is_container.expectError(u8, error.IsInt);
    try is_container.expectError(void, error.IsVoid);
    try is_container.expectError(*struct {}, error.IsPointer);
}

// === Utils ===
fn from(comptime impl: anytype) Trait {
    return Trait{ .impl = .from(impl) };
}

const fmt = std.fmt.comptimePrint;
