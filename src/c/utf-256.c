// utf256.c
// A UTF-256 encoder/decoder in portable C
// Compile: gcc utf256.c -o utf256

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define CHUNK_SIZE 8

void print_help(const char *progname) {
    fprintf(stderr,
        "\nUTF-256 Encoder/Decoder\n\n"
        "Usage:\n"
        "  %s -e UTF-8_FILE -o OUTPUT_FILE\n"
        "  %s -d UTF-256_FILE -o OUTPUT_FILE\n\n",
        progname, progname
    );
}

// Encode a UTF-8 buffer into UTF-256
int encode(const char *infile, const char *outfile) {
    FILE *in = fopen(infile, "rb");
    if (!in) {
        perror("Error opening input file");
        return 1;
    }

    FILE *out = fopen(outfile, "wb");
    if (!out) {
        perror("Error opening output file");
        fclose(in);
        return 1;
    }

    int byte;
    while ((byte = fgetc(in)) != EOF) {
        for (int i = 7; i >= 0; i--) {
            uint8_t bit = (byte >> i) & 1;
            uint8_t out_byte = bit ? 0xFF : 0x00;
            fwrite(&out_byte, 1, 1, out);
        }
    }

    fclose(in);
    fclose(out);
    return 0;
}

// Decode a UTF-256 file into UTF-8
int decode(const char *infile, const char *outfile) {
    FILE *in = fopen(infile, "rb");
    if (!in) {
        perror("Error opening input file");
        return 1;
    }

    FILE *out = fopen(outfile, "wb");
    if (!out) {
        perror("Error opening output file");
        fclose(in);
        return 1;
    }

    uint8_t chunk[CHUNK_SIZE];
    size_t read;

    while ((read = fread(chunk, 1, CHUNK_SIZE, in)) == CHUNK_SIZE) {
        uint8_t byte = 0;

        for (int i = 0; i < CHUNK_SIZE; ++i) {
            if (chunk[i] == 0x00) {
                byte <<= 1;
            } else if (chunk[i] == 0xFF) {
                byte = (byte << 1) | 1;
            } else {
                fprintf(stderr, "Invalid byte in UTF-256 file: 0x%02X\n", chunk[i]);
                fclose(in);
                fclose(out);
                return 1;
            }
        }

        fwrite(&byte, 1, 1, out);
    }

    if (!feof(in)) {
        fprintf(stderr, "Error: file is not a multiple of 8 bytes\n");
        fclose(in);
        fclose(out);
        return 1;
    }

    fclose(in);
    fclose(out);
    return 0;
}

int main(int argc, char *argv[]) {
    const char *encode_file = NULL;
    const char *decode_file = NULL;
    const char *output_file = NULL;

    if (argc < 2) {
        print_help(argv[0]);
        return 1;
    }

    // Parse flags manually
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "-e") == 0 && i + 1 < argc) {
            encode_file = argv[++i];
        } else if (strcmp(argv[i], "-d") == 0 && i + 1 < argc) {
            decode_file = argv[++i];
        } else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
            output_file = argv[++i];
        } else {
            print_help(argv[0]);
            return 1;
        }
    }

    // Validate flags
    if ((encode_file && decode_file) || (!encode_file && !decode_file)) {
        fprintf(stderr, "Error: You must specify either -e or -d, but not both.\n");
        print_help(argv[0]);
        return 1;
    }

    if (!output_file) {
        fprintf(stderr, "Error: Output file is required (-o).\n");
        print_help(argv[0]);
        return 1;
    }

    int result = 0;

    if (encode_file) {
        result = encode(encode_file, output_file);
        if (result == 0) {
            printf("Encoded successfully to '%s'\n", output_file);
        }
    } else if (decode_file) {
        result = decode(decode_file, output_file);
        if (result == 0) {
            printf("Decoded successfully to '%s'\n", output_file);
        }
    }

    return result;
}
