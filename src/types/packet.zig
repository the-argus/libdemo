const std = @import("std");

pub const Packet = extern struct {
    pub fn print(self: *@This(), log_fn: *const fn (comptime []u8, anytype) void) void {
        log_fn(
            \\Found packet:
            \\  cmd_type: {any}
            \\  unknown: {any}
            \\  tickcount: {any}
            \\  size_of_packet: {any}
            \\  buffer pointer: {any}
            \\
        , .{
            self.*.cmd_type,
            self.*.unknown,
            self.*.tickcount,
            self.*.size_of_packet,
            self.*.buffer,
        });
    }
};
