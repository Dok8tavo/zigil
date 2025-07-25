const z = @import("../../root.zig");
const kind = @import("kind.zig");

pub const Options = struct {
    allow_unknown: bool = false,
    bits: z.Range(.inner) = .{},
    bytes: z.Range(.inner) = .{},

    pub fn eqlBits(comptime bits: comptime_int) Options {
        comptime return .{ .bits = .range(bits, bits) };
    }
    pub fn eqlBytes(comptime bytes: comptime_int) Options {
        comptime return .{ .bytes = .range(bytes, bytes) };
    }

    pub fn minBits(comptime bits: comptime_int) Options {
        comptime return .{ .bits = .from(bits) };
    }
    pub fn minBytes(comptime bytes: comptime_int) Options {
        comptime return .{ .bytes = .from(bytes) };
    }

    pub fn maxBits(comptime bits: comptime_int) Options {
        comptime return .{ .bits = .until(bits) };
    }
    pub fn maxBytes(comptime bytes: comptime_int) Options {
        comptime return .{ .bytes = .until(bytes) };
    }

    pub fn rangeBits(comptime min: comptime_int, comptime max: comptime_int) Options {
        comptime return .{ .bits = .range(min, max) };
    }
    pub fn rangeBytes(comptime min: comptime_int, comptime max: comptime_int) Options {
        comptime return .{ .bytes = .range(min, max) };
    }
};

pub fn has(comptime T: type, comptime o: Options) z.Trait.Result {
    comptime {
        const r = z.Trait.Result.init(T, "has-size", "TODO");

        switch (@typeInfo(T)) {
            else => {},
            inline .@"opaque",
            .undefined,
            .null,
            .noreturn,
            .@"fn",
            => |_, tag| return if (o.allow_unknown) r else r.failWith(.{
                .@"error" = kind.@"error"(tag),
                .expect = "The type must have a known size.",
                .actual = z.fmt("The type is {}, which doesn't have a size.", .{kind.denomination(tag)}),
            }),
        }

        const bits = @bitSizeOf(T);
        const bytes = @sizeOf(T);

        if (o.bits.first) |min_bits| if (bits < min_bits) return r.failWith(.{
            .@"error" = error.BitSizeTooSmall,
            .option = z.fmt("{} <= bits", .{min_bits}),
            .expect = z.fmt("The bit size of the type must be at least {}.", .{min_bits}),
            .actual = z.fmt("The bit size of the type is {}.", .{bits}),
        });

        if (o.bits.last) |max_bits| if (max_bits < bits) return r.failWith(.{
            .@"error" = error.BitSizeTooBig,
            .option = z.fmt("bits <= {}", .{max_bits}),
            .expect = z.fmt("The bit size of the type must be at most {}.", .{max_bits}),
            .actual = z.fmt("The bit size of the type is {}.", .{bits}),
        });

        if (o.bytes.first) |min_bytes| if (bytes < min_bytes) return r.failWith(.{
            .@"error" = error.ByteSizeTooSmall,
            .option = z.fmt("{} <= bytes", .{min_bytes}),
            .expect = z.fmt("The byte size of the type must be at least {}.", .{min_bytes}),
            .actual = z.fmt("The byte size of the type is {}.", .{bytes}),
        });

        if (o.bytes.last) |max_bytes| if (max_bytes < bytes) return r.failWith(.{
            .@"error" = error.ByteSizeTooBig,
            .option = z.fmt("bytes <= {}", .{max_bytes}),
            .expect = z.fmt("The byte size of the type must be at most {}.", .{max_bytes}),
            .actual = z.fmt("The byte size of the type is {}.", .{bytes}),
        });

        return r;
    }
}
