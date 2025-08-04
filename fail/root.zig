const config = @import("config");
const std = @import("std");
const z = @import("zigil");

pub const is_listing =
    @hasDecl(config, "-l") or
    @hasDecl(config, "--list") or is_recursive;

const is_recursive = @hasDecl(config, "-lr") or
    @hasDecl(config, "--list-recursive");

pub fn main() !void {
    if (!is_listing)
        return reference_all;

    var buffer: [4096]u8 = undefined;
    const stderr = std.debug.lockStderrWriter(&buffer);
    defer std.debug.unlockStderrWriter();

    defer stderr.flush() catch @panic("Can't flush!");
    if (@typeInfo(config).@"struct".decls.len == 0)
        return try printNamespace(fail, 0, stderr);

    inline for (@typeInfo(config).@"struct".decls) |decl| {
        if (z.eql(u8, "-l", decl.name) or z.eql(u8, "--list", decl.name))
            continue;

        if (z.eql(u8, "-lr", decl.name) or z.eql(u8, "--list-recursive", decl.name))
            continue;

        try stderr.writeAll("- " ++ decl.name ++ ":\n");
        try printRoot(fail, decl.name, stderr);
    }
}

fn printRoot(comptime namespace: type, comptime path: []const u8, w: *std.Io.Writer) !void {
    comptime var next_namespace = namespace;
    comptime var split = std.mem.splitScalar(u8, path, '.');

    const end = inline while (comptime split.next()) |name| {
        if (!@hasDecl(next_namespace, name))
            return try w.writeAll("- " ++ path[0 .. split.index orelse path.len] ++ ": Doesn't exist!\n");

        switch (@TypeOf(@field(next_namespace, name))) {
            type => next_namespace = @field(next_namespace, name),
            void => break @field(next_namespace, name),
            else => unreachable,
        }
    } else next_namespace;

    if (comptime split.peek()) |_|
        return try w.writeAll("- " ++ path[0 .. split.index orelse path.len] ++ ": Isn't a namespace!\n");

    return switch (@TypeOf(end)) {
        type => try printNamespace(end, 1, w),
        void => try w.writeAll("- " ++ path ++ "\n"),
        else => unreachable,
    };
}

fn printNamespace(comptime namespace: type, comptime depth: usize, w: *std.Io.Writer) !void {
    inline for (@typeInfo(namespace).@"struct".decls) |decl_info| {
        const decl = @field(namespace, decl_info.name);

        switch (@TypeOf(decl)) {
            void => try w.writeAll("\t" ** depth ++ "- " ++ decl_info.name ++ "\n"),
            type => {
                if (is_recursive) {
                    try w.writeAll("\t" ** depth ++ "- " ++ decl_info.name ++ ":\n");
                    try printNamespace(decl, depth + 1, w);
                } else try w.writeAll("\t" ** depth ++ "- " ++ decl_info.name ++ ": ...\n");
            },
            else => unreachable,
        }
    }
}

const reference_all = for (@typeInfo(config).@"struct".decls) |decl|
    recursiveReference(fail, decl.name);

fn recursiveReference(comptime space: type, comptime name: []const u8) void {
    comptime {
        var split = std.mem.splitScalar(u8, name, '.');
        const n0 = split.next() orelse return;

        if (split.peek() != null)
            recursiveReference(@field(space, n0), split.rest())
        else
            _ = @field(space, n0);
    }
}

pub const fail = struct {
    pub const trait = @import("trait.zig");
};
