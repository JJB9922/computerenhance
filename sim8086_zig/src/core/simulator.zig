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

    ip: u16 = 0,
};

pub const flags = struct {
    c: i2 = 0,
    z: i2 = 0,
    s: i2 = 0,
    o: i2 = 0,
    p: i2 = 0,
    a: i2 = 0,
};

const Operand = struct {
    dst: union(enum) {
        reg: *u16,
        mem: u16,
    },
    src: u16,
};

pub var memory: [1024 * 1024]u8 = undefined;

pub fn print_registers(rs: registers) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("\n\n--- FINAL STATE---\n\n", .{});
    try stdout.print("AX: {d}, CX: {d}, DX: {d}, BX: {d}\n", .{ rs.ax, rs.cx, rs.dx, rs.bx });
    try stdout.print("SP: {d}, BP: {d}, SI: {d}, DI: {d}\n", .{ rs.sp, rs.bp, rs.si, rs.di });
    try stdout.print("IP: {d}\n", .{rs.ip});
}

pub fn print_flags(f: flags) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("C: {d}, Z: {d}, S: {d}, O: {d}, P: {d}, A: {d}\n", .{ f.c, f.z, f.s, f.o, f.p, f.a });
}

pub fn print_ip(rs: registers) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("| IP: 0x{x:0>4} |\n", .{rs.ip});
}

pub fn simulate_instructions(rs: *registers, f: *flags, instruction: *i.instruction, allocator: std.mem.Allocator) !void {
    try print_ip(rs.*);
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
        i.opcode.jnz => {
            return try simulate_jnz(instruction, rs, f);
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

    try map.put("ip", &rs.ip);
}

fn solve_memory_address(instruction: *i.instruction, register_map: *std.StringHashMap(*u16)) ?u16 {
    var to_solve = instruction.destination_reg;
    if (std.mem.startsWith(u8, to_solve, "word ")) {
        to_solve = to_solve[5..];
    }
    to_solve = to_solve[1 .. to_solve.len - 1];

    var it = std.mem.splitSequence(u8, to_solve, " ");
    var base: u16 = 0;
    var offset: i16 = 0;
    var op: enum { Add, Sub } = .Add;

    while (it.next()) |x| {
        if (register_map.get(x)) |reg| {
            base += reg.*;
            continue;
        }

        if (std.mem.eql(u8, "+", x)) {
            op = .Add;
            continue;
        }

        if (std.mem.eql(u8, "-", x)) {
            op = .Sub;
            continue;
        }

        const num = std.fmt.parseInt(i16, x, 10) catch return null;
        if (op == .Add) {
            offset += num;
        } else {
            offset -= num;
        }
    }

    return @intCast(@as(i32, base) + offset);
}

fn solve_memory_address_source(instruction: *i.instruction, register_map: *std.StringHashMap(*u16)) ?u16 {
    var to_solve = instruction.source_reg;
    if (std.mem.startsWith(u8, to_solve, "word ")) {
        to_solve = to_solve[5..];
    }
    to_solve = to_solve[1 .. to_solve.len - 1];

    var it = std.mem.splitSequence(u8, to_solve, " ");
    var base: u16 = 0;
    var offset: i16 = 0;
    var op: enum { Add, Sub } = .Add;

    while (it.next()) |x| {
        if (register_map.get(x)) |reg| {
            base += reg.*;
            continue;
        }

        if (std.mem.eql(u8, "+", x)) {
            op = .Add;
            continue;
        }

        if (std.mem.eql(u8, "-", x)) {
            op = .Sub;
            continue;
        }

        const num = std.fmt.parseInt(i16, x, 10) catch return null;
        if (op == .Add) {
            offset += num;
        } else {
            offset -= num;
        }
    }

    return @intCast(@as(i32, base) + offset);
}

fn is_memory_operand(operand: []const u8) bool {
    var slice = operand;
    if (std.mem.startsWith(u8, slice, "word ")) {
        slice = slice[5..];
    }
    if (slice.len == 0) return false;
    return slice[0] == '[';
}

fn get_operands(instruction: *i.instruction, register_map: *std.StringHashMap(*u16)) ?Operand {
    if (instruction.is_memory and is_memory_operand(instruction.destination_reg)) {
        const address = solve_memory_address(instruction, register_map) orelse return null;

        if (!std.mem.eql(u8, "", instruction.source_reg)) {
            if (register_map.get(instruction.source_reg)) |src_reg| {
                return .{ .dst = .{ .mem = address }, .src = src_reg.* };
            }
        }
        return .{ .dst = .{ .mem = address }, .src = instruction.source_int };
    }

    if (instruction.is_memory and is_memory_operand(instruction.source_reg)) {
        const address = solve_memory_address_source(instruction, register_map) orelse return null;

        if (std.mem.eql(u8, "", instruction.destination_reg)) return null;
        const dst = register_map.get(instruction.destination_reg) orelse return null;

        const lo = memory[address];
        const hi = memory[address + 1];
        const value: u16 = (@as(u16, hi) << 8) | lo;

        return .{ .dst = .{ .reg = dst }, .src = value };
    }

    if (std.mem.eql(u8, "", instruction.destination_reg)) return null;
    const dst = register_map.get(instruction.destination_reg) orelse return null;

    if (!std.mem.eql(u8, "", instruction.source_reg)) {
        if (register_map.get(instruction.source_reg)) |src_reg| {
            return .{ .dst = .{ .reg = dst }, .src = src_reg.* };
        }
    }

    return .{ .dst = .{ .reg = dst }, .src = instruction.source_int };
}

fn simulate_mov(instruction: *i.instruction, register_map: *std.StringHashMap(*u16)) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseMovInstruction;

    switch (operands.dst) {
        .reg => |reg| {
            reg.* = operands.src;
        },
        .mem => |addr| {
            memory[addr] = @intCast(operands.src & 0xFF);
            memory[addr + 1] = @intCast(operands.src >> 8);
        },
    }
}

