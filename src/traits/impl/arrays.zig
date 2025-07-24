const z = @import("../../root.zig");

pub const Options = struct {
    child: z.Trait = .no_trait,
    length: z.Range(.inner) = .{},
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.default(T, "is-array", "The type must be an array.");

        if (r.propagateFail(T, .isKind(.array), .{})) |fail|
            return fail;

        const info = @typeInfo(T).array;

        if (r.propagateFail(info.child, o.child, .{
            //.option = .withTraitName("child => {s}"),
            //.expect = .withTraitName("The array's child type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (o.length.first) |first| if (info.len < first) return r.failWith(.{
            .@"error" = error.TooShort,
            //.option = z.fmt("len <= {}", .{first}),
            .expect = z.fmt("The length of the array must be at least {}.", .{first}),
            .actual = z.fmt("The length of the array is {}.", .{first}),
        });

        if (o.length.last) |last| if (last < info.len) return r.failWith(.{
            .@"error" = error.TooLong,
            //.option = z.fmt("{} <= len"),
            .expect = z.fmt("The length of the array must be at most {}.", .{last}),
            .actual = z.fmt("The length of the array is {}.", .{last}),
        });

        return r;
    }
}
