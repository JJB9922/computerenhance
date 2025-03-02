const std = @import("std");

pub const FieldLoc = struct {
    byte_index: u8,
    bit_mask: u8,
    // note endianness
    bit_start: u3 = 0,
};

pub const instruction = struct {
    size: u8 = 1,
    address: i16 = 0x00,
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
    arithmetic_id_loc: ?FieldLoc = null,
    ip_inc8_loc: ?FieldLoc = null,

    data_if_w: ?bool = false,
    data_if_sw: ?bool = false,
    w_on: ?bool = false,
    imm_to_acc: ?bool = false,
};

pub const instructions = [_]instruction{
    instruction{
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
    },
    instruction{
        .opcode_id = opcode.mov,
        .opcode_bits = 0b11000110,
        .opcode_mask = 0b11111110,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
        .data_low_loc = .{ .byte_index = 4, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 5, .bit_mask = 0b11111111 },
        .data_if_w = true,
    },
    instruction{
        .opcode_id = opcode.mov,
        .opcode_bits = 0b10110000,
        .opcode_mask = 0b11110000,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00001000, .bit_start = 3 },
        .reg_loc = .{ .byte_index = 0, .bit_mask = 0b0000111, .bit_start = 0 },
        .data_low_loc = .{ .byte_index = 1, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .data_if_w = true,
    },
    instruction{
        .opcode_id = opcode.add,
        .opcode_bits = 0b00000000,
        .opcode_mask = 0b11111100,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .d_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .reg_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
    },
    instruction{
        .opcode_id = opcode.add,
        .opcode_bits = 0b10000000,
        .opcode_mask = 0b11111100,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .s_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
        .data_low_loc = .{ .byte_index = 4, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 5, .bit_mask = 0b11111111 },
        .data_if_sw = true,
        .arithmetic_id_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
    },
    instruction{
        .opcode_id = opcode.add,
        .opcode_bits = 0b00000100,
        .opcode_mask = 0b11111110,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .data_low_loc = .{ .byte_index = 1, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .data_if_w = true,
        .imm_to_acc = true,
    },
    instruction{
        .opcode_id = opcode.sub,
        .opcode_bits = 0b00101000,
        .opcode_mask = 0b11111100,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .d_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .reg_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
    },
    instruction{
        .opcode_id = opcode.sub,
        .opcode_bits = 0b10000000,
        .opcode_mask = 0b11111100,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .s_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
        .data_low_loc = .{ .byte_index = 4, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 5, .bit_mask = 0b11111111 },
        .data_if_sw = true,
        .arithmetic_id_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
    },
    instruction{
        .opcode_id = opcode.sub,
        .opcode_bits = 0b00101100,
        .opcode_mask = 0b11111110,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .data_low_loc = .{ .byte_index = 1, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .data_if_w = true,
        .imm_to_acc = true,
    },
    instruction{
        .opcode_id = opcode.cmp,
        .opcode_bits = 0b00111000,
        .opcode_mask = 0b11111100,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .d_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .reg_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
    },
    instruction{
        .opcode_id = opcode.cmp,
        .opcode_bits = 0b10000000,
        .opcode_mask = 0b11111100,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .s_loc = .{ .byte_index = 0, .bit_mask = 0b00000010, .bit_start = 1 },
        .mod_loc = .{ .byte_index = 1, .bit_mask = 0b11000000, .bit_start = 6 },
        .rm_loc = .{ .byte_index = 1, .bit_mask = 0b00000111, .bit_start = 0 },
        .disp_low_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .disp_high_loc = .{ .byte_index = 3, .bit_mask = 0b11111111 },
        .data_low_loc = .{ .byte_index = 4, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 5, .bit_mask = 0b11111111 },
        .data_if_sw = true,
        .arithmetic_id_loc = .{ .byte_index = 1, .bit_mask = 0b00111000, .bit_start = 3 },
    },
    instruction{
        .opcode_id = opcode.cmp,
        .opcode_bits = 0b00111100,
        .opcode_mask = 0b11111110,
        .w_loc = .{ .byte_index = 0, .bit_mask = 0b00000001, .bit_start = 0 },
        .data_low_loc = .{ .byte_index = 1, .bit_mask = 0b11111111 },
        .data_high_loc = .{ .byte_index = 2, .bit_mask = 0b11111111 },
        .imm_to_acc = true,
        .data_if_w = true,
    },
    instruction{
        .opcode_id = opcode.jnz,
        .opcode_bits = 0b01110101,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.je,
        .opcode_bits = 0b01110100,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },

    instruction{
        .opcode_id = opcode.jl,
        .opcode_bits = 0b01111100,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jle,
        .opcode_bits = 0b01111110,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jb,
        .opcode_bits = 0b01110010,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jbe,
        .opcode_bits = 0b01110110,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jp,
        .opcode_bits = 0b01111010,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jo,
        .opcode_bits = 0b01110000,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.js,
        .opcode_bits = 0b01111000,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jne,
        .opcode_bits = 0b01110101,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jnl,
        .opcode_bits = 0b01111101,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jg,
        .opcode_bits = 0b01111111,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jnb,
        .opcode_bits = 0b01110011,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.ja,
        .opcode_bits = 0b01110111,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jnp,
        .opcode_bits = 0b01111011,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jno,
        .opcode_bits = 0b01110001,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jns,
        .opcode_bits = 0b01111001,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.loop,
        .opcode_bits = 0b11100010,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.loopz,
        .opcode_bits = 0b11100001,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.loopnz,
        .opcode_bits = 0b11100000,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
    instruction{
        .opcode_id = opcode.jcxz,
        .opcode_bits = 0b11100011,
        .opcode_mask = 0b11111111,
        .ip_inc8_loc = .{ .byte_index = 1, .bit_mask = 0b11111111, .bit_start = 0 },
    },
};

pub const opcode = enum {
    nop,
    mov,
    add,
    sub,
    cmp,
    jnz,
    je,
    jl,
    jle,
    jb,
    jbe,
    jp,
    jo,
    js,
    jne,
    jnl,
    jg,
    jnb,
    ja,
    jnp,
    jno,
    jns,
    loop,
    loopz,
    loopnz,
    jcxz,
};

pub fn string_from_opcode(op: opcode) ![]const u8 {
    switch (op) {
        opcode.nop => return "nop",
        opcode.mov => return "mov",
        opcode.add => return "add",
        opcode.sub => return "sub",
        opcode.cmp => return "cmp",
        opcode.jnz => return "jnz",
        opcode.je => return "je",
        opcode.jl => return "jl",
        opcode.jle => return "jle",
        opcode.jb => return "jb",
        opcode.jbe => return "jbe",
        opcode.jp => return "jp",
        opcode.jo => return "jo",
        opcode.js => return "js",
        opcode.jne => return "jne",
        opcode.jnl => return "jnl",
        opcode.jg => return "jg",
        opcode.jnb => return "jnb",
        opcode.ja => return "ja",
        opcode.jnp => return "jnp",
        opcode.jno => return "jno",
        opcode.jns => return "jns",
        opcode.loop => return "loop",
        opcode.loopz => return "loopz",
        opcode.loopnz => return "loopnz",
        opcode.jcxz => return "jcxz",
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

pub fn string_from_rm_bits(allocator: std.mem.Allocator, rm: u8, mod: u8, displacement: i16) ![]const u8 {
    switch (mod) {
        0b00 => {
            switch (rm) {
                0b000 => return "[bx + si]",
                0b001 => return "[bx + di]",
                0b010 => return "[bp + si]",
                0b011 => return "[bp + di]",
                0b100 => return "[si]",
                0b101 => return "[di]",
                0b110 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[{d}]", .{displacement});
                    return ea;
                },
                0b111 => return "bx",
                else => return "??",
            }
        },
        0b01, 0b10 => {
            switch (rm) {
                0b000 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[bx + si + {d}]", .{displacement});
                    return ea;
                },
                0b001 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[bx + di + {d}]", .{displacement});
                    return ea;
                },
                0b010 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[bp + si + {d}]", .{displacement});
                    return ea;
                },
                0b011 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[bp + di + {d}]", .{displacement});
                    return ea;
                },
                0b100 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[si + {d}]", .{displacement});
                    return ea;
                },
                0b101 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[di + {d}]", .{displacement});
                    return ea;
                },
                0b110 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[bp + {d}]", .{displacement});
                    return ea;
                },
                0b111 => {
                    const ea: []const u8 = try std.fmt.allocPrint(allocator, "[bx + {d}]", .{displacement});
                    return ea;
                },
                else => return "??",
            }
        },
        else => return "??",
    }
}

pub fn arithmetic_operator_from_id_bits(arithmetic_id: u8) ![]const u8 {
    switch (arithmetic_id) {
        0b000 => return "add",
        0b010 => return "adc",
        0b101 => return "sub",
        0b011 => return "sbb",
        0b111 => return "cmp",
        else => return "???",
    }
}
