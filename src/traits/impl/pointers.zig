const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    address_space: ?std.builtin.AddressSpace = null,
    alignment: ?alignment.Other = null,
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

        if (o.size) |size| if (size != info.size) return r.failWith(.{
            .@"error" = error.WrongSize,
            .option = z.fmt("size-{s}", .{@tagName(size)}),
            .expect = z.fmt("The pointer's size must be `.{s}`.", .{@tagName(size)}),
            .actual = z.fmt("The pointer's size is `.{s}`.", .{@tagName(info.size)}),
        });

        if (o.address_space) |address_space| if (address_space != info.address_space) return r.failWith(.{
            .@"error" = error.WrongAddressSpace,
            .option = z.fmt("address-space-{s}", .{@tagName(address_space)}),
            .expect = z.fmt("The address space must be `{s}`.", .{@tagName(address_space)}),
            .actual = z.fmt("The address space is `{s}`.", .{@tagName(info.address_space)}),
        });

        if (o.is_allowzero) |is_allowzero| switch (is_allowzero) {
            true => if (!info.is_allowzero) return r.failWith(.{
                .@"error" = error.PointerForbidZero,
                .option = "allow-zero",
                .expect = "The pointer must allow zero as a valid pointer.",
            }),
            false => if (info.is_allowzero) return r.failWith(.{
                .@"error" = error.PointerAllowZero,
                .option = "forbid-zero",
                .expect = "The pointer must forbid zero as a valid pointer.",
            }),
        };

        if (o.is_const) |is_const| switch (is_const) {
            true => if (!info.is_const) return r.failWith(.{
                .@"error" = error.PointerToVar,
                .option = "var",
                .expect = "The pointer must allow mutation of the value it points to.",
            }),
            false => if (info.is_const) return r.failWith(.{
                .@"error" = error.PointerToConst,
                .option = "const",
                .expect = "The pointer must forbid mutation of the value it points to.",
            }),
        };

        if (o.is_volatile) |is_volatile| switch (is_volatile) {
            true => if (!info.is_volatile) return r.failWith(.{
                .@"error" = error.PointerIsNotVolatile,
                .option = "volatile",
                .expect = "The pointer must be volatile.",
            }),
            false => if (info.is_volatile) return r.failWith(.{
                .@"error" = error.PointerIsVolatile,
                .option = "non-volatile",
                .expect = "The pointer must not be volatile.",
            }),
        };

        if (o.has_sentinel) |has_sentinel| switch (has_sentinel) {
            true => if (info.sentinel_ptr == null) return r.failWith(.{
                .@"error" = error.PointerLacksSentinel,
                .option = "with-sentinel",
                .expect = "The pointer must have a sentinel.",
            }),
            false => if (info.sentinel_ptr != null) return r.failWith(.{
                .@"error" = error.PointerHasSentinel,
                .option = "wout-sentinel",
                .expect = "The pointer must not have a sentinel.",
            }),
        };

        if (r.propagateFail(info.child, o.child, .{
            .option = .fmtOne(".* => {s}", .trait),
            .expect = .fmtOne("The type it points to must satisfy the `{s}` trait.", .trait),
        })) |fail| return fail;

        if (o.alignment) |expect_align| {
            if (r.propagateFailResult(expect_align.result(info.child, info.alignment), .{
                .option = z.fmt("{s}", .{expect_align.optionName()}),
                .expect = "The pointer alignment must satisfy the given condition.",
            })) |fail| return fail;
        }

        return r;
    }
}
