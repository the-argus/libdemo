const std = @import("std");
const File = @import("io.zig").File;
const Header = @import("types/header.zig").Header;
const NetPacket = @import("net_packet.zig").NetPacket;

const log = std.log.scoped(.demoviewer);

test {
    try readDemo("tests/demos/shortdemo.dem");
}

/// Take a demo file and print it to stdout.
pub fn readDemo(relative_path: []const u8) !void {
    const demo_file = try openDemo(relative_path);
    const header = try demo_file.readObject(Header);
    try header.validate();
    header.print(&log.debug);
    try readAllPackets(demo_file);
}

/// open a relative path
fn openDemo(relative_path: []const u8) !File {
    log.debug("Opening {s} as demo", .{relative_path});
    return File.wrap(try std.fs.cwd().openFile(relative_path, .{}));
}

// read all packets in a loop until null is returned
fn readAllPackets(file: File) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    while (true) {
        const netpacket = try NetPacket.read(file, allocator);
        if (netpacket == null) {
            return;
        }
    }
}
