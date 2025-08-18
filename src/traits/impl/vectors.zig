const std = @import("std");
const z = @import("../../root.zig");
const kind = @import("kind.zig");

pub const Options = struct {
    child: z.Trait = .no_trait,
    length: Length = .no_option,

    pub const Length = union(enum) {
        eql: usize,
        range: z.Range(.inner),
        at_least_suggest: AtLeastSuggest,
        at_most_suggest: AtMostSuggest,
        suggest,

        const AtLeastSuggest = struct { at_most: ?usize = null };
        const AtMostSuggest = struct { at_least: ?usize = null };

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
            .option = .fmtOne("child => {s}", .trait),
            .expect = .fmtOne("The vector's child must satisfy the trait `{s}`.", .trait),
        })) |fail| return fail;

        const suggest = std.simd.suggestVectorLength(Child) orelse 1;

        const actual_length_msg = z.fmt("The vector's length is {}.", .{info.len});

        block: switch (o.length) {
            .range => |range| if (range.first != null and info.len < range.first.?) return r.failWith(.{
                .@"error" = error.VectorTooShort,
                .option = z.fmt("{} <= len", .{range.first.?}),
                .expect = z.fmt("The vector's length must be at least {}.", .{range.first.?}),
                .actual = actual_length_msg,
            }) else if (range.last != null and range.last.? < info.len) return r.failWith(.{
                .@"error" = error.VectorTooLong,
                .option = z.fmt("len <= {}", .{range.last.?}),
                .expect = z.fmt("The vector's length must be at most {}.", .{range.last.?}),
                .actual = actual_length_msg,
            }),
            .at_least_suggest => |at_least_suggest| if (info.len < suggest) return r.failWith(.{
                .@"error" = error.VectorShorterThanSuggest,
                .option = "suggest <= len",
                .expect = z.fmt(
                    "The vector's length must be at least the length suggested by `std.simd.suggestVectorLength` ({}).",
                    .{suggest},
                ),
                .actual = actual_length_msg,
            }) else if (at_least_suggest.max) |max| continue :block .atMost(max),
            .at_most_suggest => |at_most_suggest| if (suggest < info.len) return r.failWith(.{
                .@"error" = error.VectorLongerThanSuggest,
                .option = "len <= suggest",
                .expect = z.fmt(
                    "The vector's length must be at most the length suggested by `std.simd.suggestVectorLength` ({}).",
                    .{suggest},
                ),
                .actual = actual_length_msg,
            }) else if (at_most_suggest.at_least) |min| continue :block .atLeast(min),
            .suggest => if (suggest != info.len) return r.failWith(.{
                .@"error" = error.VectorLengthNotSuggest,
                .option = "len == suggest",
                .actual = actual_length_msg,
                .expect = z.fmt(
                    "The vector's length must be the length suggested by `std.simd.suggestVectorLength` ({}).",
                    .{suggest},
                ),
            }),
            .eql => |eql| if (eql != info.len) return r.failWith(.{
                .@"error" = error.WrongVectorLength,
                .option = z.fmt("len == {}", .{eql}),
                .actual = actual_length_msg,
                .expect = z.fmt("The vector's length must be {}.", .{eql}),
            }),
        }

        return r;
    }
}
