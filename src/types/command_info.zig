const std = @import("std");
const Vector = @import("primitives.zig").Vector;
const Angle = @import("primitives.zig").Angle;
const log = std.log.scoped(.libdemo);
const File = @import("../io.zig").File;

const FDEMO_NORMAL = 0;
const FDEMO_USE_ORIGIN2 = 1 << 0;
const FDEMO_USE_ANGLES2 = 1 << 1;
const FDEMO_NOINTERP = 1 << 2;

pub const CommandInfo = extern struct {
    flags: i32 = FDEMO_NORMAL,
    view_origin: Vector,
    view_angles: Angle,
    local_view_angles: Angle,
    view_origin_2: Vector,
    view_angles_2: Angle,
    local_view_angles_2: Angle,

    pub fn read(file: File) !@This() {
        log.debug("Reading command info...", .{});
        return try file.readObject(@This());
    }
};
