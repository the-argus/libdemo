pub const demo_messages = enum(u8) {
    // it's a startup message, process as fast as possible
    dem_signon = 1,
    // it's a normal network packet that we stored off
    dem_packet,
    // sync client clock to demo tick
    dem_synctick,
    // console command
    dem_consolecmd,
    // user input command
    dem_usercmd,
    // network data tables
    dem_datatables,
    // end of time.
    dem_stop,
    dem_stringtables,
    // Last command
    // dem_lastcmd = 8,
};
