pub const Vector = extern struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn print(
        self: @This(),
        label: []const u8,
        log_fn: *const fn (comptime []u8, anytype) void,
    ) void {
        log_fn("{s}X: {}\tY: {}\tZ: {}", .{ label, self.x, self.y, self.z });
    }
};
pub const Angle = Vector;
