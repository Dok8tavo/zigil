const alignment = @import("alignment.zig");
const kind = @import("kind.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    fields: Fields = .no_requirement,
    layout: AllowLayout = .any,

    pub const Fields = @import("fields.zig").Fields(.@"struct");

    pub const AllowLayout = union(enum) {
        all: z.Trait,
        auto,
        @"not-packed",
        @"extern",
        @"not-auto": z.Trait,
        @"packed": z.Trait,
        @"not-extern": z.Trait,

        pub const any = AllowLayout{ .all = .no_trait };

        pub fn expect(al: AllowLayout) []const u8 {
            return switch (al) {
                .all => "The struct can have any layout.",
                .auto => "The struct must have the auto layout.",
                .@"extern" => "The struct must have the extern layout.",
                .@"packed" => "The struct must have the packed layout.",
                .@"not-auto" => "The struct can't have the auto layout.",
                .@"not-extern" => "The struct can't have the extern layout.",
                .@"not-packed" => "The struct can't have the packed layout.",
            };
        }

        pub fn only(cl: std.builtin.Type.ContainerLayout) AllowLayout {
            return switch (cl) {
                .auto => .auto,
                .@"extern" => .@"extern",
                .@"packed" => .{ .@"packed" = .no_trait },
            };
        }

        pub fn not(cl: std.builtin.Type.ContainerLayout) AllowLayout {
            return switch (cl) {
                .auto => .{ .@"not-auto" = .no_trait },
                .@"extern" => .{ .@"not-extern" = .no_trait },
                .@"packed" => .@"not-packed",
            };
        }

        pub fn hasAuto(al: AllowLayout) bool {
            return switch (al) {
                .all, .auto, .@"not-packed", .@"not-extern" => true,
                else => false,
            };
        }

        pub fn hasExtern(al: AllowLayout) bool {
            return switch (al) {
                .all, .@"extern", .@"not-packed", .@"not-auto" => true,
                else => false,
            };
        }

        pub fn hasPacked(al: AllowLayout) ?z.Trait {
            return switch (al) {
                .all, .@"packed", .@"not-auto", .@"not-extern" => |trait| trait,
                else => null,
            };
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-struct", "The type must be a struct.");

        if (kind.propagateFail(r, T, .@"struct")) |fail|
            return fail;

        const info = @typeInfo(T).@"struct";

        if (info.is_tuple) return r.failWith(.{
            .@"error" = error.IsTuple,
            .expect = "The type must be a regular struct.",
            .actual = "The type is a tuple.",
        });

        switch (info.layout) {
            .auto => if (!o.layout.hasAuto()) return r.failWith(.{
                .@"error" = error.LayoutIsAuto,
                .option = @tagName(o.layout),
                .actual = "The layout of the struct is `.auto`.",
                .expect = switch (o.layout) {
                    .@"not-auto" => "The layout of the struct can't be `.auto`.",
                    .@"extern" => "The layout of the struct must be `.extern`.",
                    .@"packed" => "The layout of the struct must be `.packed`.",
                    else => unreachable,
                },
            }),
            .@"extern" => if (!o.layout.hasExtern()) return r.failWith(.{
                .@"error" = error.LayoutIsExtern,
                .option = @tagName(o.layout),
                .actual = "The layout of the struct is `.extern`.",
                .expect = switch (o.layout) {
                    .@"not-extern" => "The layout of the struct can't be `.extern`.",
                    .auto => "The layout of the struct must be `.auto`.",
                    .@"packed" => "The layout of the struct must be `.packed`.",
                    else => unreachable,
                },
            }),
            .@"packed" => if (o.layout.hasPacked()) |backing_integer| {
                if (r.propagateFail(info.backing_integer.?, backing_integer, .{
                    .expect = .fmtOne("The backing integer of the packed struct must satisfy the trait `{s}`.", .trait),
                    .option = .fmtOne("backing-integer => {s}", .trait),
                })) |fail| return fail;
            } else return r.failWith(.{
                .@"error" = error.LayoutIsPacked,
                .option = @tagName(o.layout),
                .actual = "The layout of the struct is `.packed`.",
                .expect = switch (o.layout) {
                    .@"not-packed" => "The layout of the struct can't be `.packed`.",
                    .auto => "The layout of the struct must be `.auto`.",
                    .@"extern" => "The layout of the struct must be `.extern`.",
                    else => unreachable,
                },
            }),
        }

        if (o.fields.propagateFail(info, r)) |fail|
            return fail;

        return r;
    }
}
