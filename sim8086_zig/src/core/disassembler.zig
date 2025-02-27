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
        mod = extract_field(immediate, instruction.mod_loc.?);

        switch (mod) {
            0b01 => instruction.size += 1,
            0b11 => instruction.size += 2,
            else => instruction.size += 0,
        }
    }

    if (instruction.w_loc != null) {
        w = extract_field(immediate, instruction.w_loc.?);
        try std.io.getStdOut().writer().print("{b:0>1}", .{w});
        if (w == 1) {
            instruction.w_on = true;
            if (instruction.data_if_w == true) {
                instruction.size += 1;
            }
        }
    }

    return instruction;
}

pub fn parse_instruction_to_string(allocator: std.mem.Allocator, binary: []u8, instruction: is.instruction) ![]const u8 {
    const opcode = try is.string_from_opcode(instruction.opcode_id);
    var reg: []const u8 = "";

    if (instruction.reg_loc != null) {
        const regBits: u8 = extract_field(binary, instruction.reg_loc.?);
        reg = try is.string_from_reg_bits(regBits, instruction.w_on.?);
    }

    return std.fmt.allocPrint(allocator, "{s} ??, {s}", .{ opcode, reg });
}

fn extract_field(data: []u8, field_loc: is.FieldLoc) u8 {
    const byte = data[field_loc.byte_index];
    const masked_byte = byte & field_loc.bit_mask;
    return masked_byte >> field_loc.bit_start;
}
