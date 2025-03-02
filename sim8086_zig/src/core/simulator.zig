const std = @import("std");

pub fn instruction_handler(instruction: []const u8, register_state: registers) !registers {
    _ = instruction;
    return try mov_handler("ax", "1", register_state);
}

pub fn mov_handler(source_val: []const u8, dest_val: []const u8, register_state: registers) !registers {
    var mut_reg_state = register_state;
    if (std.mem.eql(u8, source_val, "ax")) {
        const dest_int = try std.fmt.parseInt(u8, dest_val, 10);
        mut_reg_state.ax += dest_int;
    }

    return mut_reg_state;
}
pub fn print_register_state(register_state: registers) !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("-- REGISTERS --\n", .{});

    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "ax", register_state.ax, register_state.ax });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "al", register_state.al, register_state.al });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "ah", register_state.ah, register_state.ah });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "bx", register_state.bx, register_state.bx });
    try stdout.print("{s}: 0x{x} ({d})\n", .{ "bl", register_state.bl, register_state.bl });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "bh", register_state.bh, register_state.bh });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "cx", register_state.cx, register_state.cx });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "cl", register_state.cl, register_state.cl });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "ch", register_state.ch, register_state.ch });
    try stdout.print("{s}: 0x{x} ({d})\n", .{ "dx", register_state.dx, register_state.dx });
    try stdout.print("{s}: 0x{x} ({d}) - ", .{ "dl", register_state.dl, register_state.dl });
    try stdout.print("{s}: 0x{x} ({d})\r", .{ "dh", register_state.dh, register_state.dh });
}
// Would prefer unions / structs but Zig doesn't allow
pub const registers = struct {
    ax: u16 = 0,
    al: u8 = 0,
    ah: u8 = 0,

    bx: u16 = 0,
    bl: u8 = 0,
    bh: u8 = 0,

    cx: u16 = 0,
    cl: u8 = 0,
    ch: u8 = 0,

    dx: u16 = 0,
    dl: u8 = 0,
    dh: u8 = 0,

    sp: u16 = 0,
    bp: u16 = 0,
    si: u16 = 0,
    di: u16 = 0,
};
