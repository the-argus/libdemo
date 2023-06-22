///
/// For reading the raw data that is present in NetPackets. Implementation taken
/// from bool CNetChan::ProcessMessages( bf_read &buf  ) in engine/net_chan.cpp
/// in the tf2 source code
///
const std = @import("std");
const err = @import("error.zig").DemoError;

pub const netcodes = enum(i32) {
    NOOP = 0,
    DISCONNECT = 1,
    FILE = 2,
};

///
/// check "bool CNetChan::ProcessControlMessage(int cmd, bf_read &buf)"
/// in net_chan.cpp
///
fn processControlMessage(cmd: i32, buf: []u8) !bool {
    _ = buf;
    switch (@intToEnum(netcodes, cmd)) {
        .NOOP => {
            return true;
        },
        .DISCONNECT => {
            // TODO: there is a string that can be read describing the reason
            // for disconnect here
            return false;
        },
        .FILE => {
            // TODO: read the file requested
            return true;
        },
    }
    return err.BadNetworkControlCommand;
}
