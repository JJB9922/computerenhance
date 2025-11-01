const std = @import("std");
const is = @import("instruction_set.zig");
const opcode = @import("instruction_set.zig").opcode;

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

        opcode.arithmetic => return "arithmetic",
    }
}

pub fn opcode_from_string(s: []const u8) !opcode {
    if (std.mem.eql(u8, s, "nop")) return opcode.nop;
    if (std.mem.eql(u8, s, "mov")) return opcode.mov;
    if (std.mem.eql(u8, s, "add")) return opcode.add;
    if (std.mem.eql(u8, s, "sub")) return opcode.sub;
    if (std.mem.eql(u8, s, "cmp")) return opcode.cmp;
    if (std.mem.eql(u8, s, "jnz")) return opcode.jnz;
    if (std.mem.eql(u8, s, "je")) return opcode.je;
    if (std.mem.eql(u8, s, "jl")) return opcode.jl;
    if (std.mem.eql(u8, s, "jle")) return opcode.jle;
    if (std.mem.eql(u8, s, "jb")) return opcode.jb;
    if (std.mem.eql(u8, s, "jbe")) return opcode.jbe;
    if (std.mem.eql(u8, s, "jp")) return opcode.jp;
    if (std.mem.eql(u8, s, "jo")) return opcode.jo;
    if (std.mem.eql(u8, s, "js")) return opcode.js;
    if (std.mem.eql(u8, s, "jne")) return opcode.jne;
    if (std.mem.eql(u8, s, "jnl")) return opcode.jnl;
    if (std.mem.eql(u8, s, "jg")) return opcode.jg;
    if (std.mem.eql(u8, s, "jnb")) return opcode.jnb;
    if (std.mem.eql(u8, s, "ja")) return opcode.ja;
    if (std.mem.eql(u8, s, "jnp")) return opcode.jnp;
    if (std.mem.eql(u8, s, "jno")) return opcode.jno;
    if (std.mem.eql(u8, s, "jns")) return opcode.jns;
    if (std.mem.eql(u8, s, "loop")) return opcode.loop;
    if (std.mem.eql(u8, s, "loopz")) return opcode.loopz;
    if (std.mem.eql(u8, s, "loopnz")) return opcode.loopnz;
    if (std.mem.eql(u8, s, "jcxz")) return opcode.jcxz;

    return error.UnknownOpcode;
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

pub fn string_from_rm_bits(allocator: std.mem.Allocator, rm: u8, mod: u8, displacement: u16) ![]const u8 {
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

pub fn extract_field(data: []u8, field_loc: is.FieldLoc) u8 {
    const byte = data[field_loc.byte_index];
    const masked_byte = byte & field_loc.bit_mask;
    return masked_byte >> field_loc.bit_start;
}
