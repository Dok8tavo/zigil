const root = @import("../root.zig");
const z = @import("zigil");

const isTuple = z.Trait.isTuple;

pub const kind = if (!root.is_listing) isTuple(.{}).assert(u8);
pub const @"struct" = if (!root.is_listing) isTuple(.{}).assert(struct {});

pub const all = if (!root.is_listing) isTuple(.{ .all = .isFloat(.{}) })
    .assert(struct { f16, f32, f64, f128, u8 });

pub const size = struct {
    pub const exact = if (!root.is_listing) isTuple(.{ .size = .{ .exact = 2 } })
        .assert(struct { u1, u2, u3 });

    pub const least = if (!root.is_listing) isTuple(.{ .size = .{ .least = 4 } })
        .assert(struct { u1, u2, u3 });
};

pub const fields = struct {
    pub const miss = if (!root.is_listing) isTuple(.{
        .fields = .from(&.{.skip(2)}),
    }).assert(struct { void });

    pub const @"comptime" = struct {
        pub const yes = if (!root.is_listing) isTuple(.{
            .fields = .from(&.{.field(.{ .is_comptime = true })}),
        }).assert(struct { u8 });

        pub const not = if (!root.is_listing) isTuple(.{
            .fields = .from(&.{.field(.{ .is_comptime = false })}),
        }).assert(struct { comptime u8 = 0 });
    };
};
