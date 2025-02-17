const std = @import("std");

// Globally applicable
const mod_mask = 0b11000000;
const rm_mask = 0b00000111;

const instructiontype = enum { none, mov_A, mov_B, mov_C, mov_D, mov_E, mov_G, mov_F };

fn get_effective_address(allocator: std.mem.Allocator, mod: []const u8, rm: []const u8, instruction: []u8) ![]const u8 {
    if (std.mem.eql(u8, mod, "00")) {
        if (std.mem.eql(u8, rm, "000")) {
            return "[bx + si]";
        }

        if (std.mem.eql(u8, rm, "011")) {
            return "[bp + di]";
        }

        if (std.mem.eql(u8, rm, "001")) {
            return "[bx + di]";
        }

        if (std.mem.eql(u8, rm, "010")) {
            return "[bp + si]";
        }
    }

    if (std.mem.eql(u8, mod, "01")) {
        if (std.mem.eql(u8, rm, "110")) {
            return "[bp]";
        }

        if (std.mem.eql(u8, rm, "000")) {
            const result = try std.fmt.allocPrint(allocator, "[bx + si + {d}]", .{instruction[2]});
            return result;
        }
    }

    if (std.mem.eql(u8, mod, "10")) {
        if (std.mem.eql(u8, rm, "000")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bx + si + {d}]", .{sixteen_bit_result});
            return result;
        }
    }

    return error.CannotGetEffectiveAddress;
}

fn reg_from_instruction(instruction: u8) ![]const u8 {
    const reg_mask = 0b00111000;

    if (instruction & reg_mask == 0b00000000) {
        return "000";
    }

    if (instruction & reg_mask == 0b00001000) {
        return "001";
    }

    if (instruction & reg_mask == 0b00010000) {
        return "010";
    }

    if (instruction & reg_mask == 0b00011000) {
        return "011";
    }

    if (instruction & reg_mask == 0b00100000) {
        return "100";
    }

    if (instruction & reg_mask == 0b00101000) {
        return "101";
    }

    if (instruction & reg_mask == 0b00110000) {
        return "110";
    }

    if (instruction & reg_mask == 0b00111000) {
        return "111";
    }

    return error.CannotGetREG;
}

fn rm_from_instruction(instruction: u8) ![]const u8 {
    if (instruction & rm_mask == 0b00000000) {
        return "000";
    }

    if (instruction & rm_mask == 0b00000001) {
        return "001";
    }

    if (instruction & rm_mask == 0b00000010) {
        return "010";
    }

    if (instruction & rm_mask == 0b00000011) {
        return "011";
    }

    if (instruction & rm_mask == 0b00000100) {
        return "100";
    }

    if (instruction & rm_mask == 0b00000101) {
        return "101";
    }

    if (instruction & rm_mask == 0b00000110) {
        return "110";
    }

    if (instruction & rm_mask == 0b00000111) {
        return "111";
    }

    return error.CannotGetRM;
}

fn mod_from_instruction(instruction: u8) ![]const u8 {
    if (instruction & mod_mask == 0b00000000) {
        return "00";
    }

    if (instruction & mod_mask == 0b01000000) {
        return "01";
    }

    if (instruction & mod_mask == 0b10000000) {
        return "10";
    }

    if (instruction & mod_mask == 0b11000000) {
        return "11";
    }

    return error.CannotGetMOD;
}

fn get_single_register(register: []const u8, is_word_mode: bool) ![]const u8 {
    if (is_word_mode) {
        // 8086 User Man. 4-20
        if (std.mem.eql(u8, register, "000")) return "ax";
        if (std.mem.eql(u8, register, "001")) return "cx";
        if (std.mem.eql(u8, register, "010")) return "dx";
        if (std.mem.eql(u8, register, "011")) return "bx";
        if (std.mem.eql(u8, register, "100")) return "sp";
        if (std.mem.eql(u8, register, "101")) return "bp";
        if (std.mem.eql(u8, register, "110")) return "si";
        if (std.mem.eql(u8, register, "111")) return "di";
        return error.UnableToParseWordRegister;
    } else {
        if (std.mem.eql(u8, register, "000")) return "al";
        if (std.mem.eql(u8, register, "001")) return "cl";
        if (std.mem.eql(u8, register, "010")) return "dl";
        if (std.mem.eql(u8, register, "011")) return "bl";
        if (std.mem.eql(u8, register, "100")) return "ah";
        if (std.mem.eql(u8, register, "101")) return "ch";
        if (std.mem.eql(u8, register, "110")) return "dh";
        if (std.mem.eql(u8, register, "111")) return "bh";
        return error.UnableToParseRegister;
    }
}

