const std = @import("std");
const demo_messages = @import("demo_messages.zig").demo_messages;
const File = @import("../io.zig").File;
const DemoError = @import("../error.zig").DemoError;

const log = std.log.scoped(.libdemo);

pub const CommandHeader = extern struct {
    message: demo_messages,
    tick: i32,

    /// Reads the command that sits after the demo header and every packet, saying what comes next
    pub fn read(file: File) !@This() {
        log.debug("Reading command header...", .{});
        var result: @This() = undefined;
        result.tick = 0;
        result.message = .dem_signon;
        // first read into cmd
        {
            const buf = try file.readObject(u8);

            result.message = std.meta.intToEnum(demo_messages, buf) catch {
                return DemoError.InvalidDemoMessage;
            };
            if (result.message == .dem_stop) {
                log.info("Demo stopping code reached, exiting.", .{});
                std.os.exit(0);
            }
        }

        // now read the tick
        result.tick = try file.readObject(i32);
        return result;
    }
};
