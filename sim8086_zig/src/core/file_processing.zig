const std = @import("std");

fn binaryArrayFromByteArray(byteArray: []u8) ![]u8 {
    std.debug.assert(byteArray.len <= 64);
    std.debug.assert(byteArray.len >= 0);

    const stderr = std.io.getStdErr().writer();
    var buffer: [64]u8 = undefined;

    const bufPrint = try std.fmt.bufPrint(&buffer, "{b}", .{byteArray[0..16]});

    if (@TypeOf(bufPrint) == std.fmt.BufPrintError) {
        try stderr.print("Error printing formatted binary to buffer.", .{});
        // TODO: Make this an error enum
        return error{binaryFromByteError};
    } else {
        return bufPrint;
    }
}

pub fn binaryArrayFromCompiledAsm(listingFile: std.fs.File) ![]u8 {
    const stderr = std.io.getStdErr().writer();

    var buffered = std.io.bufferedReader(listingFile.reader());
    var bufreader = buffered.reader();

    // TODO: Replace with allocator that takes file size and assigns that
    var buffer: [64]u8 = undefined;
    @memset(buffer[0..], 0);

    // TODO: Figure out what type of error this returns and how to put it in an if statement
    _ = try bufreader.readAll(buffer[0..]);

    const binaryArray = try binaryArrayFromByteArray(buffer[0..]);

    // TODO: use enum
    if (@TypeOf(binaryArray) == error{binaryFromByteError}) {
        stderr.print("Could not parse bytes as binary", .{});
        // TOOD: Error enum
        return error{binaryFromAsmError};
    } else {
        return binaryArray;
    }
}
