///
/// I/O related utilities
///
const std = @import("std");

pub const DemoError = error{
    EarlyTermination,
};

pub fn readObject(file: std.fs.File, comptime T: type) !T {
    var object: T = undefined;
    {
        var buf: [@sizeOf(T)]u8 = undefined;
        const bytes_read = try file.read(&buf);
        if (bytes_read < buf.len) {
            return DemoviewerIOError.EarlyTermination;
        }
        object = @bitCast(T, buf);
    }
    return object;
}
