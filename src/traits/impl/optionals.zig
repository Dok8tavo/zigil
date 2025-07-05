const kind = @import("kind.zig");
const z = @import("../../root.zig");

pub fn is(comptime T: type, comptime child: z.Trait) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-optional", "The type must be an optional.");
        if (r.propagateFail(T, .isKind(.optional), .{})) |fail|
            return fail;
        const info = @typeInfo(T).optional;
        return r.propagateFail(info.child, child, .{
            .option = .withTraitName("child-type[{s}]"),
            .expect = .withTraitName("The type must be an optional whose child type must satisfy the trait {s}."),
        }) orelse r;
    }
}
