const config = @import("config");
const std = @import("std");
const z = @import("zigil");

pub fn main() void {
    comptime {
        for (@typeInfo(config).@"struct".decls) |decl|
            ref(fail, decl.name);
    }
}

fn ref(comptime space: type, comptime name: []const u8) void {
    comptime {
        var split = std.mem.SplitIterator(u8, .scalar){
            .buffer = name,
            .delimiter = '.',
            .index = 0,
        };

        const n0 = split.next() orelse return;

        if (split.peek() != null)
            ref(@field(space, n0), split.rest())
        else
            _ = @field(space, n0);
    }
}

pub const fail = struct {};
