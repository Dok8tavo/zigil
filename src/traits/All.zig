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

traits: []const Trait,

const All = @This();
const Diagnostic = @import("Diagnostic.zig");
const Trait = @import("Trait.zig");

pub fn addMany(comptime a: *All, comptime others: []const Trait) void {
    a.traits = a.traits ++ others;
}

pub fn addOne(comptime a: *All, comptime one: Trait) void {
    a.traits = a.traits ++ &[_]Trait{one};
}

pub fn diagnostic(comptime a: All, comptime T: type) Diagnostic {
    const default = Diagnostic.default(T);
    if (a.traits.len == 0)
        return default.withName("no-trait");

    var name: []const u8 = "";

    for (a.traits) |trait| {
        const d = trait.diagnostic(T);
        if (d.error_code != null)
            return d;
        name = d.name ++ ", ";
    }

    return default.withName("all[" ++ name[0 .. name.len - ", ".len] ++ "]");
}
