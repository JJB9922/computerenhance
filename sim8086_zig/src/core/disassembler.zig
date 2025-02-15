const std = @import("std");

pub fn instructionFromBinaryOpcode(opcode: u8) ![]const u8 {
    // TODO: Separate out
    const mask = 0b11111100;

    if ((opcode & mask) == 0b10001000) {
        return "mov";
    }

    return "";
}
