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

    var binary_pointer: u8 = 0;
    const registers = s.registers{
        .al = 0,
        .cl = 0,
        .dl = 0,
        .bl = 0,
        .ah = 0,
        .ch = 0,
        .dh = 0,
        .bh = 0,

        .ax = 0,
        .cx = 0,
        .dx = 0,
        .bx = 0,

        .sp = 0,
        .bp = 0,
        .si = 0,
        .di = 0,
    };

    for (0..binary_from_compiled_asm.len - 1) |_| {

        // EOF
        if (binary_pointer >= binary_from_compiled_asm.len) {
            break;
        }

        const immediate: []u8 = binary_from_compiled_asm[binary_pointer .. binary_pointer + 2];

        var instruction_ctx = try d.instruction_ctx_from_immediate(immediate);

        instruction_ctx.address = binary_pointer;
        instruction_ctx.binary = binary_from_compiled_asm[binary_pointer .. binary_pointer + instruction_ctx.size];

        const instruction = try d.parse_instruction_to_string(allocator, binary_from_compiled_asm[binary_pointer .. binary_pointer + instruction_ctx.size], instruction_ctx);

        if (!simMode) {
            try stdout.print("{s}\n", .{instruction});
        } else {
            try s.simulate_instructions(registers, instruction_ctx);
        }

        binary_pointer += instruction_ctx.size;
    }

    try s.print_registers(registers);
}
