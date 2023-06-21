const std = @import("std");
const File = @import("../io.zig").File;

pub const UserCommand = struct {
    outgoing_sequence: i32,
    command: []u8,
    pub fn free_with(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.command);
    }
    pub fn read(file: File, allocator: std.mem.Allocator) !@This() {
        var cmd: @This() = undefined;
        cmd.outgoing_sequence = try file.readObject(i32);
        cmd.command = try file.readRawData(allocator);
        return cmd;
    }
};
