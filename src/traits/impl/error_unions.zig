const kind = @import("kind.zig");
const z = @import("../../root.zig");

pub const Options = struct {
    error_set: z.Trait = .no_trait,
    payload: z.Trait = .no_trait,
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-error-union", "The type must be an error union.");

        if (kind.propagateFail(r, T, .error_union)) |fail|
            return fail;

        const info = @typeInfo(T).error_union;

        if (r.propagateFail(info.error_set, o.error_set, .{
            .option = .fmtOne("error-set => {s}", .trait),
            .expect = .fmtOne("The type's error set must satisfy the trait `{s}`", .trait),
        })) |fail| return fail;

        if (r.propagateFail(info.payload, o.payload, .{
            .option = .fmtOne("payload => {s}", .trait),
            .expect = .fmtOne("The type's payload must satisfy the trait `{s}`.", .trait),
        })) |fail| return fail;

        return r;
    }
}
