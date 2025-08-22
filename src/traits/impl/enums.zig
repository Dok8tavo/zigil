const z = @import("../../root.zig");

pub const Options = struct {
    fields: Fields = .no_requirement,
    is_exhaustive: ?bool = null,
    tag: z.Trait = .no_trait,

    pub const Fields = @import("fields.zig").Fields(.@"enum");
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-enum", "The type must be an enum.");
        if (r.propagateFail(T, .isKind(.@"enum"), .{})) |fail|
            return fail;

        const info = @typeInfo(T).@"enum";

        if (o.is_exhaustive) |is_exhaustive| if (is_exhaustive != info.is_exhaustive) return r.failWith(.{
            .@"error" = if (is_exhaustive) error.IsNotExhaustive else error.IsExhaustive,
            .expect = z.fmt("The enum type {s} be exhaustive.", .{if (is_exhaustive) "must" else "can't"}),
            .option = if (is_exhaustive) "is-exhaustive" else "is-not-exhaustive",
            .actual = z.fmt("The enum type {s} exhaustive.", .{if (is_exhaustive) "isn't" else "is"}),
        });

        if (r.propagateFail(info.tag_type, o.tag, .{
            .option = .fmtOne("tag => {s}", .trait),
            .expect = .fmtOne("The tag of the enum must respect the trait `{s}`.", .trait),
        })) |fail| return fail;

        if (o.fields.propagateFail(info, r)) |fail|
            return fail;

        return r;
    }
}
