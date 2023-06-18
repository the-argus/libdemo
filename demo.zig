///
/// This is the file to import into your zig projects which includes the public
/// demo parsing interface.
///
const std = @import("std");
// const demo_debug = @import("demo_debug.zig");
const builtin = @import("builtin");

const fcntl_header = @cImport(.{@cInclude("fcntl.h")});
const stdio_header = @cImport(.{@cInclude("stdio.h")});
const fread = stdio_header.fread;
const fwrite = stdio_header.fwrite;
const fcntl = fcntl_header.fcntl;
const F_GETFD = fcntl_header.F_GETFD;

pub const std_options = struct {
    // log level depends on build mode
    pub const log_level = if (builtin.mode == .Debug) .debug else .info;
    // Define logFn to override the std implementation
    pub const logFn = @import("src/logging.zig").libdemo_logger;
};

///
/// INTENDED FOR C API. Use demoToJSON from zig code.
/// Read from a given demo file and print the json to the given output file
/// descriptor.
///
pub fn demo_to_json(demo_file: *std.c.FILE, out: *std.c.FILE) callconv(.C) void {
    const demo_file_valid = fcntl(demo_file, F_GETFD);
    const out_file_valid = fcntl(out, F_GETFD);
    _ = demo_file_valid;
    _ = out_file_valid;
}

///
/// Read from a given demo file and print the json to the given output file
/// descriptor.
///
pub fn demoToJSON(demo_file: std.fs.File, out: std.fs.File) !void {
    _ = demo_file;
    _ = out;
}
