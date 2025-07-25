const z = @import("../../root.zig");

pub fn uMustBeT(comptime U: type, comptime T: type) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            U,
            "is",
            "The type must be `" ++ @typeName(T) ++ "`.",
        );
        return if (U == T) r else r.failWith(.{
            .@"error" = error.WrongType,
            .actual = "The type is `" ++ @typeName(U) ++ "`.",
            .option = @typeName(T),
        });
    }
}
