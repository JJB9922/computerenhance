const std = @import("std");

// Globally applicable
const mod_mask = 0b11000000;
const rm_mask = 0b00000111;

const InstructionType = enum { none, mov, add, sub, cmp };

const OpcodePattern = enum {
    none,
    reg_mem_reg, // Register/memory to/from register
    imm_reg_mem, // Immediate to register/memory
    imm_reg, // Immediate to register
    mem_acc, // Memory to accumulator
    acc_mem, // Accumulator to memory
    single_op, // Single operand
    implicit, // No operands, implied
    port_io, // Port I/O operations
    seg_op, // Segment register operations
};

const InstructionFormat = struct { bytes_needed: u8, instruction_type: InstructionType, opcode_pattern: OpcodePattern, instruction: []u8 };

pub fn parse_instruction(allocator: std.mem.Allocator, instruction_format: InstructionFormat) ![]const u8 {
    const operation = try instruction_string_from_instructiontype_enum(instruction_format.instruction_type);

    // 8086 User Man. 4-22
    switch (instruction_format.opcode_pattern) {
        OpcodePattern.reg_mem_reg => {
            std.debug.assert(instruction_format.instruction.len > 1 and instruction_format.instruction.len < 5);
            const d_mask = 0b00000010;
            const w_mask = 0b00000001;

            const mod = try mod_from_instruction(instruction_format.instruction[1]);
            const rm = try rm_from_instruction(instruction_format.instruction[1]);
            const reg = try reg_from_instruction(instruction_format.instruction[1]);

            var source_is_reg = false;
            var is_word_mode = false;

            if (instruction_format.instruction[0] & d_mask == d_mask) {
                source_is_reg = true;
            }

            if (instruction_format.instruction[0] & w_mask == w_mask) {
                is_word_mode = true;
            }

            var dest_reg: []const u8 = "???";
            var source_reg: []const u8 = "???";

            if (source_is_reg) {
                dest_reg = try get_single_register(reg, is_word_mode);
                if (!std.mem.eql(u8, mod, "11")) {
                    source_reg = try get_effective_address(allocator, mod, rm, instruction_format.instruction);
                } else {
                    source_reg = try get_single_register(rm, is_word_mode);
                }
            } else {
                source_reg = try get_single_register(reg, is_word_mode);
                if (!std.mem.eql(u8, mod, "11")) {
                    dest_reg = try get_effective_address(allocator, mod, rm, instruction_format.instruction);
                } else {
                    dest_reg = try get_single_register(rm, is_word_mode);
                }
            }
            if (source_is_reg) {}

            return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ operation, dest_reg, source_reg });
        },
        OpcodePattern.imm_reg_mem => {
            std.debug.assert(instruction_format.instruction.len > 1 and instruction_format.instruction.len < 6);
            const w_mask = 0b00000001;
            var is_word_mode = false;

            if (instruction_format.instruction[0] & w_mask == w_mask) {
                is_word_mode = true;
            }

            var source_val: i32 = 0;
            var dest_reg: []const u8 = "???";

            const rm = try rm_from_instruction(instruction_format.instruction[1]);

            dest_reg = try get_single_register(rm, is_word_mode);

            source_val = try get_data_value(instruction_format);

            return try std.fmt.allocPrint(allocator, "{s} {s}, {d}\n", .{ operation, dest_reg, source_val });
        },
        OpcodePattern.imm_reg => {
            var dest_reg: []const u8 = "???";

            // TODO: verify this is a correct guess and not an incorrect guess
            if (instruction_format.instruction.len == 3) {
                dest_reg = "ax";
            } else {
                dest_reg = "al";
            }

            const source_val = try get_data_value(instruction_format);

            return try std.fmt.allocPrint(allocator, "{s} {s}, {d}\n", .{ operation, dest_reg, source_val });
        },
        OpcodePattern.mem_acc => {},
        OpcodePattern.acc_mem => {},
        OpcodePattern.single_op => {},
        OpcodePattern.implicit => {},
        OpcodePattern.port_io => {},
        OpcodePattern.seg_op => {},
        else => {
            return error.UnhandledInstruction;
        },
    }

    return error.ParseError;
}

