const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    auto: ?bool = null,
    managed: ?bool = null,
    store_hash: ?bool = null,

    key: z.Trait = .no_trait,
    val: z.Trait = .no_trait,

    context: z.Trait = .no_trait,
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            "is-array-hash-map",
            "The type must come from an `std.ArrayHashMap` function.",
        );

        const not_array_hash_map = r.withFailure(.{
            .@"error" = error.NotArrayHashMap,
            .expect = "The type must come from `std.ArrayHashMap` or `std.ArrayHashMapUnmanaged`.",
        });

        const is_managed = z.Trait.hasDecl("Unmanaged", .{ .of_type_which = .is(type) });
        const actual_managed, const Unmanaged = if (is_managed.check(T))
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
                return not_array_hash_map;

            break :kv [2]type{
                @FieldType(Unmanaged.KV, "key"),
                @FieldType(Unmanaged.KV, "value"),
            };
        };

        const Context = ctx: {
            const has_get_entry_context = z.Trait.hasDecl("getEntryContext", .{
                .of_type_which = .isFunction(.{
                    .param_count = .exact_items,
                    .params = .many(&.{
                        .{ .trait = .is(Unmanaged) },
                        .{ .trait = .is(Key) },
                        .{ .is_generic = false },
                    }),
                }),
            });

            if (!has_get_entry_context.check(Unmanaged))
                return not_array_hash_map;

            break :ctx @typeInfo(@TypeOf(Unmanaged.getEntryContext)).@"fn".params[2].type.?;
        };

        const actual_store_hash = sh: {
            const has_hash = z.Trait.hasDecl("Hash", .{ .of_type_which = .is(type) });
            if (!has_hash.check(Unmanaged))
                return not_array_hash_map;

            break :sh Unmanaged.Hash != void;
        };

        if (actual_managed)
            if (T != std.ArrayHashMap(Key, Val, Context, actual_store_hash))
                return not_array_hash_map;

        if (r.propagateFail(Key, o.key, .{
            .option = .withTraitName("K => {s}"),
            .expect = .withTraitName("The `Key` type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (r.propagateFail(Val, o.val, .{
            .option = .withTraitName("V => {s}"),
            .expect = .withTraitName("The `Value` type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        if (r.propagateFail(Context, o.context, .{
            .option = .withTraitName("Context => {s}"),
            .expect = .withTraitName("The `Context` type must satisfy the trait `{s}`."),
        })) |fail| return fail;

        const actual_auto =
            Context == std.array_hash_map.AutoContext(Key) and
            actual_store_hash == !std.array_hash_map.autoEqlIsCheap(Key);

        if (o.auto) |expect_auto| if (expect_auto != actual_auto) return r.withFailure(.{
            .@"error" = if (actual_auto) error.IsAuto else error.IsNotAuto,
            .option = if (expect_auto) "auto" else "not-auto",
            .expect = z.fmt(
                "The array hash map {s} use the auto context.",
                .{if (expect_auto) "must" else "can't"},
            ),
        });

        if (o.managed) |expect_managed| if (actual_managed != expect_managed) return r.withFailure(.{
            .@"error" = if (actual_managed) error.IsManaged else error.IsUnmanaged,
            .option = if (expect_managed) "managed" else "unmanaged",
            .expect = z.fmt(
                "The array hash map {s} be managed.",
                .{if (expect_managed) "must" else "can't"},
            ),
        });

        if (o.store_hash) |expect_store_hash| if (actual_store_hash != expect_store_hash) return r.withFailure(.{
            .@"error" = if (actual_store_hash) error.StoreHash else error.NoStoreHash,
            .option = if (expect_store_hash) "store-hash" else "no-store-hash",
            .expect = z.fmt(
                "The array hash map {s} store the hash.",
                .{if (expect_store_hash) "must" else "can't"},
            ),
        });

        return r;
    }
}

pub const ContextOptions = @import("hash_maps.zig").ContextOptions;

pub fn isContext(comptime T: type, comptime co: ContextOptions) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            "is-array-hash-map-context",
            "The type must be suitable as an array hash map context.",
        );

        if (r.propagateFail(T, .hasMethod("hash", .{
            .is_varargs = false,
            .is_generic = false,
            .return_type = .{ .trait = .is(u32) },
            .other_param_count = .{ .exact = 1 },
        }), .{
            .expect = .str("The type must have a `fn hash(self, Key) u32` function."),
        })) |fail| return fail;

        if (r.propagateFail(T, .hasMethod("eql", .{
            .is_varargs = false,
            .is_generic = false,
            .return_type = .{ .trait = .is(bool) },
            .other_param_count = .{ .exact = 3 },
            .other_params = .many(&.{ .{}, .{}, .{ .trait = .is(usize) } }),
        }), .{
            .expect = .str("The type must have a `fn eql(self, Key, Key, u32) bool` function"),
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
            .option = .withTraitName("key => {s}"),
        })) |fail| return fail;

        if (r.propagateFail(T, co.context, .{
            .option = .withTraitName("{s}"),
        })) |fail| return fail;

        return r;
    }
}
