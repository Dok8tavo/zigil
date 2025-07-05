# ⚡ Zigil

A metaprogramming module for Zig.

## Traits

A trait is a set of conditions that a given type should satisfy.
They take the form of a function that takes in the type. Like this:

```zig
const is_float_vector = zigil.Trait.isVector(.{ .child = .isFloat(.{}) });
is_float_vector.assert(SomeType);
```

If the type fails to satisfy the conditions, the `assert` function will emit a
compile error:

```zig
error: [trait trace] The type `@Vector(8, u8)` is required to satisfy the trait `is-vector[child => is-float]`.
                              The type must be a vector whose child satisfy the trait is-float.
                          [trait trace] The type `u8` is required to satisfy the trait `is-float`.
                              The type must be a floating point.
                          [trait trace] The type `u8` is required to satisfy the trait `is-kind[.float]`.
                              The type is an integer.
                          [trait `error.IsInt`]
```

### Custom traits

You can define your own custom traits using the `Trait.Result` type.

```zig
fn customTrait(comptime T: type) zigil.Trait.Result {
    comptime {
        // initialize a passing result
        const r = zigil.Trait.Result.init(
            // with the type it's supposed to apply to
            T,
            // with a descriptive kebab-cased name
            "custom-trait",
            // And a meaningfull expectation of the trait.
            "I expect this and that from the type.",
        );

        // compute your conditions
        const condition = ...;

        // If the type fails to satisfy the condition, return the result with an error.
        if (!condition) return r.withFailure(.{
            // this error will be used by `Trait.expect` and `Trait.expectError`, they're useful
            // for testing your trait and making sure it fails where it's supposed to.
            .@"error" = error.CustomError,

            // You can setup a few useful messages. By default, "expect"  will be the initial 
            // description of the trait, the "actual" and "repair" sections will be empty.
            .expect = "I expect this particulary.",
            .actual = "What happened instead was that: ...",
            .repair = "You might fix everything by using this instead...",

            // This is the name of the condition it failed, it will help the name of the trait be
            // more precise like `custom-trait[that-condition]` instead of just "custom-trait"
            .option = "that-condition",
        });

        // The trait can also depend on a type satisfying another trait
        if (r.propagateFail(
            // most of the time, it's the same type, but not always
            T, another_trait, .{
                // This options will help display a good trace by naming the trait with the other
                // trait like this: `custom-trait[=> another-trait]` instead of just `custom-trait`
                .option = .withTraitName("=> {s}"),
                // The expect message can also be useful to explain why the other trait is required.
                .expect = .str("The type must satisfy both traits because ..."),
            },
            // we return the result if it's a fail.
        )) |fail| return fail;
    }
}

const custom_trait = Trait{ .result = customTrait };

comptime {
    custom_trait.assert(SomeType);
}
```


## 📃 License

MIT License

Copyright (c) 2025 Dok8tavo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
