const root = @import("../root.zig");
const z = @import("zigil");

const isStruct = z.Trait.isStruct;

pub const kind = if (!root.is_listing) isStruct(.{}).assert(u8);
pub const tuple = if (!root.is_listing) isStruct(.{}).assert(struct { u8 });
pub const layout = struct {
    pub const auto = struct {
        const is_auto_struct = isStruct(.{ .layout = .only(.auto) });
        pub const @"packed" = if (!root.is_listing) is_auto_struct.assert(packed struct {});
        pub const @"extern" = if (!root.is_listing) is_auto_struct.assert(extern struct {});
    };

    pub const @"packed" = struct {
        const is_packed_struct = isStruct(.{ .layout = .only(.@"packed") });
        pub const auto = if (!root.is_listing) is_packed_struct.assert(struct {});
        pub const @"extern" = if (!root.is_listing) is_packed_struct.assert(extern struct {});
    };

    pub const @"extern" = struct {
        const is_extern_struct = isStruct(.{ .layout = .only(.@"extern") });
        pub const auto = if (!root.is_listing) is_extern_struct.assert(struct {});
        pub const @"packed" = if (!root.is_listing) is_extern_struct.assert(packed struct {});
    };

    pub const @"not-auto" = if (!root.is_listing) isStruct(.{ .layout = .not(.auto) })
        .assert(struct {});

    pub const @"not-packed" = if (!root.is_listing) isStruct(.{ .layout = .not(.@"packed") })
        .assert(packed struct {});

    pub const @"not-extern" = if (!root.is_listing) isStruct(.{ .layout = .not(.@"extern") })
        .assert(extern struct {});

    pub const @"backing-integer" = if (!root.is_listing) isStruct(.{
        .layout = .onlyPacked(.isInt(.{ .signed = true })),
    }).assert(packed struct(u0) {});
};

pub const fields = struct {
    pub const miss = if (!root.is_listing) isStruct(.{
        .fields = .atLeast(.{ .hello = .{} }),
    }).assert(struct {});

    pub const trait = if (!root.is_listing) isStruct(.{
        .fields = .one("hello", .{ .trait = z.Trait.is([]const u8) }),
    }).assert(struct { hello: []u8 });

    pub const default = struct {
        pub const wout = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .has_default = false }),
        }).assert(struct { hello: []const u8 = "I'm the default!" });

        pub const with = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .has_default = true }),
        }).assert(struct { hello: []const u8 });
    };

    pub const @"comptime" = struct {
        pub const yes = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .is_comptime = true }),
        }).assert(struct { hello: []const u8 });

        pub const not = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .is_comptime = false }),
        }).assert(struct { comptime hello: []const u8 = "hello" });
    };

    pub const alignment = struct {
        pub const natural = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .alignment = .natural }),
        }).assert(extern struct { hello: u8 align(16) });

        pub const @"least-natural" = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .alignment = .least_natural }),
        }).assert(extern struct { hello: u32 align(2) });

        pub const custom = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .alignment = .{ .custom = 4 } }),
        }).assert(struct { hello: u64 });

        pub const @"least-custom" = if (!root.is_listing) isStruct(.{
            .fields = .one("hello", .{ .alignment = .{ .least_custom = 4 } }),
        }).assert(struct { hello: u16 });
    };
};
