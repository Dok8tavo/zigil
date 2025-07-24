const kind = @import("kind.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const AllowLayout = struct {
    auto: bool = true,
    @"packed": bool = true,
    @"extern": bool = true,

    pub const all = AllowLayout{};

    pub fn only(comptime cl: std.builtin.Type.ContainerLayout) AllowLayout {
        return switch (cl) {
            .auto => .{ .@"packed" = false, .@"extern" = false },
            .@"packed" => .{ .auto = false, .@"extern" = false },
            .@"extern" => .{ .auto = false, .@"packed" = false },
        };
    }

    pub fn not(comptime cl: std.builtin.Type.ContainerLayout) AllowLayout {
        return switch (cl) {
            .auto => .{ .auto = false },
            .@"packed" => .{ .@"packed" = false },
            .@"extern" => .{ .@"extern" = false },
        };
    }

    pub fn allows(comptime al: AllowLayout, comptime l: std.builtin.Type.ContainerLayout) bool {
        return @field(al, @tagName(l));
    }
};

pub fn is(comptime T: type) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.default(T, "is-container", "The type must be able to contain declarations.");
        return switch (@typeInfo(T)) {
            .@"opaque", .@"enum", .@"union" => r,
            .@"struct" => |@"struct"| if (!@"struct".is_tuple) r else r.failWith(.{
                .@"error" = error.IsTuple,
                .actual = "The type is a tuple.",
                .repair = "Consider naming its fields, to make a struct.",
            }),
            inline else => |_, k| r.failWith(.{
                .@"error" = kind.@"error"(k),
                .actual = z.fmt("The type is a {s}.", .{kind.denomination(k)}),
                .repair = switch (k) {
                    .int, .comptime_int => z.fmt("Consider wrapping it in an `enum({s})`.", .{@typeName(T)}),
                    else => "",
                },
            }),
        };
    }
}
