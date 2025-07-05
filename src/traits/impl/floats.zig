const z = @import("../../root.zig");
const kind = @import("kind.zig");

pub const Options = struct {
    distinguish: Distinguish = .{},

    pub const Distinguish = struct {
        pairs: []const [2]comptime_float = &.{},

        pub fn between(comptime a: comptime_float, comptime b: comptime_float) Distinguish {
            comptime return .{ .pairs = &.{.{ a, b }} };
        }

        pub fn all(comptime floats: []const comptime_float) Distinguish {
            comptime {
                var d = Distinguish{};
                for (floats, 1..) |f1, i| if (i != floats.len) for (floats[i..]) |f2| {
                    d.pairs = d.pairs ++ &[_][2]comptime_float{.{ f1, f2 }};
                };

                return d;
            }
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-float", "The type must be a floating point.");
        if (r.propagateFail(T, .isKind(.float), .{})) |fail|
            return fail;

        for (o.distinguish.pairs) |pair| {
            const f1: T = pair[0];
            const f2: T = pair[1];

            if (f1 == f2) return r.withFailure(.{
                .@"error" = error.NotEnoughPrecision,
                .option = z.fmt("distinguish[{e}, {e}]", .{ pair[0], pair[1] }),
                .expect = z.fmt("The float type must be able to distinguish {e} from {e}.", .{ pair[0], pair[1] }),
                .actual = z.fmt("Both {e} and {e} are represented as {e}.", .{ pair[0], pair[1], f1 }),
            });
        }

        return r;
    }
}
