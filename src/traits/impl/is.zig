const z = @import("../../root.zig");

pub fn uMustBeT(comptime U: type, comptime T: type) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(U, "is", z.fmt("The type must be `{s}`.", .{@typeName(T)}));
        return if (U == T) r else r.withFailure(.{
            .@"error" = error.WrongType,
            .actual = z.fmt("The type is `{s}`.", .{@typeName(U)}),
            .option = @typeName(T),
        });
    }
}
