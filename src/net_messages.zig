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
const netmsg = @import("net_types/definitions.zig");

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

// also see: CBaseClient::ConnectionStart and CBaseClientState::ConnectionStart
const subscribed_messages_client = &[_]netmsg.GenericMessage{
    .{ .type = .NET, .id = .{ .net_id = .TICK } },
    .{ .type = .NET, .id = .{ .net_id = .STRING_CMD } },
    .{ .type = .NET, .id = .{ .net_id = .SET_CONVAR } },
    .{ .type = .NET, .id = .{ .net_id = .SIGNON_STATE } },

    .{ .type = .CLC, .id = .{ .clc_id = .CLIENT_INFO } },
    .{ .type = .CLC, .id = .{ .clc_id = .MOVE } },
    .{ .type = .CLC, .id = .{ .clc_id = .VOICE_DATA } },
    .{ .type = .CLC, .id = .{ .clc_id = .BASELINE_ACKNOWLEDGE } },
    .{ .type = .CLC, .id = .{ .clc_id = .LISTEN_EVENTS } },
    .{ .type = .CLC, .id = .{ .clc_id = .GET_CVAR_VALUE_RESPONSE } },
    .{ .type = .CLC, .id = .{ .clc_id = .FILE_CRC_CHECK } },
    .{ .type = .CLC, .id = .{ .clc_id = .FILE_MD5_CHECK } },
    .{ .type = .CLC, .id = .{ .clc_id = .CMD_KEY_VALUES } },
};

const subscribed_messages_server = &[_]netmsg.GenericMessage{
    .{ .type = .NET, .id = .{ .net_id = .TICK } },
    .{ .type = .NET, .id = .{ .net_id = .STRING_CMD } },
    .{ .type = .NET, .id = .{ .net_id = .SET_CONVAR } },
    .{ .type = .NET, .id = .{ .net_id = .SIGNON_STATE } },

    .{ .type = .SVC, .id = .{ .svc_id = .PRINT } },
    .{ .type = .SVC, .id = .{ .svc_id = .SERVER_INFO } },
    .{ .type = .SVC, .id = .{ .svc_id = .SEND_TABLE } },
    .{ .type = .SVC, .id = .{ .svc_id = .CLASS_INFO } },
    .{ .type = .SVC, .id = .{ .svc_id = .SET_PAUSE } },
    .{ .type = .SVC, .id = .{ .svc_id = .CREATE_STRING_TABLE } },
    .{ .type = .SVC, .id = .{ .svc_id = .UPDATE_STRING_TABLE } },
    .{ .type = .SVC, .id = .{ .svc_id = .VOICE_INIT } },
    .{ .type = .SVC, .id = .{ .svc_id = .VOICE_DATA } },
    .{ .type = .SVC, .id = .{ .svc_id = .SOUNDS } },
    .{ .type = .SVC, .id = .{ .svc_id = .SET_VIEW } },
    .{ .type = .SVC, .id = .{ .svc_id = .FIX_ANGLE } },
    .{ .type = .SVC, .id = .{ .svc_id = .CROSSHAIR_ANGLE } },
    .{ .type = .SVC, .id = .{ .svc_id = .BSP_DECAL } },
    .{ .type = .SVC, .id = .{ .svc_id = .GAME_EVENT } },
    .{ .type = .SVC, .id = .{ .svc_id = .USER_MESSAGE } },
    .{ .type = .SVC, .id = .{ .svc_id = .ENTITY_MESSAGE } },
    .{ .type = .SVC, .id = .{ .svc_id = .PACKET_ENTITIES } },
    .{ .type = .SVC, .id = .{ .svc_id = .TEMP_ENTITIES } },
    .{ .type = .SVC, .id = .{ .svc_id = .PREFETCH } },
    .{ .type = .SVC, .id = .{ .svc_id = .MENU } },
    .{ .type = .SVC, .id = .{ .svc_id = .GAME_EVENT_LIST } },
    .{ .type = .SVC, .id = .{ .svc_id = .GET_CVAR_VALUE } },
    .{ .type = .SVC, .id = .{ .svc_id = .CMD_KEY_VALUES } },
    .{ .type = .SVC, .id = .{ .svc_id = .SET_PAUSE_TIMED } },
};

