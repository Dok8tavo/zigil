const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    auto: ?bool = null,
    managed: ?bool = null,

    context: z.Trait = .no_trait,

    key: z.Trait = .no_trait,
    val: z.Trait = .no_trait,

    max_load_percentage: ?u7 = null,
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.default(
            T,
            "is-hash-map",
            "The type must come from an `std.HashMap`function.",
        );

        const not_hash_map = r.failWith(.{
            .@"error" = error.NotAHashMap,
            .expect = "The type must come from `std.HashMap` or `std.HashMapUnmanaged",
        });

        const actual_managed, const Unmanaged = if (z.Trait.hasDecl("Unmanaged", .{ .of_type_which = .is(type) }).check(T))
            .{ true, T.Unmanaged }
        else
            .{ false, T };

        const Key, const Val = kv: {
            const has_kv = z.Trait.hasDecl("KV", .{
                .is_type_which = .isStruct(.{
                    .field_count = .exact_items,
                    .fields = .many(&.{
                        .{ .name = "key" },
                        .{ .name = "value" },
                    }),
                }),
            });

            if (!has_kv.check(Unmanaged))
                return not_hash_map;

            break :kv [2]type{
                @FieldType(Unmanaged.KV, "key"),
                @FieldType(Unmanaged.KV, "value"),
            };
        };

        const Context = ctx: {
            const has_promote_context = z.Trait.hasDecl("promoteContext", .{
                .of_type_which = .isFunction(.{
                    .param_count = .exact_items,
                    .params = .many(&.{
                        .{ .trait = .is(Unmanaged) },
                        .{ .trait = .is(std.mem.Allocator) },
                        .{ .is_generic = false },
                    }),
                }),
            });

            if (!has_promote_context.check(Unmanaged))
                return not_hash_map;

            break :ctx @typeInfo(@TypeOf(Unmanaged.promoteContext)).@"fn".params[2].type.?;
        };

        const actual_mlp = for (1..100) |p| {
            if (Unmanaged == std.HashMapUnmanaged(Key, Val, Context, p)) break p;
        } else return not_hash_map;

        if (actual_managed)
            if (T != std.HashMap(Key, Val, Context, actual_mlp))
                return not_hash_map;

        if (r.propagateFail(Key, o.key, .{
            //.option = .withTraitName("K => {s}"),
            //.expect = .withTraitName("The `Key` type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (r.propagateFail(Val, o.val, .{
            //.option = .withTraitName("V => {s}"),
            //.expect = .withTraitName("The `Value` type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (r.propagateFail(Context, o.context, .{
            //.option = .withTraitName("Context => {s}"),
            //.expect = .withTraitName("The `Context` type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        const actual_auto =
            Context == std.hash_map.AutoContext(Key) and
            actual_mlp == std.hash_map.default_max_load_percentage;
        if (o.auto) |expect_auto| if (expect_auto != actual_auto) return r.failWith(.{
            .@"error" = if (actual_auto) error.IsAuto else error.IsNotAuto,
            //.option = if (expect_auto) "auto" else "not-auto",
            .expect = z.fmt(
                "The hash map {s} use the auto context.",
                .{if (expect_auto) "must" else "can't"},
            ),
        });

        if (o.managed) |expect_managed| if (actual_managed != expect_managed) return r.failWith(.{
            .@"error" = if (actual_managed) error.IsManaged else error.IsUnmanaged,
            //.option = if (expect_managed) "managed" else "unmanaged",
            .expect = z.fmt(
                "The hash map {s} be managed.",
                .{if (expect_managed) "must" else "can't"},
            ),
        });

        if (o.max_load_percentage) |expect_mlp| if (expect_mlp != actual_mlp) return r.failWith(.{
            .@"error" = error.WrongMaxLoadPercentage,
            //.option = z.fmt("max-load == {}%", .{expect_mlp}),
            .expect = z.fmt("The max load percentage must be {}.", .{expect_mlp}),
            .actual = z.fmt("The max load percentage is {}.", .{actual_mlp}),
        });

        return r;
    }
}

pub const ContextOptions = struct {
    context: z.Trait = .no_trait,
    key: z.Trait = .no_trait,
};

pub fn isContext(comptime T: type, comptime co: ContextOptions) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.default(
            T,
            "is-hash-map-context",
            "The type must be suitable as a hash map context.",
        );

        if (r.propagateFail(T, .hasMethod("hash", .{
            .is_generic = false,
            .is_var_args = false,
            .return_type = .{ .trait = .is(u64) },
            .other_param_count = .{ .exact = 1 },
        }), .{
            .expect = .str("The type must have a `fn hash(self, Key) u64` method."),
        })) |fail| return fail;

        if (r.propagateFail(T, .hasMethod("eql", .{
            .is_var_args = false,
            .is_generic = false,
            .return_type = .{ .trait = .is(bool) },
            .other_param_count = .{ .exact = 2 },
        }), .{
            .expect = .str("The type must have `fn eql(self, Key, Key) bool` method."),
        })) |fail| return fail;

        const HashKey = @typeInfo(@TypeOf(T.hash)).@"fn".params[1].type.?;
        const EqlKey1 = @typeInfo(@TypeOf(T.eql)).@"fn".params[1].type.?;
        const EqlKey2 = @typeInfo(@TypeOf(T.eql)).@"fn".params[2].type.?;

        if (r.propagateFail(EqlKey1, .is(HashKey), .{
            .expect = .str("The second parameters of the `hash` and `eql` methods must have the same type."),
        })) |fail| return fail;

        if (r.propagateFail(EqlKey2, .is(EqlKey1), .{
            .expect = .str("The second and third parameters of the `eql` method must have the same type."),
        })) |fail| return fail;

        if (r.propagateFail(HashKey, co.key, .{
            //.option = .withTraitName("key => {s}"),
        })) |fail| return fail;

        if (r.propagateFail(T, co.context, .{
            //.option = .withTraitName("{s}"),
        })) |fail| return fail;

        return r;
    }
}
