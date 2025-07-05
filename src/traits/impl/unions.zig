const alignment = @import("alignment.zig");
const containers = @import("containers.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    is_tagged: ?bool = null,
    tag: z.Trait = .no_trait,
    layout: containers.AllowLayout = .all,
    variants: Variants = .{},
    variant_count: Count = .no_option,

    pub const Count = @import("options.zig").Count;

    pub const Variants = struct {
        slice: []const Variant = &.{},

        pub fn one(comptime field: Variant) Variants {
            comptime return Variants{ .slice = &[_]Variant{field} };
        }

        pub fn many(comptime fields: []const Variant) Variants {
            comptime return Variants{ .slice = fields };
        }
    };

    pub const Variant = struct {
        alignment: alignment.OtherAlignment = .no_option,
        is_comptime: ?bool = null,
        name: []const u8,
        trait: z.Trait = .no_trait,
        has_default: ?bool = null,
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-union", "The type must be a union.");

        if (r.propagateFail(T, .isKind(.@"union"), .{})) |fail|
            return fail;

        const info = @typeInfo(T).@"union";

        if (o.is_tagged) |is_tagged| if ((info.tag_type != null) != is_tagged) return r.withFailure(.{
            .@"error" = if (is_tagged) error.IsNotTagged else error.IsTagged,
            .expect = z.fmt("The type {s} be a tagged union.", .{if (is_tagged) "must" else "can't"}),
            .actual = z.fmt("The type is {s}.", .{if (is_tagged) "a bare struct" else "a tagged union"}),
            .option = z.fmt("{s}tag", .{if (is_tagged) "" else "no-"}),
        });

        if (info.tag_type) |Tag| if (r.propagateFail(Tag, o.tag, .{
            .option = .withTraitName("tag => {s}"),
            .expect = .withTraitName("The union's tag must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (!o.layout.allows(info.layout)) return r.withFailure(.{
            .@"error" = error.ForbiddenLayout,
            .expect = z.fmt("The union can't use the `{s}` layout.", .{@tagName(info.layout)}),
            .option = z.fmt("forbid-layout[{s}]", .{@tagName(info.layout)}),
            .actual = z.fmt("The union layout is `{s}`", .{@tagName(info.layout)}),
            // TODO: .repair  = "layout suggestion",
        });

        variants_count: switch (o.variant_count) {
            .no_option => {},
            .exact_items => continue :variants_count .{ .exact = o.variants.slice.len },
            .least_items => continue :variants_count .{ .least = o.variants.slice.len },
            .exact => |exact| if (info.fields.len != exact) return r.withFailure(.{
                .@"error" = error.WrongVariantCount,
                .option = z.fmt("variant-count[=={}]", .{exact}),
                .expect = z.fmt("The variant count must be exactly {}.", .{exact}),
                .actual = z.fmt("The variant count is {}.", .{info.fields.len}),
            }),
            .least => |least| if (info.fields.len < least) return r.withFailure(.{
                .@"error" = error.NotEnoughVariants,
                .option = z.fmt("variant-count[<={}]", .{least}),
                .expect = z.fmt("There must be at least {} variants.", .{least}),
                .actual = z.fmt("The variant count is {}.", .{info.fields.len}),
            }),
        }

        for (o.variants.slice) |expect| {
            const actual: std.builtin.Type.UnionField = for (info.fields) |variant| {
                if (z.eql(u8, variant.name, expect.name)) break variant;
            } else return r.withFailure(.{
                .@"error" = error.MissingVariant,
                .expect = z.fmt("The union type must have a variant named \"{s}\".", .{expect.name}),
                .option = z.fmt("has-variant[\"{s}\"]", .{expect.name}),
            });

            if (r.propagateFail(actual.type, expect.trait, .{
                .option = .withTraitName(z.fmt("has-variant[\"{s}\" => {{s}}]", .{actual.name})),
                .expect = .withTraitName(z.fmt(
                    "The type of the variant \"{s}\" must satisfy the trait `{{s}}`.",
                    .{actual.name},
                )),
            })) |fail| return fail;

            if (!expect.alignment.has(
                @alignOf(actual.type),
                actual.alignment,
            )) return r.withFailure(switch (expect.alignment) {
                .no_option => unreachable,
                .custom => |custom| .{
                    .@"error" = error.WrongVariantAlignment,
                    .option = z.fmt("has-variant[\"{s}\", alignment == {}]", .{ actual.name, custom }),
                    .expect = z.fmt(
                        "The alignment of the variant \"{s}\" must be exactly {}.",
                        .{ actual.name, custom },
                    ),
                    .actual = z.fmt(
                        "The alignment of the variant \"{s}\" is {}.",
                        .{ actual.name, actual.alignment },
                    ),
                },
                .least_custom => |least| .{
                    .@"error" = error.VariantAlignmentTooSmall,
                    .option = z.fmt("has-field[\"{s}\", alignment <= {}]", .{ actual.name, least }),
                    .expect = z.fmt(
                        "The alignment of the field \"{s}\" must be at least {}.",
                        .{ actual.name, least },
                    ),
                    .actual = z.fmt(
                        "The alignment of the field \"{s}\" is {}.",
                        .{ actual.name, actual.alignment },
                    ),
                },
                .natural => .{
                    .@"error" = error.NonNaturalVariantAlignment,
                    .option = z.fmt("has-field[\"{s}\", natural-alignment]", .{actual.name}),
                    .expect = z.fmt("The alignment of the variant \"{s}\" must be the natural alignment of its type."),
                    .actual = z.fmt(
                        "The natural alignment of its type is {} but the variant's alignment is {}.",
                        .{ @alignOf(actual.type), actual.alignment },
                    ),
                },
                .least_natural => .{
                    .@"error" = error.SmallerThanNaturalVariantAlignment,
                    .option = z.fmt("has-variant[\"{s}\", least-natural-alignment]", .{actual.name}),
                    .expect = z.fmt(
                        "The alignment of the variant \"{s}\" must be at least the natural alignment of its type.",
                        .{actual.name},
                    ),
                    .actual = z.fmt(
                        "The natural alignment of its type is {} but the variant's alignment is {}.",
                        .{ @alignOf(actual.type), actual.alignment },
                    ),
                },
            });
        }

        return r;
    }
}
