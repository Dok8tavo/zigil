const z = @import("../../root.zig");

const ebq_factor = 100_000;

pub const Id = @TypeOf(.enum_literal);
pub const Anytype = Any(null, .no_trait);

pub fn AnyId(comptime id: ?Id) type {
    return Any(id, .no_trait);
}

pub fn AnyTrait(comptime t: z.Trait) type {
    return Any(null, t);
}

pub fn Any(comptime id: ?Id, comptime t: z.Trait) type {
    return struct {
        comptime id: ?Id = id,
        comptime trait: z.Trait = t,

        const Self = @This();

        fn getId() ?Id {
            return (@This(){}).id;
        }

        fn getTrait() z.Trait {
            return (@This(){}).trait;
        }

        fn match(comptime T: type, comptime p: *Pairs) z.Trait.Result {
            comptime {
                if (id) |_|
                    return matchId(T, p);
                return t.result(T);
            }
        }

        fn matchId(comptime T: type, comptime p: *Pairs) z.Trait.Result {
            comptime {
                const r = z.Trait.Result.init(
                    T,
                    z.fmt("match[.{s}]", .{@tagName(id.?)}),
                    z.fmt(
                        "The type must correspond to `.{s}`.",
                        .{@tagName(id.?)},
                    ),
                );

                if (p.get(id.?)) |U| {
                    if (U != T) return r.failWith(.{
                        .@"error" = error.Mismatch,
                        .expect = z.fmt(
                            "The type must correspond to `.{s}`, which is `{s}`.",
                            .{ @tagName(id.?), @typeName(U) },
                        ),
                    });
                } else p.add(id.?, T);

                return t.result(T);
            }
        }
    };
}

const Pairs = struct {
    slice: []const Pair = &.{},

    const Pair = struct { id: Id, type: type };

    fn add(comptime p: *Pairs, comptime id: Id, comptime T: type) void {
        comptime p.slice = p.slice ++ &[_]Pair{.{ .id = id, .type = T }};
    }

    fn get(comptime p: Pairs, comptime id: Id) ?type {
        comptime return for (p.slice) |pair| {
            if (id == pair.id) break pair.type;
        } else null;
    }
};

pub fn isMatcher(comptime T: type) bool {
    comptime {
        const info = switch (@typeInfo(T)) {
            .@"struct" => |struct_info| struct_info,
            else => return false,
        };

        if (info.is_tuple) return false;

        const id = for (info.fields) |field| {
            if (z.eql(u8, field.name, "id")) {
                if (field.type != ?Id)
                    return false;
                break field.defaultValue() orelse return false;
            }
        } else return false;

        const trait = for (info.fields) |field| {
            if (z.eql(u8, field.name, "trait")) {
                if (field.type != z.Trait)
                    return false;
                break field.defaultValue() orelse return false;
            }
        } else return false;

        return Any(id, trait) == T;
    }
}

pub fn uMatchT(comptime U: type, comptime T: type) z.Trait.Result {
    comptime {
        var pairs = Pairs{};
        return uMatchT2(U, T, &pairs);
    }
}

pub fn uMatchT2(comptime U: type, comptime T: type, comptime pairs: *Pairs) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            U,
            "match[" ++ @typeName(T) ++ "]",
            "The type must match `" ++ @typeName(T) ++ "`.",
        );

        if (isMatcher(T))
            return r.propagateFailResult(T.match(U, pairs), .{}) orelse r;

        return switch (@typeInfo(T)) {
            .void,
            .type,
            .bool,
            .int,
            .float,
            .comptime_int,
            .comptime_float,
            .@"anyframe",
            .frame,
            .@"enum",
            .enum_literal,
            .@"union",
            .@"opaque",
            => r.propagateFail(U, .is(T), .{}) orelse r,
            .@"struct" => |info| if (info.is_tuple)
                r.propagateFailResult(matchTuple(U, T, pairs), .{}) orelse r
            else
                r.propagateFail(U, .is(T), .{}) orelse r,
            .@"fn" => r.propagateFailResult(matchFn(U, T, pairs), .{}) orelse r,
            .pointer => r.propagateFailResult(matchPointer(U, T, pairs), .{}) orelse r,
            else => z.compileError("Not implemented yet!", .{}),
        };
    }
}

