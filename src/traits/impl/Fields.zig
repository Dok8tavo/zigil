fields: []const Field,
exact: bool,

const alignment = @import("alignment.zig");
const std = @import("std");
const z = @import("../../root.zig");

const Fields = @This();

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

pub const no_requirement = Fields{ .fields = &.{}, .exact = false };

pub fn propagateFail(
    comptime expect: Fields,
    comptime struct_or_union: enum { @"struct", @"union" },
    comptime actual: switch (struct_or_union) {
        .@"struct" => std.builtin.Type.Struct,
        .@"union" => std.builtin.Type.Union,
    },
    comptime r: z.Trait.Result,
) ?z.Trait.Result {
    for (expect.fields) |expect_field| {
        const actual_field = for (actual.fields) |field| {
            if (z.eql(u8, expect_field.name, field.name)) break field;
        } else return r.failWith(.{
            .@"error" = error.MissingField,
            .expect = "The type must have a field named \"" ++ expect_field.name ++ "\".",
            .option = "has-field[." ++ expect_field.name ++ "]",
        });

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

        if (struct_or_union == .@"struct") {
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

    if (expect.exact and expect.fields.len != actual.fields.len) return r.failWith(.{
        .@"error" = error.ExtraFields,
        .expect = z.fmt(
            "The type must have exactly the {} fields given.",
            .{expect.fields.len},
        ),
        .actual = for (actual.fields) |actual_field| {
            const actual_is_in_expect = for (expect.fields) |expect_field| {
                if (z.eql(u8, actual_field.name, expect_field.name)) break true;
            } else false;

            if (!actual_is_in_expect) break z.fmt(
                "The type has {} extra fields, notably \"" ++ actual_field.name ++ "\".",
                .{actual.fields.len - expect.fields.len},
            );
        } else unreachable,
        .option = z.fmt("has-fields[{}]", .{expect.fields.len}),
    });

    return null;
}

pub fn exactly(
    // TODO: use traits for this
    comptime fields: anytype,
) Fields {
    return Fields{ .fields = sliceFrom(fields), .exact = true };
}

pub fn atLeast(
    // TODO: use traits for this
    comptime fields: anytype,
) Fields {
    return Fields{ .fields = sliceFrom(fields), .exact = false };
}

pub fn one(comptime name: []const u8, comptime field: Field.Anonymous) Fields {
    return Fields{
        .exact = false,
        .fields = &[_]Field{.{
            .name = name,
            .alignment = field.alignment,
            .has_default = field.has_default,
            .is_comptime = field.is_comptime,
            .trait = field.trait,
        }},
    };
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
