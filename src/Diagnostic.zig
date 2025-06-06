// MIT License
//
// Copyright (c) 2025 Dok8tavo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

/// It's type that's expected to implement the trait.
type: type,
/// It's name of the trait, a snake_cased description of the type that implements it.
trait: []const u8 = "anonymous_trait",
/// The error code shortly describes the issue preventing the type to implement the trait.
error_code: ?anyerror = null,
/// This describes what's expected of a type that implements the trait.
expect: ?[]const u8 = null,
/// This describes what's preventing the type to implement the trait.
status: ?[]const u8 = null,
/// This is a hint likely to coerce the `.status` into the `.expect`.
repair: ?[]const u8 = null,

const std = @import("std");
const root = @import("root.zig");

const Diagnostic = @This();

pub fn format(
    comptime d: Diagnostic,
    comptime fmt: []const u8,
    _: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    const use = !root.eql(u8, fmt, "no-color");
    const C = Color(use);
    const error_code = if (d.error_code) |error_code| error_code else {
        return try writer.print(
            "{}trait {}success{}: The type `{}{s}{}` implements the trait `{}{s}{}`",
            .{
                C.white,   C.green,           C.white,
                C.cyan,    @typeName(d.type), C.white,
                C.magenta, d.trait,           C.cyan,
            },
        );
    };

    const headline = std.fmt.comptimePrint(
        "{}trait error `{}{s}{}`: The type `{}{s}{}` doesn't implement the trait `{}{s}{}`!",
        .{
            C.white, C.red,     @errorName(error_code),
            C.white, C.cyan,    @typeName(d.type),
            C.white, C.magenta, d.trait,
            C.white,
        },
    );

    const expect_line = if (d.expect) |expect_message| std.fmt.comptimePrint(
        "\n    [{}expect{}]:\n{s}",
        .{ C.cyan, C.white, insertAtNewlines(expect_message, " " ** 8) },
    ) else "";

    const status_line = if (d.status) |status_message| std.fmt.comptimePrint(
        "\n    [{}status{}]:\n{s}",
        .{ C.red, C.white, insertAtNewlines(status_message, " " ** 8) },
    ) else "";

    const repair_line = if (d.repair) |repair_message| std.fmt.comptimePrint(
        "\n    [{}repair{}]:\n{s}",
        .{ C.green, C.white, insertAtNewlines(repair_message, " " ** 8) },
    ) else "";

    try writer.writeAll(headline ++ expect_line ++ status_line ++ repair_line);
}

fn insertAtNewlines(comptime str: []const u8, comptime insert: []const u8) []const u8 {
    @setEvalBranchQuota(str.len * 2 + 1000);

    var new_str: []const u8 = insert;
    var last = 0;
    for (str, 0..) |char, i| {
        if (char == '\n') {
            new_str = new_str ++ str[last..i] ++ insert;
            last = i;
        }
    }

    return new_str ++ str[last..];
}

pub fn Color(comptime use: bool) type {
    return enum {
        black,
        red,
        green,
        yellow,
        blue,
        magenta,
        cyan,
        white,

        pub fn format(
            comptime c: Color(use),
            comptime _: []const u8,
            _: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            if (use) try writer.writeAll(c.esc());
        }

        fn esc(comptime c: Color(use)) []const u8 {
            return "\x1B[" ++ switch (c) {
                .black => "30",
                .red => "31",
                .green => "32",
                .yellow => "33",
                .blue => "34",
                .magenta => "35",
                .cyan => "36",
                .white => "37",
            } ++ "m";
        }
    };
}
