///
/// I/O related utilities
///
const std = @import("std");
const DemoError = @import("error.zig").DemoError;
const log = std.log.scoped(.libdemo);
const buildForC = @import("build-options").buildForC;

///
/// This type provides a compile-time layer over std.fs.file and c's FILE*
/// to abstract the differences.
///
pub const File = struct {
    inner: filetype(),

    pub fn wrap(file: filetype()) @This() {
        return @This(){ .inner = file };
    }

    /// Read a type from this file
    pub fn readObject(self: @This(), comptime T: type) !T {
        var buf: [@sizeOf(T)]u8 = undefined;

        // implementation difference for C
        if (buildForC) {
            const stdio_header = @cImport({
                @cInclude("stdio.h");
            });
            // read in separate bytes * the size of T instead of 1xT
            // so that bytes_read can be bytes_read instead of T_read
            const bytes_read = stdio_header.fread(&buf[0], 1, @sizeOf(T), self.inner);
            if (bytes_read < buf.len) {
                log.debug("Error: {any} bytes read, expected {any}", .{ bytes_read, buf.len });
                return DemoError.LibcFread;
            }
        } else {
            const bytes_read = try self.inner.read(&buf);
            if (bytes_read < buf.len) {
                return DemoError.EarlyTermination;
            }
        }

        return @bitCast(T, buf);
    }

    /// Recieve a file and read an integer. That integer determines how many bytes
    /// to read after that.
    pub fn readRawData(self: @This(), allocator: std.mem.Allocator) ![]u8 {
        log.debug("Reading raw data...", .{});
        // first get the size of the data packet
        // FIXME: low-prio, but there could be bugs/buffer overwrite if there is
        // integer overflow when reading the size from the heading of the raw data
        const size = try self.readObject(i32);

        log.debug("Raw data expected size: {any}", .{size});
        if (size < 0) {
            return DemoError.Corruption;
        }

        var buf = try allocator.alloc(u8, @intCast(usize, size));
        var bytes_read: usize = undefined;

        // implementation difference for C
        if (buildForC) {
            const stdio_header = @cImport({
                @cInclude("stdio.h");
            });
            // read buf.len bytes
            bytes_read = stdio_header.fread(&buf[0], 1, buf.len, self.inner);
        } else {
            bytes_read = try self.inner.read(buf);
        }

        if (bytes_read != buf.len) {
            allocator.free(buf);
            return DemoError.FileDoesNotMatchPromised;
        }

        log.debug("Bytes of raw data read match expected.", .{});

        return buf;
    }
};

fn filetype() type {
    if (buildForC) {
        const stdio_header = @cImport({
            @cInclude("stdio.h");
        });
        return *stdio_header.FILE;
    } else {
        return std.fs.File;
    }
}
