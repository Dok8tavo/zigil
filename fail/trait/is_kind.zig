const root = @import("../root.zig");
const z = @import("zigil");

const isKind = z.Trait.isKind;

pub const @"type" = struct {
    const is_type = isKind(.type);

    pub const @"void" = if (!root.is_listing) is_type.assert(void);
    pub const @"bool" = if (!root.is_listing) is_type.assert(bool);
    pub const @"noreturn" = if (!root.is_listing) is_type.assert(noreturn);
    pub const int = if (!root.is_listing) is_type.assert(u8);
    pub const float = if (!root.is_listing) is_type.assert(f32);
    pub const pointer = if (!root.is_listing) is_type.assert(*type);
    pub const array = if (!root.is_listing) is_type.assert([1]type);
    pub const @"struct" = if (!root.is_listing) is_type.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_type.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_type.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_type.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_type.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_type.assert(?type);
    pub const error_union = if (!root.is_listing) is_type.assert(anyerror!type);
    pub const error_set = if (!root.is_listing) is_type.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_type.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_type.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_type.assert(fn () type);
    pub const @"opaque" = if (!root.is_listing) is_type.assert(opaque {});
    pub const vector = if (!root.is_listing) is_type.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_type.assert(@TypeOf(.type));
};

pub const @"void" = struct {
    const is_void = isKind(.void);

    pub const @"type" = if (!root.is_listing) is_void.assert(type);
    pub const @"bool" = if (!root.is_listing) is_void.assert(bool);
    pub const @"noreturn" = if (!root.is_listing) is_void.assert(noreturn);
    pub const int = if (!root.is_listing) is_void.assert(u8);
    pub const float = if (!root.is_listing) is_void.assert(f32);
    pub const pointer = if (!root.is_listing) is_void.assert(*void);
    pub const array = if (!root.is_listing) is_void.assert([1]type);
    pub const @"struct" = if (!root.is_listing) is_void.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_void.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_void.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_void.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_void.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_void.assert(?void);
    pub const error_union = if (!root.is_listing) is_void.assert(anyerror!void);
    pub const error_set = if (!root.is_listing) is_void.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_void.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_void.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_void.assert(fn () void);
    pub const @"opaque" = if (!root.is_listing) is_void.assert(opaque {});
    pub const vector = if (!root.is_listing) is_void.assert(@Vector(1, void));
    pub const enum_literal = if (!root.is_listing) is_void.assert(@TypeOf(.void));
};

pub const @"bool" = struct {
    const is_bool = isKind(.bool);

    pub const @"type" = if (!root.is_listing) is_bool.assert(type);
    pub const @"void" = if (!root.is_listing) is_bool.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_bool.assert(noreturn);
    pub const int = if (!root.is_listing) is_bool.assert(u8);
    pub const float = if (!root.is_listing) is_bool.assert(f32);
    pub const pointer = if (!root.is_listing) is_bool.assert(*bool);
    pub const array = if (!root.is_listing) is_bool.assert([1]bool);
    pub const @"struct" = if (!root.is_listing) is_bool.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_bool.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_bool.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_bool.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_bool.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_bool.assert(?bool);
    pub const error_union = if (!root.is_listing) is_bool.assert(anyerror!bool);
    pub const error_set = if (!root.is_listing) is_bool.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_bool.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_bool.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_bool.assert(fn () bool);
    pub const @"opaque" = if (!root.is_listing) is_bool.assert(opaque {});
    pub const vector = if (!root.is_listing) is_bool.assert(@Vector(1, bool));
    pub const enum_literal = if (!root.is_listing) is_bool.assert(@TypeOf(.bool));
};

