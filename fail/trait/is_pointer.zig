const root = @import("../root.zig");
const z = @import("zigil");

const isPointer = z.Trait.isPointer;

pub const kind = if (!root.is_listing) isPointer(.{}).assert(u8);

pub const size = struct {
    pub const one = if (!root.is_listing) isPointer(.{ .size = .one }).assert([]u8);
    pub const slice = if (!root.is_listing) isPointer(.{ .size = .slice }).assert([*]u8);
    pub const many = if (!root.is_listing) isPointer(.{ .size = .many }).assert([*c]u8);
    pub const c = if (!root.is_listing) isPointer(.{ .size = .c }).assert(*u8);
};

pub const @"address-space" = if (!root.is_listing) isPointer(.{ .address_space = .fs }).assert(*u8);

pub const alignment = struct {
    pub const natural = if (!root.is_listing) isPointer(.{ .alignment = .natural })
        .assert(*align(4) u16);
    pub const @"least-natural" = if (!root.is_listing) isPointer(.{ .alignment = .least_natural })
        .assert(*align(1) u16);
    pub const custom = if (!root.is_listing) isPointer(.{ .alignment = .{ .custom = 1 } })
        .assert(*u16);
    pub const @"least-custom" = if (!root.is_listing) isPointer(.{ .alignment = .{ .least_custom = 4 } })
        .assert(*u16);
};

pub const @"allowzero" = struct {
    pub const yes = if (!root.is_listing) isPointer(.{ .is_allowzero = true }).assert(*u8);
    pub const not = if (!root.is_listing) isPointer(.{ .is_allowzero = false }).assert(*allowzero u8);
};

pub const @"const" = struct {
    pub const yes = if (!root.is_listing) isPointer(.{ .is_const = true }).assert(*u8);
    pub const not = if (!root.is_listing) isPointer(.{ .is_const = false }).assert(*const u8);
};

pub const @"volatile" = struct {
    pub const yes = if (!root.is_listing) isPointer(.{ .is_volatile = true }).assert(*u8);
    pub const not = if (!root.is_listing) isPointer(.{ .is_volatile = false }).assert(*volatile u8);
};

pub const sentinel = struct {
    pub const with = if (!root.is_listing) isPointer(.{ .has_sentinel = true }).assert([]u8);
    pub const wout = if (!root.is_listing) isPointer(.{ .has_sentinel = false }).assert([:0]u8);
};

pub const child = if (!root.is_listing) isPointer(.{ .child = .isEnum(.{}) }).assert(*u16);
