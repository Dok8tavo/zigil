const root = @import("../root.zig");
const z = @import("zigil");

const isErrorSet = z.Trait.isErrorSet;

pub const with = if (!root.is_listing)
    isErrorSet(.{ .with = .lit(.ImALoneSomeCowboy) }).assert(error{});
pub const wout = if (!root.is_listing)
    isErrorSet(.{ .wout = .lit(.AndALongWayFromHome) }).assert(error{AndALongWayFromHome});

pub const any = struct {
    pub const must = if (!root.is_listing) isErrorSet(.{ .is_any = true }).assert(error{});
    pub const cant = if (!root.is_listing) isErrorSet(.{ .is_any = false }).assert(anyerror);
};
