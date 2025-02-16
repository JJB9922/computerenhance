const std = @import("std");

const MOVType = enum { RegMemToFromReg, ImmToRegMem, ImmToReg, MemToAcc, AccToMem, RegMemToSegReg, SegRegToRegMem };

fn getRegister(register: u8, isWordMode: bool) []const u8 {
    if (isWordMode) {
        if (register == 0b00000000) return "ax";
        if (register == 0b00000001 or register == 0b00001000) return "cx";
        if (register == 0b00011000) return "bx";
    } else {
        return "";
    }

    return "";
}

fn parseMOV(allocator: std.mem.Allocator, movType: MOVType, opcode: []u8) ![]const u8 {
    var flippedRegisters: bool = false;
    var isWordMode: bool = false;
    var displacement: u8 = 0;
    var isRegisterMode: bool = false;

    switch (movType) {
        MOVType.RegMemToFromReg => {
            if (opcode[0] & 0b00000011 == 0b00000010) {
                flippedRegisters = true;
            }
            if (opcode[0] & 0b00000011 == 0b00000001) {
                isWordMode = true;
            }

            if (opcode[1] & 0b11000000 == 0b01000000) {
                displacement = 8;
            }

            if (opcode[1] & 0b11000000 == 0b10000000) {
                displacement = 16;
            }

            if (opcode[1] & 0b11000000 == 0b11000000) {
                isRegisterMode = true;
            }

            const sourceReg = getRegister(opcode[1] & 0b00111000, isWordMode);
            const destReg = getRegister(opcode[1] & 0b00000111, isWordMode);
            return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", destReg, sourceReg });
        },
        else => {
            return "";
        },
    }
}

pub fn instructionFromBinaryOpcode(allocator: std.mem.Allocator, opcode: []u8) ![]const u8 {
    // TODO: Separate out
    const mask = 0b11111100;

    if ((opcode[0] & mask) == 0b10001000) {
        const instruction = try parseMOV(allocator, MOVType.RegMemToFromReg, opcode);
        return instruction;
    }

    return "";
}
