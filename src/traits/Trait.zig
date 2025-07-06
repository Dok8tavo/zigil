result: fn (comptime type) Result,

const std = @import("std");
const z = @import("../root.zig");

const Trait = @This();

pub const Result = @import("Result.zig");
pub inline fn expect(comptime t: Trait, comptime T: type) anyerror!void {
    comptime return if (t.result(T).failure) |f| f.@"error";
}

pub inline fn expectError(comptime t: Trait, comptime T: type, comptime expected: anyerror) anyerror!void {
    comptime return std.testing.expectError(expected, t.expect(T));
}

pub inline fn assert(comptime t: Trait, comptime T: type) void {
    comptime {
        const r = t.result(T);
        if (r.failure != null) z.compileError("{}", .{r});
    }
}

pub inline fn check(comptime t: Trait, comptime T: type) bool {
    comptime return t.result(T).failure == null;
}

pub inline fn pass(comptime t: Trait, comptime T: type) ?Result {
    comptime {
        const r = t.result(T);
        return if (r.failure) |_| null else r;
    }
}

pub inline fn fail(comptime t: Trait, comptime T: type) ?Result {
    comptime {
        const r = t.result(T);
        return if (r.failure) |_| r else null;
    }
}

pub inline fn name(comptime t: Trait, comptime T: type) []const u8 {
    comptime {
        const r = t.result(T);
        return r.info;
    }
}

pub inline fn fromResultFn(comptime result_fn: anytype, comptime args: anytype) Trait {
    return Trait{ .result = struct {
        fn call(comptime T: type) Result {
            return @call(.compile_time, result_fn, .{T} ++ args);
        }
    }.call };
}

// === TRAITS ===
pub const no_trait = Trait{
    .result = struct {
        fn call(comptime T: type) Result {
            return .init(T, "no-trait", "No expectations.");
        }
    }.call,
};

pub fn is(comptime T: type) Trait {
    return fromResultFn(@import("impl/is.zig").uMustBeT, .{T});
}
test is {
    try is(u8).expect(u8);
    try is(u8).expectError(u7, error.WrongType);

    const unique = struct {};

    try is(unique).expect(unique);
    try is(unique).expectError(struct {}, error.WrongType);
}

pub fn isKind(comptime kind: std.builtin.TypeId) Trait {
    return fromResultFn(@import("impl/kind.zig").is, .{kind});
}
test isKind {
    try isKind(.int).expect(u8);
    try isKind(.int).expectError(f32, error.IsFloat);

    try isKind(.float).expect(f32);
    try isKind(.pointer).expect(*i32);
}

pub fn isOptional(comptime child: Trait) Trait {
    return fromResultFn(@import("impl/optionals.zig").is, .{child});
}
test isOptional {
    try isOptional(.no_trait).expect(?u8);
    try isOptional(.no_trait).expect(?*u8);
    try isOptional(.no_trait).expectError(usize, error.IsInt);

    try isOptional(.is(u8)).expect(?u8);
    try isOptional(.isKind(.int)).expectError(struct {}, error.IsStruct);
}

const vectors = @import("impl/vectors.zig");
pub fn isVector(comptime o: vectors.Options) Trait {
    return fromResultFn(vectors.is, .{o});
}
test isVector {
    try isVector(.{}).expectError(u8, error.IsInt);
    try isVector(.{}).expect(@Vector(1, u8));

    try isVector(.{ .child = .is(bool) }).expectError(@Vector(1, u8), error.WrongType);
    try isVector(.{ .child = .is(bool) }).expect(@Vector(1, bool));

    const len6 = isVector(.{ .len = .{ .is = 6 } });
    try len6.expectError(@Vector(5, bool), error.WrongLength);
    try len6.expect(@Vector(6, i32));

    const suggested_length = isVector(.{ .len = .suggested });
    try suggested_length.expect(@Vector(std.simd.suggestVectorLength(bool) orelse 1, bool));

    const min_two = isVector(.{ .min_len = .{ .is = 2 } });

    try min_two.expect(@Vector(8, u8));
    try min_two.expect(@Vector(2, u8));
    try min_two.expectError(@Vector(1, u8), error.VectorTooShort);

    const max_five = isVector(.{ .max_len = .{ .is = 5 } });

    try max_five.expect(@Vector(1, isize));
    try max_five.expect(@Vector(5, isize));
    try max_five.expectError(@Vector(6, isize), error.VectorTooLong);

    const impossible = isVector(.{ .min_len = .{ .is = 10 }, .max_len = .{ .is = 5 } });
    try impossible.expectError(@Vector(7, u8), error.ImpossibleRequirement);
}

