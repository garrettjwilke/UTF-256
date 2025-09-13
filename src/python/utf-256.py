#!/usr/bin/env python3

import argparse
import os
import sys

def utf_256_encoder(text: str) -> bytes:
    result = []
    utf8_bytes = text.encode('utf-8')
    for byte in utf8_bytes:
        for i in range(8):
            bit = (byte >> (7 - i)) & 1
            result.append(0xFF if bit else 0x00)
    return bytes(result)

def utf_256_decoder(data: bytes) -> str:
    if len(data) % 8 != 0:
        raise ValueError("Invalid UTF-256 data: length must be a multiple of 8")

    utf8_bytes = []
    for i in range(0, len(data), 8):
        byte = 0
        for j in range(8):
            b = data[i + j]
            if b == 0xFF:
                bit = 1
            elif b == 0x00:
                bit = 0
            else:
                raise ValueError(f"Invalid byte: {b}, must be 0x00 or 0xFF")
            byte = (byte << 1) | bit
        utf8_bytes.append(byte)

    return bytes(utf8_bytes).decode('utf-8')

def main():
    # Define the custom help message as a constant
    CUSTOM_HELP = """
------------------------------------------------------
UTF-256 encoder/decoder

./utf-256.py [FLAG] INPUT_FILE -o OUTPUT_FILE

|-----------|------------------------------------------|
|  FLAG     |  What it does                            |
|-----------|------------------------------------------|
| -e        | Encodes a UTF-8 file into a UTF-256 file |
| --encode  |                                          |
|-----------|------------------------------------------|
| -d        | Decodes a UTF-256 file into a UTF-8 file |
| --decode  |                                          |
|-----------|------------------------------------------|
"""

    # Check for help flag manually before parsing
    if "-h" in sys.argv or "--help" in sys.argv or len(sys.argv) == 1:
        print(CUSTOM_HELP)
        sys.exit(0)

    try:
        # Configure the parser without default help messages
        parser = argparse.ArgumentParser(add_help=False)

        group = parser.add_mutually_exclusive_group(required=True)
        group.add_argument("-e", "--encode")
        group.add_argument("-d", "--decode")
        parser.add_argument("-o", "--output", required=True)

        # Parse arguments inside a try block
        args = parser.parse_args()

        if args.encode:
            input_file = args.encode
            if not os.path.isfile(input_file):
                print(f"Error: UTF-8 input file '{input_file}' does not exist.")
                sys.exit(1)
            
            with open(input_file, 'rb') as f:
                utf8_bytes = f.read()
            text = utf8_bytes.decode('utf-8')
            encoded = utf_256_encoder(text)
            
            with open(args.output, 'wb') as f:
                f.write(encoded)
            print(f"Encoded successfully to '{args.output}'")
        
        elif args.decode:
            input_file = args.decode
            if not os.path.isfile(input_file):
                print(f"Error: UTF-256 input file '{input_file}' does not exist.")
                sys.exit(1)
            
            with open(input_file, 'rb') as f:
                data = f.read()
            decoded_bytes = utf_256_decoder(data).encode('utf-8')
            
            with open(args.output, 'wb') as f:
                f.write(decoded_bytes)
            print(f"Decoded successfully to '{args.output}'")

    except SystemExit:
        # This catches errors like missing required arguments
        print(CUSTOM_HELP)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
