const std = @import("std");
const is = @import("./instruction_set.zig");

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
        mod = extract_field(immediate, instruction.mod_loc.?);

        switch (mod) {
            0b01 => instruction.size += 1,
            0b10 => instruction.size += 2,
            else => {},
        }
    }

    if (instruction.w_loc != null) {
        w = extract_field(immediate, instruction.w_loc.?);
        if (w == 1) {
            instruction.w_on = true;
            if (instruction.data_if_w == true) {
                instruction.size += 1;
            }
        }
    }

    if (instruction.data_low_loc != null) {
        instruction.size += 1;
    }

    return instruction;
}

pub fn parse_instruction_to_string(allocator: std.mem.Allocator, binary: []u8, instruction: is.instruction) ![]const u8 {
    const opcode = try is.string_from_opcode(instruction.opcode_id);
    var mod: u8 = 0b00;
    var reg: []const u8 = "";
    var rm: []const u8 = "";
    var d: u8 = 0;

    if (instruction.mod_loc != null) {
        mod = extract_field(binary, instruction.mod_loc.?);
    }

    if (instruction.reg_loc != null) {
        const regBits: u8 = extract_field(binary, instruction.reg_loc.?);
        reg = try is.string_from_reg_bits(regBits, instruction.w_on.?);
    }

    if (instruction.rm_loc != null) {
        const rmBits: u8 = extract_field(binary, instruction.rm_loc.?);

        if (mod == 0b00) {
            rm = try is.string_from_rm_bits(allocator, rmBits, mod, 0);
        }

        if (mod == 0b11) {
            rm = try is.string_from_reg_bits(rmBits, instruction.w_on.?);
        }

        if (mod == 0b01) {
            rm = try is.string_from_rm_bits(allocator, rmBits, mod, binary[2]);
        }

        if (mod == 0b10) {
            const displacement: i16 = (@as(i16, binary[3]) << 8) | (binary[2]);
            rm = try is.string_from_rm_bits(allocator, rmBits, mod, displacement);
        }
    }

    if (instruction.data_low_loc != null) {
        var imm_data: i16 = 0;
        const lowData = extract_field(binary, instruction.data_low_loc.?);
        imm_data = @as(i8, @bitCast(lowData));

        if (instruction.data_if_w.? and instruction.w_on.? and instruction.data_high_loc != null) {
            const highData = extract_field(binary, instruction.data_high_loc.?);

            imm_data = @as(i16, highData) << 8 | @as(i16, lowData);
        }

        return std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ opcode, reg, imm_data });
    }

    if (instruction.d_loc != null) {
        d = extract_field(binary, instruction.d_loc.?);
    }

    if (d == 1) {
        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ opcode, reg, rm });
    } else {
        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ opcode, rm, reg });
    }
}

fn extract_field(data: []u8, field_loc: is.FieldLoc) u8 {
    const byte = data[field_loc.byte_index];
    const masked_byte = byte & field_loc.bit_mask;
    return masked_byte >> field_loc.bit_start;
}
