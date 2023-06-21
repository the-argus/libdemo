const std = @import("std");
const log = std.log.scoped(.libdemo);
const File = @import("../io.zig").File;

pub const SequenceInfo = struct {
    sequence_number_in: i32,
    sequence_number_out: i32,

    pub fn read(file: File) !SequenceInfo {
        log.debug("Reading sequence info...", .{});

        var result: SequenceInfo = undefined;
        result.sequence_number_in = try file.readObject(i32);
        result.sequence_number_out = try file.readObject(i32);
        return result;
    }
};
