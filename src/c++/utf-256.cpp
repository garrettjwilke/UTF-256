#include <iostream>
#include <fstream>
#include <vector>
#include <string>

constexpr size_t CHUNK_SIZE = 8;

void print_help(const std::string &progname) {
    std::cerr << "\nUTF-256 Encoder/Decoder\n\n"
              << "Usage:\n"
              << "  " << progname << " -e UTF8_FILE -o OUTPUT_FILE\n"
              << "  " << progname << " -d UTF256_FILE -o OUTPUT_FILE\n\n";
}

int encode(const std::string &infile, const std::string &outfile) {
    std::ifstream in(infile, std::ios::binary);
    if (!in) {
        std::cerr << "Error opening input file: " << infile << "\n";
        return 1;
    }

    std::ofstream out(outfile, std::ios::binary);
    if (!out) {
        std::cerr << "Error opening output file: " << outfile << "\n";
        return 1;
    }

    char byte;
    while (in.get(byte)) {
        for (int i = 7; i >= 0; --i) {
            uint8_t bit = (byte >> i) & 1;
            uint8_t out_byte = bit ? 0xFF : 0x00;
            out.put(static_cast<char>(out_byte));
        }
    }

    return 0;
}

int decode(const std::string &infile, const std::string &outfile) {
    std::ifstream in(infile, std::ios::binary);
    if (!in) {
        std::cerr << "Error opening input file: " << infile << "\n";
        return 1;
    }

    std::ofstream out(outfile, std::ios::binary);
    if (!out) {
        std::cerr << "Error opening output file: " << outfile << "\n";
        return 1;
    }

    std::vector<uint8_t> chunk(CHUNK_SIZE);
    while (in.read(reinterpret_cast<char *>(chunk.data()), CHUNK_SIZE)) {
        uint8_t byte = 0;

        for (size_t i = 0; i < CHUNK_SIZE; ++i) {
            if (chunk[i] == 0x00) {
                byte <<= 1;
            } else if (chunk[i] == 0xFF) {
                byte = (byte << 1) | 1;
            } else {
                std::cerr << "Invalid byte in UTF-256 file: 0x" 
                          << std::hex << static_cast<int>(chunk[i]) << "\n";
                return 1;
            }
        }

        out.put(static_cast<char>(byte));
    }

    if (!in.eof()) {
        std::cerr << "Error: file is not a multiple of 8 bytes\n";
        return 1;
    }

    return 0;
}

int main(int argc, char *argv[]) {
    std::string encode_file, decode_file, output_file;

    if (argc < 2) {
        print_help(argv[0]);
        return 1;
    }

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "-e" && i + 1 < argc) {
            encode_file = argv[++i];
        } else if (arg == "-d" && i + 1 < argc) {
            decode_file = argv[++i];
        } else if (arg == "-o" && i + 1 < argc) {
            output_file = argv[++i];
        } else {
            print_help(argv[0]);
            return 1;
        }
    }

    if ((!encode_file.empty() && !decode_file.empty()) ||
        (encode_file.empty() && decode_file.empty())) {
        std::cerr << "Error: You must specify either -e or -d, but not both.\n";
        print_help(argv[0]);
        return 1;
    }

    if (output_file.empty()) {
        std::cerr << "Error: Output file is required (-o).\n";
        print_help(argv[0]);
        return 1;
    }

    int result = 0;

    if (!encode_file.empty()) {
        result = encode(encode_file, output_file);
        if (result == 0) {
            std::cout << "Encoded successfully to '" << output_file << "'\n";
        }
    } else if (!decode_file.empty()) {
        result = decode(decode_file, output_file);
        if (result == 0) {
            std::cout << "Decoded successfully to '" << output_file << "'\n";
        }
    }

    return result;
}
