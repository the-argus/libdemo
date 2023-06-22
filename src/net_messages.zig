///
/// For reading the raw data that is present in NetPackets. Implementation taken
/// from bool CNetChan::ProcessMessages( bf_read &buf  ) in engine/net_chan.cpp
/// in the tf2 source code
///
const std = @import("std");
const DemoError = @import("error.zig").DemoError;
const log = std.log.scoped(.libdemo);

const NETMSG_TYPE_BITS = 6; // bits in a network message

const netcodes = enum(i32) {
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
    return DemoError.BadNetworkControlCommand;
}

pub const SimpleBuffer = struct {
    data: []u8,
    head: u32,

    pub fn processMessages(self: @This()) void {
        while (true) {
            _ = self.readBits(NETMSG_TYPE_BITS) catch |err| {
                switch (err) {
                    ReadError.Overflow => {
                        log.err("processMessage overflow", .{});
                        return;
                    },
                }
            };
        }
    }

    const ReadError = error{Overflow};

    fn readBits(self: @This(), bits: u8) ReadError!u32 {
        std.debug.assert(bits <= 32);
        if (self.getRemainingBits() < bits) {
            return ReadError.Overflow;
        }

        // get an array of bytes which include all the bits we want to return
        const bytes = std.math.ceil(bits / 8);
        const selection = block: {
            const head_slice = self.slice();
            if (bytes > head_slice.len) {
                return ReadError.Overflow;
            }
            break :block head_slice[0..bytes];
        };
        _ = selection;
    }

    /// Returns a slice of the array from the byte the head is in until data end
    fn slice(self: @This()) []u8 {
        const byte = std.math.floor(self.head / 8);
        return self.data[byte..];
    }

    fn getRemainingBits(self: @This()) u32 {
        return self.data.len - self.head;
    }

    fn moveHeadBy(self: @This(), increment: u32) void {
        std.debug.assert(self.head + increment < self.data.len);
        self.head += increment;
    }
};

// little-endian stuff
// TODO: move this somewhere more appropriate and look at stdlib alternatives
// TODO: write tests for bit stuff

/// Stupid bad function just inline it. its here so I remember what
/// LoadLittleDWord in the tf2 source code.
fn loadLittleDWord(base: [*]u32, dword_index: u32) u64 {
    return littleDWord(base[dword_index]);
}

fn littleDWord(val: u32) u32 {
    const temp: i32 = 1;
    if (*@ptrCast(*u8, &temp) == 1) {
        return val;
    } else {
        return dWordSwap(val);
    }
}

fn dWordSwap(val: anytype) @TypeOf(val) {
    switch (@TypeOf(val)) {
        u32 => {},
        else => {
            @compileError("Invalid type for dWordSwap");
        },
    }
    const temp: u32 = undefined;

    temp = *(@ptrCast(*u32, &val)) >> 24;
    temp |= ((*(@ptrCast(*u32, &val)) & 0x00FF0000) >> 8);
    temp |= ((*(@ptrCast(*u32, &val)) & 0x0000FF00) << 8);
    temp |= ((*(@ptrCast(*u32, &val)) & 0x000000FF) << 24);

    return *@ptrCast(*@TypeOf(val), &temp);
}
