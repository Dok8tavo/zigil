const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    all: z.Trait = .no_trait,
    fields: Fields = .{ .slice = &.{} },
    size: union(enum) {
        any,
        least: usize,
        exact: usize,
    } = .any,

    pub const Fields = struct {
        slice: []const Field,

        pub const FieldOrSkip = union(enum) {
            f: Field,
            s: usize,

            pub fn field(comptime f: Field) FieldOrSkip {
                return FieldOrSkip{ .f = f };
            }

            pub fn skip(comptime n: usize) FieldOrSkip {
                return FieldOrSkip{ .s = n };
            }
        };

        pub fn from(comptime slice: []const FieldOrSkip) Fields {
            var fields = Fields{ .slice = &.{} };
            for (slice) |field_or_skip| switch (field_or_skip) {
                .f => |f| fields.slice = fields.slice ++ &[_]Field{f},
                .s => |n| fields.slice = fields.slice ++ &[_]Field{.{}} ** n,
            };

            return fields;
        }
    };

    pub const Field = struct {
        is_comptime: ?bool = null,
        trait: z.Trait = .no_trait,
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-tuple", "The type mus be a tuple.");

        if (r.propagateFail(T, .isKind(.@"struct"), .{})) |fail|
            return fail;

        const info = @typeInfo(T).@"struct";

        if (!info.is_tuple) return r.failWith(.{
            .@"error" = error.IsRegularStruct,
            .expect = "The type must be a tuple.",
            .actual = "The type is a regular struct.",
        });

        switch (o.size) {
            .any => {},
            .exact => |exact| if (info.fields.len != exact) return r.failWith(.{
                .@"error" = error.WrongTupleSize,
                .expect = z.fmt("The tuple must have {} fields.", .{exact}),
                .actual = z.fmt("The tuple has {} fields.", .{info.fields.len}),
                .option = z.fmt("size == {}", .{exact}),
            }),
            .least => |least| if (info.fields.len < least) return r.failWith(.{
                .@"error" = error.TupleTooSmall,
                .expect = z.fmt("The tuple must have at least {} fields.", .{least}),
                .actual = z.fmt("The tuple has {} fields.", .{info.fields.len}),
                .option = z.fmt("{} <= size", .{least}),
            }),
        }

        // TODO: incorporate this in the `Options.size`
        if (info.fields.len < o.fields.slice.len) return r.failWith(.{
            .@"error" = error.MissingFields,
            .expect = z.fmt("The tuple must have until the field n°{}.", .{o.fields.slice.len - 1}),
            .actual = z.fmt("The tuple has {} fields.", .{info.fields.len}),
            .option = z.fmt("field-{}", .{o.fields.slice.len - 1}),
        });

        for (o.fields.slice, info.fields[0..o.fields.slice.len]) |expect_field, actual_field| {
            if (expect_field.is_comptime) |expect_is_comptime| switch (actual_field.is_comptime) {
                true => if (!expect_is_comptime) return r.failWith(.{
                    .@"error" = error.FieldIsComptime,
                    .expect = "The field n°" ++ actual_field.name ++ " must be runtime.",
                    .option = actual_field.name ++ "-runtime",
                }),
                false => if (expect_is_comptime) return r.failWith(.{
                    .@"error" = error.FieldIsRuntime,
                    .expect = "The field n°" ++ actual_field.name ++ " must be comptime.",
                    .option = actual_field.name ++ "-comptime",
                }),
            };

            if (r.propagateFail(actual_field.type, expect_field.trait, .{
                .expect = .fmtOne("The field n°" ++ actual_field.name ++ " must satisfy the trait `{s}`.", .trait),
                .option = .fmtOne(actual_field.name ++ " => {s}", .trait),
            })) |fail| return fail;
        }

        for (info.fields) |field| if (r.propagateFail(field.type, o.all, .{
            .expect = .fmtOne("All fields, including the n°" ++ field.name ++ ", must satisfy the trait `{s}`.", .trait),
            .option = .fmtOne(field.name ++ " => {s}", .trait),
        })) |fail| return fail;

        return r;
    }
}
