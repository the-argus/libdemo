const std = @import("std");
const builtin = @import("builtin");
const app_name = "demo";

pub fn build(b: *std.Build) !void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardOptimizeOption(.{});

    const lib = b.addSharedLibrary(.{
        .name = app_name,
        .optimize = mode,
        .target = target,
        .root_source_file = std.Build.FileSource.relative("demo.zig"),
    });

    lib.linkLibC();

    b.installArtifact(lib);
}
