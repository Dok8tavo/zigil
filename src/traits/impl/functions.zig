const kind = @import("kind.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    calling_convention: ?std.builtin.CallingConvention = null,
    is_generic: ?bool = null,
    is_variadic: ?bool = null,
    return_type: Return = .{},
    params: Params = .no_requirement,

    pub const Return = struct {
        is_generic: ?bool = null,
        trait: z.Trait = .no_trait,
    };

    pub const Params = struct {
        slice: ?[]const Param,

        pub const no_requirement = Params{ .slice = null };

        pub fn one(comptime p: Param) Params {
            return Params{ .slice = &[_]Param{p} };
        }

        pub fn many(comptime slice: []const Param) Params {
            return Params{ .slice = slice };
        }
    };

    pub const Param = struct {
        is_noalias: ?bool = null,
        is_generic: ?bool = null,
        trait: z.Trait = .no_trait,
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            "is-function",
            "The type must be a function.",
        );

        if (kind.propagateFail(r, T, .@"fn")) |fail|
            return fail;

        const info = @typeInfo(T).@"fn";

        if (o.calling_convention) |cc| if (!info.calling_convention.eql(cc)) return r.failWith(.{
            .@"error" = error.WrongCallingConvention,
            .expect = z.fmt("The calling convention must be `{any}`.", .{cc}),
            .option = z.fmt("callconv {any}", .{cc}),
        });

        if (o.is_generic) |is_generic| if (info.is_generic != is_generic) switch (is_generic) {
            true => return r.failWith(.{
                .@"error" = error.IsNonGeneric,
                .expect = "The function must be generic.",
                .option = "generic",
            }),
            false => return r.failWith(.{
                .@"error" = error.IsGeneric,
                .expect = "The function must not be generic.",
                .option = "non-generic",
            }),
        };

        if (o.is_variadic) |is_var_args| if (info.is_var_args != is_var_args) switch (is_var_args) {
            true => return r.failWith(.{
                .@"error" = error.IsNonVariadic,
                .expect = "The function must be variadic.",
                .option = "variadic",
            }),
            false => return r.failWith(.{
                .@"error" = error.IsVariadic,
                .expect = "The function must not be variadic.",
                .option = "non-variadic",
            }),
        };

        if (o.return_type.is_generic) |is_generic| switch (is_generic) {
            true => if (!info.is_generic) return r.failWith(.{
                .@"error" = error.ReturnIsNonGeneric,
                .expect = "The return type must be generic.",
                .option = "generic-return",
            }),
            false => if (info.is_generic) return r.failWith(.{
                .@"error" = error.ReturnIsGeneric,
                .expect = "The return type must not be generic.",
                .option = "non-generic-return",
            }),
        };

        if (info.return_type) |Return| if (r.propagateFail(Return, o.return_type.trait, .{
            .option = .fmtOne("return => {s}", .trait),
            .expect = .fmtOne("The return type must satisfy the trait `{s}`.", .trait),
        })) |fail| return fail;

        const params = o.params.slice orelse return r;

        if (params.len != info.params.len) return r.failWith(.{
            .@"error" = error.WrongParameterCount,
            .expect = z.fmt("The function must take {} parameters.", .{params.len}),
            .actual = z.fmt("The function takes {} parameters.", .{info.params.len}),
            .option = z.fmt("params-{}", .{params.len}),
        });

        for (params, info.params, 0..) |expect, actual, i| {
            if (expect.is_generic) |is_generic| switch (is_generic) {
                true => if (!actual.is_generic) return r.failWith(.{
                    .@"error" = error.ParamIsNonGeneric,
                    .option = z.fmt("param-{}-generic", .{i}),
                    .expect = z.fmt("The parameter {} must be generic.", .{i}),
                }),
                false => if (actual.is_generic) return r.failWith(.{
                    .@"error" = error.ParamIsGeneric,
                    .option = z.fmt("param-{}-non-generic", .{i}),
                    .expect = z.fmt("The parameter {} must not be generic.", .{i}),
                }),
            };

            if (expect.is_noalias) |is_noalias| switch (is_noalias) {
                true => if (!actual.is_noalias) return r.failWith(.{
                    .@"error" = error.ParamIsAlias,
                    .option = z.fmt("param-{}-alias", .{i}),
                    .expect = z.fmt("The parameter {} must be noalias.", .{i}),
                }),
                false => if (actual.is_noalias) return r.failWith(.{
                    .@"error" = error.ParamIsNoalias,
                    .option = z.fmt("param-{}-noalias", .{i}),
                    .expect = z.fmt("The parameter {} must not be noalias.", .{i}),
                }),
            };

            if (actual.type) |Param| if (r.propagateFail(Param, expect.trait, .{
                .option = .fmtOne(
                    z.fmt("param-{}", .{i}) ++ " => {s}",
                    .trait,
                ),
                // TODO: what's wrong with this quota?
                .expect = .fmtOne(
                    z.fmt("The parameter {}", .{i}) ++ " must satisfy the trait `{s}`.",
                    .trait,
                ),
            })) |fail| return fail;
        }

        return r;
    }
}
