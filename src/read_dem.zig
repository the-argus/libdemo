const std = @import("std");
const readObject = @import("io.zig").readObject;
const Header = @import("types/header.zig").Header;
const NetPacket = @import("net_packet.zig").NetPacket;

const log = std.log.scoped(.demoviewer);

test {
    try readDemo("tests/demos/shortdemo.dem");
}

/// Take a demo file and print it to stdout.
pub fn readDemo(relative_path: []const u8) !void {
    const demo_file = try openDemo(relative_path);
    const header = try readObject(demo_file, Header);
    try header.validate();
    header.print(&log.debug);
    try readAllPackets(demo_file);
}

/// open a relative path
fn openDemo(relative_path: []const u8) !std.fs.File {
    return std.fs.cwd().openFile(relative_path, .{});
}

// read all packets in a loop until null is returned
fn readAllPackets(file: std.fs.File) !void {
    while (true) {
        const netpacket = try NetPacket.read(file);
        if (netpacket == null) {
            return;
        }
    }
}
