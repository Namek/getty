const std = @import("std");

const package_name = "getty";
const package_path = "src/getty.zig";

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    _ = b.addModule(
        package_name,
        .{ .source_file = .{ .path = package_path } },
    );

    tests(b, target, mode);
    docs(b, target, mode);
}

fn tests(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.OptimizeMode) void {
    const test_step = b.step("test", "Run tests");

    // Allow a test filter to be specified.
    //
    // ## Example
    //
    // ```
    // $ zig build test -- "serialize - array"
    // ```
    if (b.args) |args| {
        switch (args.len) {
            0 => unreachable, // UNREACHABLE: b.args is null if no arguments are given.
            1 => {
                const cmd = b.addSystemCommand(&[_][]const u8{
                    "zig",
                    "test",
                    "--main-pkg-path",
                    "src/",
                    package_path,
                    "--test-filter",
                    args[0],
                });

                test_step.dependOn(&cmd.step);

                return;
            },
            else => |len| std.debug.panic("expected 1 argument, found {}", .{len}),
        }
    }

    const test_ser_step = b.step("test-ser", "Run serialization tests");
    const test_de_step = b.step("test-de", "Run deserialization tests");

    // Configure tests.
    const t_ser = b.addTest(.{
        .name = "serialization test",
        .root_source_file = .{ .path = "src/ser/ser.zig" },
        .target = target,
        .optimize = mode,
    });
    t_ser.setMainPkgPath("src/");

    const t_de = b.addTest(.{
        .name = "deserialization test",
        .root_source_file = .{ .path = "src/de/de.zig" },
        .target = target,
        .optimize = mode,
    });
    t_de.setMainPkgPath("src/");

    // Configure module-level test steps.
    test_ser_step.dependOn(&b.addRunArtifact(t_ser).step);
    test_de_step.dependOn(&b.addRunArtifact(t_de).step);

    // Configure top-level test step.
    test_step.dependOn(test_ser_step);
    test_step.dependOn(test_de_step);
}

fn docs(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.OptimizeMode) void {
    // Remove cache.
    const cmd = b.addSystemCommand(&[_][]const u8{
        "rm",
        "-rf",
        "zig-cache",
    });

    const clean_step = b.step("clean", "Remove project artifacts");
    clean_step.dependOn(&cmd.step);

    // Build docs.
    const docs_obj = b.addObject(.{
        .name = "docs",
        .root_source_file = .{ .path = package_path },
        .target = target,
        .optimize = mode,
    });
    docs_obj.emit_bin = .no_emit;
    const install_docs = b.addInstallDirectory(.{
        .source_dir = docs_obj.getOutputDocs(),
        .install_dir = .prefix,
        .install_subdir = "../docs", //path next to zig-out
    });

    const docs_step = b.step("docs", "Generate project documentation");
    docs_step.dependOn(clean_step);
    docs_step.dependOn(&docs_obj.step);
    docs_step.dependOn(&install_docs.step);
}
