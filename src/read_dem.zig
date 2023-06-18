const std = @import("std");
const readObject = @import("io.zig").readObject;
const Header = @import("types/header.zig").Header;
const NetPacket = @import("types/net_packet.zig").NetPacket;

const log = std.log.scoped(.demoviewer);

pub fn readDemo(relative_path: []const u8) !void {
    const demo_file = try openDemo(relative_path);
    const header = try readObject(demo_file, Header);
    header.validate();
    header.print(&log.debug);
    try readAllPackets(demo_file);
}

fn openDemo(relative_path: []const u8) !std.fs.File {
    return std.fs.cwd().openFile(relative_path, .{});
}

fn readAllPackets(file: std.fs.File) !void {
    while (true) {
        const netpacket = try NetPacket.read(file);
        if (netpacket == null) {
            return;
        }
    }
}
