const std = @import("std");
const CommandHeader = @import("command_header.zig").CommandHeader;
const CommandInfo = @import("command_info.zig").CommandInfo;
const SequenceInfo = @import("sequence_info.zig").SequenceInfo;
const UserCommand = @import("user_command.zig").UserCommand;
const readRawData = @import("../io.zig").readRawData;
const demo_messages = @import("demo_messages.zig").demo_messages;
const log = std.log.scoped(.libdemo);

/// unused constant
pub const DEMO_FILE_MAX_STRINGTABLE_SIZE: u32 = 5000000;

/// from public/tier1/netadr.h
pub const NetAddressType = enum(u8) {
    NA_NULL = 0,
    NA_LOOPBACK,
    NA_BROADCAST,
    NA_IP,
};

pub const NetAddress = struct {
    type: NetAddressType,
    ip: [4]u8,
    port: u16,
};

pub const NetPacket = extern struct {
    from: NetAddressType, // sender IP
    source: i32, // received source
    received: f64, // received time
    data: [*]u8, // pointer to raw packet data
    message: NetAddress, // easy bitbuf data access
    size: i32, // size in bytes
    wiresize: i32, // size in bytes before decompression
    stream: bool, // was send as stream
    next: *NetPacket, // for internal use, should be NULL in public

    pub fn read(file: std.fs.File, allocator: std.mem.allocator) !?NetPacket {
        var last_command_header: CommandHeader = undefined;

        while (true) {
            last_command_header = try CommandHeader.read(file);
            // normally here there are checks for a bunch of member variables of
            // CDemoPlayer. in this case I don't want to allow for configuring the
            // reading of packets via state in a type, I would prefer an "options"
            // input to this function.

            const res = try performOneRead(file, allocator, last_command_header.message);
            if (res == .StopReading) {
                break;
            } else if (res == .EndOfDemo) {
                return null;
            }
        }

        const cmd_info = try CommandInfo.read(file);
        _ = try SequenceInfo.read(file);

        cmd_info.view_origin.print("view origin\t\t", &log.debug);
        cmd_info.view_origin_2.print("view origin 2\t\t", &log.debug);
        cmd_info.view_angles.print("view angles\t\t", &log.debug);
        cmd_info.view_angles_2.print("view angles 2\t\t", &log.debug);
        cmd_info.local_view_angles.print("local view angles\t\t", &log.debug);
        cmd_info.local_view_angles_2.print("local view angles 2\t\t", &log.debug);

        // FIXME: undefined behavior!! not all fields of packets are initialized
        var packet: NetPacket = undefined;
        // TODO: figure out time in zig, fill recieved field
        const packet_read_results = try readRawData(file, allocator);
        allocator.free(packet_read_results);

        return packet;
    }
};

const read_result = enum(u8) {
    EndOfDemo,
    ContinueReading,
    StopReading,
};

/// based on a demo command, return whether or not you should continue reading.
fn performOneRead(file: std.fs.File, allocator: std.mem.Allocator, cmd: demo_messages) !read_result {
    switch (cmd) {
        .dem_synctick => {
            // do NOTHING lol
            // nah this originally was a thing that modified a member variable of
            // CDemoPlayer, but its not relevant to reading packets. might need to
            // be implemented later
            return read_result.ContinueReading;
        },
        .dem_stop => {
            log.debug("End of demo reached.", .{});
            return read_result.EndOfDemo;
        },
        .dem_consolecmd => {
            log.debug("Reading console command...", .{});
            const console_command = try readRawData(file, allocator);
            allocator.free(console_command);
        },
        .dem_datatables => {
            log.debug("Reading network datatables...", .{});
            const network_datatables = try readRawData(file, allocator);
            allocator.free(network_datatables);
        },
        .dem_stringtables => {
            log.debug("Reading stringtables...", .{});
            const stringtables = try readRawData(file, allocator);
            allocator.free(stringtables);
        },
        .dem_usercmd => {
            log.debug("Reading user command...", .{});
            const user_command = try UserCommand.read(file, allocator);
            user_command.free_with(allocator);
        },
        else => {
            // other demo messages mean that there are no more items in this packet
            return read_result.StopReading;
        },
    }
    return read_result.ContinueReading;
}
