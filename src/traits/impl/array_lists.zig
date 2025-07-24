const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    alignment: ?alignment.Other = null,
    item: z.Trait = .no_trait,
    managed: ?bool = null,
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.default(T, "is-array-list", "The type must be an array list.");

        const has_items = z.Trait.isStruct(.{
            .field_count = .least_items,
            .fields = .one(.{
                .name = "items",
                .trait = .isKind(.pointer),
            }),
        });

        const not_an_array_list = r.failWith(.{
            .@"error" = error.NotAnArrayList,
            .expect = "The type must come from an `std.ArrayList` kind of function.",
        });

        if (!has_items.check(T))
            return not_an_array_list;

        const Items = @FieldType(T, "items");
        const info = @typeInfo(Items).pointer;

        if (!std.math.isPowerOfTwo(info.alignment))
            return not_an_array_list;

        const actual_managed = T == std.ArrayListAligned(info.child, .fromByteUnits(info.alignment));
        const actual_unmanaged = T == std.ArrayListAlignedUnmanaged(info.child, .fromByteUnits(info.alignment));

        if (!actual_managed and !actual_unmanaged)
            return not_an_array_list;

        if (o.managed) |expect_managed| if (actual_managed != expect_managed) return r.failWith(.{
            .@"error" = if (actual_managed) error.IsManaged else error.IsUnmanaged,
            //.option = if (actual_managed) "managed" else "unmanaged",
            .expect = z.fmt(
                "The type must be the {s}managed version of array list.",
                .{if (expect_managed) "" else "un"},
            ),
            .actual = z.fmt(
                "The type is the {s}managed version of array list.",
                .{if (actual_managed) "" else "un"},
            ),
        });

        if (r.propagateFail(Items, .isPointer(.{ .alignment = o.alignment }), .{
            //.option = .withTraitName("{s}"),
            // TODO: .expect = ...
        })) |fail| return fail;

        if (r.propagateFail(info.child, o.item, .{
            //.option = .withTraitName("item => {s}"),
            //.expect = .withTraitName("The type of the items must satisfy the trait `{s}`."),
        })) |fail| return fail;

        return r;
    }
}
