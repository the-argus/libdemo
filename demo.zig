const std = @import("std");
const builtin = @import("builtin");
const readDemo = @import("src/read_dem.zig");

pub const std_options = struct {
    // log level depends on build mode
    pub const log_level = if (builtin.mode == .Debug) .debug else .info;
    // Define logFn to override the std implementation
    pub const logFn = @import("src/logging.zig").libdemo_logger;
};

///
/// Read from a given demo file and print the json to the given output file.
///
pub fn demoToJSON(demo_file: std.fs.File, out: std.fs.File) !void {
    try readDemo(demo_file);
    _ = out;
}
