const std = @import("std");

const MOVType = enum { RegMemToFromReg, ImmToRegMem, ImmToReg, MemToAcc, AccToMem, RegMemToSegReg, SegRegToRegMem };

fn getSingleRegister(register: u8, isWordMode: bool) []const u8 {
    if (isWordMode) {
        // 8086 User Man. 4-20
        if (register == 0b00000000) return "ax";
        if (register == 0b00000001 or register == 0b00001000) return "cx";
        if (register == 0b00000010 or register == 0b00010000) return "dx";
        if (register == 0b00000011 or register == 0b00011000) return "bx";
        if (register == 0b00000100 or register == 0b00100000) return "sp";
        if (register == 0b00000101 or register == 0b00101000) return "bp";
        if (register == 0b00000110 or register == 0b00110000) return "si";
        if (register == 0b00000111 or register == 0b00111000) return "di";
    } else {
        if (register == 0b00000000) return "al";
        if (register == 0b00000001 or register == 0b00001000) return "cl";
        if (register == 0b00000010 or register == 0b00010000) return "dl";
        if (register == 0b00000011 or register == 0b00011000) return "bl";
        if (register == 0b00000100 or register == 0b00100000) return "ah";
        if (register == 0b00000101 or register == 0b00101000) return "ch";
        if (register == 0b00000110 or register == 0b00110000) return "dh";
        if (register == 0b00000111 or register == 0b00111000) return "bh";
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

            const sourceReg = getSingleRegister(opcode[1] & 0b00111000, isWordMode);
            const destReg = getSingleRegister(opcode[1] & 0b00000111, isWordMode);
            return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", destReg, sourceReg });
        },
        else => {
            return "";
        },
    }
}

pub fn instructionFromBinaryOpcodeArray(allocator: std.mem.Allocator, opcode: []u8) ![]const u8 {
    if ((opcode[0] & 0b11111100) == 0b10001000) {
        const instruction = try parseMOV(allocator, MOVType.RegMemToFromReg, opcode);
        return instruction;
    }

    return "";
}
