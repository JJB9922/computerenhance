const std = @import("std");

pub fn binaryArrayFromCompiledAsm(listingFile: std.fs.File, allocator: std.mem.Allocator) ![]u8 {
    const stderr = std.io.getStdErr().writer();

    const sizeLimit = std.math.maxInt(u32);
    const buffer = listingFile.readToEndAlloc(allocator, sizeLimit) catch |err| {
        try stderr.print("Unable to read bytes from file into buffer.\n", .{});
        return err;
    };

    return buffer;
}
