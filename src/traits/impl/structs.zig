const alignment = @import("alignment.zig");
const containers = @import("containers.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    is_tuple: ?bool = null,
    layout: containers.AllowLayout = .all,
    backing_integer: BackingInteger = .no_requirement,
    fields: Fields = .no_requirement,
    field_count: Count = .least_items,

    pub const Count = @import("count.zig").Count;

    pub const BackingInteger = struct {
        is_null: ?bool = null,
        trait: z.Trait = .no_trait,

        pub const no_requirement = BackingInteger{};

        pub fn must(comptime t: z.Trait) BackingInteger {
            return BackingInteger{
                .is_null = false,
                .trait = t,
            };
        }
    };

    pub const Fields = struct {
        slice: ?[]const Field = null,

        pub const no_requirement = Fields{};

        pub fn one(comptime field: Field) Fields {
            comptime return Fields{ .slice = &[_]Field{field} };
        }

        pub fn many(comptime fields: []const Field) Fields {
            comptime return Fields{ .slice = fields };
        }
    };

    pub const Field = struct {
        alignment: ?alignment.Other = null,
        is_comptime: ?bool = null,
        name: []const u8,
        trait: z.Trait = .no_trait,
        has_default: ?bool = null,
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-struct", "The type must be a struct.");

        if (r.propagateFail(T, .isKind(.@"struct"), .{})) |fail|
            return fail;

        const info = @typeInfo(T).@"struct";

        if (o.is_tuple) |is_tuple| if (info.is_tuple != is_tuple) return r.withFailure(.{
            .@"error" = if (is_tuple) error.IsNotTuple else error.IsTuple,
            .expect = z.fmt("The type {s} be a tuple.", .{if (is_tuple) "must" else "can't"}),
            .actual = z.fmt("The type is {s}.", .{if (is_tuple) "a regular struct" else "a tuple"}),
            .option = z.fmt("{s}tuple", .{if (is_tuple) "" else "no-"}),
        });

        if (!o.layout.allows(info.layout)) return r.withFailure(.{
            .@"error" = error.ForbiddenLayout,
            .expect = z.fmt("The struct can't use the `{s}` layout.", .{@tagName(info.layout)}),
            .option = z.fmt("forbid-layout[{s}]", .{@tagName(info.layout)}),
            .actual = z.fmt("The struct layout is `{s}`", .{@tagName(info.layout)}),
            // TODO: .repair  = "layout suggestion",
        });

        if (o.backing_integer.is_null) |is_null| if (is_null != (info.backing_integer == null)) return r.withFailure(.{
            .@"error" = if (is_null) error.NonNullBackingInteger else error.NullBackingInteger,
            // TODO: better messaging
            .expect = z.fmt("The struct {s} specify backing integer.", .{if (is_null) "can't" else "must"}),
            .option = z.fmt("backing-integer-is{s}null", .{if (is_null) "-" else "-not-"}),
            .actual = z.fmt(
                "The struct's backing integer is `{s}`.",
                .{if (info.backing_integer) |Bi| @typeName(Bi) else "null"},
            ),
        });

        if (info.backing_integer) |Bi| if (r.propagateFail(Bi, o.backing_integer.trait, .{
            .option = .withTraitName("backing-integer => {s}"),
            .expect = .withTraitName("The backing integer must satisfy the trait `{s}`."),
        })) |fail| return fail;

        field_count: switch (o.field_count) {
            .exact_items => if (o.fields.slice) |slice| continue :field_count .{ .exact = slice.len },
            .least_items => if (o.fields.slice) |slice| continue :field_count .{ .least = slice.len },
            .exact => |exact| if (info.fields.len != exact) return r.withFailure(.{
                .@"error" = error.WrongFieldCount,
                .option = z.fmt("field-count[=={}]", .{exact}),
                .expect = z.fmt("The field count must be exactly {}.", .{exact}),
                .actual = z.fmt("The field count is {}.", .{info.fields.len}),
            }),
            .least => |least| if (info.fields.len < least) return r.withFailure(.{
                .@"error" = error.NotEnoughFields,
                .option = z.fmt("field-count[<={}]", .{least}),
                .expect = z.fmt("There must be at least {} fields.", .{least}),
                .actual = z.fmt("The field count is {}.", .{info.fields.len}),
            }),
        }

        if (o.fields.slice) |fields| for (fields) |expect| {
            const actual: std.builtin.Type.StructField = for (info.fields) |field| {
                if (z.eql(u8, field.name, expect.name)) break field;
            } else return r.withFailure(.{
                .@"error" = error.MissingField,
                .expect = z.fmt("The struct type must have a field named \"{s}\".", .{expect.name}),
                .option = z.fmt("has-field[\"{s}\"]", .{expect.name}),
            });

            if (expect.has_default) |has_default| if (has_default != (actual.default_value_ptr != null)) return r.withFailure(.{
                .@"error" = if (has_default) error.HasNoDefault else error.HasDefault,
                .option = z.fmt("has-field[{s}-default]", .{if (has_default) "with" else "wout"}),
                .expect = z.fmt("The type {s} have a default value.", .{if (has_default) "must" else "can't"}),
                .actual = z.fmt("The field has {s} default value.", .{if (has_default) "no" else "a"}),
            });

            if (expect.is_comptime) |is_comptime| if (is_comptime != actual.is_comptime) return r.withFailure(.{
                .@"error" = if (is_comptime) error.FieldIsRuntime else error.FieldIsComptime,
                .expect = z.fmt(
                    "The type's field \"{s}\" must be {s}.",
                    .{ actual.name, if (is_comptime) "comptime" else "runtime" },
                ),
                .option = z.fmt(
                    "has-field[\"{s}\", is-{s}]",
                    .{ actual.name, if (is_comptime) "comptime" else "runtime" },
                ),
                .actual = z.fmt(
                    "The type's field \"{s}\" is {s}.",
                    .{if (is_comptime) "runtime" else "comptime"},
                ),
            });

            if (r.propagateFail(actual.type, expect.trait, .{
                .option = .withTraitName(z.fmt("has-field[\"{s}\" => {{s}}]", .{actual.name})),
                .expect = .withTraitName(z.fmt(
                    "The type of the field \"{s}\" must satisfy the trait `{{s}}`.",
                    .{actual.name},
                )),
            })) |fail| return fail;

            if (expect.alignment) |expect_align| {
                if (r.propagateFailingResult(expect_align.result(actual.type, actual.alignment), .{
                    .option = z.fmt("alignment[{s}]", .{expect_align.optionName()}),
                    .expect = z.fmt(
                        "The alignment of the field \"{s}\" must satisfy the given condition.",
                        .{actual.name},
                    ),
                })) |fail| return fail;
            }
        };

        return r;
    }
}
