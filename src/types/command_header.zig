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
            const buf = try file.readObject([1]u8);

            // get actual demo value
            var valid_demo_message = false;
            // NOTE: this could be @intToEnum. it would be much
            // faster, although it would cause the program to panic when reading
            // invalid demos.
            for (std.enums.values(demo_messages)) |message_type| {
                if (buf[0] == @enumToInt(message_type)) {
                    result.message = message_type;
                    valid_demo_message = true;
                    break;
                }
            }
            if (!valid_demo_message) {
                return DemoError.InvalidDemoMessage;
            }
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
