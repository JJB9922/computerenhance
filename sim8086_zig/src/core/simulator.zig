const std = @import("std");
const i = @import("instruction_set.zig");
const ph = @import("parsing_helpers.zig");

pub const registers = struct {
    // Should be u8 but i'm being extremely lazy until necessary
    al: u16 = 0,
    cl: u16 = 0,
    dl: u16 = 0,
    bl: u16 = 0,
    ah: u16 = 0,
    ch: u16 = 0,
    dh: u16 = 0,
    bh: u16 = 0,

    ax: u16 = 0,
    cx: u16 = 0,
    dx: u16 = 0,
    bx: u16 = 0,
    sp: u16 = 0,
    bp: u16 = 0,
    si: u16 = 0,
    di: u16 = 0,
};

pub const flags = struct {
    c: i2 = 0,
    z: i2 = 0,
    s: i2 = 0,
    o: i2 = 0,
    p: i2 = 0,
    a: i2 = 0,
};

pub fn print_registers(rs: registers) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("AX: {d}, CX: {d}, DX: {d}, BX: {d}\n", .{ rs.ax, rs.cx, rs.dx, rs.bx });
    try stdout.print("SP: {d}, BP: {d}, SI: {d}, DI: {d}\n", .{ rs.sp, rs.bp, rs.si, rs.di });
}

pub fn print_flags(f: flags) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("C: {d}, Z: {d}, S: {d}, O: {d}, P: {d}, A: {d}\n", .{ f.c, f.z, f.s, f.o, f.p, f.a });
}

pub fn simulate_instructions(rs: *registers, f: *flags, instruction: *i.instruction, allocator: std.mem.Allocator) !void {
    const stderr = std.io.getStdErr().writer();
    var register_map = std.StringHashMap(*u16).init(allocator);
    try create_register_map(&register_map, rs);

    switch (instruction.opcode_id) {
        i.opcode.mov => {
            return try simulate_mov(instruction, &register_map);
        },
        i.opcode.sub => {
            return try simulate_sub(instruction, &register_map, f);
        },
        i.opcode.add => {
            return try simulate_add(instruction, &register_map, f);
        },
        i.opcode.cmp => {
            return try simulate_cmp(instruction, &register_map, f);
        },
        else => {
            try stderr.print("Attempted to simulate unsupported instruction {s}: ", .{try ph.string_from_opcode(instruction.opcode_id)});
            return error.UnsupportedInstructionInSimulator;
        },
    }
    return;
}

fn create_register_map(map: *std.StringHashMap(*u16), rs: *registers) !void {
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

fn get_operands(instruction: *i.instruction, register_map: *std.StringHashMap(*u16)) ?struct {
    dst: *u16,
    src: u16,
} {
    if (std.mem.eql(u8, "", instruction.destination_reg)) return null;
    const dst = register_map.get(instruction.destination_reg) orelse return null;

    if (!std.mem.eql(u8, "", instruction.source_reg)) {
        if (register_map.get(instruction.source_reg)) |src_reg| {
            return .{ .dst = dst, .src = src_reg.* };
        }
    }

    return .{ .dst = dst, .src = instruction.source_int };
}

fn simulate_mov(instruction: *i.instruction, register_map: *std.StringHashMap(*u16)) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseMovInstruction;
    operands.dst.* = operands.src;
}

fn simulate_add(instruction: *i.instruction, register_map: *std.StringHashMap(*u16), f: *flags) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseAddInstruction;
    operands.dst.* += operands.src;
    set_flags(operands.dst.*, f);
}

fn simulate_sub(instruction: *i.instruction, register_map: *std.StringHashMap(*u16), f: *flags) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseSubInstruction;
    operands.dst.* -= operands.src;
    set_flags(operands.dst.*, f);
}

fn simulate_cmp(instruction: *i.instruction, register_map: *std.StringHashMap(*u16), f: *flags) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseCmpInstruction;
    const copy = operands.dst.* - operands.src;
    set_flags(copy, f);
}

fn set_flags(result: u16, f: *flags) void {
    f.*.z = if (result == 0) 1 else 0;
    f.s = if ((result & 0x8000) != 0) 1 else 0;
}