// Can always figure out needed bytes for opcode from first couple bytes of the opcode
pub fn get_instruction_format(instruction: []u8) !InstructionFormat {
    var bytes_needed: u8 = 0;
    var instruction_type: InstructionType = InstructionType.none;
    var opcode_pattern: OpcodePattern = OpcodePattern.none;
    const opcode = instruction[0];
    const opcode_byte_2 = instruction[1];

    const reg_mem_reg_mask = 0b11111100;
    const imm_reg_mem_mask = 0b11111110;
    const imm_reg_mem_mask_arithmetic = 0b11111100;
    const imm_reg_mask_mov = 0b11110000;
    const imm_reg_mask_arithmetic = 0b11111110;

    const arithmetic_identifier_mask = 0b00111000;

    const sw_mask = 0b00000011;
    const w_mask = 0b00000001;

    // reg_mem_reg
    if (opcode & reg_mem_reg_mask == 0b10001000) {
        instruction_type = InstructionType.mov;
        opcode_pattern = OpcodePattern.reg_mem_reg;
    }

    if (opcode & reg_mem_reg_mask == 0b00000000) {
        instruction_type = InstructionType.add;
        opcode_pattern = OpcodePattern.reg_mem_reg;
    }

    if (opcode & reg_mem_reg_mask == 0b00101000) {
        instruction_type = InstructionType.sub;
        opcode_pattern = OpcodePattern.reg_mem_reg;
    }

    if (opcode & reg_mem_reg_mask == 0b00111000) {
        instruction_type = InstructionType.cmp;
        opcode_pattern = OpcodePattern.reg_mem_reg;
    }

    if (opcode_pattern == OpcodePattern.reg_mem_reg) {
        if ((opcode_byte_2 & mod_mask == 0b00000000 and opcode_byte_2 & rm_mask == 0b00000110) or opcode_byte_2 & mod_mask == 0b10000000) {
            bytes_needed = 4;
        }

        if ((opcode_byte_2 & mod_mask == 0b00000000 and opcode_byte_2 & rm_mask != 0b00000110) or opcode_byte_2 & mod_mask == 0b11000000) {
            bytes_needed = 2;
        }

        if (opcode_byte_2 & mod_mask == 0b01000000) {
            bytes_needed = 3;
        }
    }

    // imm_reg_mem
    if (opcode & imm_reg_mem_mask == 0b1100011) {
        instruction_type = InstructionType.mov;
        opcode_pattern = OpcodePattern.imm_reg_mem;
    }

    if (opcode & imm_reg_mem_mask_arithmetic == 0b10000000 and opcode_byte_2 & arithmetic_identifier_mask == 0b00000000) {
        instruction_type = InstructionType.add;
        opcode_pattern = OpcodePattern.imm_reg_mem;
    }

    if (opcode & imm_reg_mem_mask_arithmetic == 0b10000000 and opcode_byte_2 & arithmetic_identifier_mask == 0b00101000) {
        instruction_type = InstructionType.sub;
        opcode_pattern = OpcodePattern.imm_reg_mem;
    }

    if (opcode & imm_reg_mem_mask_arithmetic == 0b10000000 and opcode_byte_2 & arithmetic_identifier_mask == 0b00111000) {
        instruction_type = InstructionType.cmp;
        opcode_pattern = OpcodePattern.imm_reg_mem;
    }

    if (opcode_pattern == OpcodePattern.imm_reg_mem) {
        if ((opcode_byte_2 & mod_mask == 0b00000000 and opcode_byte_2 & rm_mask == 0b00000110) or opcode_byte_2 & mod_mask == 0b10000000) {
            if (opcode & sw_mask == 0b00000001) {
                bytes_needed = 6;
            } else {
                bytes_needed = 5;
            }
        }

        if ((opcode_byte_2 & mod_mask == 0b00000000 and opcode_byte_2 & rm_mask != 0b00000110) or opcode_byte_2 & mod_mask == 0b11000000) {
            if (opcode & sw_mask == 0b00000001) {
                bytes_needed = 4;
            } else {
                bytes_needed = 3;
            }
        }

        if (opcode_byte_2 & mod_mask == 0b01000000) {
            if (opcode & sw_mask == 0b00000001) {
                bytes_needed = 5;
            } else {
                bytes_needed = 4;
            }
        }
    }

    // imm_reg
    if (opcode & imm_reg_mask_mov == 0b10110000) {
        instruction_type = InstructionType.mov;
        opcode_pattern = OpcodePattern.imm_reg;

        if (opcode & 0b00001000 == 0b00001000) {
            bytes_needed = 3;
        } else {
            bytes_needed = 2;
        }
    }

    if (opcode & imm_reg_mask_arithmetic == 0b00000100) {
        instruction_type = InstructionType.add;
        opcode_pattern = OpcodePattern.imm_reg;
    }

    if (opcode & imm_reg_mask_arithmetic == 0b00101100) {
        instruction_type = InstructionType.sub;
        opcode_pattern = OpcodePattern.imm_reg;
    }

    if (opcode & imm_reg_mask_arithmetic == 0b00111100) {
        instruction_type = InstructionType.cmp;
        opcode_pattern = OpcodePattern.imm_reg;
    }

    if (opcode_pattern == OpcodePattern.imm_reg) {
        if (instruction_type != InstructionType.mov and opcode & w_mask == 0b00000001) {
            bytes_needed = 3;
        } else {
            bytes_needed = 2;
        }
    }

    if (bytes_needed > 0) {
        return InstructionFormat{ .bytes_needed = bytes_needed, .instruction_type = instruction_type, .opcode_pattern = opcode_pattern, .instruction = "" };
    } else if (instruction[0] & 0b11111111 == 0b00000000) {
        return .{ .bytes_needed = 0, .opcode_pattern = OpcodePattern.none, .instruction_type = InstructionType.none, .instruction = "" };
    } else {
        return error.UnhandledInstruction;
    }
}

