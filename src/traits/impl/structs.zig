const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    fields: Fields = .no_requirement,
    layout: AllowLayout = .any,

    pub const Fields = union(enum) {
        exact: []const Field,
        least: []const Field,

        pub const no_requirement = Fields{ .least = &.{} };

        pub fn exactly(
            // TODO: use traits for this
            comptime fields: anytype,
        ) Fields {
            return Fields{ .exact = sliceFrom(fields) };
        }

        pub fn atLeast(
            // TODO: use traits for this
            comptime fields: anytype,
        ) Fields {
            return Fields{ .least = sliceFrom(fields) };
        }

        pub fn one(comptime name: []const u8, comptime field: Field.Anonymous) Fields {
            return Fields{ .least = &[_]Field{.{
                .name = name,
                .alignment = field.alignment,
                .has_default = field.has_default,
                .is_comptime = field.is_comptime,
                .trait = field.trait,
            }} };
        }

        fn sliceFrom(
            // TODO: use traits for this
            comptime fields: anytype,
        ) []const Field {
            var s: []const Field = &.{};
            for (@typeInfo(@TypeOf(fields)).@"struct".fields) |field| {
                const name = field.name;
                const unresolved = @field(fields, name);
                const Unresolved = @TypeOf(unresolved);
                s = s ++ &[_]Field{.{
                    .alignment = if (@hasField(Unresolved, "alignment")) unresolved.alignment else null,
                    .has_default = if (@hasField(Unresolved, "has_default")) unresolved.has_default else null,
                    .is_comptime = if (@hasField(Unresolved, "is_comptime")) unresolved.is_comptime else null,
                    .name = name,
                    .trait = if (@hasField(Unresolved, "trait")) unresolved.trait else .no_trait,
                }};
            }

            return s;
        }
    };

    pub const AllowLayout = union(enum) {
        all: z.Trait,
        auto,
        @"not-packed",
        @"extern",
        @"not-auto": z.Trait,
        @"packed": z.Trait,
        @"not-extern": z.Trait,

        pub const any = AllowLayout{ .all = .no_trait };

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

    pub const Field = struct {
        alignment: ?alignment.Other = null,
        has_default: ?bool = null,
        is_comptime: ?bool = null,
        name: []const u8,
        trait: z.Trait = .no_trait,

        pub const Anonymous = struct {
            alignment: ?alignment.Other = null,
            has_default: ?bool = null,
            is_comptime: ?bool = null,
            trait: z.Trait = .no_trait,
        };
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-struct", "The type must be a struct.");

        if (r.propagateFail(T, .isKind(.@"struct"), .{})) |fail|
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

        const field_count_is_exact, const expect_fields = switch (o.fields) {
            .exact => |exact| .{ true, exact },
            .least => |least| .{ false, least },
        };

        for (expect_fields) |expect| {
            const actual = for (info.fields) |field| {
                if (z.eql(u8, expect.name, field.name)) break field;
            } else return r.failWith(.{
                .@"error" = error.MissingField,
                .expect = "The struct must have a field named \"" ++ expect.name ++ "\".",
                .option = "has-field[." ++ expect.name ++ "]",
            });

            if (r.propagateFail(actual.type, expect.trait, .{
                .option = .fmtOne("has-field[." ++ expect.name ++ ", {s}]", .trait),
                .expect = .fmtOne(
                    "The type of the field \"" ++ expect.name ++ "\" must satisfy the trait `{s}`.",
                    .trait,
                ),
            })) |fail| return fail;

            if (expect.alignment) |expect_alignment| if (r.propagateFailResult(
                expect_alignment.result(actual.type, actual.alignment),
                .{
                    .option = expect_alignment.optionName(),
                    .expect = "The alignment of the field \"" ++ expect.name ++
                        "\" must be satisfy the condition `" ++ expect_alignment.optionName() ++ "`.",
                },
            )) |fail| return fail;

            if (expect.is_comptime) |expect_is_comptime| switch (expect_is_comptime) {
                true => if (!actual.is_comptime) return r.failWith(.{
                    .@"error" = error.FieldIsRuntime,
                    .expect = "The field \"" ++ expect.name ++ "\" must be comptime.",
                    .option = "has-comptime-field[." ++ expect.name ++ "]",
                }),
                false => if (actual.is_comptime) return r.failWith(.{
                    .@"error" = error.FieldIsComptime,
                    .expect = "The field \"" ++ expect.name ++ "\" must be runtime.",
                    .option = "has-runtime-field[." ++ expect.name ++ "]",
                }),
            };

            if (expect.has_default) |expect_has_default| switch (expect_has_default) {
                true => if (actual.default_value_ptr == null) return r.failWith(.{
                    .@"error" = error.HasNoDefault,
                    .expect = "The field \"" ++ expect.name ++ "\" must have a default value.",
                    .option = "has-field-with-default[." ++ expect.name ++ "]",
                }),
                false => if (actual.default_value_ptr != null) return r.failWith(.{
                    .@"error" = error.HasDefault,
                    .expect = "The field \"" ++ expect.name ++ "\" can't have a default value.",
                    .option = "has-field-wout-default[." ++ expect.name ++ "]",
                }),
            };
        }

        if (field_count_is_exact and expect_fields.len != info.fields.len) return r.failWith(.{
            .@"error" = error.ExtraFields,
            .expect = z.fmt(
                "The struct must have exactly the {} fields given.",
                .{expect_fields.len},
            ),
            .actual = for (info.fields) |actual_field| {
                const actual_is_in_expect = for (expect_fields) |expect_field| {
                    if (z.eql(u8, actual_field.name, expect_field.name)) break true;
                } else false;

                if (!actual_is_in_expect) break z.fmt(
                    "The struct has {} extra fields, notably \"" ++ actual_field.name ++ "\".",
                    .{info.fields.len - expect_fields.len},
                );
            } else unreachable,
            .option = z.fmt("has-fields[{}]", .{expect_fields.len}),
        });

        return r;
    }
}
