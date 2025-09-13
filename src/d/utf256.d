import std.stdio;
import std.file;
import std.path;
import std.process;
import std.exception;
import std.string;

// Prints the help message to stderr.
void printHelp() {
    stderr.writeln(
        "\nUTF-256 Encoder/Decoder\n\n",
        "Usage:\n",
        "  utf-256 -e UTF-8_INPUT -o OUTPUT_FILE\n",
        "  utf-256 -d UTF-256_INPUT -o OUTPUT_FILE\n"
    );
}

// Encodes a UTF-8 ubyte array into a "UTF-256" ubyte array, where each bit is a byte (0x00 or 0xFF).
ubyte[] utf8ToUtf256(ubyte[] input) {
    auto output = new ubyte[input.length * 8];
    foreach (byte_idx, input_byte; input) {
        foreach (j; 0..8) {
            const i = cast(ubyte)(7 - j);
            const bit = (input_byte >> i) & 1;
            const out_byte = bit == 1 ? 0xFF : 0x00;
            output[byte_idx * 8 + j] = out_byte;
        }
    }
    return output;
}

// Decodes a "UTF-256" ubyte array back into a UTF-8 ubyte array.
ubyte[] utf256ToUtf8(ubyte[] input) {
    enforce(input.length % 8 == 0, "Input length is not a multiple of 8 bytes.");

    auto output = new ubyte[input.length / 8];
    foreach (i; 0..output.length) {
        ubyte output_byte = 0;
        foreach (j; 0..8) {
            output_byte <<= 1;
            switch (input[i * 8 + j]) {
                case 0x00:
                    break;
                case 0xFF:
                    output_byte |= 1;
                    break;
                default:
                    throw new Exception(format("Invalid byte in UTF-256 stream: 0x%02X", input[i * 8 + j]));
            }
        }
        output[i] = output_byte;
    }
    return output;
}

int main(string[] args) {
    if (args.length < 5) {
        printHelp();
        return 1;
    }

    string encodeFile = null;
    string decodeFile = null;
    string outputFile = null;

    int i = 1;
    while (i < args.length) {
        switch (args[i]) {
            case "-e":
                if (encodeFile !is null || i + 1 >= args.length) {
                    printHelp();
                    return 1;
                }
                encodeFile = args[i + 1];
                i += 1;
                break;
            case "-d":
                if (decodeFile !is null || i + 1 >= args.length) {
                    printHelp();
                    return 1;
                }
                decodeFile = args[i + 1];
                i += 1;
                break;
            case "-o":
                if (outputFile !is null || i + 1 >= args.length) {
                    printHelp();
                    return 1;
                }
                outputFile = args[i + 1];
                i += 1;
                break;
            default:
                printHelp();
                return 1;
        }
        i += 1;
    }

    if ((encodeFile !is null) == (decodeFile !is null)) {
        stderr.writeln("Error: Must use exactly one of -e or -d.\n");
        printHelp();
        return 1;
    }

    if (outputFile is null) {
        stderr.writeln("Error: Output file (-o) is required.\n");
        printHelp();
        return 1;
    }

    try {
        if (encodeFile !is null) {
            auto data = cast(ubyte[])read(encodeFile);
            auto encoded = utf8ToUtf256(data);
            std.file.write(outputFile, encoded);
        } else if (decodeFile !is null) {
            auto data = cast(ubyte[])read(decodeFile);
            auto decoded = utf256ToUtf8(data);
            std.file.write(outputFile, decoded);
        }
        stdout.writeln("Success: Output written to '", outputFile, "'");
    } catch (Exception e) {
        stderr.writeln("Error: ", e.msg);
        return 1;
    }

    return 0;
}
