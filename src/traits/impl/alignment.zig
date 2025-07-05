const z = @import("../../root.zig");

pub const OtherAlignment = union(enum) {
    least_custom: u16,
    least_natural,
    custom: u16,
    natural,
    no_option,

    pub fn name(comptime oa: OtherAlignment) ?[]const u8 {
        return switch (oa) {
            .no_option => null,
            .custom => |n| z.fmt("{}", .{n}),
            .natural => "natural",
            .least_custom => |min| z.fmt("{}<=", .{min}),
            .least_natural => "natural<=",
        };
    }

    pub fn err(comptime oa: OtherAlignment) anyerror {
        return switch (oa) {
            .no_option => error.UnreachableError,
            .custom => error.NotRequiredAlignment,
            .natural => error.NotNaturalAlignment,
            .least_custom => error.LessThanRequiredAlignment,
            .least_natural => error.LessThanNaturalAlignment,
        };
    }

    pub fn has(comptime oa: OtherAlignment, comptime natural: u16, comptime alignment: u16) bool {
        return switch (oa) {
            .no_option => true,
            .custom => |exact| exact == alignment,
            .natural => natural == alignment,
            .least_custom => |min| min <= alignment,
            .least_natural => natural <= alignment,
        };
    }
};

pub const NaturalAlignment = union(enum) {
    exact: u16,
    least: u16,
};

pub fn hasNaturalAlignment(comptime T: type, comptime na: NaturalAlignment) z.Trait.Result {
    comptime {
        var r = z.Trait.Result.init(T, "has-natural-alignment", "");

        const actual = @alignOf(T);
        switch (na) {
            .exact => |exact| if (actual != exact) return r.withFailure(.{
                .@"error" = error.WrongNaturalAlignment,
                .option = z.fmt("[=={}]", .{exact}),
                .expect = z.fmt("The natural alignment of the type must be exactly {}.", .{exact}),
                .actual = z.fmt("The natural alignment of the type is {}.", .{actual}),
            }),
            .least => |least| if (actual < least) return r.withFailure(.{
                .@"error" = error.NaturalAlignmentTooSmall,
                .option = z.fmt("[>={}]", .{least}),
                .expect = z.fmt("The natural alignment of the type must be at least {}.", .{least}),
                .actual = z.fmt("The natural alignement of the type is {}.", .{actual}),
            }),
        }

        return r;
    }
}
