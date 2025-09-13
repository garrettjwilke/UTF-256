#!/usr/bin/env ruby

def print_help(progname)
  STDERR.puts <<~HELP
    UTF-256 Encoder/Decoder

    Usage:
      #{progname} -e UTF8_FILE -o OUTPUT_FILE
      #{progname} -d UTF256_FILE -o OUTPUT_FILE
  HELP
end

def encode(input_path, output_path)
  File.open(input_path, 'rb') do |input|
    File.open(output_path, 'wb') do |output|
      input.each_byte do |byte|
        7.downto(0) do |i|
          bit = (byte >> i) & 1
          output.write(bit == 1 ? 0xFF.chr : 0x00.chr)
        end
      end
    end
  end
  puts "Encoded successfully to '#{output_path}'"
end

def decode(input_path, output_path)
  chunk_size = 8
  File.open(input_path, 'rb') do |input|
    File.open(output_path, 'wb') do |output|
      while chunk = input.read(chunk_size)
        if chunk.size != chunk_size
          STDERR.puts "Error: input file size is not a multiple of 8 bytes"
          exit 1
        end

        byte = 0
        chunk.each_byte do |b|
          case b
          when 0x00
            byte <<= 1
          when 0xFF
            byte = (byte << 1) | 1
          else
            STDERR.puts "Invalid byte in UTF-256 file: 0x#{b.to_s(16).rjust(2, '0')}"
            exit 1
          end
        end
        output.write(byte.chr)
      end
    end
  end
  puts "Decoded successfully to '#{output_path}'"
end

def main(args)
  encode_file = nil
  decode_file = nil
  output_file = nil

  i = 0
  while i < args.length
    case args[i]
    when '-e'
      i += 1
      encode_file = args[i]
    when '-d'
      i += 1
      decode_file = args[i]
    when '-o'
      i += 1
      output_file = args[i]
    else
      print_help($0)
      exit 1
    end
    i += 1
  end

  if (encode_file && decode_file) || (!encode_file && !decode_file)
    STDERR.puts "Error: Specify either -e or -d, but not both."
    print_help($0)
    exit 1
  end

  unless output_file
    STDERR.puts "Error: Output file is required (-o)."
    print_help($0)
    exit 1
  end

  if encode_file
    encode(encode_file, output_file)
  else
    decode(decode_file, output_file)
  end
end

if __FILE__ == $0
  main(ARGV)
end
