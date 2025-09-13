#!/usr/bin/env lua
local CHUNK_SIZE = 8

local function print_help(progname)
    io.stderr:write([[
UTF-256 Encoder/Decoder

Usage:
  ]] .. progname .. [[ -e UTF-8_FILE -o OUTPUT_FILE
  ]] .. progname .. [[ -d UTF-256_FILE -o OUTPUT_FILE

]])
end

local function encode(infile, outfile)
    local in_file = io.open(infile, "rb")
    if not in_file then
        io.stderr:write("Error opening input file\n")
        return 1
    end

    local out_file = io.open(outfile, "wb")
    if not out_file then
        io.stderr:write("Error opening output file\n")
        in_file:close()
        return 1
    end

    while true do
        local byte = in_file:read(1)
        if not byte then break end
        local b = string.byte(byte)
        for i = 7, 0, -1 do
            local bit = (b >> i) & 1
            local out_byte = bit == 1 and 0xFF or 0x00
            out_file:write(string.char(out_byte))
        end
    end

    in_file:close()
    out_file:close()
    return 0
end

local function decode(infile, outfile)
    local in_file = io.open(infile, "rb")
    if not in_file then
        io.stderr:write("Error opening input file\n")
        return 1
    end

    local out_file = io.open(outfile, "wb")
    if not out_file then
        io.stderr:write("Error opening output file\n")
        in_file:close()
        return 1
    end

    while true do
        local chunk = in_file:read(CHUNK_SIZE)
        if not chunk then break end
        if #chunk < CHUNK_SIZE then
            io.stderr:write("Error: file is not a multiple of 8 bytes\n")
            in_file:close()
            out_file:close()
            return 1
        end

        local byte = 0
        for i = 1, CHUNK_SIZE do
            local c = string.byte(chunk, i)
            if c == 0x00 then
                byte = (byte << 1)
            elseif c == 0xFF then
                byte = (byte << 1) | 1
            else
                io.stderr:write(string.format("Invalid byte in UTF-256 file: 0x%02X\n", c))
                in_file:close()
                out_file:close()
                return 1
            end
        end

        out_file:write(string.char(byte))
    end

    in_file:close()
    out_file:close()
    return 0
end

-- Main program
local function main()
    local encode_file = nil
    local decode_file = nil
    local output_file = nil

    local args = arg

    local i = 1
    while i <= #arg do
        local a = arg[i]
        if a == "-e" and i + 1 <= #arg then
            encode_file = arg[i + 1]
            i = i + 2
        elseif a == "-d" and i + 1 <= #arg then
            decode_file = arg[i + 1]
            i = i + 2
        elseif a == "-o" and i + 1 <= #arg then
            output_file = arg[i + 1]
            i = i + 2
        else
            print_help(arg[0] or "utf-256.lua")
            return 1
        end
    end

    if (encode_file and decode_file) or (not encode_file and not decode_file) then
        io.stderr:write("Error: You must specify either -e or -d, but not both.\n")
        print_help(arg[0] or "utf-256.lua")
        return 1
    end

    if not output_file then
        io.stderr:write("Error: Output file is required (-o).\n")
        print_help(arg[0] or "utf-256.lua")
        return 1
    end

    local result = 0
    if encode_file then
        result = encode(encode_file, output_file)
        if result == 0 then
            print("Encoded successfully to '" .. output_file .. "'")
        end
    elseif decode_file then
        result = decode(decode_file, output_file)
        if result == 0 then
            print("Decoded successfully to '" .. output_file .. "'")
        end
    end

    return result
end

os.exit(main())