pub const NetworkBitBuffer = struct {
    reader: MemoryBitReader,
    stream: *std.io.FixedBufferStream([]const u8),
    raw_data: []const u8,
    needs_free: packed struct {
        stream: bool,
        raw_data: bool,
    },

    pub const ReadError = error{ OutputBufferTooSmall, Overflow, EndOfBuffer };
    pub const InputError = error{InvalidNetworkPacketType};

    fn wrapGeneric(
        allocator: std.mem.Allocator,
        raw: []const u8,
        comptime opt: struct { owns: bool },
    ) !@This() {
        var stream = try allocator.create(std.io.FixedBufferStream([]const u8));
        stream.* = std.io.fixedBufferStream(raw);
        var reader = MemoryBitReader.init(stream.*.reader());
        return .{
            .reader = reader,
            .stream = stream,
            .raw_data = raw,
            .needs_free = .{ .stream = true, .raw_data = opt.owns },
        };
    }

    pub fn wrap(allocator: std.mem.Allocator, raw: []const u8) !@This() {
        return wrapGeneric(allocator, raw, .{ .owns = false });
    }

    pub fn wrapOwning(allocator: std.mem.Allocator, raw: []const u8) !@This() {
        return wrapGeneric(allocator, raw, .{ .owns = true });
    }

    pub fn free_with(self: @This(), allocator: std.mem.Allocator) void {
        if (self.needs_free.stream) {
            _ = allocator.destroy(self.stream);
        }
        if (self.needs_free.raw_data) {
            _ = allocator.free(self.raw_data);
        }
    }

    pub fn processMessages(self: *@This()) !void {
        while (true) {
            const cmd = @intCast(netmsg.Type, self.readBits(netmsg.bits) catch |err| {
                if (err == ReadError.EndOfBuffer) {
                    return;
                }
                warnBitReaderError(err);
                return DemoError.Corruption;
            });

            // we are always interested in control code regardless of subscribed_messages
            if (netmsg.isControlMessage(cmd)) {
                const control_code = @intToEnum(netmsg.Control, cmd);
                log.debug("Network control message found: {any}", .{control_code});
                if (!try self.processControlMessage(control_code)) {
                    // disconnect
                    return;
                }
                // if no disconnect, try to read a netcode again
                continue;
            }

            const subscribed = netmsg.getSubscribed(cmd, subscribed_messages_server);
            const message = block: {
                if (subscribed) |msg| {
                    break :block msg;
                }
                std.log.err("Unknown/Unexpected net message with id {any}", .{cmd});
                return;
            };
            log.debug("Regular network message found: {any}", .{message});

            const err = "developer error. didn't deal with a network message type which was subscribed to";
            switch (message.type) {
                .CLC => {
                    switch (message.id.clc_id) {
                        else => {
                            @panic(err);
                        },
                    }
                },
                .NET => {
                    switch (message.id.net_id) {
                        .TICK => {},
                        .STRING_CMD => {},
                        .SET_CONVAR => {},
                        .SIGNON_STATE => {},
                        else => {
                            @panic(err);
                        },
                    }
                },
                .SVC => {
                    switch (message.id.svc_id) {
                        .PRINT => {},
                        .SERVER_INFO => {},
                        .SEND_TABLE => {},
                        .CLASS_INFO => {},
                        .SET_PAUSE => {},
                        .CREATE_STRING_TABLE => {},
                        .UPDATE_STRING_TABLE => {},
                        .VOICE_INIT => {},
                        .VOICE_DATA => {},
                        .SOUNDS => {},
                        .SET_VIEW => {},
                        .FIX_ANGLE => {},
                        .CROSSHAIR_ANGLE => {},
                        .BSP_DECAL => {},
                        .GAME_EVENT => {},
                        .USER_MESSAGE => {},
                        .ENTITY_MESSAGE => {},
                        .PACKET_ENTITIES => {},
                        .TEMP_ENTITIES => {},
                        .PREFETCH => {},
                        .MENU => {},
                        .GAME_EVENT_LIST => {},
                        .GET_CVAR_VALUE => {},
                        .CMD_KEY_VALUES => {},
                        .SET_PAUSE_TIMED => {},
                    }
                },
            }
        }
    }

    ///
    /// check "bool CNetChan::ProcessControlMessage(int cmd, bf_read &buf)"
    /// in net_chan.cpp. this this case, self is buf (or self.data)
    ///
    fn processControlMessage(self: *@This(), cmd: netmsg.Control) !bool {
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
                const transfer_id: u32 = self.readBits(32) catch |err| {
                    switch (err) {
                        ReadError.EndOfBuffer => {
                            log.warn("End of buffer reached when trying to read file. Ending control message read.", .{});
                            return false;
                        },
                        else => {
                            return err;
                        },
                    }
                };

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
        const slice = block: {
            var result: []const u8 = undefined;
            result.ptr = @ptrCast([*]const u8, data);
            result.len = @sizeOf(@TypeOf(data));
            break :block result;
        };
        return @This().wrap(allocator, slice);
    }

    pub fn readBits(self: *@This(), bits: usize) !u32 {
        var bits_read: usize = 0;
        const output = self.reader.readBits(u32, bits, &bits_read);
        if (bits_read < bits) {
            return ReadError.EndOfBuffer;
        }
        return output;
    }

    /// Reads a series of bytes until reaching a 0 byte. Sends them all to an
    /// output slice, and returns the used slice of the output.
    pub fn readStringInto(self: *@This(), out: []u8) ![]u8 {
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
        NetworkBitBuffer.ReadError.OutputBufferTooSmall => {
            log.warn("Output buffer too small, this is potentially a bug but probably corruption.", .{});
        },
        NetworkBitBuffer.ReadError.Overflow => {
            log.warn(
                \\NetworkBitBuffer Overflow error: attempt to read past the end of
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
test "NetworkBitBufferTest" {
    const ally = std.testing.allocator;
    const data: u32 = 0b10101010100011111;
    var bitbuf = try NetworkBitBuffer.wrapU32AsBytes(ally, &data);
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
    bitbuf.free_with(ally);
}

test "NetworkBitBufferTestSixes" {
    const ally = std.testing.allocator;
    // this is 135 2 in bytes
    const data: u32 = 0b1000011100000010;
    var bitbuf = try NetworkBitBuffer.wrapU32AsBytes(ally, &data);
    const first_6_bits = try bitbuf.readBits(6);
    try std.testing.expectEqual(@intCast(u32, 0b000010), first_6_bits);
    const next_6_bits = try bitbuf.readBits(6);
    try std.testing.expectEqual(@intCast(u32, 0b011100), next_6_bits);
    bitbuf.free_with(ally);
}
