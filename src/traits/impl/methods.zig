const functions = @import("functions.zig");
const std = @import("std");
const type_name = @import("../type_name.zig");
const z = @import("../../root.zig");

pub const Options = struct {
    calling_convention: ?std.builtin.CallingConvention = null,
    is_var_args: ?bool = null,
    is_generic: ?bool = null,
    return_type: functions.Options.Return = .{},
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

        const self_param = &[_]functions.Options.Param{.{
            .is_generic = if (o.self.allow_anytype) null else false,
        }};

        if (r.propagateFail(T, .hasDecl(name, .{ .of_type_which = .isFunction(.{
            .calling_convention = o.calling_convention,
            .is_variadic = o.is_var_args,
            .is_generic = o.is_generic,
            .return_type = o.return_type,
            .params = if (o.other_params.slice) |slice| .many(self_param ++ slice) else .no_requirement,
        }) }), .{})) |fail| return fail;

        const Method = @TypeOf(@field(T, name));
        const info = @typeInfo(Method).@"fn";

        if (info.params.len == 0) return r.failWith(.{
            .@"error" = error.NoParam,
            .expect = "The method must take at least the self parameter.",
        });

        if (info.params[0].type) |Self| switch (Self) {
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
                .expect = "The first parameter must be `" ++ type_name.of(T, .min) ++ "` or a pointer to one.",
                .actual = "The first parameter is `" ++ type_name.of(Self, .min) ++ "`.",
            }),
        };

        return r;
    }
}
