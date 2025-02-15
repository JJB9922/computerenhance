const std = @import("std");

fn BinaryStringFromCompiledAsm() !void {
    var file = try std.fs.cwd().openFile("./listings/listing37.asm", .{});
    defer file.close();

    var buffered = std.io.bufferedReader(file.reader());
    var bufreader = buffered.reader();

    var buffer: [1000]u8 = undefined;
    @memset(buffer[0..], 0);

    _ = try bufreader.readAll(buffer[0..]);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{buffer});
}

// Program Start
pub fn main() !void {
    _ = try BinaryStringFromCompiledAsm();
}
