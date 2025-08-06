const root = @import("../root.zig");
const z = @import("zigil");

const isEnum = z.Trait.isEnum;

pub const kind = if (!root.is_listing) isEnum(.{}).assert(u8);
pub const with = if (!root.is_listing) isEnum(.{ .with = .name("variant") }).assert(enum {});
pub const wout = if (!root.is_listing) isEnum(.{ .wout = .name("variant") }).assert(enum { variant });
pub const exhaustive = struct {
    pub const yes = if (!root.is_listing) isEnum(.{ .is_exhaustive = true })
        .assert(enum(u8) { _ });
    pub const not = if (!root.is_listing) isEnum(.{ .is_exhaustive = false })
        .assert(enum {});
};
