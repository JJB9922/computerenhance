const std = @import("std");
const fp = @import("./core/file_processing.zig");
const ds = @import("./core/disassembler.zig");

// Program Start
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        try stderr.print("Expected: ./sim8086_zig {{listing binary}}\n", .{});
        return;
    }

    var listingFile = std.fs.cwd().openFile(args[1], .{}) catch |err| {
        try stderr.print("Could not open specified file\n", .{});
        return err;
    };

    defer listingFile.close();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const binaryFromAsmResult = fp.binaryArrayFromCompiledAsm(listingFile, allocator) catch |err| {
        try stderr.print("Could not get binary from compiled asm.", .{});
        return err;
    };

    defer allocator.free(binaryFromAsmResult);

    try stdout.print("Binary from file:\n{b}\n\n", .{binaryFromAsmResult});

    try stdout.print("Instructions:\n\nbits 16\n\n", .{});
    for (0..binaryFromAsmResult.len - 1) |i| {
        const instruction = try ds.instructionFromBinaryOpcodeArray(allocator, binaryFromAsmResult[i .. i + 2]);
        try stdout.print("{s}", .{instruction});
        allocator.free(instruction);
    }
}
