const functions = @import("functions.zig");
const std = @import("std");
const z = @import("../../root.zig");

pub const Options = struct {
    calling_convention: ?std.builtin.CallingConvention = null,
    is_var_args: ?bool = null,
    is_generic: ?bool = null,
    return_type: functions.Options.Return = .{},
    other_param_count: @import("count.zig").Count = .least_items,
    other_params: functions.Options.Params = .no_requirement,
    self: Self = .{},

    pub const Self = struct {
        allow_value: bool = true,
        allow_var_ptr: bool = true,
        allow_const_ptr: bool = true,
        allow_anytype: bool = true,
    };
};

pub fn has(comptime T: type, comptime name: []const u8, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(
            T,
            z.fmt("has-method[{s}]", .{name}),
            z.fmt("The type must have a \"{s}\" method.", .{name}),
        );

        const self_param = functions.Options.Param{
            .is_generic = if (o.self.allow_anytype) null else false,
        };

        if (r.propagateFail(T, .hasDecl(name, .{ .of_type_which = .isFunction(.{
            .calling_convention = o.calling_convention,
            .is_var_args = o.is_var_args,
            .is_generic = o.is_generic,
            .param_count = switch (o.other_param_count) {
                .exact_items, .least_items => o.other_param_count,
                .least => |least| .{ .least = least + 1 },
                .exact => |exact| .{ .exact = exact + 1 },
            },
            .return_type = o.return_type,
            .params = if (o.other_params.slice) |other_params| .many(
                &[_]functions.Options.Param{self_param} ++ other_params,
            ) else .one(self_param),
        }) }), .{})) |fail| return fail;

        if (@typeInfo(@TypeOf(@field(T, name))).@"fn".params[0].type) |Self| switch (Self) {
            T => if (!o.self.allow_value) return r.failWith(.{
                .@"error" = error.PassByValue,
                .option = "self-disallow-value",
                .expect = "The `self` parameter must not be passed by value.",
            }),
            *T => if (!o.self.allow_var_ptr) return r.failWith(.{
                .@"error" = error.PassByVarPtr,
                .option = "self-dissalow-var-ptr",
                .expect = "The `self` parameter must not be passed by var pointer.",
            }),
            *const T => if (!o.self.allow_const_ptr) return r.failWith(.{
                .@"error" = error.PassByConstPtr,
                .option = "self-dissalow-const-ptr",
                .expect = "The `self` parameter must not be passed by const pointer.",
            }),
            else => return r.failWith(.{
                .@"error" = error.NoSelf,
                .expect = z.fmt(
                    "The type of the first parameter must be `{s}` or a pointer to one.",
                    .{@typeName(T)},
                ),
                .actual = z.fmt("The type of the first parameter is `{s}`.", .{@typeName(Self)}),
            }),
        };

        return r;
    }
}
