const std = @import("std");
const fp = @import("./core/file_processing.zig");

// Program Start
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();

    var listingFile = try std.fs.cwd().openFile("./listings/listing37", .{});

    if (@TypeOf(listingFile) == std.fs.File.OpenError) {
        stderr.print("Could not open specified file", .{});
        return listingFile;
    }

    defer listingFile.close();

    // TODO: Get file as console args
    const binaryArray = try fp.binaryArrayFromCompiledAsm(listingFile);

    if (@TypeOf(binaryArray) == error{binaryFromAsmError}) {
        stderr.print("Could not parse asm binary", .{});
    }

    try stdout.print("Binary from file:\n{s}\n", .{binaryArray});
}
