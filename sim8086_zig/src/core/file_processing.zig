const std = @import("std");

const FileProcessingError = error{ BinaryFromByteError, BinaryFromAsmError, FileReadAllError };

fn binaryArrayFromByteArray(byteArray: []u8) ![]u8 {
    std.debug.assert(byteArray.len <= 64);
    std.debug.assert(byteArray.len >= 0);

    const stderr = std.io.getStdErr().writer();
    var buffer: [64]u8 = undefined;

    const bufPrintResult = try std.fmt.bufPrint(&buffer, "{b}", .{byteArray[0..16]});

    if (@TypeOf(bufPrintResult) == std.fmt.BufPrintError) {
        try stderr.print("Error printing formatted binary to buffer: {s}", .{bufPrintResult});
        return FileProcessingError.BinaryFromByteError;
    } else {
        return bufPrintResult;
    }
}

pub fn binaryArrayFromCompiledAsm(listingFile: std.fs.File) ![]u8 {
    const stderr = std.io.getStdErr().writer();

    var buffered = std.io.bufferedReader(listingFile.reader());
    var bufreader = buffered.reader();

    // TODO: Replace with allocator that takes file size and assigns that
    var buffer: [64]u8 = undefined;
    @memset(buffer[0..], 0);

    const readBufferResult = try bufreader.readAll(buffer[0..]);

    if (@TypeOf(readBufferResult) != usize) {
        stderr.print("Unable to read bytes from file into buffer: {s}", .{readBufferResult});
        return FileProcessingError.BinaryFromAsmError;
    }

    const binaryFromBytesResult = try binaryArrayFromByteArray(buffer[0..]);

    if (@TypeOf(binaryFromBytesResult) == FileProcessingError) {
        stderr.print("Could not parse bytes as binary: {s}", .{binaryFromBytesResult});
        return FileProcessingError.BinaryFromAsmError;
    } else {
        return binaryFromBytesResult;
    }
}
