use std::env;
use std::io::{self};
use std::path::PathBuf;
use std::process;

fn print_help() {
    eprintln!(
        "\nUTF-256 Encoder/Decoder

Usage:
  utf256 -e UTF-8_INPUT -o OUTPUT_FILE
  utf256 -d UTF-256_INPUT -o OUTPUT_FILE

"
    );
}

fn utf8_to_utf256(input: &[u8]) -> Vec<u8> {
    let mut output = Vec::with_capacity(input.len() * 8);
    for byte in input {
        for i in (0..8).rev() {
            let bit = (byte >> i) & 1;
            output.push(if bit == 1 { 0xFF } else { 0x00 });
        }
    }
    output
}

fn utf256_to_utf8(input: &[u8]) -> io::Result<Vec<u8>> {
    if input.len() % 8 != 0 {
        return Err(io::Error::new(io::ErrorKind::InvalidData, "Input is not a multiple of 8 bytes"));
    }

    let mut output = Vec::with_capacity(input.len() / 8);
    for chunk in input.chunks(8) {
        let mut byte = 0u8;
        for &b in chunk {
            byte <<= 1;
            match b {
                0x00 => {}         // 0 bit
                0xFF => byte |= 1, // 1 bit
                _ => {
                    return Err(io::Error::new(
                        io::ErrorKind::InvalidData,
                        format!("Invalid byte in UTF-256 stream: 0x{:02X}", b),
                    ));
                }
            }
        }
        output.push(byte);
    }

    Ok(output)
}

fn main() {
    let args: Vec<String> = env::args().collect();

    if args.len() < 5 {
        print_help();
        process::exit(1);
    }

    let mut encode_file: Option<PathBuf> = None;
    let mut decode_file: Option<PathBuf> = None;
    let mut output_file: Option<PathBuf> = None;

    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "-e" => {
                if encode_file.is_some() || i + 1 >= args.len() {
                    print_help();
                    process::exit(1);
                }
                encode_file = Some(PathBuf::from(&args[i + 1]));
                i += 1;
            }
            "-d" => {
                if decode_file.is_some() || i + 1 >= args.len() {
                    print_help();
                    process::exit(1);
                }
                decode_file = Some(PathBuf::from(&args[i + 1]));
                i += 1;
            }
            "-o" => {
                if output_file.is_some() || i + 1 >= args.len() {
                    print_help();
                    process::exit(1);
                }
                output_file = Some(PathBuf::from(&args[i + 1]));
                i += 1;
            }
            _ => {
                print_help();
                process::exit(1);
            }
        }
        i += 1;
    }

    // Validate flags
    if encode_file.is_some() == decode_file.is_some() {
        eprintln!(" Error: Must use exactly one of -e or -d.\n");
        print_help();
        process::exit(1);
    }

    if output_file.is_none() {
        eprintln!(" Error: Output file (-o) is required.\n");
        print_help();
        process::exit(1);
    }

    let output_path = output_file.unwrap();

    let result = if let Some(input_path) = encode_file {
        match std::fs::read(&input_path) {
            Ok(data) => {
                let encoded = utf8_to_utf256(&data);
                std::fs::write(&output_path, encoded)
            }
            Err(e) => {
                eprintln!("Error reading input file: {}", e);
                process::exit(1);
            }
        }
    } else if let Some(input_path) = decode_file {
        match std::fs::read(&input_path) {
            Ok(data) => match utf256_to_utf8(&data) {
                Ok(decoded) => std::fs::write(&output_path, decoded),
                Err(e) => {
                    eprintln!("Decoding error: {}", e);
                    process::exit(1);
                }
            },
            Err(e) => {
                eprintln!("Error reading input file: {}", e);
                process::exit(1);
            }
        }
    } else {
        unreachable!();
    };

    if let Err(e) = result {
        eprintln!("Error writing output file: {}", e);
        process::exit(1);
    }

    println!(" Success: Output written to '{}'", output_path.display());
}
