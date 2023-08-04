const std = @import("std");
const builtin = @import("builtin");
const NetworkBitBuffer = @import("../net_messages.zig").NetworkBitBuffer;
const State = @import("../state.zig");

reliable: bool,

tick: i16,
host_frame_time: f16,
host_frame_std_deviation: f16,
read: if (builtin.mode == .Debug) bool else void,

const NET_TICK_SCALEUP: f16 = 100000.0;

pub fn default() @This() {
    return .{
        .reliable = true,
        .tick = 0,
        .host_frame_time = 0,
        .host_frame_std_deviation = 0,
        .read = false,
    };
}

pub fn constructor(tick: i16, host_frame_time: f32, host_frame_std_deviation: f32) @This() {
    var result = default();
    result.tick = tick;
    result.host_frame_time = host_frame_time;
    result.host_frame_std_deviation = host_frame_std_deviation;

    return result;
}

pub fn readFromBuffer(self: *@This(), buf: *NetworkBitBuffer) !void {
    self.tick = @bitCast(i32, try buf.readBits(32));
    self.host_frame_time = @bitCast(f16, try buf.readBits(16)) / NET_TICK_SCALEUP;
    self.host_frame_std_deviation = @bitCast(f16, try buf.readBits(16)) / NET_TICK_SCALEUP;

    if (builtin.mode == .Debug) {
        self.read = true;
    }
}

pub fn process(self: *const @This(), state: *State) void {
    std.debug.assert(self.read);
    state.host_frame_std_deviation = self.host_frame_std_deviation;
    state.remote_frame_time = self.host_frame_time;

    // TODO: check out CBaseClient::UpdateAcknowledgedFramecount to see how this
    // actually should be implemented. involves client snapshots
    state.delta_tick = self.tick;
    if (self.tick > -1) {
        state.string_table_acknowledge_tick = self.tick;
        // CBaseClientState::ProcessTick
        state.string_tables.setTick(self.tick);
    }
}
