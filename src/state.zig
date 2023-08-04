///
/// an object which stores all variables which accumulate or have values
/// relevent to how further network packets should be interpreted
///
const std = @import("std");
const StringCommand = @import("configuration.zig").StringCommand;

pub fn init(ally: std.mem.Allocator) @This() {
    return .{
        .remote_frame_time = 0,
        .host_frame_std_deviation = 0,
        .delta_tick = 0,
        .string_table_acknowledge_tick = 0,
        .string_tables = .{
            .tick = 0,
        },
        .string_command_queue = std.ArrayList(StringCommand).init(ally),
    };
}

// TICK ---------------------------------------------------
remote_frame_time: f16,
host_frame_std_deviation: f16,

delta_tick: i16,
string_table_acknowledge_tick: i16,

// STRING CMD ---------------------------------------------

string_tables: *struct {
    tick: i16,

    pub fn setTick(self: *@This(), tick: i16) void {
        self.tick = tick;
    }
    // TABLEID					m_id;
    // char					*m_pszTableName;
    // // Must be a power of 2, so encoding can determine # of bits to use based on log2
    // int						m_nMaxEntries;
    // int						m_nEntryBits;
    // int						m_nTickCount;
    // int						m_nLastChangedTick;

    // bool					m_bChangeHistoryEnabled : 1;
    // bool					m_bLocked : 1;
    // bool					m_bAllowClientSideAddString : 1;
    // bool					m_bUserDataFixedSize : 1;
    // bool					m_bIsFilenames : 1;

    // int						m_nUserDataSize;
    // int						m_nUserDataSizeBits;

    // // Change function callback
    // pfnStringChanged		m_changeFunc;
    // // Optional context/object
    // void					*m_pObject;

    // // pointer to local backdoor table
    // INetworkStringTable		*m_pMirrorTable;

    // INetworkStringDict		*m_pItems;
    // INetworkStringDict		*m_pItemsClientSide;	 // For m_bAllowClientSideAddString, these items are non-networked and are referenced by a negative string index!!!
},

string_command_queue: std.ArrayList(StringCommand),
// COMVAR (console variables) ----------------------------------
convars: std.HashMap([]u8, []u8),

// STRING CMD ---------------------------------------------

pub fn enqueue_command(self: *@This(), cmd: *StringCommand) !void {
    // TODO: Cbuf_Execute needs to be called to dequeue these commands. they may
    // alter the gamestate
    const allocated_cmd = try self.string_command_queue.addOne();
    @memcpy(allocated_cmd, cmd);
}

// COMVAR (console variables) ----------------------------------
