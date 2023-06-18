const std = @import("std");
const readRawData = @import("../io.zig").readRawData;
const readObject = @import("../io.zig").readObject;

pub const UserCommand = struct {
    outgoing_sequence: i32,
    command: []u8,
    pub fn free_with(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.command);
    }
    pub fn read(file: std.fs.File, allocator: std.mem.Allocator) !void {
        var cmd: @This() = undefined;
        cmd.outgoing_sequence = try readObject(file, i32);
        cmd.command = try readRawData(file, allocator);
        return cmd;
    }
};
