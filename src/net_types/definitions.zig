pub const Messages = struct {
    pub const bits = 6; // bits in a network message
    pub const Type = u6; // should be the same bits as above

    pub const MessageTypes = enum {
        NET,
        SVC,
        CLC,
    };

    pub fn getType(message: Messages.all) MessageTypes {
        const num = @enumToInt(message);
        if (num <= 6) {
            return .NET;
        } else if (num <= 33) {
            return .SVC;
        }
        return .CLC;
    }

    /// duplicate of the first three elements of all netmsg types.
    pub const control = enum(Messages.Type) {
        NOP = 0,
        DISCONNECT = 1,
        FILE = 2,
    };

    pub const all = enum(Messages.Type) {
        /// check whether a message is NOP, DISCONNECT, or FILE
        pub inline fn isControlMessage(self: Messages.all) bool {
            return @enumToInt(self) < 2;
        }
        // NET
        NOP = 0,
        DISCONNECT = 1,
        FILE = 2,
        TICK = 3,
        STRING_CMD = 4,
        SET_CONVAR = 5,
        SIGNON_STATE = 6,
        // SVC
        PRINT = 7, // print text to console
        SERVER_INFO = 8, // first message from server about game, map etc
        SEND_TABLE = 9, // sends a sendtable description for a game class
        CLASS_INFO = 10, // Info about classes (first byte is a CLASSINFO_ define)
        SET_PAUSE = 11, // tells client if server paused or unpaused
        CREATE_STRING_TABLE = 12, // inits shared string tables
        UPDATE_STRING_TABLE = 13, // updates a string table
        VOICE_INIT = 14, // inits used voice codecs & quality
        VOICE_DATA = 15, // Voicestream data from the server
        // 16 is unused
        SOUNDS = 17, // starts playing sound
        SET_VIEW = 18, // sets entity as point of view
        FIX_ANGLE = 19, // sets/corrects players viewangle
        CROSSHAIR_ANGLE = 20, // adjusts crosshair in auto aim mode to lock on traget
        BSP_DECAL = 21, // add a static decal to the worl BSP
        // 22 unused
        USER_MESSAGE = 23, // a game specific message
        ENTITY_MESSAGE = 24, // a message for an entity
        GAME_EVENT = 25, // global game event fired
        PACKET_ENTITIES = 26, // non-delta compressed entities
        TEMP_ENTITIES = 27, // non-reliable event object
        PREFETCH = 28, // only sound indices for now
        MENU = 29, // display a menu from a plugin
        GAME_EVENT_LIST = 30, // list of known games events and fields
        GET_CVAR_VALUE = 31, // Server wants to know the value of a cvar on the client
        CMD_KEYVALUES = 32, // Server submits KeyValues command for the client
        SET_PAUSE_TIMED = 33, // Timed pause - to avoid breaking demos
    };

    // potentially unused
    pub const clc = enum(u8) {
        CLIENT_INFO = 8,
        MOVE = 9,
        VOICE_DATA = 10,
        BASELINE_ACKNOWLEDGE = 11, // client acknowledges a new baseline seqnr
        LISTEN_EVENTS,
        GET_CVAR_VALUE_RESPONSE = 13,
        FILE_CRC_CHECK = 14,
        SAVE_REPLAY = 15,
        CMD_KEY_VALUES = 16,
        FILE_MD5_CHECK,
    };
};
