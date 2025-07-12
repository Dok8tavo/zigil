const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    calling_convention: ?std.builtin.CallingConvention = null,
    is_generic: ?bool = null,
    is_varargs: ?bool = null,
    return_type: Return = .{},
    params: []const Param = &.{},
    param_count: @import("options.zig").Count = .no_option,

    pub const Return = struct {
        is_generic: ?bool = null,
        trait: z.Trait = .no_trait,
    };

    pub const Param = struct {
        is_noalias: ?bool = null,
        is_generic: ?bool = null,
        trait: z.Trait = .no_trait,
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-function", "The type must be a function.");

        if (r.propagateFail(T, .isKind(.@"fn"), .{})) |fail|
            return fail;

        const info = @typeInfo(T).@"fn";

        if (o.calling_convention) |cc| if (!info.calling_convention.eql(cc)) return r.withFailure(.{
            .@"error" = error.WrongCallingConvention,
            .expect = z.fmt("The calling convention must be {any}.", .{cc}),
        });

        if (o.is_generic) |is_generic| if (info.is_generic != is_generic) return r.withFailure(.{
            .@"error" = if (is_generic) error.IsNotGeneric else error.IsGeneric,
            .expect = z.fmt("The function type {s} be generic.", .{if (is_generic) "must" else "can't"}),
            .actual = z.fmt("The function type {s} generic.", .{if (is_generic) "isn't" else "is"}),
            .option = z.fmt("is{s}generic", .{if (is_generic) "-" else "-not-"}),
        });

        if (o.is_varargs) |is_varargs| if (info.is_varargs != is_varargs) return r.withFailure(.{
            .@"error" = if (is_varargs) error.IsNotVariadic else error.IsVariadic,
            .expect = z.fmt("The function type {s} be variadic.", .{if (is_varargs) "must" else "can't"}),
            .actual = z.fmt("The function type {s} variadic.", .{if (is_varargs) "isn't" else "is"}),
            .option = z.fmt("is{s}variadic", .{if (is_varargs) "-" else "-not-"}),
        });

        if (o.return_type.is_generic) |is_generic| if ((info.is_generic == null) != is_generic) return r.withFailure(.{
            .@"error" = if (is_generic) error.ReturnIsNotGeneric else error.ReturnIsGeneric,
            .expect = z.fmt("The return type {} be generic.", .{if (is_generic) "must" else "can't"}),
            .actual = z.fmt("The return type {s} generic.", .{if (is_generic) "isn't" else "is"}),
            .option = z.fmt("{s}generic-return", .{if (is_generic) "" else "non-"}),
        });

        if (info.return_type) |Return| if (r.propagateFail(Return, o.return_type.trait, .{
            .option = .withTraitName("return => {s}"),
            .expect = .withTraitName("The return type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        param_count: switch (o.param_count) {
            .no_option => {},
            .exact_items => continue :param_count .{ .exact = o.params.len },
            .least_items => continue :param_count .{ .least = o.params.len },
            .exact => |exact| if (exact != info.params.len) return r.withFailure(.{
                .@"error" = error.WrongParamCount,
                .option = z.fmt("param-count == {}", .{exact}),
                .expect = z.fmt("The parameter count must be exactly {}.", .{exact}),
                .actual = z.fmt("The parameter count is {}.", .{info.params.len}),
            }),
            .least => |least| if (info.params.len < least) return r.withFailure(.{
                .@"error" = error.TooFewParams,
                .option = z.fmt("param-count >= {}", .{least}),
                .expect = z.fmt("The parameter count must be at least {}.", .{least}),
                .actual = z.fmt("The parameter count is {}.", .{info.params.len}),
            }),
        }

        const len = @min(o.params.len, info.params.len);
        for (0..len) |i| {
            const expect = o.params[i];
            const actual = info.params[i];

            if (expect.is_generic) |is_generic| if (is_generic != actual.is_generic) return r.withFailure(.{
                .@"error" = if (is_generic) error.ParamIsNotGeneric else error.ParamIsGeneric,
                .option = z.fmt("param-{}[{s}generic]", .{ i, if (is_generic) "" else "not-" }),
                .expect = z.fmt("The parameter {} {s} be generic.", .{ i, if (is_generic) "must" else "can't" }),
                .actual = z.fmt("The parameter {} {s} generic.", .{ i, if (is_generic) "isn't" else "is" }),
            });

            if (expect.is_noalias) |is_noalias| if (is_noalias != actual.is_noalias) return r.withFailure(.{
                .@"error" = if (is_noalias) error.ParamIsNotNoalias else error.ParamIsNoalias,
                .option = z.fmt("param-{}[{s}noalias]", .{ i, if (is_noalias) "" else "not-" }),
                .expect = z.fmt("The parameter {} {s} be noalias.", .{ i, if (is_noalias) "must" else "can't" }),
                .actual = z.fmt("The parameter {} {s} noalias.", .{ i, if (is_noalias) "isn't" else "is" }),
            });

            if (actual.type) |Param| if (r.propagateFail(Param, expect.trait, .{
                .option = .withTraitName("param => {s}"),
                .expect = .withTraitName("The parameter type must satisfy the trait `{s}`."),
            })) |fail| return fail;
        }

        return r;
    }
}
