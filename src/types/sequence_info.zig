const std = @import("std");
const log = std.log.scoped(.libdemo);
const readObject = @import("../io.zig").readObject;

pub const SequenceInfo = struct {
    sequence_number_in: i32,
    sequence_number_out: i32,

    pub fn read(file: std.fs.File) !SequenceInfo {
        log.debug("Reading sequence info...", .{});

        var result: SequenceInfo = undefined;
        result.sequence_number_in = try readObject(file, i32);
        result.sequence_number_out = try readObject(file, i32);
        return result;
    }
};