const ints = @import("impl/ints.zig");
pub fn isInt(comptime o: ints.Options) Trait {
    return fromResultFn(ints.is, .{o});
}
test isInt {
    try isInt(.{}).expect(u8);
    try isInt(.{}).expectError(bool, error.IsBool);

    const is_pos = isInt(.{ .signed = false });
    try is_pos.expect(u8);
    try is_pos.expectError(i8, error.IsSignedInt);

    const cant_from_125 = isInt(.{ .cant_repr = .from(125) });
    try cant_from_125.expectError(u8, error.ForbiddenRepresentation);
    try cant_from_125.expectError(u7, error.ForbiddenRepresentation);
    try cant_from_125.expect(u6);
    try cant_from_125.expect(i7);

    const cant_until_m12 = isInt(.{ .cant_repr = .until(-12) });
    try cant_until_m12.expect(u4);
    try cant_until_m12.expectError(i5, error.ForbiddenRepresentation);
    try cant_until_m12.expect(i4);

    const cant_12_31 = isInt(.{ .cant_repr = .range(-12, 31) });
    try cant_12_31.expect(u4);
    try cant_12_31.expect(i4);
    try cant_12_31.expectError(i5, error.ForbiddenRepresentation);
    try cant_12_31.expectError(u5, error.ForbiddenRepresentation);

    const must_from_m12 = isInt(.{ .must_repr = .from(-12) });
    try must_from_m12.expect(i5);
    try must_from_m12.expectError(i4, error.MissingRepresentation);

    const must_until_12 = isInt(.{ .must_repr = .until(12) });
    try must_until_12.expect(u5);
    try must_until_12.expect(i5);
    try must_until_12.expect(u4);
    try must_until_12.expectError(i4, error.MissingRepresentation);
    try must_until_12.expectError(u3, error.MissingRepresentation);

    const must_from_m100_until_8 = isInt(.{ .must_repr = .range(-100, 8) });
    try must_from_m100_until_8.expect(i8);
    try must_from_m100_until_8.expectError(i7, error.MissingRepresentation);
    try must_from_m100_until_8.expectError(u8, error.MissingRepresentation);
}

const floats = @import("impl/floats.zig");
pub fn isFloat(comptime o: floats.Options) Trait {
    return fromResultFn(floats.is, .{o});
}
test isFloat {
    try isFloat(.{}).expect(f16);

    try isFloat(.{ .distinguish = .between(10_000, 10_001) }).expectError(f16, error.NotEnoughPrecision);
    try isFloat(.{ .distinguish = .between(10_000, 10_001) }).expect(f32);

    try isFloat(.{ .distinguish = .all(&.{ 10, 10.1, 10.11 }) })
        .expect(f16);
    try isFloat(.{ .distinguish = .all(&.{ 10, 10.1, 10.11, 10.111 }) })
        .expectError(f16, error.NotEnoughPrecision);
}

const error_sets = @import("impl/error_sets.zig");
pub fn isErrorSet(comptime o: error_sets.Options) z.Trait {
    return fromResultFn(error_sets.is, .{o});
}
test isErrorSet {
    try isErrorSet(.{}).expect(error{});
    try isErrorSet(.{}).expect(anyerror);
    try isErrorSet(.{}).expectError(enum {}, error.IsEnum);

    const is_any = isErrorSet(.{ .is_any = true });
    try is_any.expect(anyerror);
    try is_any.expectError(error{}, error.IsNotAnyerror);

    const is_not_any = isErrorSet(.{ .is_any = false });
    try is_not_any.expect(error{});
    try is_not_any.expectError(anyerror, error.IsAnyerror);

    const with = isErrorSet(.{ .with = .lit(.Required) });
    try with.expect(error{Required});
    try with.expect(anyerror);
    try with.expectError(error{}, error.MissingError);

    const wout = isErrorSet(.{ .wout = .lit(.Nope) });
    try wout.expect(error{});
    try wout.expectError(anyerror, error.ForbiddenError);
    try wout.expectError(error{Nope}, error.ForbiddenError);
}

const error_unions = @import("impl/error_unions.zig");
pub fn isErrorUnion(comptime o: error_unions.Options) z.Trait {
    return fromResultFn(error_unions.is, .{o});
}
test isErrorUnion {
    try isErrorUnion(.{}).expectError(u8, error.IsInt);
    try isErrorUnion(.{}).expect(anyerror!void);

    try isErrorUnion(.{ .payload = .is(u8) }).expectError(anyerror!void, error.WrongType);
    try isErrorUnion(.{ .payload = .is(u8) }).expect(anyerror!u8);

    const with_required_error = isErrorUnion(.{ .error_set = .isErrorSet(.{ .with = .lit(.RequiredError) }) });
    try with_required_error.expectError(error{}!u8, error.MissingError);
    try with_required_error.expect(error{RequiredError}!void);
    try with_required_error.expect(anyerror!void);
}

