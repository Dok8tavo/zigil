const containers = @import("containers.zig");
const kind = @import("kind.zig");
const ints = @import("ints.zig");
const z = @import("../../root.zig");

pub const Options = struct {
    with: Values = .{},
    wout: Values = .{},
    is_exhaustive: ?bool = null,
    tag: z.Trait = .no_trait,

    pub const Values = struct {
        strings: []const []const u8 = &.{},

        pub fn names(comptime n: []const []const u8) Values {
            return .{ .strings = n };
        }

        pub fn name(comptime n: []const u8) Values {
            return .{ .strings = &.{n} };
        }
    };
};

pub fn is(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "is-enum", "The type must be an enum.");
        if (r.propagateFail(T, .isKind(.@"enum"), .{})) |fail|
            return fail;

        const info = @typeInfo(T).@"enum";

        const enum_exhaustiveness_name = switch (info.fields.len) {
            0 => if (info.is_exhaustive) "enum {}" else "enum { _ }",
            else => "enum { ..." ++ if (info.is_exhaustive) " }" else ", _ }",
        };

        if (o.is_exhaustive) |is_exhaustive| if (is_exhaustive != info.is_exhaustive) return r.failWith(.{
            .@"error" = if (is_exhaustive) error.IsNotExhaustive else error.IsExhaustive,
            .type = enum_exhaustiveness_name,
            .expect = z.fmt("The enum type {s} be exhaustive.", .{if (is_exhaustive) "must" else "can't"}),
            .option = if (is_exhaustive) "is-exhaustive" else "is-not-exhaustive",
            .actual = z.fmt("The enum type {s} exhaustive.", .{if (is_exhaustive) "isn't" else "is"}),
        });

        const enum_tag_name = "enum ({s}) {{" ++ if (info.fields.len == 0) "}}" else " ... }}";

        if (r.propagateFail(info.tag_type, o.tag, .{
            .type = .fmtOne(enum_tag_name, .type),
            .option = .fmtOne("tag => {s}", .trait),
            .expect = .fmtOne("The tag of the enum must respect the trait `{s}`.", .trait),
        })) |fail| return fail;

        const enum_with_name = "enum {" ++ if (info.fields.len == 0) "}" else "... }";

        for (o.with.strings) |name| if (!@hasField(T, name)) return r.failWith(.{
            .@"error" = error.MissingValue,
            .type = enum_with_name,
            .expect = z.fmt("The enum type must have a value named \"{s}\".", .{name}),
            .option = z.fmt("has[{s}]", .{name}),
        });

        for (o.wout.strings) |name| for (info.fields, 0..) |field, i| {
            if (!z.eql(u8, name, field.name)) continue;
            const enum_wout_name =
                (if (i != 0) "enum { ..., " else "enum { ") ++
                name ++
                (if (i != 0) z.fmt("({})", .{i}) else "") ++
                (if (i + 1 != info.fields.len) ", ... }" else " }");
            return r.failWith(.{
                .@"error" = error.ForbiddenValue,
                .type = enum_wout_name,
                .expect = z.fmt("The enum type can't have a value named \"{s}\".", .{name}),
                .option = z.fmt("has-no[{s}]", .{name}),
            });
        };

        return r;
    }
}
