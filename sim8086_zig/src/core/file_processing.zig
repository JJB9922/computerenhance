const std = @import("std");

pub const FileProcessingError = error{ BinaryFromByteError, BinaryFromAsmError, FileReadAllError };

fn binaryArrayFromByteArray(byteArray: []u8) ![]u8 {
    std.debug.assert(byteArray.len > 0);

    const stderr = std.io.getStdErr().writer();

    // TODO: consider
    var buffer: [4096]u8 = undefined;
    const bufPrintResult = std.fmt.bufPrint(&buffer, "{b}", .{byteArray[0..]}) catch {
        try stderr.print("Error printing formatted binary to buffer.\n", .{});
        return FileProcessingError.BinaryFromByteError;
    };

    return bufPrintResult;
}

pub fn binaryArrayFromCompiledAsm(listingFile: std.fs.File) ![]u8 {
    const stderr = std.io.getStdErr().writer();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const sizeLimit = std.math.maxInt(u32);
    var buffer = listingFile.readToEndAlloc(allocator, sizeLimit) catch |err| {
        try stderr.print("Unable to read bytes from file into buffer.\n", .{});
        return err;
    };

    const binaryFromBytesResult = try binaryArrayFromByteArray(buffer[0..]);

    if (@TypeOf(binaryFromBytesResult) == FileProcessingError) {
        try stderr.print("Could not parse bytes as binary.\n", .{});
        return FileProcessingError.BinaryFromAsmError;
    }

    return binaryFromBytesResult;
}