const enums = @import("impl/enums.zig");
pub fn isEnum(comptime o: enums.Options) z.Trait {
    return fromResultFn(enums.is, .{o});
}
test isEnum {
    try isEnum(.{}).expect(enum {});
    try isEnum(.{}).expectError(u8, error.IsInt);

    const exhaustive = isEnum(.{ .is_exhaustive = true });
    try exhaustive.expect(enum {});
    try exhaustive.expectError(enum(u8) { _ }, error.IsNotExhaustive);

    const non_exhaustive = isEnum(.{ .is_exhaustive = false });
    try non_exhaustive.expectError(enum {}, error.IsExhaustive);
    try non_exhaustive.expect(enum(u8) { _ });

    const has_lol = isEnum(.{ .with = .name("lol") });
    try has_lol.expect(enum { lol });
    try has_lol.expectError(enum {}, error.MissingValue);

    const has_no_lol = isEnum(.{ .wout = .name("lol") });
    try has_no_lol.expectError(enum { lol }, error.ForbiddenValue);
    try has_no_lol.expect(enum {});
}

const structs = @import("impl/structs.zig");
pub fn isStruct(comptime o: structs.Options) z.Trait {
    return fromResultFn(structs.is, .{o});
}
test isStruct {
    try isStruct(.{}).expect(struct {});
    try isStruct(.{}).expect(struct { u8 });
    try isStruct(.{}).expect(struct { field: u8 });

    const is_tuple = isStruct(.{ .is_tuple = true });
    try is_tuple.expect(struct { u8 });
    try is_tuple.expectError(struct { field: u8 }, error.IsNotTuple);
    try is_tuple.expectError(struct {}, error.IsNotTuple);

    const isnt_tuple = isStruct(.{ .is_tuple = false });
    try isnt_tuple.expect(struct {});
    try isnt_tuple.expect(struct { field: u8 });
    try isnt_tuple.expectError(struct { u8 }, error.IsTuple);

    const is_auto = isStruct(.{ .layout = .only(.auto) });
    try is_auto.expect(struct {});
    try is_auto.expectError(packed struct {}, error.ForbiddenLayout);
    try is_auto.expectError(extern struct {}, error.ForbiddenLayout);

    const is_signed = isStruct(.{ .backing_integer = .must(.isInt(.{ .signed = true })) });
    try is_signed.expectError(packed struct(u0) {}, error.IsUnsignedInt);
    try is_signed.expect(packed struct(i0) {});

    const has_field = isStruct(.{ .fields = .one(.{ .name = "hello" }) });
    try has_field.expect(struct { hello: void });

    const has_field_with = isStruct(.{ .fields = .one(.{ .name = "hello", .trait = .is(u8) }) });
    try has_field_with.expect(struct { hello: u8 });

    const has_fields = isStruct(.{ .fields = .many(&.{ .{ .name = "0" }, .{ .name = "1" } }) });
    try has_fields.expect(struct { u8, u16 });

    const has_least_fields = isStruct(.{ .field_count = .{ .least = 4 } });
    try has_least_fields.expectError(struct { u8, u8, u8 }, error.NotEnoughFields);
    try has_least_fields.expect(struct { u8, u8, u8, u8 });
    try has_least_fields.expect(struct { u8, u8, u8, u8, u8 });

    const has_exact_fields = isStruct(.{ .field_count = .{ .exact = 4 } });
    try has_exact_fields.expectError(struct { u8, u8, u8 }, error.WrongFieldCount);
    try has_exact_fields.expect(struct { u8, u8, u8, u8 });
    try has_exact_fields.expectError(struct { u8, u8, u8, u8, u8 }, error.WrongFieldCount);
}

