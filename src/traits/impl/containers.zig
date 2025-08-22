const kind = @import("kind.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub fn is(comptime T: type) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-container", "The type must be able to contain declarations.");
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
