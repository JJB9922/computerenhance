const std = @import("std");

const movtype = enum { reg_mem_to_from_reg, imm_to_reg_mem, imm_to_reg, mem_to_acc, acc_to_mem, reg_mem_to_seg_reg, seg_reg_to_reg_mem };

fn get_single_register(register: u8, is_word_mode: bool) []const u8 {
    if (is_word_mode) {
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

fn parse_mov(allocator: std.mem.Allocator, mov_type: movtype, opcode: []u8) ![]const u8 {
    var flipped_registers: bool = false;
    var is_word_mode: bool = false;
    var displacement: u8 = 0;
    var is_register_mode: bool = false;

    switch (mov_type) {
        movtype.reg_mem_to_from_reg => {
            if (opcode[0] & 0b00000011 == 0b00000010) {
                flipped_registers = true;
            }
            if (opcode[0] & 0b00000011 == 0b00000001) {
                is_word_mode = true;
            }

            if (opcode[1] & 0b11000000 == 0b01000000) {
                displacement = 8;
            }

            if (opcode[1] & 0b11000000 == 0b10000000) {
                displacement = 16;
            }

            if (opcode[1] & 0b11000000 == 0b11000000) {
                is_register_mode = true;
            }

            const source_reg = get_single_register(opcode[1] & 0b00111000, is_word_mode);
            const dest_reg = get_single_register(opcode[1] & 0b00000111, is_word_mode);
            return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", dest_reg, source_reg });
        },
        else => {
            return "";
        },
    }
}

pub fn instruction_from_binary_opcode_array(allocator: std.mem.Allocator, opcode: []u8) ![]const u8 {
    if ((opcode[0] & 0b11111100) == 0b10001000) {
        const instruction = try parse_mov(allocator, movtype.reg_mem_to_from_reg, opcode);
        return instruction;
    }

    return "";
}

pub fn get_needed_bytes() !void {}
