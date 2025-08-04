const z = @import("zigil");
const root = @import("../root.zig");

const isVector = z.Trait.isVector;

pub const kind = if (!root.is_listing) isVector(.{}).assert(i32);
pub const child = if (!root.is_listing) isVector(.{ .child = .isKind(.float) }).assert(@Vector(8, i32));
