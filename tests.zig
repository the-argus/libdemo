const std = @import("std");
const testing = std.testing;
const errors = @import("src/error.zig").DemoError;
const print = std.debug.print();

const readDemo = @import("src/read_dem.zig").readDemo;

test "normal-demo" {
    try readDemo("tests/demos/shortdemo.dem");
}

test "truncated-demo" {
    try testing.expectError(errors.EarlyTermination, readDemo("tests/demos/truncated.dem"));
}
