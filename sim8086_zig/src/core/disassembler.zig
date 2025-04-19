const std = @import("std");
const is = @import("./instruction_set.zig");
const ph = @import("./parsing_helpers.zig");

pub fn instruction_ctx_from_immediate(immediate: []u8) !is.instruction {
    var instruction = is.instruction{};

    for (is.instructions) |inst| {
        if ((immediate[0] & inst.opcode_mask) == inst.opcode_bits) {
            instruction = inst;
        }
    }

    var mod: u8 = 0;
    var w: u8 = 0;

    if (instruction.mod_loc != null) {
        instruction.size += 1;
        mod = ph.extract_field(immediate, instruction.mod_loc.?);

        switch (mod) {
            0b00 => {
                const rm = ph.extract_field(immediate, instruction.rm_loc.?);
                if (rm == 0b110) instruction.size += 2;
            },
            0b01 => instruction.size += 1,
            0b10 => instruction.size += 2,
            else => {},
        }
    }

    if (instruction.w_loc != null) {
        w = ph.extract_field(immediate, instruction.w_loc.?);
        if (w == 1) {
            instruction.w_on = true;
            if (instruction.data_if_w == true) {
                instruction.size += 1;
            }

            if (instruction.data_if_sw == true) {
                const s = ph.extract_field(immediate, instruction.s_loc.?);
                if (s == 0) {
                    instruction.size += 1;
                }
            }
        }
    }

    if (instruction.data_low_loc != null or instruction.ip_inc8_loc != null) {
        instruction.size += 1;
    }

    return instruction;
}

pub fn parse_instruction_to_string(allocator: std.mem.Allocator, binary: []u8, instruction: *is.instruction) ![]const u8 {
    var opcode = try ph.string_from_opcode(instruction.opcode_id);
    var mod: u8 = 0b00;
    var reg: []const u8 = "";
    var rm: []const u8 = "";
    var d: u8 = 0;

    if (instruction.mod_loc != null) {
        mod = ph.extract_field(binary, instruction.mod_loc.?);
    }

    if (instruction.reg_loc != null) {
        const regBits: u8 = ph.extract_field(binary, instruction.reg_loc.?);
        reg = try ph.string_from_reg_bits(regBits, instruction.w_on.?);
    }

    if (instruction.rm_loc != null) {
        const rmBits: u8 = ph.extract_field(binary, instruction.rm_loc.?);

        if (mod == 0b00) {
            if (rmBits == 0b110) {
                const direct_address: i16 = (@as(i16, binary[3]) << 8) | (binary[2]);
                rm = try ph.string_from_rm_bits(allocator, rmBits, mod, direct_address);
            } else {
                rm = try ph.string_from_rm_bits(allocator, rmBits, mod, 0);
            }
        }

        if (mod == 0b11) {
            rm = try ph.string_from_reg_bits(rmBits, instruction.w_on.?);
        }

        if (mod == 0b01) {
            rm = try ph.string_from_rm_bits(allocator, rmBits, mod, binary[2]);
        }

        if (mod == 0b10) {
            const displacement: i16 = (@as(i16, binary[3]) << 8) | (binary[2]);
            rm = try ph.string_from_rm_bits(allocator, rmBits, mod, displacement);
        }
    }

    if (instruction.arithmetic_id_loc != null) {
        const arithmetic_id = ph.extract_field(binary, instruction.arithmetic_id_loc.?);
        opcode = try ph.arithmetic_operator_from_id_bits(arithmetic_id);
    }

    if (instruction.d_loc != null) {
        d = ph.extract_field(binary, instruction.d_loc.?);
    }

    if (instruction.imm_to_acc.?) {
        reg = if (instruction.w_on.?) "ax" else "al";
        rm = if (instruction.w_on.?) "ax" else "al";
    }

    if (instruction.data_low_loc != null) {
        if (instruction.mod_loc != null) {
            switch (mod) {
                0b00, 0b11 => {
                    instruction.data_low_loc.?.byte_index -= 2;
                    instruction.data_high_loc.?.byte_index -= 2;
                },
                0b01 => {
                    instruction.disp_low_loc.?.byte_index -= 1;
                    instruction.data_high_loc.?.byte_index -= 1;
                },
                else => {},
            }
        }

        var imm_data: i16 = 0;
        const lowData = ph.extract_field(binary, instruction.data_low_loc.?);
        imm_data = @as(i8, @bitCast(lowData));

        if (instruction.data_if_w.? and instruction.w_on.? and instruction.data_high_loc != null) {
            const highData = ph.extract_field(binary, instruction.data_high_loc.?);

            imm_data = @as(i16, highData) << 8 | @as(i16, lowData);
        }

        if (instruction.reg_loc != null) {
            instruction.destination = reg;
            instruction.source_int = imm_data;
            return std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ opcode, reg, imm_data });
        }

        instruction.destination = rm;
        instruction.source_int = imm_data;
        return std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ opcode, rm, imm_data });
    }

    if (instruction.ip_inc8_loc != null) {
        const displacement: i16 = binary[1];

        const target_address = instruction.address + @as(i16, @intCast(binary.len)) + displacement;
        return try std.fmt.allocPrint(allocator, "{s} 0x{x}", .{ opcode, target_address });
    }

    if (d == 1) {
        instruction.destination = reg;
        instruction.source_reg = rm;

        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ opcode, reg, rm });
    } else {
        instruction.destination = rm;
        instruction.source_reg = reg;

        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ opcode, rm, reg });
    }
}
