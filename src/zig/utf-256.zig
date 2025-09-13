const std = @import("std");

// Prints the help message to stderr.
fn print_help(progname: []const u8) void {
    std.debug.print(
        \\
        \\UTF-256 Encoder/Decoder
        \\
        \\Usage:
        \\  {s} -e UTF-8_FILE -o OUTPUT_FILE
        \\  {s} -d UTF-256_FILE -o OUTPUT_FILE
        \\
    , .{progname, progname});
}

// Encodes a UTF-8 byte slice into a "UTF-256" byte slice, where each bit is a byte (0x00 or 0xFF).
fn utf8_to_utf256(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const output_len = input.len * 8;
    var output = try allocator.alloc(u8, output_len);
    
    for (input, 0..) |byte, byte_idx| {
        for (0..8) |j| {
            const i: u3 = @intCast(7 - j);
            const bit = (byte >> i) & 1;
            const out_byte: u8 = if (bit == 1) 0xFF else 0x00;
            output[byte_idx * 8 + j] = out_byte;
        }
    }

    return output;
}

// Decodes a "UTF-256" byte slice back into a UTF-8 byte slice.
fn utf256_to_utf8(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    if (input.len % 8 != 0) {
        return error.InvalidInputLength;
    }

    const output_len = input.len / 8;
    var output = try allocator.alloc(u8, output_len);
    
    for (0..output_len) |i| {
        var byte: u8 = 0;
        for (0..8) |j| {
            byte <<= 1;
            switch (input[i * 8 + j]) {
                0x00 => {},
                0xFF => byte |= 1,
                else => return error.InvalidByte,
            }
        }
        output[i] = byte;
    }

    return output;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 5) {
        print_help(args[0]);
        return error.InvalidUsage;
    }

    var encode_file: ?[]const u8 = null;
    var decode_file: ?[]const u8 = null;
    var output_file: ?[]const u8 = null;

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (std.mem.eql(u8, arg, "-e")) {
            if (encode_file != null or i + 1 >= args.len) {
                print_help(args[0]);
                return error.InvalidUsage;
            }
            encode_file = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "-d")) {
            if (decode_file != null or i + 1 >= args.len) {
                print_help(args[0]);
                return error.InvalidUsage;
            }
            decode_file = args[i + 1];
            i += 1;
        } else if (std.mem.eql(u8, arg, "-o")) {
            if (output_file != null or i + 1 >= args.len) {
                print_help(args[0]);
                return error.InvalidUsage;
            }
            output_file = args[i + 1];
            i += 1;
        } else {
            print_help(args[0]);
            return error.InvalidUsage;
        }
    }

    if (encode_file != null and decode_file != null) {
        std.debug.print("Error: Must use exactly one of -e or -d.\n", .{});
        print_help(args[0]);
        return error.InvalidUsage;
    }
    if (encode_file == null and decode_file == null) {
        std.debug.print("Error: Must use exactly one of -e or -d.\n", .{});
        print_help(args[0]);
        return error.InvalidUsage;
    }

    if (output_file == null) {
        std.debug.print("Error: Output file (-o) is required.\n", .{});
        print_help(args[0]);
        return error.InvalidUsage;
    }

    const output_path = output_file.?;
    
    if (encode_file) |input_path| {
        const data = try std.fs.cwd().readFileAlloc(allocator, input_path, 1024 * 1024);
        defer allocator.free(data);
        const encoded = try utf8_to_utf256(allocator, data);
        defer allocator.free(encoded);
        const file = try std.fs.cwd().createFile(output_path, .{});
        defer file.close();
        try file.writeAll(encoded);
    } else if (decode_file) |input_path| {
        const data = try std.fs.cwd().readFileAlloc(allocator, input_path, 1024 * 1024);
        defer allocator.free(data);
        const decoded = try utf256_to_utf8(allocator, data);
        defer allocator.free(decoded);
        const file = try std.fs.cwd().createFile(output_path, .{});
        defer file.close();
        try file.writeAll(decoded);
    } else {
        unreachable;
    }

    std.debug.print("Success: Output written to '{s}'\n", .{output_path});
}
