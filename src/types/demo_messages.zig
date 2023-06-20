pub const demo_messages = enum(u8) {
    // it's a startup message, process as fast as possible
    dem_signon = 1,
    // it's a normal network packet that we stored off
    dem_packet = 2,
    // sync client clock to demo tick
    dem_synctick = 3,
    // console command
    dem_consolecmd = 4,
    // user input command
    dem_usercmd = 5,
    // network data tables
    dem_datatables = 6,
    // end of time.
    dem_stop = 7,
    dem_stringtables = 8,
    // Last command
    // dem_lastcmd = 8,
};
