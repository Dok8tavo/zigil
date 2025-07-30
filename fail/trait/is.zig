const z = @import("zigil");

const is = z.Trait.is;

pub const primitive = is(i32).assert(u32);
pub const composite = is(fn () void).assert(fn () u8);
pub const @"user-defined" = is(struct {}).assert(struct {});
