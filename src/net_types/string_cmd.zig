const std = @import("std");
const builtin = @import("builtin");
const NetworkBitBuffer = @import("../net_messages.zig").NetworkBitBuffer;
const State = @import("../state.zig");

read: if (builtin.mode == .Debug) bool else void,
command_buffer: @import("../configuration.zig").StringCommand,
string_slice: []u8,

pub fn default() @This() {
    return .{
        .read = false,
        .command_buffer = undefined,
    };
}

pub fn readFromBuffer(self: *@This(), buf: *NetworkBitBuffer) !void {
    self.string_slice = try buf.readStringInto(&self.command_buffer);

    if (builtin.mode == .Debug) {
        self.read = true;
    }
}

pub fn process(self: *const @This(), state: *State) void {
    std.debug.assert(self.read);
    if (self.string_slice.len == 0) {
        return;
    }
    state.enqueue_command(self.string_slice);
}
