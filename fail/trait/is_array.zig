const root = @import("../root.zig");
const z = @import("zigil");

const isArray = z.Trait.isArray;

pub const child = if (!root.is_listing) isArray(.{ .child = .is_container }).assert([4]u8);
pub const kind = if (!root.is_listing) isArray(.{}).assert(@Vector(8, u8));
pub const length = struct {
    pub const eql = if (!root.is_listing) isArray(.{ .length = .eql(8) }).assert([2]u8);
    pub const at_least = if (!root.is_listing) isArray(.{ .length = .atLeast(8) }).assert([2]u8);
    pub const at_most = if (!root.is_listing) isArray(.{ .length = .atMost(4) }).assert([6]u8);
};
