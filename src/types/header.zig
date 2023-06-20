const std = @import("std");

///
/// The struct present at the start of every demo file.
/// Credits to cancername on discord for writing the original iteration of
/// the ``validate`` function.
///
pub const Header = extern struct {
    magic: [8]u8 align(1), // "HL2DEMO\x00"
    demo_version: i32 align(1),
    network_version: i32 align(1),
    server_name: [260]u8 align(1),
    client_name: [260]u8 align(1),
    map_name: [260]u8 align(1),
    game_directory: [260]u8 align(1),
    demo_len_s: f32 align(1),
    ticks: i32 align(1),
    frames: i32 align(1),
    signon_length: i32 align(1),

    const ValidationError = error{ BadMagic, NegativeValue, InvalidFloat, NoTerminator };

    pub fn validate(dh: @This()) ValidationError!void {
        if (!std.mem.eql(u8, &dh.magic, "HL2DEMO\x00"))
            return error.BadMagic;

        for ([_]i32{
            dh.demo_version,
            dh.network_version,
            dh.ticks,
            dh.frames,
            dh.signon_length,
        }) |v| {
            if (v < 0) return error.NegativeValue;
        }

        if (dh.demo_len_s != dh.demo_len_s or dh.demo_len_s < 0 or std.math.isInf(dh.demo_len_s))
            return error.InvalidFloat;

        for ([_][]const u8{
            &dh.server_name,
            &dh.client_name,
            &dh.map_name,
        }) |v| {
            if (std.mem.indexOfScalar(u8, v, 0) == null)
                return error.NoTerminator;
        }
    }

    pub fn print(self: *const @This(), log_fn: *const fn (comptime []u8, anytype) void) void {
        log_fn(
            \\Magic: {s}
            \\Demo Protocol Version: {any}
            \\Network Protocol Version: {any}
            \\Server Name: {s}
            \\Client Name: {s}
            \\Map Name: {s}
            \\Game Directory: {s}
            \\Playback Time: {any}
            \\Ticks: {any}
            \\Frames: {any}
            \\Signon Length: {any}
            \\
        , .{
            self.*.magic,
            self.*.demo_version,
            self.*.network_version,
            self.*.server_name,
            self.*.client_name,
            self.*.map_name,
            self.*.game_directory,
            self.*.demo_len_s,
            self.*.ticks,
            self.*.frames,
            self.*.signon_length,
        });
    }
};
