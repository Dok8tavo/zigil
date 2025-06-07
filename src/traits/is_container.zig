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

const Diagnostic = @import("Diagnostic.zig");
const Trait = @import("Trait.zig");

const fmt = std.fmt.comptimePrint;

const name = "is_container";
const expect_message = "The type must be a container, a type that can held declarations.";

pub fn diagnostic(comptime _: @This(), comptime T: type) Diagnostic {
    const info = @typeInfo(T);
    const success = Diagnostic.default(T).withName(name);
    return switch (info) {
        .@"union", .@"enum", .@"opaque" => success,
        .@"struct" => |@"struct"| if (!@"struct".is_tuple) success else fail(
            T,
            "a tuple",
            error.IsTuple,
            "Consider naming its elements to make a struct instead.",
        ),
        .enum_literal => fail(T, "the enum literal type", error.IsEnumLiteral, null),
        .vector => fail(T, "a vector type", error.IsVector, null),
        .@"anyframe" => fail(T, "the anyframe type", error.IsAnyframe, null),
        .frame => fail(T, "a frame type", error.IsFrame, null),
        .@"fn" => fail(T, "a function type", error.IsFunction, null),
        .error_set => fail(T, "an error set", error.IsError, null),
        .error_union => |error_union| fail(
            T,
            "an error union",
            error.IsErrorUnion,
            if (Trait.is_container.check(error_union.payload))
                "Consider asserting that no error can happen."
            else
                null,
        ),
        .optional => |optional| fail(
            T,
            "an optional",
            error.IsOptional,
            if (Trait.is_container.check(optional.payload))
                "Consider asserting that it isn't `null`."
            else
                null,
        ),
        .null => fail(T, "the null type", error.IsNull, null),
        .undefined => fail(T, "the undefined type", error.IsUndefined, null),
        .comptime_float => fail(T, "the comptime floating point type", error.IsComptimeFloat, null),
        .comptime_int => fail(
            T,
            "the comptime integer type",
            error.IsComptimeInt,
            "Consider wrapping it into an `enum(comptime_int) { _ }` type.",
        ),
        .array => fail(
            T,
            "an array type",
            error.IsArray,
            "Consider naming the elements and make it a struct.",
        ),
        .pointer => |pointer| fail(
            T,
            "a pointer type",
            error.IsPointer,
            if (pointer.size == .one and Trait.is_container.check(pointer.child))
                "Consider dereferencing the pointer."
            else
                null,
        ),
        .float => fail(T, "a floating point type", error.IsFloat, null),
        .int => fail(
            T,
            "an integer type",
            error.IsInt,
            fmt("Consider wrapping it into an `enum({s}) {{ _ }}` instead.", .{@typeName(T)}),
        ),
        .noreturn => fail(T, "the noreturn type", error.IsNoReturn, null),
        .bool => fail(
            T,
            "the boolean type",
            error.IsBool,
            "Consider using an `enum { true, false }` instead.",
        ),
        .void => fail(T, "the void type", error.IsVoid, "Consider using a namespace instead."),
        .type => fail(T, "the type type", error.IsType, null),
    };
}

fn fail(
    comptime T: type,
    comptime info: []const u8,
    comptime error_code: anyerror,
    comptime repair: ?[]const u8,
) Diagnostic {
    return Diagnostic{
        .type = T,
        .error_code = error_code,
        .expect = expect_message,
        .status = fmt("The type is {s}, and can't held declarations.", .{info}),
        .repair = repair,
        .name = name,
    };
}