fn simulate_add(instruction: *i.instruction, register_map: *std.StringHashMap(*u16), f: *flags) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseAddInstruction;

    switch (operands.dst) {
        .reg => |reg| {
            const result = reg.* + operands.src;
            reg.* = result;
            set_flags(reg.*, f);
        },
        .mem => |addr| {
            const lo = memory[addr];
            const hi = memory[addr + 1];
            const value: u16 = (@as(u16, hi) << 8) | lo;

            const result = value + operands.src;
            memory[addr] = @intCast(result & 0xFF);
            memory[addr + 1] = @intCast(result >> 8);
            set_flags(result, f);
        },
    }
}

fn simulate_sub(instruction: *i.instruction, register_map: *std.StringHashMap(*u16), f: *flags) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseSubInstruction;
    const result: i16 = @as(i16, @bitCast(operands.dst.reg.*)) - @as(i16, @bitCast(operands.src));
    operands.dst.reg.* = @as(u16, @bitCast(result));
    set_flags(operands.dst.reg.*, f);
}

fn simulate_cmp(instruction: *i.instruction, register_map: *std.StringHashMap(*u16), f: *flags) !void {
    const operands = get_operands(instruction, register_map) orelse return error.UnableToParseCmpInstruction;
    const result: i16 = @as(i16, @bitCast(operands.dst.reg.*)) - @as(i16, @bitCast(operands.src));
    set_flags(@as(u16, @bitCast(result)), f);
}

fn simulate_jnz(instruction: *i.instruction, rs: *registers, f: *flags) !void {
    const stdout = std.io.getStdOut().writer();
    if (f.z == 1) {
        return;
    }

    try stdout.print("Jumping to 0x{x}\n", .{instruction.jump_addr});
    rs.ip = instruction.jump_addr;
    try print_ip(rs.*);
    // Horrible. Horrible. Horrible.
    rs.ip -= instruction.size;
}

fn set_flags(result: u16, f: *flags) void {
    f.z = if (result == 0) 1 else 0;
    f.s = if ((result & 0x8000) != 0) 1 else 0;
}
