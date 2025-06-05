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

value: *const anyopaque,
type: type,

const std = @import("std");
const AnyValue = @This();

pub fn from(comptime value: anytype) AnyValue {
    return AnyValue{
        .value = &value,
        .type = @TypeOf(value),
    };
}

pub fn get(comptime any_value: AnyValue) any_value.type {
    const ptr: *const any_value.type = @ptrCast(@alignCast(any_value.value));
    return ptr.*;
}

test AnyValue {
    {
        const integer: usize = 12;
        const any_value = AnyValue.from(integer);
        try std.testing.expectEqual(12, any_value.get());
    }
    {
        const T = usize;
        const any_value = AnyValue.from(T);
        try std.testing.expectEqual(usize, any_value.get());
    }
    {
        const comptime_integer = 100;
        const any_value = AnyValue.from(comptime_integer);
        try std.testing.expectEqual(100, any_value.get());
    }
}
