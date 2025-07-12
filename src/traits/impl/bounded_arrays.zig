const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    alignment: alignment.OtherAlignment = .no_option,
    capacity: z.Range(.inner) = .{},
    item: z.Trait = .no_trait,
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            "is-bounded-array",
            "The type must come from the `std.BoundedArray` or the `std.BoundedArrayAligned` function.",
        );

        const not_bounded_array = r.withFailure(.{ .@"error" = error.NotBoundedArray });

        if (!z.Trait.isStruct(.{
            .field_count = .{ .exact = 2 },
            .fields = .one(.{ .name = "buffer", .trait = .isKind(.array) }),
        }).check(T)) return not_bounded_array;

        const actual_align = @typeInfo(T).@"struct".fields[0].alignment;
        const array_info = @typeInfo(@FieldType(T, "buffer")).array;

        const ActualItem = array_info.child;
        const actual_capacity = array_info.len;

        if (T != std.BoundedArrayAligned(ActualItem, .fromByteUnits(actual_align), actual_capacity))
            return not_bounded_array;

        if (r.propagateFail(ActualItem, o.item, .{
            .option = .withTraitName("Item => {s}"),
            .expect = .withTraitName("The type of the bounded array's items must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (o.capacity.first) |first| if (actual_capacity < first) return r.withFailure(.{
            .@"error" = error.CapacityTooSmall,
            .option = z.fmt("{} <= cap", .{first}),
            .expect = z.fmt("The capacity of the bounded array must be at least {}.", .{first}),
            .actual = z.fmt("The capacity of the bounded array is {}.", .{actual_capacity}),
        });

        if (o.capacity.last) |last| if (last < actual_capacity) return r.withFailure(.{
            .@"error" = error.CapacityTooBig,
            .option = z.fmt("cap <= {}", .{last}),
            .expect = z.fmt("The capacity of the bounded array must be at most {}.", .{last}),
            .actual = z.fmt("The capacity of the bounded array is {}.", .{actual_capacity}),
        });

        if (r.propagateFail(T, .isStruct(.{
            .field_count = .{ .least = 1 },
            .fields = .one(.{ .name = "buffer", .alignment = o.alignment }),
        }), .{})) |fail| return fail;

        return r;
    }
}
