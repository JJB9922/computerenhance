const std = @import("std");
const i = @import("instruction_set.zig");
const ph = @import("parsing_helpers.zig");

pub const registers = struct {
    al: u8 = 0,
    cl: u8 = 0,
    dl: u8 = 0,
    bl: u8 = 0,
    ah: u8 = 0,
    ch: u8 = 0,
    dh: u8 = 0,
    bh: u8 = 0,

    ax: u8 = 0,
    cx: u8 = 0,
    dx: u8 = 0,
    bx: u8 = 0,
    sp: u8 = 0,
    bp: u8 = 0,
    si: u8 = 0,
    di: u8 = 0,
};

pub fn print_registers(rs: registers) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("AL: {d}, CL: {d}, DL: {d}, BL: {d}\n", .{ rs.al, rs.cl, rs.dl, rs.bl });
    try stdout.print("AH: {d}, CH: {d}, DH: {d}, BH: {d}\n", .{ rs.ah, rs.ch, rs.dh, rs.bh });
    try stdout.print("AX: {d}, CX: {d}, DX: {d}, BX: {d}\n", .{ rs.ax, rs.cx, rs.dx, rs.bx });
    try stdout.print("SP: {d}, BP: {d}, SI: {d}, DI: {d}\n", .{ rs.sp, rs.bp, rs.si, rs.di });
}

pub fn simulate_instructions(rs: registers, instruction: *i.instruction) !void {
    const stderr = std.io.getStdErr().writer();
    _ = rs;
    switch (instruction.opcode_id) {
        i.opcode.mov => {},
        else => {
            try stderr.print("Attempted to simulate unsupported instruction {s}", .{try ph.string_from_opcode(instruction.opcode_id)});
            return error.UnsupportedInstructionInSimulator;
        },
    }
    return;
}
