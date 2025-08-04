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

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zigil", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const fail_exe = b.addExecutable(.{
        .name = "fail",
        .root_module = b.createModule(.{
            .root_source_file = b.path("fail/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    fail_exe.root_module.addImport("zigil", mod);

    const test_exe = b.addTest(.{ .root_module = mod });
    const test_run = b.addRunArtifact(test_exe);
    const fail_run = b.addRunArtifact(fail_exe);

    const fail_config = b.addOptions();
    if (b.args) |args| {
        test_run.addArgs(args);
        for (args) |arg| fail_config.addOption(void, arg, {});
    }
    fail_exe.root_module.addOptions("config", fail_config);

    const lib = b.addLibrary(.{ .name = "zigil", .root_module = mod });
    const doc = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "doc",
        .source_dir = lib.getEmittedDocs(),
    });

    const test_step = b.step("test", "Build & Run the tests");
    const doc_step = b.step("doc", "Build & Install the documentation");
    const zls_step = b.step("zls", "A step for ZLS to use");
    const fail_step = b.step("fail",
        \\Attempt to build a failing executable:
        \\                               Use a `path.to.the.target.assertion` as an additional argument:
        \\                                   `zig build fail -- trait.is.primitive`
        \\                               And a compilation error resulting from the assertion will show up.
        \\                               You can use `-l`, `--list` or `-lr`, `--list-recursive` to show the list of available assertions. 
        \\
    );

    fail_step.dependOn(&fail_run.step);
    test_step.dependOn(&test_run.step);
    doc_step.dependOn(&doc.step);
    zls_step.dependOn(&test_exe.step);

    // if someone uses `zig build` instead of `zig build zls` as a ZLS step
    b.getInstallStep().dependOn(&test_exe.step);
}
