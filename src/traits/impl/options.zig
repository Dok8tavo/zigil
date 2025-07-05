pub const Count = union(enum) {
    no_option,
    exact: usize,
    least: usize,
    exact_items,
    least_items,
};
