const std = @import("std");
const builtin = @import("builtin");

///
///Much of this is stolen from
///https://github.com/mitchellh/libxev/blob/main/build.zig
///
pub fn build(b: *std.Build) !void {
    const test_install = b.option(
        bool,
        "install-tests",
        "Install the test binaries into zig-out",
    ) orelse false;

    const target = b.standardTargetOptions(.{});
    // Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall
    const mode = b.standardOptimizeOption(.{});

    // tests -------------------------------------------------------------------
    const main_tests = b.addTest(.{
        .name = "",
        .root_source_file = .{ .path = "tests.zig" },
        .optimize = mode,
        .target = target,
    });

    const tests_run = b.addRunArtifact(main_tests);
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests_run.step);

    // create and install the C static library
    createStaticCLib(b, target, mode, test_step, test_install);

    // C Header installation
    const c_header = b.addInstallFileWithDir(
        .{ .path = "include/demo.h" },
        .header,
        "demo.h",
    );
    b.getInstallStep().dependOn(&c_header.step);

    // pkg-config file
    {
        const file = try b.cache_root.join(b.allocator, &[_][]const u8{"libdemo.pc"});
        const pkgconfig_file = try std.fs.cwd().createFile(file, .{});

        const writer = pkgconfig_file.writer();
        try writer.print(
            \\prefix={s}
            \\includedir=${{prefix}}/include
            \\libdir=${{prefix}}/lib
            \\
            \\Name: libdemo
            \\URL: https://github.com/the-argus/libdemo
            \\Description: TF2 demo file parsing
            \\Version: 0.0.1
            \\Cflags: -I${{includedir}}
            \\Libs: -L${{libdir}} -ldemo
        , .{b.install_prefix});
        defer pkgconfig_file.close();

        b.installFile(file, "share/pkgconfig/libdemo.pc");
    }
}

fn createStaticCLib(
    b: *std.Build,
    target: std.zig.CrossTarget,
    mode: std.builtin.Mode,
    test_step: *std.build.Step,
    test_install: bool,
) void {
    const static_lib = b.addStaticLibrary(.{
        .name = "demo",
        .root_source_file = .{ .path = "src/c_api.zig" },
        .target = target,
        .optimize = mode,
    });
    b.installArtifact(static_lib);
    static_lib.linkLibC();
    b.default_step.dependOn(&static_lib.step);

    const static_binding_test = b.addExecutable(.{
        .name = "static-binding-test",
        .target = target,
        .optimize = mode,
    });
    static_binding_test.linkLibC();
    static_binding_test.addIncludePath("include");
    static_binding_test.addCSourceFile(
        "tests/cprogram/main.c",
        &[_][]const u8{ "-Wall", "-Wextra", "-pedantic", "-std=c99", "-D_POSIX_C_SOURCE=199309L" },
    );
    static_binding_test.linkLibrary(static_lib);
    if (test_install) b.installArtifact(static_binding_test);

    const static_binding_test_run = b.addRunArtifact(static_binding_test);
    test_step.dependOn(&static_binding_test_run.step);
}
