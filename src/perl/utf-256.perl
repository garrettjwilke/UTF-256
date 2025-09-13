#!/usr/bin/env perl
use strict;
use warnings;
use Fcntl ':mode';
use File::Basename;

my $CHUNK_SIZE = 8;

sub print_help {
    my $progname = basename($0);
    print "\nUTF-256 Encoder/Decoder\n\n";
    print "Usage:\n";
    print "  $progname -e UTF8_FILE -o OUTPUT_FILE\n";
    print "  $progname -d UTF256_FILE -o OUTPUT_FILE\n\n";
    exit 1;
}

sub encode {
    my ($infile, $outfile) = @_;

    open my $in, '<:raw', $infile or die "Error opening input file: $!\n";
    open my $out, '>:raw', $outfile or die "Error opening output file: $!\n";

    while (read($in, my $byte, 1)) {
        my $value = ord($byte);
        for my $i (reverse 0 .. 7) {
            my $bit = ($value >> $i) & 1;
            my $out_byte = $bit ? "\xFF" : "\x00";
            print $out $out_byte;
        }
    }

    close $in;
    close $out;
}

sub decode {
    my ($infile, $outfile) = @_;

    open my $in, '<:raw', $infile or die "Error opening input file: $!\n";
    open my $out, '>:raw', $outfile or die "Error opening output file: $!\n";

    while (read($in, my $chunk, $CHUNK_SIZE) == $CHUNK_SIZE) {
        my $byte = 0;
        my @bytes = unpack("C*", $chunk);

        for my $b (@bytes) {
            if ($b == 0x00) {
                $byte <<= 1;
            } elsif ($b == 0xFF) {
                $byte = ($byte << 1) | 1;
            } else {
                die sprintf "Invalid byte in UTF-256 file: 0x%02X\n", $b;
            }
        }

        print $out chr($byte);
    }

    # Check if the file ended correctly
    if (!eof($in)) {
        die "Error: file is not a multiple of 8 bytes\n";
    }

    close $in;
    close $out;
}

### Main

my ($encode_file, $decode_file, $output_file);
while (@ARGV) {
    my $arg = shift @ARGV;
    if ($arg eq "-e") {
        $encode_file = shift @ARGV or print_help();
    } elsif ($arg eq "-d") {
        $decode_file = shift @ARGV or print_help();
    } elsif ($arg eq "-o") {
        $output_file = shift @ARGV or print_help();
    } else {
        print_help();
    }
}

if ((!$encode_file && !$decode_file) || ($encode_file && $decode_file)) {
    print STDERR "Error: You must specify either -e or -d, but not both.\n";
    print_help();
}

if (!$output_file) {
    print STDERR "Error: Output file is required (-o).\n";
    print_help();
}

if ($encode_file) {
    encode($encode_file, $output_file);
    print "Encoded successfully to '$output_file'\n";
} else {
    decode($decode_file, $output_file);
    print "Decoded successfully to '$output_file'\n";
}
