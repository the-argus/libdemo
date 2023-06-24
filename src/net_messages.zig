///
/// For reading the raw data that is present in NetPackets. Implementation taken
/// from bool CNetChan::ProcessMessages( bf_read &buf  ) in engine/net_chan.cpp
/// in the tf2 source code
///
const std = @import("std");
const DemoError = @import("error.zig").DemoError;
const log = std.log.scoped(.libdemo);

const NETMSG_TYPE_BITS = 6; // bits in a network message
const NETMSG_TYPE = u6; // should be the same bits as above

const netcodes = enum(NETMSG_TYPE) {
    NOOP = 0,
    DISCONNECT = 1,
    FILE = 2,
};

pub const SimpleBuffer = struct {
    data: []const u8,
    head: u32,

    pub fn wrap(raw: []const u8) @This() {
        return .{
            .data = raw,
            .head = 0,
        };
    }

    pub fn processMessages(self: *@This()) !void {
        while (true) {
            const cmd = @intCast(NETMSG_TYPE, self.readBits(NETMSG_TYPE_BITS) catch |err| {
                switch (err) {
                    ReadError.Overflow => {
                        log.err("processMessage overflow, likely corruption.", .{});
                        return DemoError.Corruption;
                    },
                    else => {
                        log.err("processMessage error: {any}", .{err});
                        return err;
                    },
                }
            });

            const netcode = std.meta.intToEnum(netcodes, cmd) catch {
                self.processRegularMessage(cmd);
                return;
            };

            const should_continue = try self.processControlMessage(netcode);
            if (!should_continue) {
                // disconnect
                return;
            }
            // if no disconnect, try to read a netcode again (continue)
        }
    }

    // as opposed to a control message (file, disconnect, noop)
    fn processRegularMessage(self: *@This(), cmd: NETMSG_TYPE) void {
        _ = cmd;
        _ = self;
    }

    ///
    /// check "bool CNetChan::ProcessControlMessage(int cmd, bf_read &buf)"
    /// in net_chan.cpp. this this case, self is buf (or self.data)
    ///
    fn processControlMessage(self: *@This(), cmd: netcodes) !bool {
        switch (cmd) {
            .NOOP => {
                return true;
            },
            .DISCONNECT => {
                // TODO: there is a string that can be read describing the reason
                // for disconnect here
                return false;
            },
            .FILE => {
                var string_buffer: [1024]u8 = undefined;
                const transfer_id: u32 = try self.readBits(32);

                const string_slice = self.readStringInto(&string_buffer) catch |err| {
                    if (err == ReadError.OutputBufferTooSmall) {
                        log.err("The output buffer of size {any} is too small for the FILE control message. Assuming that the file is corrupted as there is no reason the file path should be that big.", .{string_buffer.len});
                        return DemoError.Corruption;
                    }
                    return err;
                };

                // original tf2 source has a bunch of checks to ensure the
                // filename is valid.
                if (try self.readBits(1) != 0) {
                    // TODO: the string slice contains the requested filename
                    _ = string_slice;
                    _ = transfer_id;
                }

                return true;
            },
        }
        return DemoError.BadNetworkControlCommand;
    }

    const ReadError = error{ Overflow, OutputBufferTooSmall };

    fn readBits(self: *@This(), bits: u8) ReadError!u32 {
        log.debug("readBits called. Head pointer at {any} and {any} bits requested.", .{ self.head, bits });
        log.debug("First 2 bytes of data:", .{});
        for (0..2) |index| {
            log.debug("{any}", .{self.data[index]});
        }
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
        const head_bit_from_byte_offset = @intCast(u8, self.head - local_head);
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

    fn wrapU32AsBytes(data: *const u32) SimpleBuffer {
        return .{
            .data = block: {
                var result: []const u8 = undefined;
                result.ptr = @ptrCast([*]const u8, &data);
                result.len = @sizeOf(@TypeOf(data));
                break :block result;
            },
            .head = 0,
        };
    }

    fn getRemainingBits(self: @This()) u32 {
        return @intCast(u32, (self.data.len * 8) - self.head);
    }

    fn moveHeadBy(self: *@This(), increment: u32) void {
        std.debug.assert(std.math.ceil(@intToFloat(f32, self.head + increment) / 8) < @intToFloat(f32, self.data.len));
        self.head += increment;
    }

    /// Reads a series of bytes until reaching a 0 byte. Sends them all to an
    /// output slice, and returns the used slice of the output.
    fn readStringInto(self: *@This(), out: []u8) ReadError![]u8 {
        var output_slice = out;
        output_slice.len = 0; // start at 0, increment as we read
        var terminated = false;
        for (out, 0..) |_, index| {
            // FIXME: may panic on invalid char, would be better with "try"
            const char = @intCast(u8, try self.readChar());

            if (char == 0) {
                terminated = true;
                break;
            }

            out[index] = char;
            output_slice.len += 1;
        }
        if (!terminated) {
            return ReadError.OutputBufferTooSmall;
        }

        return output_slice;
    }

    fn readChar(self: *@This()) !u8 {
        // FIXME: may panic on invalid char, would be better with "try"
        return @intCast(u8, try self.readBits(8));
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
    var bitbuf = SimpleBuffer.wrapU32AsBytes(&data);
    const first_3_bits = bitbuf.readBits(3);
    const next_4_bits = bitbuf.readBits(4);
    const next_byte = bitbuf.readBits(8);
    const last_two_bits = bitbuf.readBits(2);
    try std.testing.expectEqual(first_3_bits, @intCast(u32, 0b0111));
    try std.testing.expectEqual(next_4_bits, @intCast(u32, 0b0011));
    try std.testing.expectEqual(next_byte, @intCast(u32, 0b10101010));
    try std.testing.expectEqual(last_two_bits, @intCast(u32, 0b10));
}

test "IntegerOverflow" {
    // this is 135 2 in bytes
    const data: u32 = 0b1000011100000010;
    var bitbuf = SimpleBuffer.wrapU32AsBytes(&data);
    const first_6_bits = bitbuf.readBits(6);
    const next_6_bits = bitbuf.readBits(6);
    try std.testing.expectEqual(first_6_bits, @intCast(u32, 0b000010));
    try std.testing.expectEqual(next_6_bits, @intCast(u32, 0b011100));
}
