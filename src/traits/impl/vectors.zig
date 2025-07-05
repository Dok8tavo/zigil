const std = @import("std");
const z = @import("../../root.zig");
const kind = @import("kind.zig");

pub const Options = struct {
    child: z.Trait = .no_trait,
    len: Length = .no_option,
    max_len: Length = .no_option,
    min_len: Length = .no_option,

    pub const Length = union(enum) {
        no_option,
        suggested,
        is: usize,
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-vector", "The type must be a vector.");

        if (r.propagateFail(T, .isKind(.vector), .{})) |fail|
            return fail;

        const info = @typeInfo(T).vector;
        const Child = info.child;
        if (r.propagateFail(Child, o.child, .{
            .option = .withTraitName("child => {s}"),
            .expect = .withTraitName("The type must be a vector whose child satisfy the trait {s}."),
        })) |fail| return fail;

        const suggested = std.simd.suggestVectorLength(Child) orelse 1;

        const eql: ?usize = switch (o.len) {
            .suggested => suggested,
            .no_option => null,
            .is => |eql| eql,
        };

        const min = switch (o.min_len) {
            .suggested => suggested,
            .no_option => 0,
            .is => |min| min,
        };

        const max = switch (o.max_len) {
            .suggested => suggested,
            .no_option => std.math.maxInt(usize),
            .is => |max| max,
        };

        if (max < min) return r.withFailure(.{
            .@"error" = error.ImpossibleRequirement,
            .option = z.fmt("max-len[{}] < min-len[{}]", .{ max, min }),
            .expect = z.fmt("The length of the vector type must be at most {} but at least {}.", .{ max, min }),
        });

        if (eql) |eql_len| {
            if (eql_len < min) return r.withFailure(.{
                .@"error" = error.ImpossibleRequirement,
                .option = z.fmt("eql-len[{}] < min-len[{}]", .{ eql_len, min }),
                .expect = z.fmt("The length of the vector type must be exactly {} but at least {}.", .{ eql_len, min }),
            });

            if (max < eql_len) return r.withFailure(.{
                .@"error" = error.ImpossibleRequirement,
                .option = z.fmt("max-len[{}] < eql-len[{}]", .{ max, eql_len }),
                .expect = z.fmt("The length of the vector type must be exactly {} but at most {}.", .{ eql_len, max }),
            });
        }

        const len = info.len;

        if (eql) |eql_len| return if (eql_len != len) r.withFailure(.{
            .@"error" = error.WrongLength,
            .actual = z.fmt("The vector's length is {}.", .{len}),
            .option = z.fmt("eql-len[{}]", .{eql_len}),
            .expect = z.fmt("The vector's length must be exactly {}.", .{eql_len}),
        }) else r;

        if (len < min) return r.withFailure(.{
            .@"error" = error.VectorTooShort,
            .actual = z.fmt("The vector's length is {}.", .{len}),
            .option = z.fmt("min-len[{}]", .{min}),
            .expect = z.fmt("The vector's length must be at least {}.", .{min}),
        });

        if (max < len) return r.withFailure(.{
            .@"error" = error.VectorTooLong,
            .actual = z.fmt("The vector's length is {}.", .{len}),
            .option = z.fmt("max-len[{}]", .{max}),
            .expect = z.fmt("The vector's length must be at most {}.", .{max}),
        });

        return r;
    }
}
