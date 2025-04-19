const std = @import("std");
const i = @import("instruction_set.zig");
const ph = @import("parsing_helpers.zig");

pub const registers = struct {
    al: i16 = 0,
    cl: i16 = 0,
    dl: i16 = 0,
    bl: i16 = 0,
    ah: i16 = 0,
    ch: i16 = 0,
    dh: i16 = 0,
    bh: i16 = 0,

    ax: i16 = 0,
    cx: i16 = 0,
    dx: i16 = 0,
    bx: i16 = 0,
    sp: i16 = 0,
    bp: i16 = 0,
    si: i16 = 0,
    di: i16 = 0,
};

pub fn print_registers(rs: registers) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("AL: {d}, CL: {d}, DL: {d}, BL: {d}\n", .{ rs.al, rs.cl, rs.dl, rs.bl });
    try stdout.print("AH: {d}, CH: {d}, DH: {d}, BH: {d}\n", .{ rs.ah, rs.ch, rs.dh, rs.bh });
    try stdout.print("AX: {d}, CX: {d}, DX: {d}, BX: {d}\n", .{ rs.ax, rs.cx, rs.dx, rs.bx });
    try stdout.print("SP: {d}, BP: {d}, SI: {d}, DI: {d}\n", .{ rs.sp, rs.bp, rs.si, rs.di });
}

pub fn simulate_instructions(rs: *registers, instruction: *i.instruction, allocator: std.mem.Allocator) !void {
    const stderr = std.io.getStdErr().writer();
    var register_map = std.StringHashMap(*i16).init(allocator);
    try create_register_map(&register_map, rs);

    switch (instruction.opcode_id) {
        i.opcode.mov => {
            if (!std.mem.eql(u8, "", instruction.destination)) {
                if (!(instruction.source_int == 0)) {
                    if (register_map.get(instruction.destination)) |v| {
                        v.* = instruction.source_int;
                        return;
                    }
                }

                if (!std.mem.eql(u8, "", instruction.source_reg)) {
                    if (register_map.get(instruction.destination)) |v| {
                        if (register_map.get(instruction.source_reg)) |s| {
                            v.* = s.*;
                            return;
                        }
                    }
                }
            }

            return error.UnableToParseMovInstruction;
        },
        else => {
            try stderr.print("Attempted to simulate unsupported instruction {s}", .{try ph.string_from_opcode(instruction.opcode_id)});
            return error.UnsupportedInstructionInSimulator;
        },
    }
    return;
}

fn create_register_map(map: *std.StringHashMap(*i16), rs: *registers) !void {
    try map.put("al", &rs.al);
    try map.put("cl", &rs.cl);
    try map.put("dl", &rs.dl);
    try map.put("bl", &rs.bl);

    try map.put("ah", &rs.ah);
    try map.put("ch", &rs.ch);
    try map.put("dh", &rs.dh);
    try map.put("bh", &rs.bh);

    try map.put("ax", &rs.ax);
    try map.put("cx", &rs.cx);
    try map.put("dx", &rs.dx);
    try map.put("bx", &rs.bx);

    try map.put("sp", &rs.sp);
    try map.put("bp", &rs.bp);
    try map.put("si", &rs.si);
    try map.put("di", &rs.di);
}
