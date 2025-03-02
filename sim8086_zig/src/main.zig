const std = @import("std");
const fp = @import("./core/file_processing.zig");
const is = @import("./core/instruction_set.zig");
const d = @import("./core/disassembler.zig");
const s = @import("./core/simulator.zig");

// Program Start
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stderr = std.io.getStdErr().writer();
    var simMode: bool = false;

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        try stderr.print("Expected: ./sim8086_zig [-sim or -dis] {{listing binary}}\n", .{});
        return;
    }

    if (args.len == 3) {
        if (std.mem.eql(u8, args[1], "-sim")) {
            simMode = true;
        }
    }

    var listing_file = std.fs.cwd().openFile(args[2], .{}) catch |err| {
        try stderr.print("Could not open specified file\n", .{});
        return err;
    };

    defer listing_file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const binary_from_compiled_asm = fp.binary_array_from_compiled_asm(listing_file, allocator) catch |err| {
        try stderr.print("Could not get binary from asm file.", .{});
        return err;
    };

    if (!simMode) {
        try stdout.print("bits 16\n\n", .{});
    }

    var register_state: s.registers = s.registers{};

    var binary_pointer: u8 = 0;

    for (0..binary_from_compiled_asm.len - 1) |_| {
        // EOF
        if (binary_pointer >= binary_from_compiled_asm.len) {
            break;
        }

        const immediate: []u8 = binary_from_compiled_asm[binary_pointer .. binary_pointer + 2];

        var instruction_ctx = try d.instruction_ctx_from_immediate(immediate);

        instruction_ctx.address = binary_pointer;

        const instruction = try d.parse_instruction_to_string(allocator, binary_from_compiled_asm[binary_pointer .. binary_pointer + instruction_ctx.size], instruction_ctx);

        if (!simMode) {
            try stdout.print("{s}\n", .{instruction});
        } else {
            register_state = try s.instruction_handler(instruction, register_state);
        }

        binary_pointer += instruction_ctx.size;
    }

    if (simMode) {
        try s.print_register_state(register_state);
    }
}
