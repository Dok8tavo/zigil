const root = @import("../root.zig");
const z = @import("zigil");

const isEnum = z.Trait.isEnum;

pub const kind = if (!root.is_listing) isEnum(.{}).assert(u8);

pub const exhaustive = struct {
    pub const yes = if (!root.is_listing) isEnum(.{ .is_exhaustive = true })
        .assert(enum(u8) { _ });
    pub const not = if (!root.is_listing) isEnum(.{ .is_exhaustive = false })
        .assert(enum {});
};

pub const fields = struct {
    pub const miss = if (!root.is_listing) isEnum(.{ .fields = .one("hello", .{}) })
        .assert(enum { not_hello });
    pub const value = if (!root.is_listing) isEnum(.{ .fields = .one("hello", .{ .value = 42 }) })
        .assert(enum(u8) { hello = 13 });
};
