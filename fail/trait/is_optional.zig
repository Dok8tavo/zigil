const root = @import("../root.zig");
const z = @import("zigil");

const isOptional = z.Trait.isOptional;

pub const kind = if (!root.is_listing) isOptional(.no_trait).assert(u32);
pub const child = if (!root.is_listing) isOptional(.is(i32)).assert(?u32);
