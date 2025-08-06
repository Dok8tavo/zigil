const root = @import("../root.zig");
const z = @import("zigil");

const isFloat = z.Trait.isFloat;

pub const kind = if (!root.is_listing) isFloat(.{}).assert(*f32);
pub const precision = if (!root.is_listing) isFloat(.{ .distinguish = .pair(10_000, 10_001) }).assert(f16);
