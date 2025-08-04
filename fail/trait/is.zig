const z = @import("zigil");
const root = @import("../root.zig");

const is = z.Trait.is;

pub const primitive = if (!root.is_listing) is(i32).assert(u32);
pub const composite = if (!root.is_listing) is(fn () void).assert(fn () u8);
pub const @"user-defined" = if (!root.is_listing) is(struct {}).assert(struct {});
