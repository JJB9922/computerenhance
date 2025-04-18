const std = @import("std");
const i = @import("instruction_set.zig");
const ph = @import("parsing_helpers.zig");

pub const registers = struct {
    al: u8,
    cl: u8,
    dl: u8,
    bl: u8,
    ah: u8,
    ch: u8,
    dh: u8,
    bh: u8,

    ax: u8,
    cx: u8,
    dx: u8,
    bx: u8,
    sp: u8,
    bp: u8,
    si: u8,
    di: u8,
};

pub fn print_registers(rs: registers) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("AL: {d}, CL: {d}, DL: {d}, BL: {d}\n", .{ rs.al, rs.cl, rs.dl, rs.bl });
    try stdout.print("AH: {d}, CH: {d}, DH: {d}, BH: {d}\n", .{ rs.ah, rs.ch, rs.dh, rs.bh });
    try stdout.print("AX: {d}, CX: {d}, DX: {d}, BX: {d}\n", .{ rs.ax, rs.cx, rs.dx, rs.bx });
    try stdout.print("SP: {d}, BP: {d}, SI: {d}, DI: {d}\n", .{ rs.sp, rs.bp, rs.si, rs.di });
}

pub fn simulate_instructions(rs: registers, inst: i.instruction) !void {
    const stderr = std.io.getStdErr().writer();
    const stdout = std.io.getStdOut().writer();
    _ = rs;
    switch (inst.opcode_id) {
        i.opcode.mov => {
            const regBits: u8 = ph.extract_field(inst.binary, inst.reg_loc.?);
            const reg = try ph.string_from_reg_bits(regBits, inst.w_on.?);
            try stdout.print("{s}\n", .{reg});
        },
        else => {
            try stderr.print("Attempted to simulate unsupported instruction {s}", .{try ph.string_from_opcode(inst.opcode_id)});
            return error.UnsupportedInstructionInSimulator;
        },
    }
    return;
}
