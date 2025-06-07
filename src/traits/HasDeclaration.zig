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

const Diagnostic = @import("Diagnostic.zig");
const HasDeclaration = @This();
const Trait = @import("Trait.zig");

pub fn diagnostic(comptime has_decl: HasDeclaration, comptime T: type) Diagnostic {
    const trait_name = has_decl.traitName();
    const default = Diagnostic.default(T).withName(trait_name);
    if (!Trait.is_container.check(T))
        return Trait.is_container.diagnostic(T).withName(trait_name);
    return if (@hasDecl(T, has_decl.name))
        default
    else
        default
            .withErrorCode(error.MissingDeclaration)
            .withExpect("The type must declare a public `" ++ has_decl.name ++ "` declaration!");
}

fn traitName(comptime has_decl: HasDeclaration) []const u8 {
    return "has_decl(" ++ has_decl.name ++ ")";
}
