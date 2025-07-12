/// Whether the trait failed and why.
failure: ?Failure,
/// Information that concerns the current step of the trait.
info: Info,
/// Information that concerns the preceding steps of the trait.
trace: []const Info,

const z = @import("../root.zig");
const std = @import("std");

const Result = @This();

pub fn init(
    comptime T: type,
    comptime trait: []const u8,
    comptime default_expect: []const u8,
) Result {
    comptime return Result{
        .failure = null,
        .info = Info{
            .type = @typeName(T),
            .trait = trait,
            .expect = default_expect,
        },
        .trace = &.{},
    };
}

pub const WithFailure = struct {
    @"error": anyerror,
    option: ?[]const u8 = null,
    expect: ?[]const u8 = null,
    actual: []const u8 = "",
    repair: []const u8 = "",
};

/// This function always returns a failing result.
pub inline fn withFailure(
    comptime passing_result: Result,
    comptime wf: WithFailure,
) Result {
    comptime {
        passing_result.compileErrorOnFailure();
        const r = passing_result;
        const info = Info{
            .expect = wf.expect orelse r.info.expect,
            .trait = r.info.trait ++ if (wf.option) |o| "[" ++ o ++ "]" else "",
            .type = r.info.type,
        };

        return Result{
            .info = info,
            .trace = &[_]Info{info} ++ if (r.trace.len != 0) r.trace[1..] else &[_]Info{},
            .failure = .{
                .@"error" = wf.@"error",
                .actual = wf.actual,
                .repair = wf.repair,
            },
        };
    }
}

pub const DependsOnResult = struct {
    expect: ?[]const u8 = null,
    option: ?[]const u8 = null,
};

/// This function returns the result only if its failing.
pub inline fn propagateFailingResult(
    comptime passing_result: Result,
    comptime r: Result,
    comptime info: DependsOnResult,
) ?Result {
    comptime {
        passing_result.compileErrorOnFailure();
        var failing_result = if (r.failure) |failure| passing_result.withFailure(.{
            .option = info.option,
            .expect = info.expect,
            .@"error" = failure.@"error",
            .actual = failure.actual,
            .repair = failure.repair,
        }) else return null;

        failing_result.trace = &[_]Info{failing_result.info} ++ passing_result.trace ++ r.trace;
        return failing_result;
    }
}

pub const DependsOnTrait = struct {
    expect: Option = .none,
    option: Option = .none,

    pub const Option = union(enum) {
        none,
        resolved: []const u8,
        unresolved: []const u8,

        pub fn resolve(comptime o: Option, comptime name: []const u8) ?[]const u8 {
            comptime return switch (o) {
                .none => null,
                .resolved => |resolved| resolved,
                .unresolved => |unresolved| z.fmt(unresolved, .{name}),
            };
        }

        pub fn str(comptime s: []const u8) Option {
            return .{ .resolved = s };
        }

        pub fn fmt(comptime s: []const u8, comptime args: anytype) Option {
            return .{ .resolved = z.fmt(s, args) };
        }

        // TODO: document the fact that "s" contain a placeholder destined to the trait name.
        pub fn withTraitName(comptime s: []const u8) Option {
            return .{ .unresolved = s };
        }
    };
};

/// This function returns the result only if its failing.
pub inline fn propagateFail(
    comptime passing_result: Result,
    comptime T: type,
    comptime t: z.Trait,
    comptime info: DependsOnTrait,
) ?Result {
    comptime {
        passing_result.compileErrorOnFailure();

        const r = t.result(T);
        var failing_result = if (r.failure) |failure| passing_result.withFailure(.{
            .@"error" = failure.@"error",
            .actual = failure.actual,
            .repair = failure.repair,
            .option = info.option.resolve(r.info.trait),
            .expect = info.expect.resolve(r.info.trait),
        }) else return null;

        failing_result.trace = &[_]Info{failing_result.info} ++ passing_result.trace ++ r.trace;
        return failing_result;
    }
}
inline fn compileErrorOnFailure(comptime r: Result) void {
    if (r.failure) |f| z.compileError(
        \\This function is meant to be used on a passing result.
        \\This result already fails with `error.{s}`.
        \\
    , .{@errorName(f.@"error")});
}

pub fn format(
    r: Result,
    comptime _: []const u8,
    _: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    for (r.trace) |info|
        try writer.print("{}\n", .{info});
    if (r.failure) |f|
        try writer.print("{}\n", .{f});
}

pub const Info = struct {
    expect: []const u8,
    trait: []const u8,
    type: []const u8,

    pub fn format(
        i: Info,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print(
            "[trait trace] The type `{s}` is required to satisfy the trait `{s}`.\n",
            .{ i.type, i.trait },
        );

        if (i.expect.len != 0)
            try insertAtNewLines("    ", i.expect, writer);
    }
};

pub const Failure = struct {
    actual: []const u8 = "",
    repair: []const u8 = "",
    @"error": anyerror,

    pub fn format(
        f: Failure,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print(
            "[trait `error.{s}`] {s}\n",
            .{ @errorName(f.@"error"), f.actual },
        );

        if (f.repair.len != 0)
            try insertAtNewLines("    ", f.repair, writer);
    }
};

fn insertAtNewLines(comptime insert: []const u8, str: []const u8, writer: anytype) !void {
    var i: usize = 0;

    try writer.writeAll(insert);

    for (str, 0..) |c, j| if (c == '\n') {
        try writer.writeAll(str[i..j]);
        try writer.writeAll(insert);
        i = j;
    };

    try writer.writeAll(str[i..]);
}
