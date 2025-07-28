const config = @import("config");
const z = @import("zigil");

pub fn main() void {
    comptime {
        for (@typeInfo(config).@"struct".decls) |decl|
            _ = @field(@This(), decl.name);
    }
}

const is = z.Trait.is;
pub const is_primitive = {
    is(i32).assert(u8);
};

pub const is_composite = {
    is(struct { u8, u8 }).assert(struct { u8, i8 });
};

pub const is_userdef = {
    const userdef = struct {};
    is(userdef).assert(struct {});
};

const isKind = z.Trait.isKind;
pub const isKind_int = {
    isKind(.int).assert(struct { u8 });
};
