const kind = @import("kind.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    signed: ?bool = null,
    must_repr: z.Range(.inner) = .{},
    cant_repr: z.Range(.outer) = .{},
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-int", "The type must be an integer.");

        if (r.propagateFail(T, .isKind(.int), .{})) |fail|
            return fail;

        const info = @typeInfo(T).int;

        if (o.signed) |signed| switch (signed) {
            true => if (info.signedness == .unsigned) return r.withFailure(.{
                .@"error" = error.IsUnsignedInt,
                .option = "signed",
                .expect = "The type must be a signed integer.",
                .actual = z.fmt("The type is {s}, an unsigned integer.", .{@typeName(T)}),
            }),
            false => if (info.signedness == .signed) return r.withFailure(.{
                .@"error" = error.IsSignedInt,
                .option = "unsigned",
                .expect = "The type must be an unsigned integer.",
                .actual = z.fmt("The type is {s}, a signed integer.", .{@typeName(T)}),
            }),
        };

        const max = std.math.maxInt(T);
        const min = std.math.minInt(T);

        // can't < first <= can <= last < can't
        if (o.cant_repr.first) |first| if (min <= first) return r.withFailure(.{
            .@"error" = error.ForbiddenRepresentation,
            .option = z.fmt("cant-until[{}]", .{first}),
            .expect = z.fmt("The integer type must be unable to represent {} or less.", .{first}),
            .actual = z.fmt("The integer can represent {}.", .{min}),
        });

        if (o.cant_repr.last) |last| if (last <= max) return r.withFailure(.{
            .@"error" = error.ForbiddenRepresentation,
            .option = z.fmt("cant-from[{}]", .{last}),
            .expect = z.fmt("The integer type must be unable to represent {} or more.", .{last}),
            .actual = z.fmt("The integer can represent {}.", .{max}),
        });

        // doesn't have to <= first <= must <= last <= doesn't have to
        if (o.must_repr.first) |first| if (first < min) return r.withFailure(.{
            .@"error" = error.MissingRepresentation,
            .option = z.fmt("must-from[{}]", .{first}),
            .expect = z.fmt("The integer type must be able to represent {}.", .{first}),
            .actual = z.fmt("The smallest integer it can represent is {}.", .{min}),
        });

        if (o.must_repr.last) |last| if (max < last) return r.withFailure(.{
            .@"error" = error.MissingRepresentation,
            .option = z.fmt("must-until[{}]", .{last}),
            .expect = z.fmt("The integer type must be able to represent {}.", .{last}),
            .actual = z.fmt("The biggest integer it can represent is {}.", .{max}),
        });

        return r;
    }
}
