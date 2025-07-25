const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    with: Errors = .{},
    wout: Errors = .{},
    is_any: ?bool = null,

    // TODO: incorporate `is_any` into the other fields?

    pub const Errors = struct {
        names: []const []const u8 = &.{},

        pub fn lit(comptime l: @TypeOf(.enum_literal)) Errors {
            comptime return .{ .names = &.{@tagName(l)} };
        }

        pub fn lits(comptime literals: []const @TypeOf(.enum_literal)) Errors {
            comptime {
                var names: []const []const u8 = &.{};
                for (literals) |l|
                    names = names ++ &[_][]const u8{@tagName(l)};
                return .{ .names = names };
            }
        }

        pub fn err(comptime e: anyerror) Errors {
            comptime return .{ .names = &.{@errorName(e)} };
        }

        pub fn errs(comptime errors: []const anyerror) Errors {
            comptime {
                var names: []const []const u8 = &.{};
                for (errors) |e|
                    names = names ++ &[_][]const u8{@errorName(e)};
                return .{ .names = names };
            }
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-error-set", "The type must be an error set.");

        if (r.propagateFail(T, .isKind(.error_set), .{})) |fail|
            return fail;

        const info = @typeInfo(T).error_set;

        if (o.is_any) |is_any| if ((info == null) != is_any) return r.failWith(.{
            .@"error" = if (is_any) error.IsNotAnyerror else error.IsAnyerror,
            .actual = z.fmt("The error set is `{s}`.", .{@typeName(T)}),
            //.option = if (is_any) "is-any" else "is-not-any",
            .expect = z.fmt(
                "The error set {s} be `anyerror`.",
                .{if (is_any) "must" else "can't"},
            ),
        });

        for (o.with.names) |name| if (!has(info, name)) return r.failWith(.{
            .@"error" = error.MissingError,
            .expect = z.fmt("The error set must contain `error.{s}`.", .{name}),
            //.option = z.fmt("with[{s}]", .{name}),
        });

        for (o.wout.names) |name| if (has(info, name)) return r.failWith(.{
            .@"error" = error.ForbiddenError,
            .expect = z.fmt("The error set can't contain `error.{s}`.", .{name}),
            //.option = z.fmt("wout[{s}]", .{name}),
        });

        return r;
    }
}

fn has(comptime info: ?[]const std.builtin.Type.Error, comptime e: []const u8) bool {
    comptime {
        const errors = info orelse return true;
        return for (errors) |@"error"| {
            if (z.eql(u8, @"error".name, e)) break true;
        } else false;
    }
}
