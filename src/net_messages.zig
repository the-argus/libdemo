///
/// For reading the raw data that is present in NetPackets. Implementation taken
/// from bool CNetChan::ProcessMessages( bf_read &buf  ) in engine/net_chan.cpp
/// in the tf2 source code
///
const std = @import("std");
const builtin = @import("builtin");
const DemoError = @import("error.zig").DemoError;
const log = std.log.scoped(.libdemo);
const io = @import("io.zig");
const netmsg = @import("net_types/definitions.zig").Messages;

const FixedBufferStreamReader = std.io.Reader(
    *std.io.FixedBufferStream([]const u8),
    std.io.FixedBufferStream([]const u8).ReadError,
    std.io.FixedBufferStream([]const u8).read,
);
const MemoryBitReader = std.io.BitReader(
    // NOTE: always use host endian, may be better to always assume
    // TF2 files are in little endian
    builtin.cpu.arch.endian(),
    FixedBufferStreamReader,
);

pub const SimpleBuffer = struct {
    reader: MemoryBitReader,
    stream: *std.io.FixedBufferStream([]const u8),
    raw_data: []const u8,

    pub fn wrap(allocator: std.mem.Allocator, raw: []const u8) !@This() {
        var stream = try allocator.create(std.io.FixedBufferStream([]const u8));
        stream.* = std.io.fixedBufferStream(raw);
        var reader = MemoryBitReader.init(stream.*.reader());
        return .{
            .reader = reader,
            .stream = stream,
            .raw_data = raw,
        };
    }

    pub fn free_with(self: @This(), allocator: std.mem.Allocator) void {
        _ = allocator.destroy(self.stream);
        _ = allocator.free(self.raw_data);
    }

    pub fn processMessages(self: *@This()) !void {
        while (true) {
            const cmd = @intCast(netmsg.Type, self.readBits(netmsg.bits) catch |err| {
                warnBitReaderError(err);
                return DemoError.Corruption;
            });

            const netcode = @intToEnum(netmsg.all, cmd);

            if (!netcode.isControlMessage()) {
                log.debug("Regular network message found: {any}", .{netcode});
                self.processRegularMessage(cmd);
                return;
            }
            const control_code = @intToEnum(netmsg.control, @enumToInt(netcode));
            log.debug("Network control message found: {any}", .{control_code});

            if (!try self.processControlMessage(control_code)) {
                // disconnect
                return;
            }
            // if no disconnect, try to read a netcode again (continue)
        }
    }

    // as opposed to a control message (file, disconnect, noop)
    fn processRegularMessage(self: *@This(), cmd: netmsg.Type) void {
        _ = cmd;
        _ = self;
    }

    ///
    /// check "bool CNetChan::ProcessControlMessage(int cmd, bf_read &buf)"
    /// in net_chan.cpp. this this case, self is buf (or self.data)
    ///
    fn processControlMessage(self: *@This(), cmd: netmsg.control) !bool {
        switch (cmd) {
            .NOP => {
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
                    warnBitReaderError(err);
                    return DemoError.Corruption;
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
    }

    fn wrapU32AsBytes(allocator: std.mem.Allocator, data: *const u32) !@This() {
        var slice = block: {
            var result: []const u8 = undefined;
            result.ptr = @ptrCast([*]const u8, data);
            result.len = @sizeOf(@TypeOf(data));
            break :block result;
        };
        return @This().wrap(allocator, slice);
    }

    pub const ReadError = error{ OutputBufferTooSmall, Overflow, EndOfBuffer };

    pub fn readBits(self: *@This(), bits: usize) !u32 {
        var bits_read: usize = 0;
        const output = self.reader.readBits(u32, bits, &bits_read);
        if (bits_read == 0) {
            return ReadError.EndOfBuffer;
        }
        return output;
    }

    /// Reads a series of bytes until reaching a 0 byte. Sends them all to an
    /// output slice, and returns the used slice of the output.
    fn readStringInto(self: *@This(), out: []u8) ![]u8 {
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

/// Prints a bit reader error to warn
fn warnBitReaderError(bit_reader_error: anyerror) void {
    switch (bit_reader_error) {
        SimpleBuffer.ReadError.OutputBufferTooSmall => {
            log.warn("Output buffer too small, this is potentially a bug but probably corruption.", .{});
        },
        SimpleBuffer.ReadError.Overflow => {
            log.warn(
                \\SimpleBuffer Overflow error: attempt to read past the end of
                \\the buffer. Usually caused by a string that isn't properly
                \\null terminated (e.g. bad/corrupted data)
            , .{});
        },
        else => {
            // otherwise its not an error from simplebuffer and instead it is internal
            log.warn("Internal BitReader error: {any}", .{bit_reader_error});
        },
    }
}

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

// TODO: maybe remove these tests
//
// These are tests originally written for my own implementation of bit reader before
// I realized there was a stdlib implementation. Doesn't hurt to assert that the
// stdlib one works the way I expect.
//
test "SimpleBitBufferTest" {
    const data: u32 = 0b10101010100011111;
    var bitbuf = try SimpleBuffer.wrapU32AsBytes(std.testing.allocator, &data);
    const expected_first_byte = @intCast(u32, 0b00011111);
    std.debug.print("\nFirst byte of bitbuf is 0b{b} and expected is 0b{b}\n", .{ bitbuf.raw_data[0], expected_first_byte });
    try std.testing.expectEqual(expected_first_byte, bitbuf.raw_data[0]);
    const first_3_bits = try bitbuf.readBits(3);
    try std.testing.expectEqual(@intCast(u32, 0b0111), first_3_bits);
    const next_4_bits = try bitbuf.readBits(4);
    try std.testing.expectEqual(@intCast(u32, 0b0011), next_4_bits);
    const next_byte = try bitbuf.readBits(8);
    try std.testing.expectEqual(@intCast(u32, 0b10101010), next_byte);
    const last_two_bits = try bitbuf.readBits(2);
    try std.testing.expectEqual(@intCast(u32, 0b10), last_two_bits);
}

test "BitBufferTestSixes" {
    // this is 135 2 in bytes
    const data: u32 = 0b1000011100000010;
    var bitbuf = try SimpleBuffer.wrapU32AsBytes(std.testing.allocator, &data);
    const first_6_bits = try bitbuf.readBits(6);
    try std.testing.expectEqual(@intCast(u32, 0b000010), first_6_bits);
    const next_6_bits = try bitbuf.readBits(6);
    try std.testing.expectEqual(@intCast(u32, 0b011100), next_6_bits);
}
