const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    address_space: ?std.builtin.AddressSpace = null,
    alignment: alignment.OtherAlignment = .no_option,
    child: z.Trait = .no_trait,

    has_sentinel: ?bool = null,

    is_allowzero: ?bool = null,
    is_const: ?bool = null,
    is_volatile: ?bool = null,

    size: ?std.builtin.Type.Pointer.Size = null,
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-pointer", "The type is a pointer.");

        if (r.propagateFail(T, .isKind(.pointer), .{})) |fail|
            return fail;

        const info = @typeInfo(T).pointer;

        if (o.size) |size| if (size != info.size) return r.withFailure(.{
            .@"error" = error.WrongSize,
            .option = z.fmt("size-{s}", .{@tagName(size)}),
            .expect = z.fmt("The pointer's size must be `.{s}`.", .{@tagName(size)}),
            .actual = z.fmt("The pointer's size is `.{s}`.", .{@tagName(info.size)}),
        });

        if (o.address_space) |address_space| if (address_space != info.address_space) return r.withFailure(.{
            .@"error" = error.WrongAddressSpace,
            .option = z.fmt("address-space-{s}", .{@tagName(address_space)}),
            .expect = z.fmt("The address space must be `{s}`.", .{@tagName(address_space)}),
            .actual = z.fmt("The address space is `{s}`.", .{@tagName(info.address_space)}),
        });

        if (o.is_allowzero) |is_allowzero| if (is_allowzero != info.is_allowzero) return r.withFailure(.{
            .@"error" = if (is_allowzero) error.PointerForbidZero else error.PointerAllowZero,
            .option = if (is_allowzero) "allow-zero" else "forbid-zero",
            .expect = z.fmt(
                "The pointer {s} allow zero as a valid pointer.",
                .{if (is_allowzero) "must" else "can't"},
            ),
            .actual = z.fmt(
                "The pointer {s} zero as a valid pointer.",
                .{if (is_allowzero) "forbids" else "allows"},
            ),
        });

        if (o.is_const) |is_const| if (is_const != info.is_const) return r.withFailure(.{
            .@"error" = if (is_const) error.PointerToVar else error.PointerToConst,
            .option = if (is_const) "const" else "var",
            .expect = z.fmt(
                "The pointer {s} allow mutation of the value it points to.",
                .{if (is_const) "can't" else "must"},
            ),
            .actual = z.fmt(
                "The pointer {s} mutation of the value it points to.",
                .{if (is_const) "allows" else "forbids"},
            ),
        });

        if (o.is_volatile) |is_volatile| if (is_volatile != info.is_volatile) return r.withFailure(.{
            .@"error" = if (is_volatile) error.PointerIsNotVolatile else error.PointerIsVolatile,
            .option = if (is_volatile) "volatile" else "not-volatile",
            .expect = z.fmt(
                "The pointer {s} be volatile.",
                .{if (is_volatile) "must" else "can't"},
            ),
            .actual = z.fmt(
                "The pointer {s} volatile.",
                .{if (is_volatile) "isn't" else "is"},
            ),
        });

        if (o.has_sentinel) |has_sentinel| if (has_sentinel != (info.sentinel_ptr != null)) return r.withFailure(.{
            .@"error" = if (has_sentinel) error.PointerLacksSentinel else error.PointerHasSentinel,
            .option = if (has_sentinel) "with-sentinel" else "wout-sentinel",
            .expect = z.fmt(
                "The pointer {s} have a sentinel.",
                .{if (has_sentinel) "must" else "can't"},
            ),
            .actual = z.fmt(
                "The pointer {s} a sentinel.",
                .{if (has_sentinel) "doesn't have" else "has"},
            ),
        });

        if (r.propagateFail(info.child, o.child, .{
            .option = .withTraitName(".* => {s}"),
            .expect = .withTraitName("The type it points to must satisfy the `{s}` trait."),
        })) |fail| return fail;

        alignment: switch (o.alignment) {
            .no_option => {},
            .natural => continue :alignment .{ .custom = @alignOf(info.child) },
            .least_natural => continue :alignment .{ .least_custom = @alignOf(info.child) },
            .custom => |custom| if (info.alignment != custom) return r.withFailure(.{
                .@"error" = error.WrongAlignment,
                .option = z.fmt("align == {}", .{custom}),
                .expect = z.fmt("The pointer alignment must be exactly {}.", .{custom}),
                .actual = z.fmt("The pointer alignment is {}.", .{info.alignment}),
            }),
            .least_custom => |least| if (info.alignment < least) return r.withFailure(.{
                .@"error" = error.AlignmentTooSmall,
                .option = z.fmt("align >= {}", .{least}),
                .expect = z.fmt("The pointer alignment must be at least {}.", .{least}),
                .actual = z.fmt("The pointer alignment is {}.", .{info.alignment}),
            }),
        }

        return r;
    }
}
