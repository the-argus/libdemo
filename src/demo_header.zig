const std = @import("std");

///
/// The struct present at the start of every demo file.
/// Credits to cancername on discord for writing the original iteration of
/// the ``validate`` function.
///
pub const ExternDemoHeader = extern struct {
    magic: [8]u8 align(1), // "HL2DEMO\x00"
    demo_version: i32 align(1),
    network_version: i32 align(1),
    server_name: [260]u8 align(1),
    client_name: [260]u8 align(1),
    map_name: [260]u8 align(1),
    demo_len_s: f32 align(1),
    nb_ticks: i32 align(1),
    nb_frames: i32 align(1),
    sign_on_len: i32 align(1),

    const ValidationError = error{ BadMagic, NegativeValue, InvalidFloat, NoTerminator };

    pub fn validate(dh: @This()) ValidationError!void {
        if (!std.mem.eql(u8, &dh.magic, "HL2DEMO\x00"))
            return error.BadMagic;

        for ([_]i32{
            dh.demo_version,
            dh.network_version,
            dh.nb_ticks,
            dh.nb_frames,
            dh.sign_on_len,
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
};
