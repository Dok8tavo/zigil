const z = @import("../../root.zig");

pub const Options = struct {
    child: z.Trait = .no_trait,
    length: Length = .{},

    pub const Length = struct {
        inner: z.Range(.inner) = .{},

        pub fn eql(comptime l: comptime_int) Length {
            return .{ .inner = .range(l, l) };
        }

        pub fn between(comptime l1: comptime_int, comptime l2: comptime_int) Length {
            return .{ .inner = .range(l1, l2) };
        }

        pub fn atLeast(comptime l: comptime_int) Length {
            return .{ .inner = .from(l) };
        }

        pub fn atMost(comptime l: comptime_int) Length {
            return .{ .inner = .until(l) };
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-array", "The type must be an array.");

        if (r.propagateFail(T, .isKind(.array), .{})) |fail|
            return fail;

        const info = @typeInfo(T).array;
        if (r.propagateFail(info.child, o.child, .{
            .type = .fmtOne("[_]{s}", .type),
            .option = .fmtOne("child => {s}", .trait),
            .expect = .fmtOne("The array's child must satisfy the trait `{s}`.", .trait),
        })) |fail| return fail;

        const array_length_name = z.fmt("[{}]@Child", .{info.len});
        const actual_length_msg = z.fmt("The array's length is {}.", .{info.len});

        if (o.length.inner.first != null and
            o.length.inner.last != null and
            o.length.inner.first.? == o.length.inner.last.? and
            o.length.inner.first.? != info.len) return r.failWith(.{
            .@"error" = error.WrongArrayLength,
            .type = array_length_name,
            .option = z.fmt("len == {}", .{o.length.inner.first.?}),
            .actual = actual_length_msg,
            .expect = z.fmt("The array's length must be {}.", .{o.length.inner.first.?}),
        });

        if (o.length.inner.first) |at_least| if (info.len < at_least) return r.failWith(.{
            .@"error" = error.ArrayTooShort,
            .option = z.fmt("{} <= len", .{at_least}),
            .type = array_length_name,
            .actual = actual_length_msg,
            .expect = z.fmt("The array's length must be at least {}.", .{at_least}),
        });

        if (o.length.inner.last) |at_most| if (at_most < info.len) return r.failWith(.{
            .@"error" = error.ArrayTooLong,
            .option = z.fmt("len <= {}", .{at_most}),
            .type = array_length_name,
            .actual = actual_length_msg,
            .expect = z.fmt("The array's length must be at most {}.", .{at_most}),
        });

        return r;
    }
}
