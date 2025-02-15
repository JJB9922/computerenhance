const std = @import("std");

pub fn instructionFromBinaryOpcode(opcode: u8) ![]const u8 {
    if (opcode == 0b10001001) {
        return "mov";
    }
    return "";
}
