const z = @import("zigil");

const isOptional = z.Trait.isOptional;

pub const wrong_kind = isOptional(.no_trait).assert(u32);
pub const wrong_child = isOptional(.is(i32)).assert(?u32);
