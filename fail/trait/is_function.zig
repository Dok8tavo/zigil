const root = @import("../root.zig");
const z = @import("zigil");

const isFunction = z.Trait.isFunction;

pub const kind = if (!root.is_listing) isFunction(.{}).assert(u8);
pub const @"calling-convention" = if (!root.is_listing) isFunction(.{ .calling_convention = .@"inline" })
    .assert(fn () void);

pub const generic = struct {
    pub const not = if (!root.is_listing) isFunction(.{ .is_generic = false }).assert(@TypeOf(z.eql));
    pub const yes = if (!root.is_listing) isFunction(.{ .is_generic = true }).assert(fn () void);
};

pub const variadic = struct {
    pub const yes = if (!root.is_listing) isFunction(.{ .is_variadic = true }).assert(fn () void);
    pub const not = if (!root.is_listing) isFunction(.{ .is_variadic = false }).assert(fn (...) callconv(.c) void);
};

pub const @"return" = struct {
    pub const trait = if (!root.is_listing) isFunction(.{
        .return_type = .{
            .trait = .isOptional(.isInt(.{ .signed = false })),
        },
    }).assert(fn () ?i8);

    pub const generic = struct {
        pub const yes = if (!root.is_listing) isFunction(.{ .return_type = .{ .is_generic = true } })
            .assert(fn () void);
        pub const not = if (!root.is_listing) isFunction(.{ .return_type = .{ .is_generic = false } })
            .assert(@TypeOf(z.Comptype.get));
    };
};

pub const params = struct {
    pub const count = if (!root.is_listing) isFunction(.{ .params = .one(.{}) }).assert(fn () void);
    pub const trait = if (!root.is_listing) isFunction(.{
        .params = .one(.{ .trait = .isPointer(.{}) }),
    }).assert(fn (u8) void);

    pub const generic = struct {
        pub const yes = if (!root.is_listing) isFunction(.{
            .params = .one(.{ .is_generic = true }),
        }).assert(fn (void) void);

        pub const not = if (!root.is_listing) isFunction(.{
            .params = .one(.{ .is_generic = false }),
        }).assert(fn (anytype) void);
    };

    pub const @"noalias" = struct {
        pub const yes = if (!root.is_listing) isFunction(.{
            .params = .one(.{ .is_noalias = true }),
        }).assert(fn (*const u8) void);

        pub const not = if (!root.is_listing) isFunction(.{
            .params = .one(.{ .is_noalias = false }),
        }).assert(fn (noalias *u8) void);
    };
};
