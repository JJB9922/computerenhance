const std = @import("std");

const disassemblererror = error{unhandled_instruction};

// TODO: Fix awful naming
const instructiontype = enum { none, mov_A, mov_B, mov_C, mov_D, mov_E, mov_G, mov_F };

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

pub fn parse_instruction(allocator: std.mem.Allocator, instruction_type: instructiontype, instruction: []u8) ![]const u8 {
    var flipped_registers: bool = false;
    var is_word_mode: bool = false;
    var displacement: u8 = 0;
    var is_register_mode: bool = false;

    // 8086 User Man. 4-22
    switch (instruction_type) {
        instructiontype.mov_A => {
            std.debug.assert(instruction.len > 1 and instruction.len < 5);
            if (instruction[0] & 0b00000011 == 0b00000010) {
                flipped_registers = true;
            }
            if (instruction[0] & 0b00000011 == 0b00000001) {
                is_word_mode = true;
            }

            if (instruction[1] & 0b11000000 == 0b01000000) {
                displacement = 8;
            }

            if (instruction[1] & 0b11000000 == 0b10000000) {
                displacement = 16;
            }

            if (instruction[1] & 0b11000000 == 0b11000000) {
                is_register_mode = true;
            }

            const source_reg = get_single_register(instruction[1] & 0b00111000, is_word_mode);
            const dest_reg = get_single_register(instruction[1] & 0b00000111, is_word_mode);

            // TODO: Handle disp
            if (displacement == 0) {
                return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", dest_reg, source_reg });
            }

            if (displacement == 8) {
                return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", dest_reg, source_reg });
            }

            if (displacement == 16) {
                return try std.fmt.allocPrint(allocator, "{s} {s}, {s}\n", .{ "mov", dest_reg, source_reg });
            }
        },
        instructiontype.mov_B => {},
        instructiontype.mov_C => {
            std.debug.assert(instruction.len > 1 and instruction.len < 4);

            if (instruction.len == 3) {
                is_word_mode = true;
            }

            const dest_reg = get_single_register(instruction[0] & 0b00000111, is_word_mode);

            if (is_word_mode) {
                const data: i16 = @as(i16, instruction[2]) << 8 | @as(i16, instruction[1]);
                return try std.fmt.allocPrint(allocator, "{s} {s}, {d}\n", .{ "mov", dest_reg, data });
            } else {
                const data: i8 = @bitCast(instruction[1]);
                return try std.fmt.allocPrint(allocator, "{s} {s}, {d}\n", .{ "mov", dest_reg, data });
            }
        },
        else => {
            return "";
        },
    }

    return "";
}

// Can always figure out needed bytes for opcode from first couple bytes of the opcode
pub fn get_bytes_needed_and_instruction_type(instruction: []u8) !struct { bytes_needed: u8, instruction_type: instructiontype } {
    // MOV
    const mod_mask = 0b11000000;
    const rm_mask = 0b00000111;

    if ((instruction[0] & 0b11111100) == 0b10001000) {
        if ((instruction[1] & mod_mask == 0b00000000 and instruction[1] & rm_mask == 0b00000110) or instruction[1] & mod_mask == 0b10000000) {
            return .{ .bytes_needed = 4, .instruction_type = instructiontype.mov_A };
        }

        if ((instruction[1] & mod_mask == 0b00000000 and instruction[1] & rm_mask != 0b00000110) or instruction[1] & mod_mask == 0b11000000) {
            return .{ .bytes_needed = 2, .instruction_type = instructiontype.mov_A };
        }

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
        return disassemblererror.unhandled_instruction;
    }
}
