const std = @import("std");

pub const FieldLoc = struct {
    byte_index: u8,
    bit_mask: u8,
    // note endianness
    bit_start: u3 = 0,
};

pub const instruction = struct {
    size: u8 = 1,
    address: u32 = 0x00,
    opcode_bits: u8 = 0b00000000,
    opcode_mask: u8 = 0b00000000,
    opcode_id: opcode = opcode.nop,

    // Field locations
    d_loc: ?FieldLoc = null,
    w_loc: ?FieldLoc = null,
    s_loc: ?FieldLoc = null,
    v_loc: ?FieldLoc = null,
    z_loc: ?FieldLoc = null,
    mod_loc: ?FieldLoc = null,
    reg_loc: ?FieldLoc = null,
    rm_loc: ?FieldLoc = null,
    disp_low_loc: ?FieldLoc = null,
    disp_high_loc: ?FieldLoc = null,
    data_low_loc: ?FieldLoc = null,
    data_high_loc: ?FieldLoc = null,
    sr_loc: ?FieldLoc = null,

    data_if_w: ?bool = false,
    w_on: ?bool = false,
};

pub const instructions = [_]instruction{instruction{
    .opcode_id = opcode.mov,
    .opcode_bits = 0b10001000,
    .opcode_mask = 0b11111100,

    .d_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
    .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
    .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
    .reg_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
    .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
    .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
    .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
}};

pub const opcode = enum {
    nop,
    mov,
};

pub fn string_from_opcode(op: opcode) ![]const u8 {
    switch (op) {
        opcode.nop => return "nop",
        opcode.mov => return "mov",
    }
}

pub fn string_from_reg_bits(reg: u8, w: bool) ![]const u8 {
    switch (reg) {
        0b000 => return if (w) "ax" else "al",
        0b001 => return if (w) "cx" else "cl",
        0b010 => return if (w) "dx" else "dl",
        0b011 => return if (w) "bx" else "bl",
        0b100 => return if (w) "sp" else "ah",
        0b101 => return if (w) "bp" else "ch",
        0b110 => return if (w) "si" else "dh",
        0b111 => return if (w) "di" else "bh",
        else => return "??",
    }
}
