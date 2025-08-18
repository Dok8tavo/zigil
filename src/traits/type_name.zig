const matching = @import("impl/matching.zig");
const std = @import("std");
const z = @import("../root.zig");

pub const Options = struct {
    address_space: bool,
    alignment: bool,
    sentinel: bool,
    calling_convention: CallingConvention,

    pub const CallingConvention = enum {
        show_tag,
        show,
        hide,
    };

    pub const min = Options{
        .address_space = false,
        .alignment = false,
        .sentinel = false,
        .calling_convention = .hide,
    };

    pub const max = Options{
        .address_space = true,
        .alignment = true,
        .sentinel = true,
        .calling_convention = .show,
    };
};

pub inline fn of(comptime T: type, comptime o: Options) []const u8 {
    comptime {
        return switch (@typeInfo(T)) {
            .@"union", .@"enum", .@"opaque" => ofUserDefined(T),
            .@"struct" => |info| if (info.is_tuple)
                ofTuple(info, o)
            else if (matching.isMatcher(T))
                "lol"
                //ofMatcher(T)
            else
                ofUserDefined(T),
            .@"fn" => |function| ofFunction(function, o),
            .pointer => |pointer| ofPointer(pointer, o),
            else => @typeName(T),
        };
    }
}

fn ofMatcher(comptime T: type) []const u8 {
    comptime {
        const t = T{};

        if (t.id == null)
            return "Any[]";

        return "Any[." ++ @tagName(t.id.?) ++ "]";
    }
}

fn ofUserDefined(comptime T: type) []const u8 {
    comptime {
        var new: []const u8 = "";
        const old: []const u8 = @typeName(T);
        var lower_index: usize = 0;
        var upper_index: usize = 0;

        // idk if this is even possible but here we are...
        if (old.len == 0) return old;

        path: switch (old[upper_index]) {
            'a'...'z', 'A'...'Z', '_' => {
                const not_identifier = loop: for (old[upper_index..], upper_index..) |byte, i| switch (byte) {
                    'a'...'z', 'A'...'Z', '0'...'9', '_', '.' => {},
                    else => break :loop i,
                } else {
                    new = new ++ old[lower_index..];
                    break :path;
                };

                upper_index = not_identifier;
                continue :path old[not_identifier];
            },
            '.' => {
                upper_index += 1;
                // it starts or ends with a dot
                if (upper_index == 0 or upper_index == old.len) return old;
                continue :path old[upper_index];
            },
            '(' => {
                // it starts with a parenthese
                if (upper_index == 0) return old;

                upper_index += 1;
                new = new ++ old[lower_index..upper_index];

                var encountered_braces: usize = 1;
                var iter = std.unicode.Utf8Iterator{
                    .i = upper_index,
                    .bytes = old,
                };

                while (iter.nextCodepoint()) |cp| switch (cp) {
                    else => {},
                    '(' => encountered_braces += 1,
                    ')' => switch (encountered_braces) {
                        1 => break,
                        0 => return old,
                        else => encountered_braces -= 1,
                    },
                    '\"', '\'' => while (iter.nextCodepoint()) |cp2| switch (cp2) {
                        cp => break,
                        '\\' => _ = iter.nextCodepointSlice(),
                        else => {},
                        // the string/character wasn't closed, in an unclosed parenthese
                    } else return old,
                    // there's a missing closing parenthese
                } else return old;

                upper_index = iter.i;
                lower_index = iter.i;
                new = new ++ "...)";
            },
            // there's a weird character
            else => return old,
        }

        return new;
    }
}

fn ofTuple(comptime tuple: std.builtin.Type.Struct, comptime o: Options) []const u8 {
    comptime {
        var name: []const u8 = "struct { ";

        for (tuple.fields, 1..) |field, i|
            name = name ++ of(field.type, o) ++ if (i == tuple.fields.len) " " else ", ";

        return name ++ "}";
    }
}

fn ofFunction(comptime function: std.builtin.Type.Fn, comptime o: Options) []const u8 {
    comptime {
        var name: []const u8 = if (function.calling_convention == .@"inline")
            "inline fn ("
        else if (function.calling_convention.eql(.c))
            "export fn ("
        else
            "fn (";

        for (function.params, 1..) |param, i| {
            const param_name = if (param.is_generic)
                "..?"
            else if (param.is_noalias)
                "noalias " ++ of(param.type.?)
            else
                of(param.type.?, o);

            name = name ++ param_name ++ if (i == function.params.len) "" else ", ";
        }

        name = name ++ ") " ++ if (function.calling_convention == .@"inline" or
            function.calling_convention == .auto or
            function.calling_convention.eql(.c)) "" else switch (o.calling_convention) {
            .hide => "callconv(_) ",
            .show_tag => z.fmt("callconv({t}) ", .{function.calling_convention}),
            .show => z.fmt("callconv({any}) ", .{function.calling_convention}),
        };

        name = name ++
            if (function.return_type) |return_type|
                of(return_type, o)
            else
                "..?";

        return name;
    }
}

fn ofPointer(comptime pointer: std.builtin.Type.Pointer, comptime o: Options) []const u8 {
    return if (o.sentinel) switch (pointer.size) {
        .c => if (pointer.sentinel()) |sentinel| z.fmt("[*c:{}]", .{sentinel}) else "[*c]",
        .many => if (pointer.sentinel()) |sentinel| z.fmt("[*:{}]", .{sentinel}) else "[*]",
        .slice => if (pointer.sentinel()) |sentinel| z.fmt("[:{}]", .{sentinel}) else "[]",
        .one => "*",
    } else switch (pointer.size) {
        .c => if (pointer.sentinel_ptr) |_| "[*c:_]" else "[*c]",
        .many => if (pointer.sentinel_ptr) |_| "[*:_]" else "[*]",
        .slice => if (pointer.sentinel_ptr) |_| "[:_]" else "[]",
        .one => "*",
    } ++
        (if (pointer.is_allowzero) "allowzero " else "") ++
        (if (pointer.alignment != @alignOf(pointer.child)) switch (o.alignment) {
            true => z.fmt("align({}) ", .{pointer.alignment}),
            false => "align(_) ",
        } else "") ++
        (if (pointer.address_space != .generic) switch (o.address_space) {
            true => z.fmt("addrspace(.{t})", .{pointer.address_space}),
            false => "addrspce(_) ",
        } else "") ++
        (if (pointer.is_const) "const " else "") ++
        (if (pointer.is_volatile) "volatile " else "") ++
        of(pointer.child, o);
}
