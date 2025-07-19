const z = @import("../root.zig");

pub fn Contract(comptime Contractor: type, field_name: []const u8, comptime Implementor: type) type {
    z.Trait.isStruct(.{ .is_tuple = false }).assert(Contractor);
    z.Trait.is_container.assert(Implementor);

    return struct {
        pub fn varPtrSelf(interface: anytype) *Contractor {
            return @alignCast(@fieldParentPtr(field_name, interface));
        }

        pub fn ptrSelf(interface: anytype) *const Contractor {
            return varPtrSelf(@constCast(interface));
        }

        pub fn self(interface: anytype) Contractor {
            return ptrSelf(interface).*;
        }

        pub inline fn default(
            comptime name: []const u8,
            comptime default_value: anytype,
        ) @TypeOf(default_value) {
            const Decl = @TypeOf(default_value);

            if (hasDecl(name, .is(Decl)).check(Implementor))
                return @field(Implementor, name);

            return default_value;
        }

        pub inline fn require(comptime name: []const u8, comptime Type: type) Type {
            hasDecl(name, .is(Type)).assert(Implementor);
            return @field(Implementor, name);
        }

        pub inline fn requireWith(comptime name: []const u8, comptime t: z.Trait) RequireWith(name) {
            hasDecl(name, t).assert(Implementor);
            return @field(Implementor, name);
        }

        pub fn RequireWith(comptime name: []const u8) type {
            return if (@hasDecl(Implementor, name))
                @TypeOf(@field(Implementor, name))
            else
                noreturn;
        }

        pub fn hasDecl(comptime name: []const u8, comptime t: z.Trait) z.Trait {
            return z.Trait.hasDecl(name, .{ .of_type_which = t });
        }
    };
}

pub fn Iterable(
    comptime Iterator: type,
    comptime field_name: []const u8,
    comptime Implementor: type,
) type {
    return struct {
        const Interface = @This();

        pub const contract = Contract(Iterator, field_name, Implementor);
        pub const Item = contract.require("Item", type);

        pub fn peek(interface: *const Interface) ?Item {
            const self = contract.ptrSelf(interface);
            const peekFn = contract.require("peek", fn (*const Iterator) ?Item);
            return peekFn(self);
        }

        pub fn skip(iter: *Interface, n: usize) void {
            const self = contract.varPtrSelf(iter);
            const skipFn = contract.require("skip", fn (*Iterator, usize) void);
            return skipFn(self, n);
        }

        pub fn next(iter: *Interface) ?Item {
            return if (iter.peek()) |item| {
                iter.skip(1);
                return item;
            } else null;
        }
    };
}

pub const Bytes = struct {
    slice: []const u8 = "Hello world!",
    index: usize = 0,
    iterable: Iterable(Bytes, "iterable", struct {
        pub const Item = u8;

        pub fn skip(b: *Bytes, n: usize) void {
            b.index = @max(b.index +| n, b.slice.len);
        }

        pub fn peek(b: *const Bytes) ?u8 {
            return if (b.index == b.slice.len) null else b.slice[b.index];
        }
    }) = .{},
};

const std = @import("std");
test {
    var b = Bytes{};
    var i: usize = 0;
    while (b.iterable.next()) |byte| : (i += 1)
        try std.testing.expectEqual(byte, "Hello world!"[i]);
}
