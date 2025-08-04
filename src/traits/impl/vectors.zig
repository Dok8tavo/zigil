const std = @import("std");
const z = @import("../../root.zig");
const kind = @import("kind.zig");

pub const Options = struct {
    child: z.Trait = .no_trait,
    length: Length = .no_option,

    pub const Length = union(enum) {
        eql: usize,
        range: z.Range(.inner),
        min_suggested: Max,
        max_suggested: Min,
        suggested,

        const Max = struct { max: ?usize = null };
        const Min = struct { min: ?usize = null };

        pub const no_option = Length{ .range = .{} };

        pub fn atMost(comptime m: comptime_int) Length {
            return .{ .range = .until(m) };
        }

        pub fn atLeast(comptime m: comptime_int) Length {
            return .{ .range = .from(m) };
        }

        pub fn between(comptime l1: comptime_int, comptime l2: comptime_int) Length {
            return .{ .range = .range(l1, l2) };
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            "is-vector",
            "The type must be a vector.",
        );

        if (r.propagateFail(T, .isKind(.vector), .{})) |fail|
            return fail;

        const info = @typeInfo(T).vector;
        const Child = info.child;

        if (r.propagateFail(Child, o.child, .{
            .type = .fmtOne("@Vector(..., {s})", .type),
            .option = .fmtOne("child => {s}", .trait),
            .expect = .fmtOne("The vector's child must satisfy the trait {s}.", .trait),
        })) |fail| return fail;

        const suggested = std.simd.suggestVectorLength(Child) orelse 1;

        const vector_length_name = z.fmt("@Vector({}, ...)", .{info.len});
        const actual_length_msg = z.fmt("The vector's length is {}.", .{info.len});

        block: switch (o.length) {
            .range => |range| if (range.first != null and info.len < range.first.?) return r.failWith(.{
                .@"error" = error.VectorTooShort,
                .type = vector_length_name,
                .option = z.fmt("{} <= len", .{range.first.?}),
                .expect = z.fmt("The vector's length must be at least {}.", .{range.first.?}),
                .actual = actual_length_msg,
            }) else if (range.last != null and range.last.? < info.len) return r.failWith(.{
                .@"error" = error.VectorTooLong,
                .type = vector_length_name,
                .option = z.fmt("len <= {}", .{range.last.?}),
                .expect = z.fmt("The vector's length must be at most {}.", .{range.last.?}),
                .actual = actual_length_msg,
            }),
            .min_suggested => |min_suggested| if (info.len < suggested) return r.failWith(.{
                .@"error" = error.VectorShorterThanSuggested,
                .type = vector_length_name,
                .option = "suggest <= len",
                .expect = z.fmt(
                    "The vector's length must be at least the length suggested by `std.simd.suggestVectorLength` ({}).",
                    .{suggested},
                ),
                .actual = actual_length_msg,
            }) else if (min_suggested.max) |max| continue :block .atMost(max),
            .max_suggested => |max_suggested| if (suggested < info.len) return r.failWith(.{
                .@"error" = error.VectorLongerThanSuggested,
                .type = vector_length_name,
                .option = "len <= suggest",
                .expect = z.fmt(
                    "The vector's length must be at most the length suggested by `std.simd.suggestVectorLength` ({}).",
                    .{suggested},
                ),
                .actual = actual_length_msg,
            }) else if (max_suggested.min) |min| continue :block .atLeast(min),
            .suggested => if (suggested != info.len) return r.failWith(.{
                .@"error" = error.VectorLengthNotSuggested,
                .type = vector_length_name,
                .option = "len == suggest",
                .actual = actual_length_msg,
                .expect = z.fmt(
                    "The vector's length must be the length suggested by `std.simd.suggestVectorLength` ({}).",
                    .{suggested},
                ),
            }),
            .eql => |eql| if (eql != info.len) return r.failWith(.{
                .@"error" = error.WrongVectorLength,
                .type = vector_length_name,
                .option = z.fmt("len == {}", .{eql}),
                .actual = actual_length_msg,
                .expect = z.fmt("The vector's length must be {}.", .{eql}),
            }),
        }

        return r;
    }
}
