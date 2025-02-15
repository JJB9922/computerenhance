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

    const binaryFromAsmResult = try fp.binaryArrayFromCompiledAsm(listingFile);

    if (@TypeOf(binaryFromAsmResult) == fp.FileProcessingError) {
        try stderr.print("Could not parse asm binary.\n", .{});
        return binaryFromAsmResult;
    }

    try stdout.print("Binary from file:\n{s}\n", .{binaryFromAsmResult});

    try stdout.print("Instructions in file:\n", .{});
    const testVal = ds.instructionFromBinaryOpcode(binaryFromAsmResult[0]);
    try stdout.print("{s}", .{testVal});
}
