const std = @import("std");
const File = @import("io.zig").File;
const Header = @import("types/header.zig").Header;
const NetPacket = @import("net_packet.zig").NetPacket;

const log = std.log.scoped(.libdemo);

test {
    try readDemo("tests/demos/shortdemo.dem");
}

/// Take a demo file path and print the file's contents to stdout.
pub fn readDemo(relative_path: []const u8) !void {
    const demo_file = try openDemo(relative_path);
    try readAndValidateHeader(demo_file);
    try readAllPackets(demo_file);
}

/// open a relative path as a demo file
pub fn openDemo(relative_path: []const u8) !File {
    log.debug("Opening {s} as demo", .{relative_path});
    return File.wrap(try std.fs.cwd().openFile(relative_path, .{}));
}

// begin reading a demo file by consuming the header and making sure it's good
pub fn readAndValidateHeader(file: File) !void {
    const header = try file.readObject(Header);
    try header.validate();
    header.print(&log.debug);
}

// read all packets from a file in a loop until null is returned
pub fn readAllPackets(file: File) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    while (true) {
        const netpacket = try NetPacket.read(file, allocator);
        if (netpacket == null) {
            return;
        }
        netpacket.free_with(allocator);
    }
}
