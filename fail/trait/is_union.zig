const root = @import("../root.zig");
const z = @import("zigil");

const isUnion = z.Trait.isUnion;

pub const kind = if (!root.is_listing) isUnion(.{}).assert(u8);
pub const layout = struct {
    pub const auto = struct {
        const is_auto = isUnion(.{ .layout = .only(.auto) });
        pub const @"packed" = if (!root.is_listing) is_auto.assert(packed union {});
        pub const @"extern" = if (!root.is_listing) is_auto.assert(extern union {});
    };

    pub const @"packed" = struct {
        const is_packed = isUnion(.{ .layout = .only(.@"packed") });
        pub const auto = if (!root.is_listing) is_packed.assert(union {});
        pub const @"extern" = if (!root.is_listing) is_packed.assert(extern union {});
    };

    pub const @"extern" = struct {
        const is_extern = isUnion(.{ .layout = .only(.@"extern") });
        pub const auto = if (!root.is_listing) is_extern.assert(union {});
        pub const @"packed" = if (!root.is_listing) is_extern.assert(packed union {});
    };

    pub const @"not-auto" = if (!root.is_listing) isUnion(.{ .layout = .not(.auto) })
        .assert(union {});

    pub const @"not-packed" = if (!root.is_listing) isUnion(.{ .layout = .not(.@"packed") })
        .assert(packed union {});

    pub const @"not-extern" = if (!root.is_listing) isUnion(.{ .layout = .not(.@"extern") })
        .assert(extern union {});

    pub const tag = if (!root.is_listing) isUnion(.{
        .layout = .{
            .auto = .isInt(.{ .signed = true }),
        },
    }).assert(union(u0) {});
};

pub const fields = struct {
    pub const miss = if (!root.is_listing) isUnion(.{
        .fields = .atLeast(.{ .hello = .{} }),
    }).assert(union {});

    pub const extra = if (!root.is_listing) isUnion(.{
        .fields = .exactly(.{ .hello = .{} }),
    }).assert(union { hello: u8, goodbye: u8 });

    pub const trait = if (!root.is_listing) isUnion(.{
        .fields = .one("hello", .{ .trait = z.Trait.is([]const u8) }),
    }).assert(union { hello: []u8 });

    pub const alignment = struct {
        pub const natural = if (!root.is_listing) isUnion(.{
            .fields = .one("hello", .{ .alignment = .natural }),
        }).assert(extern union { hello: u8 align(16) });

        pub const @"least-natural" = if (!root.is_listing) isUnion(.{
            .fields = .one("hello", .{ .alignment = .least_natural }),
        }).assert(extern union { hello: u32 align(2) });

        pub const custom = if (!root.is_listing) isUnion(.{
            .fields = .one("hello", .{ .alignment = .{ .custom = 4 } }),
        }).assert(union { hello: u64 });

        pub const @"least-custom" = if (!root.is_listing) isUnion(.{
            .fields = .one("hello", .{ .alignment = .{ .least_custom = 4 } }),
        }).assert(union { hello: u16 });
    };
};
