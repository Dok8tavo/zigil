const z = @import("../../root.zig");

pub const Count = union(enum) {
    exact: usize,
    least: usize,
    exact_items,
    least_items,
};
