const root = @import("../root.zig");
const z = @import("zigil");

const hasDecl = z.Trait.hasDecl;

pub const @"non-container" = if (!root.is_listing) hasDecl("hello", .no_option).assert(u8);
pub const miss = if (!root.is_listing) hasDecl("hello", .no_option).assert(struct {});

pub const @"type" = if (!root.is_listing) hasDecl("hello", .{ .of_type = .isEnum(.{}) }).assert(struct {
    pub const hello = struct {};
});

pub const trait = struct {
    const has_decl_trait = if (!root.is_listing) hasDecl("hello", .{ .is_type = .isEnum(.{}) });

    pub const @"not-type" = if (!root.is_listing) has_decl_trait.assert(struct {
        pub const hello = "goodbye";
    });

    pub const @"type" = if (!root.is_listing) has_decl_trait.assert(struct {
        pub const hello = []const u8;
    });
};
