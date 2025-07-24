const z = @import("../../root.zig");

pub fn uMustBeT(comptime U: type, comptime T: type) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.default(
            U,
            "is",
            z.fmt("The type must be `{s}`.", .{@typeName(T)}),
        );
        return if (U == T) r else r.failWith(.{
            .@"error" = error.WrongType,
            .actual = z.fmt("The type is `{s}`.", .{@typeName(U)}),
            //.option = @typeName(T),
        });
    }
}
