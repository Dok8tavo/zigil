const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub fn Fields(comptime kind: enum { @"struct", @"union", @"enum" }) type {
    return struct {
        slice: []const Field,

        pub const Actual = switch (kind) {
            .@"struct" => std.builtin.Type.Struct,
            .@"enum" => std.builtin.Type.Enum,
            .@"union" => std.builtin.Type.Union,
        };

        pub const Field = switch (kind) {
            .@"struct" => StructField,
            .@"enum" => EnumField,
            .@"union" => UnionField,
        };

        const EnumField = struct {
            name: []const u8,
            value: ?comptime_int = null,

            pub const Anonymous = struct {
                value: ?comptime_int = null,
            };
        };

        const UnionField = struct {
            alignment: ?alignment.Other = null,
            name: []const u8,
            trait: z.Trait = .no_trait,

            pub const Anonymous = struct {
                alignment: ?alignment.Other = null,
                trait: z.Trait = .no_trait,
            };
        };

        const StructField = struct {
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

        pub const no_requirement = Fields(kind){ .slice = &.{} };

        pub fn propagateFail(
            comptime expect: Fields(kind),
            comptime actual: Actual,
            comptime r: z.Trait.Result,
        ) ?z.Trait.Result {
            for (expect.slice) |expect_field| {
                const actual_field = for (actual.fields) |field| {
                    if (z.eql(u8, expect_field.name, field.name)) break field;
                } else return r.failWith(.{
                    .@"error" = error.MissingField,
                    .expect = "The type must have a field named \"" ++ expect_field.name ++ "\".",
                    .option = "has-field[." ++ expect_field.name ++ "]",
                });

                if (kind == .@"enum") {
                    if (expect_field.value) |expect_value| if (expect_value != actual_field.value) return r.failWith(.{
                        .@"error" = error.WrongValue,
                        .option = "." ++ expect_field.name ++ z.fmt(" == {}", .{expect_value}),
                        .expect = "The field \"" ++ expect_field.name ++
                            z.fmt("\" must have the value {}.", .{expect_value}),
                        .actual = "The field \"" ++ expect_field.name ++
                            z.fmt("\" has the value {}.", .{actual_field.value}),
                    });
                } else {
                    if (r.propagateFail(actual_field.type, expect_field.trait, .{
                        .option = .fmtOne("has-field[." ++ expect_field.name ++ ", {s}]", .trait),
                        .expect = .fmtOne(
                            "The type of the field \"" ++ expect_field.name ++ "\" must satisfy the trait `{s}`.",
                            .trait,
                        ),
                    })) |fail| return fail;

                    if (expect_field.alignment) |expect_alignment| if (r.propagateFailResult(
                        expect_alignment.result(actual_field.type, actual_field.alignment),
                        .{
                            .option = expect_alignment.optionName(),
                            .expect = "The alignment of the field \"" ++ expect_field.name ++
                                "\" must be satisfy the condition `" ++ expect_alignment.optionName() ++ "`.",
                        },
                    )) |fail| return fail;
                }

                if (kind == .@"struct") {
                    if (expect_field.is_comptime) |expect_is_comptime| switch (expect_is_comptime) {
                        true => if (!actual_field.is_comptime) return r.failWith(.{
                            .@"error" = error.FieldIsRuntime,
                            .expect = "The field \"" ++ expect_field.name ++ "\" must be comptime.",
                            .option = "has-comptime-field[." ++ expect_field.name ++ "]",
                        }),
                        false => if (actual_field.is_comptime) return r.failWith(.{
                            .@"error" = error.FieldIsComptime,
                            .expect = "The field \"" ++ expect_field.name ++ "\" must be runtime.",
                            .option = "has-runtime-field[." ++ expect_field.name ++ "]",
                        }),
                    };

                    if (expect_field.has_default) |expect_has_default| switch (expect_has_default) {
                        true => if (actual_field.default_value_ptr == null) return r.failWith(.{
                            .@"error" = error.HasNoDefault,
                            .expect = "The field \"" ++ expect_field.name ++ "\" must have a default value.",
                            .option = "has-field-with-default[." ++ expect_field.name ++ "]",
                        }),
                        false => if (actual_field.default_value_ptr != null) return r.failWith(.{
                            .@"error" = error.HasDefault,
                            .expect = "The field \"" ++ expect_field.name ++ "\" can't have a default value.",
                            .option = "has-field-wout-default[." ++ expect_field.name ++ "]",
                        }),
                    };
                }
            }

            return null;
        }

        pub fn names(n: []const []const u8) Fields(kind) {
            comptime {
                var fields: []const Field = &.{};
                for (n) |name| fields = fields ++ &[_]Field{.{ .name = name }};
                return Fields(kind){ .slice = fields };
            }
        }

        pub fn one(comptime name: []const u8, comptime field: Field.Anonymous) Fields(kind) {
            comptime {
                var named_field = Field{ .name = name };
                for (@typeInfo(Field.Anonymous).@"struct".fields) |f|
                    @field(named_field, f.name) = @field(field, f.name);
                return Fields(kind){ .slice = &[_]Field{named_field} };
            }
        }

        pub fn from(
            // TODO: use traits for this
            comptime fields: anytype,
        ) Fields(kind) {
            var s: []const Field = &.{};

            for (@typeInfo(@TypeOf(fields)).@"struct".fields) |unresolved_info| {
                const Unresolved = unresolved_info.type;
                const unresolved = Unresolved{};
                var resolved = Field{ .name = unresolved_info.name };

                for (@typeInfo(Unresolved).@"struct".fields) |field_info|
                    @field(resolved, field_info.name) = @field(unresolved, field_info.name);

                s = s ++ &[_]Field{resolved};
            }

            return Fields(kind){ .slice = s };
        }
    };
}
