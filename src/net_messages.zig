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
    data: []const u8,
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

    fn readBits(self: *@This(), bits: u8) ReadError!u32 {
        std.debug.assert(bits <= 32);
        if (self.getRemainingBits() < bits) {
            return ReadError.Overflow;
        }

        // get an array of bytes which include all the bits we want to return
        const bytes: usize = @floatToInt(usize, std.math.ceil(@intToFloat(f32, bits) / 8.0));
        const byte_containing_head = @floatToInt(usize, std.math.floor(@intToFloat(f32, self.head) / 8));
        const selection = block: {
            const head_slice = self.data[byte_containing_head..];
            if (bytes > head_slice.len) {
                return ReadError.Overflow;
            }
            break :block head_slice[0..bytes];
        };

        // the output where we will store the read bits
        var result: u32 = 0;

        // the head pointer but it's been shifted back to the beginning of its byte
        var local_head = byte_containing_head;
        const head_bit_from_byte_offset = @intCast(u8, local_head - self.head);
        for (selection, 0..) |byte, byteindex| {
            // loop through all the bits in this byte
            for ([_]u8{ 0, 1, 2, 3, 4, 5, 6, 7 }) |bitindex| {
                // skip the bit if its before the read head
                // FIXME: this is prone to off-by-one errors and defeats the
                // purpose of range-based for loops
                if (local_head < self.head or local_head >= self.head + bits) {
                    local_head += 1;
                    continue;
                }

                // otherwise mask out this bit and apply it to the result
                const mask: u8 = @intCast(u8, @intCast(u8, 1) << @intCast(u3, bitindex));
                const bit_in_byte: u8 = mask & byte;
                // could quit here if bit_in_byte is zero...
                const bit_in_long: u32 = bit_in_byte << @intCast(u3, ((byteindex * 8) - head_bit_from_byte_offset));
                result &= bit_in_long;

                local_head += 1;
            }
        }

        self.moveHeadBy(bits);
        return result;
    }

    fn getRemainingBits(self: @This()) u32 {
        return @intCast(u32, (self.data.len * 8) - self.head);
    }

    fn moveHeadBy(self: *@This(), increment: u32) void {
        std.debug.assert(std.math.ceil(@intToFloat(f32, self.head + increment) / 8) < @intToFloat(f32, self.data.len));
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

test "SimpleBufferBitTest" {
    const data: u32 = 0b10101010100011111;
    var bitbuf: SimpleBuffer = .{
        .data = block: {
            var result: []const u8 = undefined;
            result.ptr = @ptrCast([*]const u8, &data);
            result.len = @sizeOf(u32);
            break :block result;
        },
        .head = 0,
    };
    const first_3_bits = bitbuf.readBits(3);
    const next_4_bits = bitbuf.readBits(4);
    const next_byte = bitbuf.readBits(8);
    const last_two_bits = bitbuf.readBits(2);
    try std.testing.expectEqual(first_3_bits, @intCast(u32, 0b0111));
    try std.testing.expectEqual(next_4_bits, @intCast(u32, 0b0011));
    try std.testing.expectEqual(next_byte, @intCast(u32, 0b10101010));
    try std.testing.expectEqual(last_two_bits, @intCast(u32, 0b10));
}
