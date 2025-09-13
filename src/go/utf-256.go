// UTF-256 Encoder/Decoder in Go (no external packages)

package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
)

func printUsage() {
	fmt.Fprintf(os.Stderr, `
UTF-256 Encoder/Decoder

Usage:
  utf256 -e UTF-8_INPUT -o OUTPUT_FILE
  utf256 -d UTF-256_INPUT -o OUTPUT_FILE

`)
}

func encodeToUTF256(input []byte) []byte {
	output := make([]byte, 0, len(input)*8)

	for _, b := range input {
		for i := 7; i >= 0; i-- {
			if (b>>i)&1 == 1 {
				output = append(output, 0xFF)
			} else {
				output = append(output, 0x00)
			}
		}
	}

	return output
}

func decodeFromUTF256(input []byte) ([]byte, error) {
	if len(input)%8 != 0 {
		return nil, errors.New("input is not a multiple of 8 bytes")
	}

	output := make([]byte, 0, len(input)/8)

	for i := 0; i < len(input); i += 8 {
		var b byte
		for j := 0; j < 8; j++ {
			b <<= 1
			switch input[i+j] {
			case 0x00:
				// nothing
			case 0xFF:
				b |= 1
			default:
				return nil, fmt.Errorf("invalid byte in UTF-256 stream: 0x%02X", input[i+j])
			}
		}
		output = append(output, b)
	}

	return output, nil
}

func readFile(path string) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	return io.ReadAll(file)
}

func writeFile(path string, data []byte) error {
	file, err := os.Create(path)
	if err != nil {
		return err
	}
	defer file.Close()

	_, err = file.Write(data)
	return err
}

func main() {
	var encodePath string
	var decodePath string
	var outputPath string

	flag.StringVar(&encodePath, "e", "", "Input UTF-8 file to encode")
	flag.StringVar(&decodePath, "d", "", "Input UTF-256 file to decode")
	flag.StringVar(&outputPath, "o", "", "Output file")
	flag.Parse()

	// Enforce mutual exclusivity and required output
	if (encodePath == "" && decodePath == "") || (encodePath != "" && decodePath != "") {
		fmt.Fprintln(os.Stderr, "Error: You must use exactly one of -e or -d.\n")
		printUsage()
		os.Exit(1)
	}

	if outputPath == "" {
		fmt.Fprintln(os.Stderr, "Error: Output file (-o) is required.\n")
		printUsage()
		os.Exit(1)
	}

	var inputData []byte
	var err error

	if encodePath != "" {
		inputData, err = readFile(encodePath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
			os.Exit(1)
		}

		encoded := encodeToUTF256(inputData)
		err = writeFile(outputPath, encoded)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error writing output file: %v\n", err)
			os.Exit(1)
		}

		fmt.Printf("Encoded to '%s'\n", outputPath)

	} else {
		inputData, err = readFile(decodePath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
			os.Exit(1)
		}

		decoded, err := decodeFromUTF256(inputData)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Decoding failed: %v\n", err)
			os.Exit(1)
		}

		err = writeFile(outputPath, decoded)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error writing output file: %v\n", err)
			os.Exit(1)
		}

		fmt.Printf("Decoded to '%s'\n", outputPath)
	}
}
