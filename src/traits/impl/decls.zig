const z = @import("../../root.zig");

pub const Options = union(enum) {
    no_option,
    is_type_which: z.Trait,
    of_type_which: z.Trait,
};

pub fn has(comptime T: type, comptime name: []const u8, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "has-decl", z.fmt(
            "The type must have a declaration named \"{s}\".",
            .{name},
        ));

        if (r.propagateFail(T, .is_container, .{})) |fail|
            return fail;

        if (!@hasDecl(T, name)) return r.withFailure(.{
            .@"error" = error.MissingDeclaration,
            .option = z.fmt("\"{s}\"", .{name}),
        });

        const decl = @field(T, name);

        const r2 = switch (o) {
            .no_option => return r,
            .of_type_which => |t| t.result(@TypeOf(decl)),
            .is_type_which => |t| if (r.propagateFail(@TypeOf(decl), .isKind(.type), .{
                .option = .fmt("{s}, is-type", .{name}),
                .expect = .str("The declaration must be a type."),
            })) |f| return f else t.result(decl),
        };

        return r.propagateFailingResult(r2, switch (o) {
            .no_option => unreachable,
            .is_type_which => .{
                .option = z.fmt("{s}, is-type-which[{s}]", .{ name, r2.info.trait }),
                .expect = z.fmt("The declaration must be a type that respect the trait `{s}`.", .{r2.info.trait}),
            },
            .of_type_which => .{
                .option = z.fmt("{s}, of-type-which[{s}]", .{ name, r2.info.trait }),
                .expect = z.fmt("The declaration's type must respect the trait `{s}`.", .{r2.info.trait}),
            },
        }) orelse r;
    }
}
