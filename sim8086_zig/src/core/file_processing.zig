const std = @import("std");

pub fn binary_array_from_compiled_asm(listingFile: std.fs.File, allocator: std.mem.Allocator) ![]u8 {
    const stderr = std.io.getStdErr().writer();

    const size_limit = std.math.maxInt(u32);
    const buffer = listingFile.readToEndAlloc(allocator, size_limit) catch |err| {
        try stderr.print("Unable to read bytes from file into buffer.\n", .{});
        return err;
    };

    return buffer;
}
