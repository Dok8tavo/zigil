const root = @import("../root.zig");
const z = @import("zigil");

const isOptional = z.Trait.isOptional;

pub const wrong_kind = if (!root.is_listing) isOptional(.no_trait).assert(u32);
pub const wrong_child = if (!root.is_listing) isOptional(.is(i32)).assert(?u32);