pub fn matchFn(comptime T: type, comptime Fn: type, comptime pairs: *Pairs) z.Trait.Result {
    comptime {
        const fns = @import("functions.zig");

        z.Trait.isFunction(.{ .is_generic = false }).assert(Fn);

        const r = z.Trait.Result.init(
            T,
            "match-function[" ++ @typeName(Fn) ++ "]",
            "The type must match the function.",
        );

        const expect_info = @typeInfo(Fn).@"fn";

        var params: []const fns.Options.Param = &.{};
        for (expect_info.params) |param| params = params ++ &[_]fns.Options.Param{.{
            .is_noalias = param.is_noalias,
            .is_generic = false,
            .trait = .no_trait,
        }};

        const match_trait = z.Trait.isFunction(.{
            .calling_convention = expect_info.calling_convention,
            .is_variadic = expect_info.is_var_args,
            .is_generic = false,
            .params = .many(params),
        });

        if (r.propagateFail(T, match_trait, .{})) |fail|
            return fail;

        const actual_info = @typeInfo(T).@"fn";

        @setEvalBranchQuota(expect_info.params.len * ebq_factor);

        for (expect_info.params, actual_info.params) |expect_param, actual_param|
            if (r.propagateFailResult(uMatchT2(actual_param.type.?, expect_param.type.?, pairs), .{})) |fail|
                return fail;

        if (r.propagateFailResult(uMatchT2(
            actual_info.return_type.?,
            expect_info.return_type.?,
            pairs,
        ), .{})) |fail| return fail;

        return r;
    }
}

pub fn matchTuple(comptime T: type, comptime Tuple: type, comptime pairs: *Pairs) z.Trait.Result {
    const is_tuple = z.Trait.isTuple(.{});

    comptime {
        is_tuple.assert(Tuple);

        const r = z.Trait.Result.init(
            T,
            z.fmt("match-tuple[{s}]", .{@typeName(Tuple)}),
            z.fmt("The type must match with the tuple `{s}`.", .{@typeName(Tuple)}),
        );

        if (r.propagateFail(T, is_tuple, .{})) |fail|
            return fail;

        const actual_info = @typeInfo(T).@"struct";
        const expect_info = @typeInfo(Tuple).@"struct";

        if (actual_info.fields.len != expect_info.fields.len) return r.failWith(.{
            .@"error" = error.WrongFieldCount,
            .expect = z.fmt("The tuple must have {} fields.", .{expect_info.fields.len}),
            .actual = z.fmt("The tuple has {} fields.", .{actual_info.fields.len}),
        });

        @setEvalBranchQuota(expect_info.fields.len * ebq_factor);

        for (expect_info.fields, actual_info.fields) |expect_field, actual_field|
            if (r.propagateFailResult(uMatchT2(actual_field.type, expect_field.type, pairs), .{})) |fail|
                return fail;

        return r;
    }
}

pub fn matchPointer(comptime T: type, comptime Pointer: type, comptime pairs: *Pairs) z.Trait.Result {
    comptime {
        // can't deal with sentinels yet
        z.Trait.isPointer(.{ .has_sentinel = false }).assert(Pointer);

        const r = z.Trait.Result.init(
            T,
            "match-pointer[" ++ @typeName(Pointer) ++ "]",
            "The type must match the pointer type",
        );

        const expect_info = @typeInfo(Pointer).pointer;

        if (r.propagateFail(T, .isPointer(.{
            .has_sentinel = false,
            .address_space = expect_info.address_space,
            .alignment = if (expect_info.alignment == @alignOf(expect_info.child))
                .natural
            else
                .{ .custom = expect_info.alignment },
            .is_allowzero = expect_info.is_allowzero,
            .is_const = expect_info.is_const,
            .is_volatile = expect_info.is_volatile,
            .size = expect_info.size,
        }), .{})) |fail| return fail;

        const actual_info = @typeInfo(T).pointer;

        if (r.propagateFailResult(uMatchT2(actual_info.child, expect_info.child, pairs), .{})) |fail|
            return fail;

        return r;
    }
}
