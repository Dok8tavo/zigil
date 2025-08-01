const z = @import("zigil");

const match = z.Trait.match;
const m = z.Trait.matching;

pub const tuple = struct {
    const A = m.AnyId(.a);
    const B = m.AnyId(.b);

    pub const wrong_count = match(struct { void }).assert(struct { void, void });
    pub const wrong_type = match(struct { u32 }).assert(struct { i32 });

    pub const mismatch = match(struct { A, A }).assert(struct { i32, u32 });
    pub const mismatch2 = match(struct { A, B, B, A }).assert(struct { A, B, A, A });
};
