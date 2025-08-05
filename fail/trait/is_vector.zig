const root = @import("../root.zig");
const std = @import("std");
const z = @import("zigil");

const isVector = z.Trait.isVector;

pub const kind = if (!root.is_listing) isVector(.{}).assert(i32);
pub const child = if (!root.is_listing) isVector(.{ .child = .isKind(.float) }).assert(@Vector(8, i32));

pub const length = struct {
    pub const at_most = if (!root.is_listing) isVector(.{ .length = .atMost(4) }).assert(@Vector(5, u8));
    pub const at_least = if (!root.is_listing) isVector(.{ .length = .atLeast(4) }).assert(@Vector(3, u8));
    pub const eql = if (!root.is_listing) isVector(.{ .length = .{ .eql = 16 } }).assert(@Vector(8, u8));
    pub const at_most_suggest = if (!root.is_listing) isVector(.{ .length = .{ .at_most_suggest = .{} } })
        .assert(@Vector((std.simd.suggestVectorLength(u8) orelse 1) + 1, u8));
    pub const at_least_suggest = if (!root.is_listing) isVector(.{ .length = .{ .at_least_suggest = .{} } })
        .assert(@Vector((std.simd.suggestVectorLength(u8) orelse 1) - 1, u8));
    pub const suggest = if (!root.is_listing) isVector(.{ .length = .suggest })
        .assert(@Vector((std.simd.suggestVectorLength(u8) orelse 1) + 1, u8));
};