pub const @"noreturn" = struct {
    const is_noreturn = isKind(.noreturn);

    pub const @"type" = if (!root.is_listing) is_noreturn.assert(type);
    pub const @"bool" = if (!root.is_listing) is_noreturn.assert(bool);
    pub const @"void" = if (!root.is_listing) is_noreturn.assert(void);
    pub const int = if (!root.is_listing) is_noreturn.assert(u8);
    pub const float = if (!root.is_listing) is_noreturn.assert(f32);
    pub const pointer = if (!root.is_listing) is_noreturn.assert(*anyopaque);
    pub const array = if (!root.is_listing) is_noreturn.assert([1]u8);
    pub const @"struct" = if (!root.is_listing) is_noreturn.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_noreturn.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_noreturn.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_noreturn.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_noreturn.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_noreturn.assert(?noreturn);
    pub const error_union = if (!root.is_listing) is_noreturn.assert(anyerror!noreturn);
    pub const error_set = if (!root.is_listing) is_noreturn.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_noreturn.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_noreturn.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_noreturn.assert(fn () noreturn);
    pub const @"opaque" = if (!root.is_listing) is_noreturn.assert(opaque {});
    pub const vector = if (!root.is_listing) is_noreturn.assert(@Vector(1, bool));
    pub const enum_literal = if (!root.is_listing) is_noreturn.assert(@TypeOf(.noreturn));
};

pub const int = struct {
    const is_int = isKind(.int);

    pub const @"type" = if (!root.is_listing) is_int.assert(type);
    pub const @"void" = if (!root.is_listing) is_int.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_int.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_int.assert(bool);
    pub const float = if (!root.is_listing) is_int.assert(f32);
    pub const pointer = if (!root.is_listing) is_int.assert(*u7);
    pub const array = if (!root.is_listing) is_int.assert([1]u32);
    pub const @"struct" = if (!root.is_listing) is_int.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_int.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_int.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_int.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_int.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_int.assert(?c_int);
    pub const error_union = if (!root.is_listing) is_int.assert(anyerror!i32);
    pub const error_set = if (!root.is_listing) is_int.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_int.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_int.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_int.assert(fn () i512);
    pub const @"opaque" = if (!root.is_listing) is_int.assert(opaque {});
    pub const vector = if (!root.is_listing) is_int.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_int.assert(@TypeOf(.int));
};

pub const float = struct {
    const is_float = isKind(.float);

    pub const @"type" = if (!root.is_listing) is_float.assert(type);
    pub const @"void" = if (!root.is_listing) is_float.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_float.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_float.assert(bool);
    pub const int = if (!root.is_listing) is_float.assert(u32);
    pub const pointer = if (!root.is_listing) is_float.assert(*u7);
    pub const array = if (!root.is_listing) is_float.assert([1]f32);
    pub const @"struct" = if (!root.is_listing) is_float.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_float.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_float.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_float.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_float.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_float.assert(?f16);
    pub const error_union = if (!root.is_listing) is_float.assert(anyerror!f64);
    pub const error_set = if (!root.is_listing) is_float.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_float.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_float.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_float.assert(fn () c_longdouble);
    pub const @"opaque" = if (!root.is_listing) is_float.assert(opaque {});
    pub const vector = if (!root.is_listing) is_float.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_float.assert(@TypeOf(.float));
};

pub const pointer = struct {
    const is_pointer = isKind(.pointer);

    pub const @"type" = if (!root.is_listing) is_pointer.assert(type);
    pub const @"void" = if (!root.is_listing) is_pointer.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_pointer.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_pointer.assert(bool);
    pub const int = if (!root.is_listing) is_pointer.assert(u32);
    pub const float = if (!root.is_listing) is_pointer.assert(f32);
    pub const array = if (!root.is_listing) is_pointer.assert([1]*usize);
    pub const @"struct" = if (!root.is_listing) is_pointer.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_pointer.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_pointer.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_pointer.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_pointer.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_pointer.assert(?*anyopaque);
    pub const error_union = if (!root.is_listing) is_pointer.assert(anyerror!*anyopaque);
    pub const error_set = if (!root.is_listing) is_pointer.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_pointer.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_pointer.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_pointer.assert(fn () []const u8);
    pub const @"opaque" = if (!root.is_listing) is_pointer.assert(opaque {});
    pub const vector = if (!root.is_listing) is_pointer.assert(@Vector(1, *f32));
    pub const enum_literal = if (!root.is_listing) is_pointer.assert(@TypeOf(.float));
};

