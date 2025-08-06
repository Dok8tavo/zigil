const root = @import("../root.zig");
const z = @import("zigil");

const isErrorUnion = z.Trait.isErrorUnion;

pub const kind = if (!root.is_listing) isErrorUnion(.{}).assert(error{SetIsNotUnion});
pub const payload = if (!root.is_listing) isErrorUnion(.{ .payload = .is_container })
    .assert(anyerror!usize);
pub const @"error" = if (!root.is_listing)
    isErrorUnion(.{ .@"error" = .isErrorSet(.{ .with = .lit(.GimmeDat) }) })
        .assert(error{NoGimmeDat}!void);
