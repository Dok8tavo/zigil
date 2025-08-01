const std = @import("std");
const z = @import("../../root.zig");

pub fn is(comptime T: type, comptime kind: std.builtin.TypeId) z.Trait.Result {
    comptime {
        const actual = @typeInfo(T);
        const r = z.Trait.Result.init(
            T,
            "is-kind",
            "The type must be " ++ denomination(kind) ++ ".",
        );

        return switch (@typeInfo(T)) {
            kind => r,
            else => r.failWith(.{
                .@"error" = @"error"(actual),
                .option = "." ++ @tagName(kind),
                .actual = "The type actually is " ++ denomination(actual) ++ ".",
            }),
        };
    }
}

pub fn denomination(comptime kind: std.builtin.TypeId) []const u8 {
    comptime return switch (kind) {
        .type,
        .void,
        .bool,
        .noreturn,
        .comptime_int,
        .comptime_float,
        => "`" ++ @tagName(kind) ++ "`",
        .undefined,
        .null,
        => "`@TypeOf(" ++ @tagName(kind) ++ ")`",
        .int => "an integer",
        .float => "a floating point",
        .@"struct" => "a struct",
        .array => "an array",
        .vector => "a vector",
        .@"enum" => "an enum",
        .enum_literal => "an enum literal",
        .error_set => "an error set",
        .error_union => "an error union",
        .optional => "an optional",
        .@"union" => "a union",
        .@"fn" => "a function",
        .frame => "a frame",
        .@"anyframe" => "an anyframe",
        .pointer => "a pointer",
        .@"opaque" => "an opaque",
    };
}

pub fn @"error"(comptime kind: std.builtin.TypeId) anyerror {
    comptime return switch (kind) {
        .type => error.IsType,
        .void => error.IsVoid,
        .bool => error.IsBool,
        .noreturn => error.IsNoreturn,
        .comptime_int => error.IsComptimeInt,
        .comptime_float => error.IsComptimeFloat,
        .undefined => error.IsUndefinedType,
        .null => error.IsNullType,
        .int => error.IsInt,
        .float => error.IsFloat,
        .@"struct" => error.IsStruct,
        .array => error.IsArray,
        .vector => error.IsVector,
        .@"enum" => error.IsEnum,
        .enum_literal => error.IsEnumLiteral,
        .error_set => error.IsErrorSet,
        .error_union => error.IsErrorUnion,
        .optional => error.IsOptional,
        .@"union" => error.IsUnion,
        .@"fn" => error.IsFn,
        .frame => error.IsFrame,
        .@"anyframe" => error.IsAnyframe,
        .pointer => error.IsPointer,
        .@"opaque" => error.IsOpaque,
    };
}

inline fn repair(comptime expect: std.builtin.TypeId, comptime actual: std.builtin.Type) []const u8 {
    comptime {
        switch (actual) {
            .optional => |optional| if (@typeInfo(optional.child) == expect)
                return "Consider using `orelse` or `.?` on the instance.",
            .error_union => |error_union| if (@typeInfo(error_union.payload) == expect)
                return "Consider using `catch` or `try` on the instance.",
            .pointer => |pointer| if (pointer.size == .one and @typeInfo(pointer.child) == expect)
                return "Consider using `.*` on the instance.",
            .array => |array| if (array.len == 1 and @typeInfo(array.child) == expect)
                return "Consider using `instance[0]` instead of the instance.",
            .int, .comptime_int => if (expect == .@"enum")
                return "Consider wrapping it into an `enum(" ++ @typeName(@Type(actual)) ++ ")`.",
            else => {},
        }

        return "";
    }
}