pub const array = struct {
    const is_array = isKind(.array);

    pub const @"type" = if (!root.is_listing) is_array.assert(type);
    pub const @"void" = if (!root.is_listing) is_array.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_array.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_array.assert(bool);
    pub const int = if (!root.is_listing) is_array.assert(u32);
    pub const float = if (!root.is_listing) is_array.assert(f32);
    pub const pointer = if (!root.is_listing) is_array.assert(*[1]i16);
    pub const @"struct" = if (!root.is_listing) is_array.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_array.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_array.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_array.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_array.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_array.assert(?[8]struct {});
    pub const error_union = if (!root.is_listing) is_array.assert(anyerror![1]usize);
    pub const error_set = if (!root.is_listing) is_array.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_array.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_array.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_array.assert(fn () [2]u8);
    pub const @"opaque" = if (!root.is_listing) is_array.assert(opaque {});
    pub const vector = if (!root.is_listing) is_array.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_array.assert(@TypeOf(.enum_literal));
};

pub const @"struct" = struct {
    const is_struct = isKind(.@"struct");

    pub const @"type" = if (!root.is_listing) is_struct.assert(type);
    pub const @"void" = if (!root.is_listing) is_struct.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_struct.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_struct.assert(bool);
    pub const int = if (!root.is_listing) is_struct.assert(u32);
    pub const float = if (!root.is_listing) is_struct.assert(f32);
    pub const pointer = if (!root.is_listing) is_struct.assert(*struct {});
    pub const array = if (!root.is_listing) is_struct.assert([1]struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_struct.assert(comptime_float);
    pub const @"comptime_int" = if (!root.is_listing) is_struct.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_struct.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_struct.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_struct.assert(?struct {});
    pub const error_union = if (!root.is_listing) is_struct.assert(anyerror!struct {});
    pub const error_set = if (!root.is_listing) is_struct.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_struct.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_struct.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_struct.assert(fn () struct {});
    pub const @"opaque" = if (!root.is_listing) is_struct.assert(opaque {});
    pub const vector = if (!root.is_listing) is_struct.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_struct.assert(@TypeOf(.float));
};

pub const @"comptime_float" = struct {
    const is_comptime_float = isKind(.comptime_float);

    pub const @"type" = if (!root.is_listing) is_comptime_float.assert(type);
    pub const @"void" = if (!root.is_listing) is_comptime_float.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_comptime_float.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_comptime_float.assert(bool);
    pub const int = if (!root.is_listing) is_comptime_float.assert(u32);
    pub const float = if (!root.is_listing) is_comptime_float.assert(f32);
    pub const pointer = if (!root.is_listing) is_comptime_float.assert(*comptime_float);
    pub const array = if (!root.is_listing) is_comptime_float.assert([1]comptime_float);
    pub const @"struct" = if (!root.is_listing) is_comptime_float.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_comptime_float.assert(comptime_int);
    pub const @"undefined" = if (!root.is_listing) is_comptime_float.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_comptime_float.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_comptime_float.assert(?comptime_float);
    pub const error_union = if (!root.is_listing) is_comptime_float.assert(anyerror!comptime_float);
    pub const error_set = if (!root.is_listing) is_comptime_float.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_comptime_float.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_comptime_float.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_comptime_float.assert(fn () comptime_float);
    pub const @"opaque" = if (!root.is_listing) is_comptime_float.assert(opaque {});
    pub const vector = if (!root.is_listing) is_comptime_float.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_comptime_float.assert(@TypeOf(.enum_literal));
};

pub const @"comptime_int" = struct {
    const is_comptime_int = isKind(.comptime_int);

    pub const @"type" = if (!root.is_listing) is_comptime_int.assert(type);
    pub const @"void" = if (!root.is_listing) is_comptime_int.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_comptime_int.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_comptime_int.assert(bool);
    pub const int = if (!root.is_listing) is_comptime_int.assert(u32);
    pub const float = if (!root.is_listing) is_comptime_int.assert(f32);
    pub const pointer = if (!root.is_listing) is_comptime_int.assert(*comptime_int);
    pub const array = if (!root.is_listing) is_comptime_int.assert([1]comptime_int);
    pub const @"struct" = if (!root.is_listing) is_comptime_int.assert(struct {});
    pub const @"comptime_float" = if (!root.is_listing) is_comptime_int.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_comptime_int.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_comptime_int.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_comptime_int.assert(?comptime_int);
    pub const error_union = if (!root.is_listing) is_comptime_int.assert(anyerror!comptime_int);
    pub const error_set = if (!root.is_listing) is_comptime_int.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_comptime_int.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_comptime_int.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_comptime_int.assert(fn () comptime_int);
    pub const @"opaque" = if (!root.is_listing) is_comptime_int.assert(opaque {});
    pub const vector = if (!root.is_listing) is_comptime_int.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_comptime_int.assert(@TypeOf(.enum_literal));
};

pub const @"undefined" = struct {
    const is_undefined = isKind(.undefined);

    pub const @"type" = if (!root.is_listing) is_undefined.assert(type);
    pub const @"void" = if (!root.is_listing) is_undefined.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_undefined.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_undefined.assert(bool);
    pub const int = if (!root.is_listing) is_undefined.assert(u32);
    pub const float = if (!root.is_listing) is_undefined.assert(f32);
    pub const pointer = if (!root.is_listing) is_undefined.assert(*@TypeOf(undefined));
    pub const array = if (!root.is_listing) is_undefined.assert([1]@TypeOf(undefined));
    pub const @"struct" = if (!root.is_listing) is_undefined.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_undefined.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_undefined.assert(comptime_float);
    pub const @"null" = if (!root.is_listing) is_undefined.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_undefined.assert(?@TypeOf(undefined));
    pub const error_union = if (!root.is_listing) is_undefined.assert(anyerror!@TypeOf(undefined));
    pub const error_set = if (!root.is_listing) is_undefined.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_undefined.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_undefined.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_undefined.assert(fn () @TypeOf(undefined));
    pub const @"opaque" = if (!root.is_listing) is_undefined.assert(opaque {});
    pub const vector = if (!root.is_listing) is_undefined.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_undefined.assert(@TypeOf(.enum_literal));
};

pub const @"null" = struct {
    const is_null = isKind(.null);

    pub const @"type" = if (!root.is_listing) is_null.assert(type);
    pub const @"void" = if (!root.is_listing) is_null.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_null.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_null.assert(bool);
    pub const int = if (!root.is_listing) is_null.assert(u32);
    pub const float = if (!root.is_listing) is_null.assert(f32);
    pub const pointer = if (!root.is_listing) is_null.assert(*@TypeOf(null));
    pub const array = if (!root.is_listing) is_null.assert([1]@TypeOf(null));
    pub const @"struct" = if (!root.is_listing) is_null.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_null.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_null.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_null.assert(@TypeOf(undefined));
    pub const optional = if (!root.is_listing) is_null.assert(?@TypeOf(null));
    pub const error_union = if (!root.is_listing) is_null.assert(anyerror!@TypeOf(null));
    pub const error_set = if (!root.is_listing) is_null.assert(error{});
    pub const @"enum" = if (!root.is_listing) is_null.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_null.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_null.assert(fn () @TypeOf(null));
    pub const @"opaque" = if (!root.is_listing) is_null.assert(opaque {});
    pub const vector = if (!root.is_listing) is_null.assert(@Vector(1, f32));
    pub const enum_literal = if (!root.is_listing) is_null.assert(@TypeOf(.enum_literal));
};

pub const optional = struct {
    const is_optional = isKind(.optional);

    pub const @"type" = if (!root.is_listing) is_optional.assert(type);
    pub const @"void" = if (!root.is_listing) is_optional.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_optional.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_optional.assert(bool);
    pub const int = if (!root.is_listing) is_optional.assert(u32);
    pub const float = if (!root.is_listing) is_optional.assert(f32);
    pub const pointer = if (!root.is_listing) is_optional.assert(*?u8);
    pub const array = if (!root.is_listing) is_optional.assert([1]?u8);
    pub const @"struct" = if (!root.is_listing) is_optional.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_optional.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_optional.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_optional.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_optional.assert(@TypeOf(null));
    pub const error_set = if (!root.is_listing) is_optional.assert(error{});
    pub const error_union = if (!root.is_listing) is_optional.assert(anyerror!@TypeOf(null));
    pub const @"enum" = if (!root.is_listing) is_optional.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_optional.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_optional.assert(fn () ?*anyopaque);
    pub const @"opaque" = if (!root.is_listing) is_optional.assert(opaque {});
    pub const vector = if (!root.is_listing) is_optional.assert(@Vector(1, ?*u8));
    pub const enum_literal = if (!root.is_listing) is_optional.assert(@TypeOf(.enum_literal));
};

pub const error_set = struct {
    const is_error_set = isKind(.error_set);

    pub const @"type" = if (!root.is_listing) is_error_set.assert(type);
    pub const @"void" = if (!root.is_listing) is_error_set.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_error_set.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_error_set.assert(bool);
    pub const int = if (!root.is_listing) is_error_set.assert(u32);
    pub const float = if (!root.is_listing) is_error_set.assert(f32);
    pub const pointer = if (!root.is_listing) is_error_set.assert(*anyerror);
    pub const array = if (!root.is_listing) is_error_set.assert([1]anyerror);
    pub const @"struct" = if (!root.is_listing) is_error_set.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_error_set.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_error_set.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_error_set.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_error_set.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_error_set.assert(?anyerror);
    pub const error_union = if (!root.is_listing) is_error_set.assert(anyerror!void);
    pub const @"enum" = if (!root.is_listing) is_error_set.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_error_set.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_error_set.assert(fn () anyerror);
    pub const @"opaque" = if (!root.is_listing) is_error_set.assert(opaque {});
    pub const vector = if (!root.is_listing) is_error_set.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_error_set.assert(@TypeOf(.enum_literal));
};

pub const error_union = struct {
    const is_error_union = isKind(.error_union);

    pub const @"type" = if (!root.is_listing) is_error_union.assert(type);
    pub const @"void" = if (!root.is_listing) is_error_union.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_error_union.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_error_union.assert(bool);
    pub const int = if (!root.is_listing) is_error_union.assert(u32);
    pub const float = if (!root.is_listing) is_error_union.assert(f32);
    pub const pointer = if (!root.is_listing) is_error_union.assert(*anyerror!void);
    pub const array = if (!root.is_listing) is_error_union.assert([1]anyerror!void);
    pub const @"struct" = if (!root.is_listing) is_error_union.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_error_union.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_error_union.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_error_union.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_error_union.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_error_union.assert(?anyerror!void);
    pub const error_set = if (!root.is_listing) is_error_union.assert(anyerror);
    pub const @"enum" = if (!root.is_listing) is_error_union.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_error_union.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_error_union.assert(fn () anyerror!void);
    pub const @"opaque" = if (!root.is_listing) is_error_union.assert(opaque {});
    pub const vector = if (!root.is_listing) is_error_union.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_error_union.assert(@TypeOf(.enum_literal));
};

pub const @"enum" = struct {
    const is_enum = isKind(.@"enum");

    pub const @"type" = if (!root.is_listing) is_enum.assert(type);
    pub const @"void" = if (!root.is_listing) is_enum.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_enum.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_enum.assert(bool);
    pub const int = if (!root.is_listing) is_enum.assert(u32);
    pub const float = if (!root.is_listing) is_enum.assert(f32);
    pub const pointer = if (!root.is_listing) is_enum.assert(*enum {});
    pub const array = if (!root.is_listing) is_enum.assert([1]enum {});
    pub const @"struct" = if (!root.is_listing) is_enum.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_enum.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_enum.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_enum.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_enum.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_enum.assert(?enum {});
    pub const error_set = if (!root.is_listing) is_enum.assert(anyerror);
    pub const error_union = if (!root.is_listing) is_enum.assert(anyerror!enum {});
    pub const @"union" = if (!root.is_listing) is_enum.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_enum.assert(fn () enum {});
    pub const @"opaque" = if (!root.is_listing) is_enum.assert(opaque {});
    pub const vector = if (!root.is_listing) is_enum.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_enum.assert(@TypeOf(.enum_literal));
};

pub const @"union" = struct {
    const is_union = isKind(.@"union");

    pub const @"type" = if (!root.is_listing) is_union.assert(type);
    pub const @"void" = if (!root.is_listing) is_union.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_union.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_union.assert(bool);
    pub const int = if (!root.is_listing) is_union.assert(u32);
    pub const float = if (!root.is_listing) is_union.assert(f32);
    pub const pointer = if (!root.is_listing) is_union.assert(*union {});
    pub const array = if (!root.is_listing) is_union.assert([1]union {});
    pub const @"struct" = if (!root.is_listing) is_union.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_union.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_union.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_union.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_union.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_union.assert(?enum {});
    pub const error_set = if (!root.is_listing) is_union.assert(anyerror);
    pub const error_union = if (!root.is_listing) is_union.assert(anyerror!union {});
    pub const @"enum" = if (!root.is_listing) is_union.assert(enum {});
    pub const @"fn" = if (!root.is_listing) is_union.assert(fn () union {});
    pub const @"opaque" = if (!root.is_listing) is_union.assert(opaque {});
    pub const vector = if (!root.is_listing) is_union.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_union.assert(@TypeOf(.enum_literal));
};

pub const @"opaque" = struct {
    const is_opaque = isKind(.@"opaque");

    pub const @"type" = if (!root.is_listing) is_opaque.assert(type);
    pub const @"void" = if (!root.is_listing) is_opaque.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_opaque.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_opaque.assert(bool);
    pub const int = if (!root.is_listing) is_opaque.assert(u32);
    pub const float = if (!root.is_listing) is_opaque.assert(f32);
    pub const pointer = if (!root.is_listing) is_opaque.assert(*opaque {});
    pub const array = if (!root.is_listing) is_opaque.assert([1]opaque {});
    pub const @"struct" = if (!root.is_listing) is_opaque.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_opaque.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_opaque.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_opaque.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_opaque.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_opaque.assert(?enum {});
    pub const error_set = if (!root.is_listing) is_opaque.assert(anyerror);
    pub const error_union = if (!root.is_listing) is_opaque.assert(anyerror!opaque {});
    pub const @"union" = if (!root.is_listing) is_opaque.assert(union {});
    pub const @"enum" = if (!root.is_listing) is_opaque.assert(enum {});
    pub const @"fn" = if (!root.is_listing) is_opaque.assert(fn () enum {});
    pub const vector = if (!root.is_listing) is_opaque.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_opaque.assert(@TypeOf(.enum_literal));
};

pub const @"fn" = struct {
    const is_fn = isKind(.@"fn");

    pub const @"type" = if (!root.is_listing) is_fn.assert(type);
    pub const @"void" = if (!root.is_listing) is_fn.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_fn.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_fn.assert(bool);
    pub const int = if (!root.is_listing) is_fn.assert(u32);
    pub const float = if (!root.is_listing) is_fn.assert(f32);
    pub const pointer = if (!root.is_listing) is_fn.assert(*const fn () void);
    pub const array = if (!root.is_listing) is_fn.assert([1]*const fn () void);
    pub const @"struct" = if (!root.is_listing) is_fn.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_fn.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_fn.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_fn.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_fn.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_fn.assert(?*const fn () void);
    pub const error_set = if (!root.is_listing) is_fn.assert(anyerror);
    pub const error_union = if (!root.is_listing) is_fn.assert(anyerror!fn () void);
    pub const @"union" = if (!root.is_listing) is_fn.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_fn.assert(fn () void);
    pub const @"opaque" = if (!root.is_listing) is_fn.assert(opaque {});
    pub const vector = if (!root.is_listing) is_fn.assert(@Vector(1, u8));
    pub const enum_literal = if (!root.is_listing) is_fn.assert(@TypeOf(.enum_literal));
};

pub const vector = struct {
    const is_vector = isKind(.vector);

    pub const @"type" = if (!root.is_listing) is_vector.assert(type);
    pub const @"void" = if (!root.is_listing) is_vector.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_vector.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_vector.assert(bool);
    pub const int = if (!root.is_listing) is_vector.assert(u32);
    pub const float = if (!root.is_listing) is_vector.assert(f32);
    pub const pointer = if (!root.is_listing) is_vector.assert(*@Vector(8, bool));
    pub const array = if (!root.is_listing) is_vector.assert([1]@Vector(8, u8));
    pub const @"struct" = if (!root.is_listing) is_vector.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_vector.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_vector.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_vector.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_vector.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_vector.assert(?@Vector(16, f16));
    pub const error_set = if (!root.is_listing) is_vector.assert(anyerror);
    pub const error_union = if (!root.is_listing) is_vector.assert(anyerror!@Vector(8, i32));
    pub const @"enum" = if (!root.is_listing) is_vector.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_vector.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_vector.assert(fn () @Vector(4, f64));
    pub const @"opaque" = if (!root.is_listing) is_vector.assert(opaque {});
    pub const enum_literal = if (!root.is_listing) is_vector.assert(@TypeOf(.enum_literal));
};

pub const enum_literal = struct {
    const is_enum_literal = isKind(.enum_literal);

    pub const @"type" = if (!root.is_listing) is_enum_literal.assert(type);
    pub const @"void" = if (!root.is_listing) is_enum_literal.assert(void);
    pub const @"noreturn" = if (!root.is_listing) is_enum_literal.assert(noreturn);
    pub const @"bool" = if (!root.is_listing) is_enum_literal.assert(bool);
    pub const int = if (!root.is_listing) is_enum_literal.assert(u32);
    pub const float = if (!root.is_listing) is_enum_literal.assert(f32);
    pub const pointer = if (!root.is_listing) is_enum_literal.assert(*@TypeOf(.enum_literal));
    pub const array = if (!root.is_listing) is_enum_literal.assert([1]@TypeOf(.enum_literal));
    pub const @"struct" = if (!root.is_listing) is_enum_literal.assert(struct {});
    pub const @"comptime_int" = if (!root.is_listing) is_enum_literal.assert(comptime_int);
    pub const @"comptime_float" = if (!root.is_listing) is_enum_literal.assert(comptime_float);
    pub const @"undefined" = if (!root.is_listing) is_enum_literal.assert(@TypeOf(undefined));
    pub const @"null" = if (!root.is_listing) is_enum_literal.assert(@TypeOf(null));
    pub const optional = if (!root.is_listing) is_enum_literal.assert(?@TypeOf(.enum_literal));
    pub const error_set = if (!root.is_listing) is_enum_literal.assert(anyerror);
    pub const error_union = if (!root.is_listing) is_enum_literal.assert(anyerror!@TypeOf(.enum_literal));
    pub const @"enum" = if (!root.is_listing) is_enum_literal.assert(enum {});
    pub const @"union" = if (!root.is_listing) is_enum_literal.assert(union {});
    pub const @"fn" = if (!root.is_listing) is_enum_literal.assert(fn () enum {});
    pub const @"opaque" = if (!root.is_listing) is_enum_literal.assert(opaque {});
    pub const vector = if (!root.is_listing) is_enum_literal.assert(@Vector(1, u8));
};
