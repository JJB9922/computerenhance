const std = @import("std");
const is = @import("./instruction_set.zig");
const ph = @import("./parsing_helpers.zig");

pub fn instruction_ctx_from_immediate(immediate: []u8) !is.instruction {
    var instruction = is.instruction{};

    for (is.instructions) |inst| {
        if ((immediate[0] & inst.opcode_mask) == inst.opcode_bits) {
            instruction = inst;
            break;
        }
    }

    var mod: u8 = 0;
    var w: u8 = 0;
    var s: u8 = 0;

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
                s = ph.extract_field(immediate, instruction.s_loc.?);
                if (s == 0) {
                    instruction.size += 1;
                }
            }
        }
    }

    if (instruction.s_loc != null) {
        s = ph.extract_field(immediate, instruction.s_loc.?);
        if (s == 1) {
            instruction.s_on = true;
        }
    }

    if (instruction.data_low_loc != null or instruction.ip_inc8_loc != null) {
        instruction.size += 1;
    }

    return instruction;
}

fn maybe_add_word_prefix(allocator: std.mem.Allocator, text: []const u8, is_memory: bool, w_on: bool) ![]const u8 {
    if (is_memory and w_on) {
        return std.fmt.allocPrint(allocator, "word {s}", .{text});
    }
    return text;
}

pub fn parse_instruction_to_string(allocator: std.mem.Allocator, binary: []u8, instruction: *is.instruction) ![]const u8 {
    var opcode = try ph.string_from_opcode(instruction.opcode_id);
    var mod: u8 = 0b00;
    var reg: []const u8 = "";
    var rm: []const u8 = "";
    var d: u8 = 0;

    var cursor: usize = 1;

    if (instruction.mod_loc != null) {
        mod = ph.extract_field(binary, instruction.mod_loc.?);
        cursor += 1;
    }

    if (instruction.reg_loc != null) {
        const regBits: u8 = ph.extract_field(binary, instruction.reg_loc.?);
        reg = try ph.string_from_reg_bits(regBits, instruction.w_on.?);
    }

    if (instruction.rm_loc != null) {
        const rmBits: u8 = ph.extract_field(binary, instruction.rm_loc.?);

        if (mod == 0b00) {
            if (rmBits == 0b110) {
                const direct_address: u16 = (@as(u16, binary[cursor + 1]) << 8) | binary[cursor];
                rm = try ph.string_from_rm_bits(allocator, rmBits, mod, direct_address);
                cursor += 2;
                instruction.*.is_memory = true;
            } else {
                rm = try ph.string_from_rm_bits(allocator, rmBits, mod, 0);
                instruction.*.is_memory = true;
            }
        } else if (mod == 0b01) {
            const disp: u8 = binary[cursor];
            rm = try ph.string_from_rm_bits(allocator, rmBits, mod, disp);
            cursor += 1;
            instruction.*.is_memory = true;
        } else if (mod == 0b10) {
            const disp: u16 = (@as(u16, binary[cursor + 1]) << 8) | binary[cursor];
            rm = try ph.string_from_rm_bits(allocator, rmBits, mod, disp);
            cursor += 2;
            instruction.*.is_memory = true;
        } else if (mod == 0b11) {
            rm = try ph.string_from_reg_bits(rmBits, instruction.w_on.?);
        }
    }

    if (instruction.arithmetic_id_loc != null) {
        const arithmetic_id = ph.extract_field(binary, instruction.arithmetic_id_loc.?);
        opcode = try ph.arithmetic_operator_from_id_bits(arithmetic_id);
        instruction.opcode_id = try ph.opcode_from_string(opcode);
    }

    if (instruction.d_loc != null) {
        d = ph.extract_field(binary, instruction.d_loc.?);
    }

    if (instruction.imm_to_acc.?) {
        reg = if (instruction.w_on.?) "ax" else "al";
        rm = if (instruction.w_on.?) "ax" else "al";
    }

    if (instruction.data_low_loc != null) {
        var imm_data: u16 = 0;
        const lowData = binary[cursor];

        if (instruction.w_on.? and !instruction.s_on.?) {
            const highData = binary[cursor + 1];
            imm_data = (@as(u16, highData) << 8) | lowData;
            cursor += 2;
        } else {
            imm_data = lowData;
            cursor += 1;
        }

        if (instruction.reg_loc != null) {
            reg = try maybe_add_word_prefix(allocator, reg, false, instruction.w_on.?);
            instruction.destination_reg = reg;
            instruction.source_int = imm_data;
            return std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ opcode, reg, imm_data });
        }

        rm = try maybe_add_word_prefix(allocator, rm, instruction.is_memory, instruction.w_on.?);
        instruction.destination_reg = rm;
        instruction.source_int = imm_data;
        return std.fmt.allocPrint(allocator, "{s} {s}, {d}", .{ opcode, rm, imm_data });
    }

    if (instruction.ip_inc8_loc != null) {
        const raw: u8 = binary[cursor];
        const disp: i8 = @bitCast(raw);
        const next_ip: u16 = instruction.address + instruction.size;
        const target: i16 = @as(i16, @bitCast(next_ip)) + @as(i16, @intCast(disp));

        instruction.jump_addr = @bitCast(target);
        return try std.fmt.allocPrint(allocator, "{s} 0x{x}", .{ opcode, target });
    }

    reg = try maybe_add_word_prefix(allocator, reg, false, instruction.w_on.?);
    rm = try maybe_add_word_prefix(allocator, rm, instruction.is_memory, instruction.w_on.?);

    if (d == 1) {
        instruction.destination_reg = reg;
        instruction.source_reg = rm;
        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ opcode, reg, rm });
    } else {
        instruction.destination_reg = rm;
        instruction.source_reg = reg;
        return std.fmt.allocPrint(allocator, "{s} {s}, {s}", .{ opcode, rm, reg });
    }
}
