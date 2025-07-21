const kind = @import("kind.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub fn is(comptime T: type) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-c", "The type must be a C-compatible type.");

        return switch (@typeInfo(T)) {
            inline .@"anyframe",
            .frame,
            .null,
            .undefined,
            .comptime_int,
            .comptime_float,
            .type,
            .error_union,
            .error_set,
            .enum_literal,
            => |_, tag| r.withFailure(.{
                .@"error" = kind.@"error"(tag),
                .actual = "There's no equivalent of `." ++ @tagName(tag) ++ "` types in C.",
            }),
            .int => |info| switch (info.bits) {
                0, 8, 16, 32, 64, 128 => r,
                else => r.withFailure(.{
                    .@"error" = if (!std.math.isPositiveZero(info.bits)) error.IntNonPowerOfTwo else error.IntTooBig,
                }),
            },
            .noreturn, .float, .bool, .void => r,
            .@"union" => r.propagateFail(T, .isUnion(.{ .layout = .only(.@"extern") }), .{}) orelse r,
            .@"struct" => r.propagateFail(T, .isStruct(.{ .layout = .only(.@"extern") }), .{}) orelse r,
            .@"fn" => r.propagateFail(T, .isFunction(.{ .calling_convention = .c }), .{}) orelse r,
            inline .array, .vector => |info| r.propagateFail(info.child, .{ .result = is }, .{
                .expect = .str(
                    "The child type of an array/vector type must be C-compatible for the array/vector type to be C-compatible.",
                ),
            }) orelse r,
            .pointer => |info| if (info == .slice) r.withFailure(.{
                .@"error" = error.IsSlice,
                .actual = "Slice pointers aren't compatible with the C ABI.",
            }) else r.propagateFail(info.child, .{ .result = is }, .{}) orelse r,
            .@"enum" => |info| r.propagateFail(info.tag_type, .{ .result = is }, .{}) orelse r,
            .@"opaque", .optional => z.compileError("Not implemented yet!", .{}),
        };
    }
}