fn get_data_value(instruction_format: InstructionFormat) !i32 {
    if (instruction_format.opcode_pattern == OpcodePattern.imm_reg_mem) {
        const is_signed_word = instruction_format.instruction[0] & 0b00000001 == 0b00000001;

        if (!is_signed_word) {
            const sixteen_bit_result: u16 = @as(u16, instruction_format.instruction[instruction_format.instruction.len - 1]) << 8 | @as(u16, instruction_format.instruction[instruction_format.instruction.len - 2]);
            return @as(u16, sixteen_bit_result);
        } else {
            return @as(u16, instruction_format.instruction[instruction_format.instruction.len - 1]);
        }
    }

    if (instruction_format.opcode_pattern == OpcodePattern.imm_reg) {
        const is_word = instruction_format.instruction[0] & 0b00000001 == 0b00000001;

        if (is_word) {
            const sixteen_bit_result: i16 = @as(i16, instruction_format.instruction[instruction_format.instruction.len - 1]) << 8 | @as(i16, instruction_format.instruction[instruction_format.instruction.len - 2]);
            return @as(i16, sixteen_bit_result);
        } else {
            return @as(i16, instruction_format.instruction[instruction_format.instruction.len - 1]);
        }
    }

    return error.UnhandledDataValueFormat;
}

fn get_effective_address(allocator: std.mem.Allocator, mod: []const u8, rm: []const u8, instruction: []u8) ![]const u8 {
    if (std.mem.eql(u8, mod, "00")) {
        if (std.mem.eql(u8, rm, "000")) {
            return "[bx + si]";
        }

        if (std.mem.eql(u8, rm, "001")) {
            return "[bx + di]";
        }

        if (std.mem.eql(u8, rm, "010")) {
            return "[bp + si]";
        }

        if (std.mem.eql(u8, rm, "011")) {
            return "[bp + di]";
        }

        if (std.mem.eql(u8, rm, "100")) {
            return "[si]";
        }

        if (std.mem.eql(u8, rm, "101")) {
            return "[di]";
        }

        if (std.mem.eql(u8, rm, "110")) {
            return "???";
        }

        if (std.mem.eql(u8, rm, "111")) {
            return "[bx]";
        }
    }

    if (std.mem.eql(u8, mod, "01")) {
        const value = @as(i32, instruction[2]);

        if (std.mem.eql(u8, rm, "000")) {
            return try std.fmt.allocPrint(allocator, "[bx + si + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "001")) {
            return try std.fmt.allocPrint(allocator, "[bx + di + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "010")) {
            return try std.fmt.allocPrint(allocator, "[bp + si + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "011")) {
            return try std.fmt.allocPrint(allocator, "[bp + di + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "100")) {
            return try std.fmt.allocPrint(allocator, "[si + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "101")) {
            return try std.fmt.allocPrint(allocator, "[di + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "110")) {
            return try std.fmt.allocPrint(allocator, "[bp + {d}]", .{value});
        }

        if (std.mem.eql(u8, rm, "111")) {
            return try std.fmt.allocPrint(allocator, "[bx + {d}]", .{value});
        }
    }

    if (std.mem.eql(u8, mod, "10")) {
        if (std.mem.eql(u8, rm, "000")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bx + si + {d}]", .{sixteen_bit_result});
            return result;
        }

        if (std.mem.eql(u8, rm, "001")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bx + di + {d}]", .{sixteen_bit_result});
            return result;
        }

        if (std.mem.eql(u8, rm, "010")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bp + si + {d}]", .{sixteen_bit_result});
            return result;
        }

        if (std.mem.eql(u8, rm, "011")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bp + di + {d}]", .{sixteen_bit_result});
            return result;
        }

        if (std.mem.eql(u8, rm, "100")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[s§i + {d}]", .{sixteen_bit_result});
            return result;
        }

        if (std.mem.eql(u8, rm, "101")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[di + {d}]", .{sixteen_bit_result});
            return result;
        }
        if (std.mem.eql(u8, rm, "110")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bp + {d}]", .{sixteen_bit_result});
            return result;
        }

        if (std.mem.eql(u8, rm, "111")) {
            const sixteen_bit_result: i16 = @as(i16, instruction[3]) << 8 | @as(i16, instruction[2]);
            const result = try std.fmt.allocPrint(allocator, "[bx + {d}]", .{sixteen_bit_result});
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

fn instruction_string_from_instructiontype_enum(instruction_type: InstructionType) ![]const u8 {
    switch (instruction_type) {
        InstructionType.mov => return "mov",
        InstructionType.add => return "add",
        InstructionType.sub => return "sub",
        InstructionType.cmp => return "cmp",
        else => return "???",
    }
}