const unions = @import("impl/unions.zig");
pub fn isUnion(comptime o: unions.Options) Trait {
    return fromResultFn(unions.is, .{o});
}
test isUnion {
    try isUnion(.{}).expect(union {});
    try isUnion(.{}).expect(union(enum) {});

    const is_auto = isUnion(.{ .layout = .only(.auto) });
    try is_auto.expect(union {});
    try is_auto.expectError(packed union {}, error.ForbiddenLayout);

    try is_auto.expectError(extern union {}, error.ForbiddenLayout);

    const is_signed = isUnion(.{ .tag = .isEnum(.{ .tag = .isInt(.{ .signed = true }) }) });
    // unions without variants always have a `u0` as a tag.
    try is_signed.expect(union(enum(i8)) { variant });
    try is_signed.expectError(union(enum(u8)) { variant }, error.IsUnsignedInt);

    const has_variant = isUnion(.{ .variants = .one(.{ .name = "hello" }) });
    try has_variant.expect(union { hello: void });

    const has_variant_with = isUnion(.{ .variants = .one(.{ .name = "hello", .trait = .is(u8) }) });
    try has_variant_with.expect(union { hello: u8 });

    const has_variants = isUnion(.{ .variants = .many(&.{ .{ .name = "hello" }, .{ .name = "goodbye" } }) });
    try has_variants.expect(union(enum) { hello, goodbye });

    const has_least_variants = isUnion(.{ .variant_count = .{ .least = 4 } });
    try has_least_variants.expectError(union(enum) { a, b, c }, error.NotEnoughVariants);
    try has_least_variants.expect(union(enum) { a, b, c, d });
    try has_least_variants.expect(union(enum) { a, b, c, d, e });

    const has_exact_variants = isUnion(.{ .variant_count = .{ .exact = 4 } });
    try has_exact_variants.expectError(union(enum) { a, b, c }, error.WrongVariantCount);
    try has_exact_variants.expect(union(enum) { a, b, c, d });
    try has_exact_variants.expectError(union(enum) { a, b, c, d, e }, error.WrongVariantCount);
}

const function = @import("impl/functions.zig");
pub fn isFunction(comptime o: function.Options) Trait {
    return fromResultFn(function.is, .{o});
}
test isFunction {
    try isFunction(.{}).expect(fn () void);
    try isFunction(.{}).expect(@TypeOf(z.eql));

    const generic = isFunction(.{ .is_generic = true });
    try generic.expect(@TypeOf(z.eql));
    try generic.expectError(fn () void, error.IsNotGeneric);

    const c = isFunction(.{ .calling_convention = .c });
    try c.expectError(fn () void, error.WrongCallingConvention);
    try c.expect(fn () callconv(.c) void);

    const has_one_param = isFunction(.{ .param_count = .{ .exact = 1 } });
    try has_one_param.expectError(fn () void, error.WrongParamCount);
    try has_one_param.expect(fn (bool) void);
    try has_one_param.expectError(fn (void, void) void, error.WrongParamCount);

    const has_many_param = isFunction(.{ .param_count = .{ .least = 2 } });
    try has_many_param.expectError(fn () void, error.TooFewParams);
    try has_many_param.expectError(fn (void) void, error.TooFewParams);
    try has_many_param.expect(fn (bool, bool, bool) void);

    const has_int_param = isFunction(.{ .params = &.{.{ .type = .isInt(.{}) }} });
    try has_int_param.expect(fn (u8) void);
    try has_int_param.expectError(fn (f32) void, error.IsFloat);
}

const pointers = @import("impl/pointers.zig");
pub fn isPointer(comptime o: pointers.Options) z.Trait {
    return fromResultFn(pointers.is, .{o});
}
test isPointer {
    try isPointer(.{}).expect([]const u8);
    try isPointer(.{}).expect(*i32);

    const is_slice = isPointer(.{ .size = .slice });
    try is_slice.expect([]usize);
    try is_slice.expect([:true]volatile bool);
    try is_slice.expectError(*i32, error.WrongSize);

    const is_allowzero = isPointer(.{ .is_allowzero = true });
    try is_allowzero.expect(*allowzero anyopaque);
    try is_allowzero.expectError(*f64, error.PointerForbidZero);

    const is_const = isPointer(.{ .is_const = true });
    try is_const.expect(*const i32);
    try is_const.expectError(*i32, error.PointerToVar);

    const no_volatile = isPointer(.{ .is_volatile = false });
    try no_volatile.expect([*c]const f16);
    try no_volatile.expectError([*]volatile isize, error.PointerIsVolatile);

    const natural_aligned = isPointer(.{ .alignment = .natural });
    try natural_aligned.expect(*i32);
    try natural_aligned.expect(*align(1) u8);
    try natural_aligned.expectError(*align(1) i32, error.WrongAlignment);

    const to_struct = isPointer(.{ .child = .isStruct(.{}) });
    try to_struct.expect(*struct {});
    try to_struct.expectError(*union {}, error.IsUnion);

    const with_sentinel = isPointer(.{ .has_sentinel = true });
    try with_sentinel.expect([*:0]u8);
    try with_sentinel.expect([:false]bool);
    try with_sentinel.expectError([*c]const u8, error.PointerLacksSentinel);

    const is_fs = isPointer(.{ .address_space = .fs });
    try is_fs.expect(*addrspace(.fs) u8);
    try is_fs.expectError(*f32, error.WrongAddressSpace);
}

