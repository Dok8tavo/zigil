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

name: []const u8,
condition: fn (comptime T: type) bool,
repair: ?[]const u8 = null,

const std = @import("std");

const Pass = @This();
const Diagnostic = @import("Diagnostic.zig");

const fmt = std.fmt.comptimePrint;

pub fn diagnostic(comptime p: Pass, comptime T: type) Diagnostic {
    const name = fmt("pass({s})", .{p.name});
    return if (p.condition(T)) Diagnostic.default(T).withName(name) else Diagnostic.default(T)
        .withName(name)
        .withErrorCode(error.False)
        .withExpect(fmt("Calling `{s}` on `{s}` must return `true`!", .{ @typeName(T), p.name }))
        .withRepair(p.repair);
}
