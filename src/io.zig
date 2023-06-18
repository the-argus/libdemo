///
/// I/O related utilities
///
const std = @import("std");
const DemoError = @import("error.zig").DemoError;
const log = std.log.scoped(.demoviewer);

pub fn readObject(file: std.fs.File, comptime T: type) !T {
    var buf: [@sizeOf(T)]u8 = undefined;
    const bytes_read = try file.read(&buf);
    if (bytes_read < buf.len) {
        return DemoError.EarlyTermination;
    }
    return @bitCast(T, buf);
}

const stdio_header = @cImport(.{@cInclude("stdio.h")});
pub fn read_object_c(file: *std.c.FILE, comptime T: type) !T {
    var buf: [@sizeOf(T)]u8 = undefined;
    const bytes_read = stdio_header.fread(&buf[0], @sizeOf(T), 1, file);
    if (bytes_read < buf.len) {
        return DemoError.LibcFread;
    }
    return @bitCast(T, buf);
}

/// Recieve a file and read an integer. That integer determines how many bytes
/// to read after that.
pub fn readRawData(file: std.fs.File, allocator: std.mem.Allocator) ![]u8 {
    log.debug("Reading raw data...", .{});
    // first get the size of the data packet
    // FIXME: low-prio, but there could be bugs/buffer overwrite if there is
    // integer overflow when reading the size from the heading of the raw data
    const size = try readObject(file, i32);

    log.debug("Raw data expected size: {any}", .{size});
    if (size < 0) {
        return DemoError.Corruption;
    }

    var buf = try allocator.alloc(u8, @intCast(usize, size));
    const bytes_read = try file.read(buf);
    if (bytes_read != buf.len) {
        allocator.free(buf);
        return DemoError.FileDoesNotMatchPromised;
    }
    log.debug("Bytes of raw data read match expected.", .{});

    return buf;
}
