#!/usr/bin/env bash
# utf-256: Encode/decode UTF-256 format
set -euo pipefail

print_help() {
    echo "UTF-256 Encoder/Decoder (Bash version)"
    echo
    echo "Usage:"
    echo "  $0 -e INPUT_FILE -o OUTPUT_FILE   Encode UTF-8 → UTF-256"
    echo "  $0 -d INPUT_FILE -o OUTPUT_FILE   Decode UTF-256 → UTF-8"
    echo
    exit 1
}

# Parse arguments
ENCODE_FILE=""
DECODE_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -e)
            ENCODE_FILE="$2"
            shift 2
            ;;
        -d)
            DECODE_FILE="$2"
            shift 2
            ;;
        -o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -*|--*)
            echo "Unknown option: $1"
            print_help
            ;;
        *)
            echo "Unknown argument: $1"
            print_help
            ;;
    esac
done

# Validate arguments
if [[ -n "$ENCODE_FILE" && -n "$DECODE_FILE" ]]; then
    echo "Error: Cannot specify both -e and -d"
    print_help
fi

if [[ -z "$ENCODE_FILE" && -z "$DECODE_FILE" ]]; then
    echo "Error: Must specify one of -e or -d"
    print_help
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "Error: Output file required (-o)"
    print_help
fi

# --- Encoding logic ---
encode() {
    local input="$1"
    local output="$2"

    > "$output"

    while IFS= read -r -n1 -d '' char || [[ -n "$char" ]]; do
        byte=$(printf "%d" "'$char")
        for i in {7..0}; do
            bit=$(( (byte >> i) & 1 ))
            if [[ $bit -eq 1 ]]; then
                printf '\xFF' >> "$output"
            else
                printf '\x00' >> "$output"
            fi
        done
    done < "$input"

    echo "Encoded successfully to '$output'"
}

# --- Decoding logic ---
decode() {
    local input="$1"
    local output="$2"

    > "$output"

    while true; do
        chunk=$(dd if="$input" bs=1 count=8 status=none | xxd -p | tr -d '\n')
        [[ -z "$chunk" ]] && break
        [[ ${#chunk} -ne 16 ]] && {
            echo "Error: File is not a multiple of 8 bytes" >&2
            exit 1
        }

        byte=0
        for (( i=0; i<16; i+=2 )); do
            hex="${chunk:$i:2}"
            if [[ "$hex" == "00" ]]; then
                byte=$(( byte << 1 ))
            elif [[ "$hex" == "ff" || "$hex" == "FF" ]]; then
                byte=$(( (byte << 1) | 1 ))
            else
                echo "Invalid byte in UTF-256: 0x$hex" >&2
                exit 1
            fi
        done

        printf "\\x%02x" "$byte" >> "$output"
    done

    echo "Decoded successfully to '$output'"
}

# --- Run ---
if [[ -n "$ENCODE_FILE" ]]; then
    encode "$ENCODE_FILE" "$OUTPUT_FILE"
elif [[ -n "$DECODE_FILE" ]]; then
    decode "$DECODE_FILE" "$OUTPUT_FILE"
fi
