const alignment = @import("alignment.zig");
const containers = @import("containers.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    is_tagged: ?bool = null,
    tag: z.Trait = .no_trait,
    layout: containers.AllowLayout = .all,
    variants: Variants = .no_requirement,
    variant_count: Count = .least_items,

    pub const Count = @import("count.zig").Count;

    pub const Variants = struct {
        slice: ?[]const Variant = null,

        pub const no_requirement = Variants{};

        pub fn one(comptime field: Variant) Variants {
            comptime return Variants{ .slice = &[_]Variant{field} };
        }

        pub fn many(comptime fields: []const Variant) Variants {
            comptime return Variants{ .slice = fields };
        }
    };

    pub const Variant = struct {
        alignment: ?alignment.Other = null,
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

        if (o.is_tagged) |is_tagged| if ((info.tag_type != null) != is_tagged) return r.failWith(.{
            .@"error" = if (is_tagged) error.IsNotTagged else error.IsTagged,
            .expect = z.fmt("The type {s} be a tagged union.", .{if (is_tagged) "must" else "can't"}),
            .actual = z.fmt("The type is {s}.", .{if (is_tagged) "a bare struct" else "a tagged union"}),
            //.option = z.fmt("{s}tag", .{if (is_tagged) "" else "no-"}),
        });

        if (info.tag_type) |Tag| if (r.propagateFail(Tag, o.tag, .{
            //.option = .withTraitName("tag => {s}"),
            //.expect = .withTraitName("The union's tag must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (!o.layout.allows(info.layout)) return r.failWith(.{
            .@"error" = error.ForbiddenLayout,
            .expect = z.fmt("The union can't use the `{s}` layout.", .{@tagName(info.layout)}),
            //.option = z.fmt("forbid-layout[{s}]", .{@tagName(info.layout)}),
            .actual = z.fmt("The union layout is `{s}`", .{@tagName(info.layout)}),
            // TODO: .repair  = "layout suggestion",
        });

        variants_count: switch (o.variant_count) {
            .exact_items => if (o.variants.slice) |variants| continue :variants_count .{ .exact = variants.len },
            .least_items => if (o.variants.slice) |variants| continue :variants_count .{ .least = variants.len },
            .exact => |exact| if (info.fields.len != exact) return r.failWith(.{
                .@"error" = error.WrongVariantCount,
                //.option = z.fmt("variant-count[=={}]", .{exact}),
                .expect = z.fmt("The variant count must be exactly {}.", .{exact}),
                .actual = z.fmt("The variant count is {}.", .{info.fields.len}),
            }),
            .least => |least| if (info.fields.len < least) return r.failWith(.{
                .@"error" = error.NotEnoughVariants,
                //.option = z.fmt("variant-count[<={}]", .{least}),
                .expect = z.fmt("There must be at least {} variants.", .{least}),
                .actual = z.fmt("The variant count is {}.", .{info.fields.len}),
            }),
        }

        if (o.variants.slice) |variants| for (variants) |expect| {
            const actual: std.builtin.Type.UnionField = for (info.fields) |variant| {
                if (z.eql(u8, variant.name, expect.name)) break variant;
            } else return r.failWith(.{
                .@"error" = error.MissingVariant,
                .expect = z.fmt("The union type must have a variant named \"{s}\".", .{expect.name}),
                .option = z.fmt("has-variant[\"{s}\"]", .{expect.name}),
            });

            if (r.propagateFail(actual.type, expect.trait, .{
                //.option = .withTraitName(z.fmt("has-variant[\"{s}\" => {{s}}]", .{actual.name})),
                //.expect = .withTraitName(z.fmt(
                //    "The type of the variant \"{s}\" must satisfy the trait `{{s}}`.",
                //    .{actual.name},
                //)),
            })) |fail| return fail;

            if (expect.alignment) |expect_alignment| {
                if (r.propagateFailResult(expect_alignment.result(actual.type, actual.alignment), .{
                    //.option = z.fmt(
                    //    "alignment[\"{s}\", {s}]",
                    //    .{ actual.name, expect_alignment.optionName() },
                    //),
                    .expect = z.fmt(
                        "The alignment of the variant \"{s}\" must satisfy the given condition.",
                        .{actual.name},
                    ),
                })) |fail| return fail;
            }
        };

        return r;
    }
}
