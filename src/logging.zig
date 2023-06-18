///
/// Logging function, includes formatting for log messages and settings for min
/// log level. Ripped straight from the zig stdlib documentation.
///
const std = @import("std");

pub fn libdemo_logger(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    // custom text as opposed to doing level.asText()
    const leveltext = switch (level) {
        .warn => "WARN",
        .err => "FATAL",
        .info => "INFO",
        .debug => "DEBUG",
    };

    const scope_prefix = if (scope == .libdemo) "" else ("<" ++ @tagName(scope) ++ ">");
    const prefix = "[" ++ leveltext ++ "] " ++ scope_prefix;

    // Print the message to stderr, silently ignoring any errors
    std.debug.getStderrMutex().lock();
    defer std.debug.getStderrMutex().unlock();
    const stderr = std.io.getStdErr().writer();
    nosuspend stderr.print(prefix ++ format ++ "\n", args) catch return;
}
