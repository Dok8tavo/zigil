const z = @import("../../root.zig");

pub const Options = union(enum) {
    no_option,
    is_type: z.Trait,
    of_type: z.Trait,
};

pub fn has(comptime T: type, comptime name: []const u8, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            "has-decl[" ++ name ++ "]",
            "The type must have a declaration named \"" ++ name ++ "\".",
        );

        if (r.propagateFail(T, .is_container, .{})) |fail|
            return fail;

        if (!@hasDecl(T, name)) return r.failWith(.{
            .@"error" = error.MissingDeclaration,
        });

        const decl = @field(T, name);

        // TODO: better differentiate when the trait applies to the declaration, and the declaration's type
        return switch (o) {
            .no_option => r,
            .of_type => |t| r.propagateFail(@TypeOf(decl), t, .{
                .option = .fmtOne("type => {s}", .trait),
                .expect = .fmtOne(
                    "The type of the declaration \"" ++ name ++ "\" must satisfy the trait `{s}`",
                    .trait,
                ),
            }) orelse r,
            .is_type => |t| r.propagateFail(@TypeOf(decl), .is(type), .{
                .option = .str("=> ..."),
                .expect = .str("The the declaration \"" ++ name ++
                    "\" must satisfy a trait, and therefore be a type."),
            }) orelse (r.propagateFail(decl, t, .{
                .option = .fmtOne("=> {s}", .trait),
                .expect = .fmtOne("The declaration \"" ++ name ++
                    "\" must satisfy the trait `{s}`.", .trait),
            }) orelse r),
        };
    }
}
