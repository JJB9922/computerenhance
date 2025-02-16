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

    var listing_file = std.fs.cwd().openFile(args[1], .{}) catch |err| {
        try stderr.print("Could not open specified file\n", .{});
        return err;
    };

    defer listing_file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer _ = arena.deinit();
    const allocator = arena.allocator();

    const binary_from_asm_result = fp.binary_array_from_compiled_asm(listing_file, allocator) catch |err| {
        try stderr.print("Could not get binary from compiled asm.", .{});
        return err;
    };

    defer allocator.free(binary_from_asm_result);

    try stdout.print("Binary from file:\n{b:0>8}\n\n", .{binary_from_asm_result});

    var binary_pointer: u8 = 0;

    try stdout.print("Instructions:\n\nbits 16\n\n", .{});

    for (0..binary_from_asm_result.len - 1) |_| {
        if (binary_pointer >= binary_from_asm_result.len) {
            try stdout.print("EOF reached.\n", .{});
            break;
        }

        const bytes_needed_and_instruction_type = ds.get_bytes_needed_and_instruction_type(binary_from_asm_result[binary_pointer .. binary_pointer + 2]) catch |err| {
            try stderr.print("Unhandled instruction encountered.\n", .{});
            return err;
        };

        if (bytes_needed_and_instruction_type.bytes_needed == 0) {
            try stdout.print("EOF reached.\n", .{});
            break;
        }

        const instruction = try ds.parse_instruction(allocator, bytes_needed_and_instruction_type.instruction_type, binary_from_asm_result[binary_pointer .. binary_pointer + bytes_needed_and_instruction_type.bytes_needed]);
        try stdout.print("{s}", .{instruction});
        allocator.free(instruction);
        binary_pointer += bytes_needed_and_instruction_type.bytes_needed;
    }
}