pub fn parse_instruction(allocator: std.mem.Allocator, instruction_type: instructiontype, instruction: []u8) ![]const u8 {
    var instruction_source_is_reg = false;
    var is_word_mode: bool = false;

    // 8086 User Man. 4-22
    switch (instruction_type) {
        instructiontype.mov_A => {
            std.debug.assert(instruction.len > 1 and instruction.len < 5);

            if (instruction[0] & 0b00000010 == 0b00000010) {
                instruction_source_is_reg = true;
            }
            if (instruction[0] & 0b00000001 == 0b00000001) {
                is_word_mode = true;
            }

            const mod = try mod_from_instruction(instruction[1]);
            const rm = try rm_from_instruction(instruction[1]);
            const reg = try reg_from_instruction(instruction[1]);

            std.debug.assert(!std.mem.eql(u8, mod, ""));
            std.debug.assert(!std.mem.eql(u8, rm, ""));
            std.debug.assert(!std.mem.eql(u8, reg, ""));

            var source_reg: []const u8 = "undefined";
            var dest_reg: []const u8 = "undefined";

            if (instruction_source_is_reg) {
                dest_reg = try get_single_register(reg, is_word_mode);
                if (!std.mem.eql(u8, mod, "11")) {
                    source_reg = try get_effective_address(allocator, mod, rm, instruction);
                } else {
                    source_reg = try get_single_register(rm, is_word_mode);
                }
            } else {
                source_reg = try get_single_register(reg, is_word_mode);
                if (!std.mem.eql(u8, mod, "11")) {
                    dest_reg = try get_effective_address(allocator, mod, rm, instruction);
                } else {
                    dest_reg = try get_single_register(rm, is_word_mode);
                }
            }

            return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", dest_reg, source_reg });
        },
        instructiontype.mov_B => {},
        instructiontype.mov_C => {
            std.debug.assert(instruction.len > 1 and instruction.len < 4);

            if (instruction.len == 3) {
                is_word_mode = true;
            }

            const reg = try rm_from_instruction(instruction[0]);
            const dest_reg = try get_single_register(reg, is_word_mode);

            if (is_word_mode) {
                const data: i16 = @as(i16, instruction[2]) << 8 | @as(i16, instruction[1]);
                return try std.fmt.allocPrint(allocator, "{s} {s}, {d}\n", .{ "mov", dest_reg, data });
            } else {
                const data: i8 = @bitCast(instruction[1]);
                return try std.fmt.allocPrint(allocator, "{s} {s}, {d}\n", .{ "mov", dest_reg, data });
            }
        },
        else => {
            return error.UnhandledInstruction;
        },
    }

    return error.ParseError;
}

// Can always figure out needed bytes for opcode from first couple bytes of the opcode
pub fn get_bytes_needed_and_instruction_type(instruction: []u8) !struct { bytes_needed: u8, instruction_type: instructiontype } {
    if ((instruction[0] & 0b11111100) == 0b10001000) {
        // 00 or 11
        if ((instruction[1] & mod_mask == 0b00000000 and instruction[1] & rm_mask == 0b00000110) or instruction[1] & mod_mask == 0b10000000) {
            return .{ .bytes_needed = 4, .instruction_type = instructiontype.mov_A };
        }

        // 01
        if ((instruction[1] & mod_mask == 0b00000000 and instruction[1] & rm_mask != 0b00000110) or instruction[1] & mod_mask == 0b11000000) {
            return .{ .bytes_needed = 2, .instruction_type = instructiontype.mov_A };
        }

        // 10
        if (instruction[1] & mod_mask == 0b01000000) {
            return .{ .bytes_needed = 3, .instruction_type = instructiontype.mov_A };
        }
    }

    if (instruction[0] & 0b11111110 == 0b11000110) {
        const w_mask = 0b00000001;
        var is_word = false;
        if (instruction[0] & w_mask == 0b00000001) {
            is_word = true;
        }

        if ((instruction[1] & mod_mask == 0b00000000 and instruction[1] & rm_mask == 0b00000110) or instruction[1] & mod_mask == 0b10000000) {
            if (is_word) {
                return .{ .bytes_needed = 6, .instruction_type = instructiontype.mov_B };
            } else {
                return .{ .bytes_needed = 5, .instruction_type = instructiontype.mov_B };
            }
        }

        if ((instruction[1] & mod_mask == 0b00000000 and instruction[1] & rm_mask != 0b00000110) or instruction[1] & mod_mask == 0b11000000) {
            if (is_word) {
                return .{ .bytes_needed = 4, .instruction_type = instructiontype.mov_B };
            } else {
                return .{ .bytes_needed = 3, .instruction_type = instructiontype.mov_B };
            }
        }

        if (instruction[1] & mod_mask == 0b01000000) {
            if (is_word) {
                return .{ .bytes_needed = 5, .instruction_type = instructiontype.mov_B };
            } else {
                return .{ .bytes_needed = 4, .instruction_type = instructiontype.mov_B };
            }
        }
    }

    if (instruction[0] & 0b11110000 == 0b10110000) {
        const w_mask = 0b00001000;

        if (instruction[0] & w_mask == 0b00001000) {
            return .{ .bytes_needed = 3, .instruction_type = instructiontype.mov_C };
        } else {
            return .{ .bytes_needed = 2, .instruction_type = instructiontype.mov_C };
        }
    }

    if (instruction[0] & 0b11111111 == 0b00000000) {
        return .{ .bytes_needed = 0, .instruction_type = instructiontype.none };
    } else {
        return error.UnhandledInstruction;
    }
}
