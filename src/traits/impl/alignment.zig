const z = @import("../../root.zig");

pub const Other = union(enum) {
    least_custom: u16,
    least_natural,
    custom: u16,
    natural,

    pub fn optionName(comptime o: Other) []const u8 {
        return switch (o) {
            .custom => |n| z.fmt("{}", .{n}),
            .natural => "natural",
            .least_custom => |min| z.fmt("{}<=", .{min}),
            .least_natural => "natural<=",
        };
    }

    pub fn err(comptime o: Other) anyerror {
        return switch (o) {
            .custom => error.NotRequiredAlignment,
            .natural => error.NotNaturalAlignment,
            .least_custom => error.LessThanRequiredAlignment,
            .least_natural => error.LessThanNaturalAlignment,
        };
    }

    pub fn has(comptime o: Other, comptime natural: u16, comptime alignment: u16) bool {
        return switch (o) {
            .custom => |exact| exact == alignment,
            .natural => natural == alignment,
            .least_custom => |min| min <= alignment,
            .least_natural => natural <= alignment,
        };
    }

    pub fn result(comptime o: Other, comptime T: type, comptime alignment: u16) z.Trait.Result {
        comptime {
            const r = z.Trait.Result.init(T, o.optionName(), "The alignment must be " ++ switch (o) {
                .custom => |custom| z.fmt("exactly {}.", .{custom}),
                .natural => "natural.",
                .least_custom => |least| z.fmt("at least {}.", .{least}),
                .least_natural => "at least natural.",
            });

            if (!o.has(@alignOf(T), alignment)) return r.failWith(.{
                .@"error" = o.err(),
                .actual = z.fmt("The alignment is {}{s}.", .{ alignment, switch (o) {
                    .natural => z.fmt(" instead of {}", .{@alignOf(T)}),
                    .least_natural => z.fmt(" instead of at least {}.", .{@alignOf(T)}),
                    else => "",
                } }),
            });

            return r;
        }
    }
};

pub const Natural = union(enum) {
    exact: u16,
    least: u16,

    pub fn result(comptime n: Natural, comptime T: type) z.Trait.Result {
        comptime {
            var r = z.Trait.Result.init(
                T,
                "has-natural-alignment",
                z.fmt("The type must have a natural of {s} {d}.", switch (n) {
                    .exact => |exact| .{ "exactly", exact },
                    .least => |least| .{ "at least", least },
                }),
            );

            const actual = @alignOf(T);

            switch (n) {
                .exact => |exact| if (actual != exact) return r.failWith(.{
                    .@"error" = error.WrongNaturalAlignment,
                    //.option = z.fmt("[=={}]", .{exact}),
                    .expect = z.fmt("The natural alignment of the type must be exactly {}.", .{exact}),
                    .actual = z.fmt("The natural alignment of the type is {}.", .{actual}),
                }),
                .least => |least| if (actual < least) return r.failWith(.{
                    .@"error" = error.NaturalAlignmentTooSmall,
                    //.option = z.fmt("[>={}]", .{least}),
                    .expect = z.fmt("The natural alignment of the type must be at least {}.", .{least}),
                    .actual = z.fmt("The natural alignement of the type is {}.", .{actual}),
                }),
            }

            return r;
        }
    }
};
