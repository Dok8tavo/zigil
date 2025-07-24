failure: ?Failure = null,
trace: Trace = .{},
default_expect: ?[]const u8 = null,
default_trait: ?[]const u8 = null,
default_type: ?[]const u8 = null,

const std = @import("std");
const z = @import("../root.zig");

const Result = @This();
const WriteError = std.Io.Writer.Error;

pub fn default(comptime @"type": ?type, expect: ?[]const u8, trait: ?[]const u8) Result {
    return Result{
        .default_type = if (@"type") |T| @typeName(T) else null,
        .default_expect = expect,
        .default_trait = trait,
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
        return Result{
            .failure = Failure{
                .@"error" = fw.@"error",
                .actual = fw.actual,
                .repair = fw.repair,
            },
            .trace = r.trace.with(.{
                // TODO: better compile error messages for no info and no default fields.
                .expect = fw.expect orelse r.default_expect.?,
                .trait = fw.trait orelse r.default_trait.?,
                .type = fw.type orelse r.default_type.?,
            }),
        };
    }
}
pub const FailWith = struct {
    @"error": anyerror,
    actual: []const u8 = "",
    repair: []const u8 = "",
    expect: ?[]const u8 = null,
    trait: ?[]const u8 = null,
    type: ?[]const u8 = null,
};

pub fn propagateFailResult(comptime r1: Result, comptime r2: Result, comptime pi: PropagateInfo) ?Result {
    comptime {
        r1.compileErrorOn(.fail);
        return if (r2.failure) |f| Result{
            .failure = f,
            .trace = .with(.combine(r1.trace, r2.trace), .{
                // TODO: better compile error messages for no info and no default fields.
                .expect = pi.expect orelse r1.default_expect.?,
                .trait = pi.trait orelse r1.default_trait.?,
                .type = pi.type orelse r1.default_type.?,
            }),
        } else null;
    }
}
pub fn propagateFail(
    comptime r: Result,
    comptime T: type,
    comptime t: z.Trait,
    comptime pi: PropagateInfo,
) ?Result {
    comptime return r.propagateFailResult(t.result(T), pi);
}
pub const PropagateInfo = struct {
    expect: ?[]const u8 = null,
    trait: ?[]const u8 = null,
    type: ?[]const u8 = null,
};

pub const Failure = struct {
    @"error": anyerror,
    actual: []const u8 = "",
    repair: []const u8 = "",

    pub fn format(f: Failure, w: *std.Io.Writer) WriteError!void {
        try w.print("[trait `error.{[error]t}`] {[actual]s}\n\t{[repair]s}", f);
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
            try w.print("[trait trace] {f}\n", .{info});
    }
};

pub const Info = struct {
    expect: []const u8,
    trait: []const u8,
    type: []const u8,

    pub fn format(i: Info, w: *std.Io.Writer) WriteError!void {
        try w.print("The type `{[type]s}` is required to satisfy the trait `{[trait]s}`.\n\t{[expect]s}", i);
    }
};

pub fn format(r: Result, w: *std.Io.Writer) WriteError!void {
    try w.print("{f}{?f}", .{ r.trace, r.failure });
}

inline fn compileErrorOn(comptime r: Result, comptime p_or_f: enum { pass, fail }) void {
    comptime if (r.isPassing() == (p_or_f == .pass)) z.compileError(
        \\This function is meant to be used on a {s} result.
    , .{switch (p_or_f) {
        .pass => "failing",
        .fail => "passing",
    }});
}