pub const is_container = fromResultFn(@import("impl/containers.zig").is, .{});
test is_container {
    try is_container.expect(enum {});
    try is_container.expect(opaque {});
    try is_container.expect(struct {});
    try is_container.expect(union {});

    try is_container.expectError(comptime_int, error.IsComptimeInt);
    try is_container.expectError(struct { u8 }, error.IsTuple);
}

const decls = @import("impl/decls.zig");
pub fn hasDecl(comptime decl: []const u8, comptime o: decls.Options) Trait {
    return fromResultFn(decls.has, .{ decl, o });
}
test hasDecl {
    const has_decl = hasDecl("decl", .no_option);
    try has_decl.expectError(u8, error.IsInt);
    try has_decl.expectError(enum(u8) {}, error.MissingDeclaration);
    try has_decl.expectError(enum(u8) {
        const decl = "this is not `pub`";
    }, error.MissingDeclaration);

    // The `Trait` type has an `isKind` declaration.
    try hasDecl("isKind", .no_option).expect(Trait);
    // The `Trait` type has an `is` declaration that's a function.
    try hasDecl("is", .{ .of_type_which = .isKind(.@"fn") }).expect(Trait);
    // The `Trait.Result` type has an `Info` declaration that's a container type.
    try hasDecl("Info", .{ .is_type_which = .is_container }).expect(Trait.Result);

    try hasDecl("Result", .{
        .is_type_which = .hasDecl("Info", .{
            .is_type_which = .hasDecl("format", .{
                .of_type_which = .isKind(.@"fn"),
            }),
        }),
    }).expect(Trait);
}

const alignment = @import("impl/alignment.zig");
pub fn hasNaturalAlignment(comptime na: alignment.NaturalAlignment) Trait {
    return fromResultFn(alignment.hasNaturalAlignment, .{na});
}
test hasNaturalAlignment {
    const exact_16 = hasNaturalAlignment(.{ .exact = 2 });
    try exact_16.expectError(u8, error.WrongNaturalAlignment);
    try exact_16.expect(u16);
    try exact_16.expectError(u32, error.WrongNaturalAlignment);

    const least_32 = hasNaturalAlignment(.{ .least = 4 });
    try least_32.expectError(i16, error.NaturalAlignmentTooSmall);
    try least_32.expect(i32);
    try least_32.expect(i64);
}

const size = @import("impl/size.zig");
pub fn hasSize(comptime o: size.Options) Trait {
    return fromResultFn(size.has, .{o});
}
test hasSize {
    const eql18 = hasSize(.eqlBits(18));
    try eql18.expect(i18);
    try eql18.expect(packed struct { a: f16, b: bool, c: bool });
    try eql18.expectError(i32, error.BitSizeTooBig);
    try eql18.expectError(i16, error.BitSizeTooSmall);

    const from16_till24 = hasSize(.rangeBits(16, 24));
    try from16_till24.expectError(i15, error.BitSizeTooSmall);
    try from16_till24.expect(i16);
    try from16_till24.expect(i20);
    try from16_till24.expect(i24);
    try from16_till24.expectError(i25, error.BitSizeTooBig);
}

const array_lists = @import("impl/array_lists.zig");
pub fn isArrayList(comptime o: array_lists.Options) z.Trait {
    return fromResultFn(array_lists.is, .{o});
}
test isArrayList {
    try isArrayList(.{}).expect(std.ArrayList(u8));
    try isArrayList(.{}).expect(std.ArrayListAlignedUnmanaged(isize, .@"4"));
    try isArrayList(.{}).expectError(struct {
        items: []const u8,
    }, error.NotAnArrayList);

    const managed = isArrayList(.{ .managed = true });
    try managed.expect(std.ArrayList(bool));
    try managed.expectError(std.ArrayListUnmanaged(bool), error.IsUnmanaged);

    const aligned = isArrayList(.{ .alignment = .least_natural });
    try aligned.expect(std.ArrayListAligned(usize, .fromByteUnits(2 * @alignOf(usize))));
    try aligned.expect(std.ArrayList(usize));
    try aligned.expectError(std.ArrayListAligned(usize, .fromByteUnits(@alignOf(usize) / 2)), error.AlignmentTooSmall);

    const of_int = isArrayList(.{ .item = .isInt(.{}) });
    try of_int.expect(std.ArrayList(usize));
    try of_int.expectError(std.ArrayList(bool), error.IsBool);
}
