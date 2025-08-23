const alignment = @import("alignment.zig");
const kind = @import("kind.zig");
const type_name = @import("../type_name.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    layout: AllowLayout = .any,
    fields: Fields = .no_requirement,

    pub const Fields = @import("fields.zig").Fields(.@"union");

    pub const AllowLayout = union(enum) {
        all: z.Trait,
        auto: z.Trait,
        @"extern",
        @"packed",
        @"not-auto",
        @"not-extern": z.Trait,
        @"not-packed": z.Trait,

        pub const any = AllowLayout{ .all = .no_trait };

        pub fn expect(al: AllowLayout) []const u8 {
            return switch (al) {
                .all => "The union can have any layout.",
                .auto => "The union must have the auto layout.",
                .@"extern" => "The union must have the extern layout.",
                .@"packed" => "The union must have the packed layout.",
                .@"not-auto" => "The union can't have the auto layout.",
                .@"not-extern" => "The union can't have the extern layout.",
                .@"not-packed" => "The union can't have the packed layout.",
            };
        }

        pub fn only(cl: std.builtin.Type.ContainerLayout) AllowLayout {
            return switch (cl) {
                .auto => .{ .auto = .no_trait },
                .@"extern" => .@"extern",
                .@"packed" => .@"packed",
            };
        }

        pub fn not(cl: std.builtin.Type.ContainerLayout) AllowLayout {
            return switch (cl) {
                .auto => .@"not-auto",
                .@"extern" => .{ .@"not-extern" = .no_trait },
                .@"packed" => .{ .@"not-packed" = .no_trait },
            };
        }

        pub fn hasAuto(al: AllowLayout) ?z.Trait {
            return switch (al) {
                .all, .auto, .@"not-packed", .@"not-extern" => |trait| trait,
                else => null,
            };
        }

        pub fn hasExtern(al: AllowLayout) bool {
            return switch (al) {
                .all, .@"extern", .@"not-packed", .@"not-auto" => true,
                else => false,
            };
        }

        pub fn hasPacked(al: AllowLayout) bool {
            return switch (al) {
                .all, .@"packed", .@"not-auto", .@"not-extern" => true,
                else => false,
            };
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-union", "The type must be a union.");

        if (kind.propagateFail(r, T, .@"union")) |fail|
            return fail;

        const info = @typeInfo(T).@"union";

        switch (info.layout) {
            .auto => if (o.layout.hasAuto()) |trait| {
                if (info.tag_type) |Tag| if (r.propagateFail(Tag, trait, .{
                    .expect = .fmtOne("The tag `" ++ type_name.of(Tag, .min) ++
                        "` must satisfy the trait `{s}`.", .trait),
                    .option = .fmtOne("tag => {s}", .trait),
                })) |fail| return fail;
            } else return r.failWith(.{
                .@"error" = error.LayoutIsAuto,
                .option = @tagName(o.layout),
                .expect = o.layout.expect(),
                .actual = "The union has the auto layout,",
            }),
            .@"extern" => if (!o.layout.hasExtern()) return r.failWith(.{
                .@"error" = error.LayoutIsExtern,
                .option = @tagName(o.layout),
                .expect = o.layout.expect(),
                .actual = "The union has the extern layout.",
            }),
            .@"packed" => if (!o.layout.hasPacked()) return r.failWith(.{
                .@"error" = error.LayoutIsPacked,
                .option = @tagName(o.layout),
                .expect = o.layout.expect(),
                .actual = "The union has the packed layout.",
            }),
        }

        if (o.fields.propagateFail(info, r)) |fail|
            return fail;

        return r;
    }
}
