failure: ?Failure = null,
trace: Trace = .{},
info: Info,

const std = @import("std");
const type_name = @import("type_name.zig");
const z = @import("../root.zig");

const Result = @This();
const WriteError = std.Io.Writer.Error;

pub fn init(comptime T: type, generic_trait_name: []const u8, generic_expectation: []const u8) Result {
    return Result{
        .info = Info{
            .type = type_name.of(T, .max),
            .expect = generic_expectation,
            .trait = generic_trait_name,
        },
    };
}

pub fn isPassing(r: Result) bool {
    return r.failure == null;
}

pub fn isFailing(r: Result) bool {
    return r.failure != null;
}

pub fn failWith(comptime r: Result, comptime fw: FailWith) Result {
    comptime {
        r.compileErrorOn(.fail);
        const info = Info.from(fw.expect, fw.option, r);
        return Result{
            .trace = r.trace.with(info),
            .info = info,
            .failure = Failure{
                .@"error" = fw.@"error",
                .actual = fw.actual,
                .repair = fw.repair,
            },
        };
    }
}
pub const FailWith = struct {
    @"error": anyerror,
    actual: []const u8 = "",
    repair: []const u8 = "",
    expect: ?[]const u8 = null,
    option: ?[]const u8 = null,
};

pub fn propagateFailResult(comptime r1: Result, comptime r2: Result, comptime pri: PropagateResultInfo) ?Result {
    comptime {
        r1.compileErrorOn(.fail);
        const info = Info.from(
            pri.expect,
            pri.option,
            r1,
        );
        return if (r2.failure) |f| Result{
            .failure = f,
            .info = info,
            .trace = .with(.combine(r1.trace, r2.trace), info),
        } else null;
    }
}
pub const PropagateResultInfo = struct {
    expect: ?[]const u8 = null,
    option: ?[]const u8 = null,
};
pub fn propagateFail(
    comptime r: Result,
    comptime T: type,
    comptime t: z.Trait,
    comptime pi: PropagateInfo,
) ?Result {
    comptime {
        r.compileErrorOn(.fail);
        const r2 = t.result(T);
        return r.propagateFailResult(r2, .{
            .expect = if (pi.expect) |expect| expect.resolve(r2) else null,
            .option = if (pi.option) |option| option.resolve(r2) else null,
        });
    }
}
pub const PropagateInfo = struct {
    expect: ?Resolvable = null,
    option: ?Resolvable = null,

    pub const Resolvable = struct {
        string: []const u8,
        args: []const Resolve,

        const Resolve = enum {
            expect,
            type,
            trait,
        };

        pub fn resolve(comptime resolvable: Resolvable, comptime result: Result) []const u8 {
            comptime {
                var args: std.meta.Tuple(&[_]type{[]const u8} ** resolvable.args.len) = undefined;

                for (resolvable.args, &args) |into, *resolved| {
                    resolved.* = switch (into) {
                        .expect => result.info.expect,
                        .trait => result.info.trait,
                        .type => result.info.type,
                    };
                }

                return z.fmt(resolvable.string, args);
            }
        }

        pub fn str(string: []const u8) Resolvable {
            return .fmtMany(string, &.{});
        }

        pub fn fmtOne(string: []const u8, arg: Resolve) Resolvable {
            return .fmtMany(string, &.{arg});
        }

        pub fn fmtMany(string: []const u8, args: []const Resolve) Resolvable {
            return .{ .string = string, .args = args };
        }
    };
};

pub const Failure = struct {
    @"error": anyerror,
    actual: []const u8 = "",
    repair: []const u8 = "",

    pub fn format(f: Failure, w: *std.Io.Writer) WriteError!void {
        try w.print("[trait error ({[error]t})] {[actual]s}\n    {[repair]s}", f);
    }
};

pub const Trace = struct {
    stack: []const Info = &.{},

    fn with(comptime t: Trace, comptime i: Info) Trace {
        return Trace{ .stack = &[_]Info{i} ++ t.stack };
    }

    fn combine(comptime t1: Trace, comptime t2: Trace) Trace {
        return Trace{ .stack = t1.stack ++ t2.stack };
    }

    pub fn format(t: Trace, w: *std.Io.Writer) WriteError!void {
        for (t.stack) |info|
            try w.print("{f}\n", .{info});
    }
};

pub const Info = struct {
    expect: []const u8,
    trait: []const u8,
    type: []const u8,

    pub fn format(i: Info, w: *std.Io.Writer) WriteError!void {
        try w.print("[trait info] `{[type]s}` => `{[trait]s}`.\n    {[expect]s}", i);
    }

    fn from(expect: ?[]const u8, option: ?[]const u8, r: Result) Info {
        return Info{
            .expect = expect orelse r.info.expect,
            .trait = r.info.trait ++ if (option) |o| "[" ++ o ++ "]" else "",
            .type = r.info.type,
        };
    }
};

pub fn format(r: Result, w: *std.Io.Writer) WriteError!void {
    if (r.failure) |f|
        try w.print("{f}{f}", .{ r.trace, f })
    else
        w.print("{f}", .{r.info});
}

inline fn compileErrorOn(comptime r: Result, comptime p_or_f: enum { pass, fail }) void {
    comptime if (r.isPassing() == (p_or_f == .pass)) z.compileError(
        \\This function is meant to be used on a {s} result.
    , .{switch (p_or_f) {
        .pass => "failing",
        .fail => "passing",
    }});
}
