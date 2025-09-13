import java.io.*;
import java.nio.file.Files;

public class utf256 {

    private static final int CHUNK_SIZE = 8;

    public static void printHelp(String progName) {
        System.err.println("\nUTF-256 Encoder/Decoder\n");
        System.err.println("Usage:");
        System.err.println("  " + progName + " -e UTF-8_FILE -o OUTPUT_FILE");
        System.err.println("  " + progName + " -d UTF-256_FILE -o OUTPUT_FILE\n");
    }

    public static int encode(String infile, String outfile) {
        try (InputStream in = new BufferedInputStream(new FileInputStream(infile));
             OutputStream out = new BufferedOutputStream(new FileOutputStream(outfile))) {

            int byteRead;
            while ((byteRead = in.read()) != -1) {
                for (int i = 7; i >= 0; i--) {
                    int bit = (byteRead >> i) & 1;
                    out.write(bit == 1 ? 0xFF : 0x00);
                }
            }
        } catch (IOException e) {
            System.err.println("Error during encoding: " + e.getMessage());
            return 1;
        }
        return 0;
    }

    public static int decode(String infile, String outfile) {
        try (InputStream in = new BufferedInputStream(new FileInputStream(infile));
             OutputStream out = new BufferedOutputStream(new FileOutputStream(outfile))) {

            byte[] chunk = new byte[CHUNK_SIZE];
            int bytesRead;
            while ((bytesRead = in.read(chunk)) == CHUNK_SIZE) {
                int decodedByte = 0;
                for (int i = 0; i < CHUNK_SIZE; i++) {
                    byte b = chunk[i];
                    if (b == 0x00) {
                        decodedByte <<= 1;
                    } else if ((b & 0xFF) == 0xFF) {
                        decodedByte = (decodedByte << 1) | 1;
                    } else {
                        System.err.printf("Invalid byte in UTF-256 file: 0x%02X%n", b);
                        return 1;
                    }
                }
                out.write(decodedByte);
            }
            if (bytesRead != -1) {
                System.err.println("Error: file is not a multiple of 8 bytes");
                return 1;
            }
        } catch (IOException e) {
            System.err.println("Error during decoding: " + e.getMessage());
            return 1;
        }
        return 0;
    }

    public static void main(String[] args) {
        String encodeFile = null;
        String decodeFile = null;
        String outputFile = null;

        if (args.length < 1) {
            printHelp("Utf256");
            System.exit(1);
        }

        // Simple flag parsing
        for (int i = 0; i < args.length; i++) {
            switch (args[i]) {
                case "-e":
                    if (i + 1 < args.length) {
                        encodeFile = args[++i];
                    } else {
                        printHelp("Utf256");
                        System.exit(1);
                    }
                    break;
                case "-d":
                    if (i + 1 < args.length) {
                        decodeFile = args[++i];
                    } else {
                        printHelp("Utf256");
                        System.exit(1);
                    }
                    break;
                case "-o":
                    if (i + 1 < args.length) {
                        outputFile = args[++i];
                    } else {
                        printHelp("Utf256");
                        System.exit(1);
                    }
                    break;
                default:
                    printHelp("Utf256");
                    System.exit(1);
            }
        }

        if ((encodeFile != null && decodeFile != null) || (encodeFile == null && decodeFile == null)) {
            System.err.println("Error: You must specify either -e or -d, but not both.");
            printHelp("Utf256");
            System.exit(1);
        }

        if (outputFile == null) {
            System.err.println("Error: Output file is required (-o).");
            printHelp("Utf256");
            System.exit(1);
        }

        int result = 0;
        if (encodeFile != null) {
            result = encode(encodeFile, outputFile);
            if (result == 0) {
                System.out.println("Encoded successfully to '" + outputFile + "'");
            }
        } else if (decodeFile != null) {
            result = decode(decodeFile, outputFile);
            if (result == 0) {
                System.out.println("Decoded successfully to '" + outputFile + "'");
            }
        }

        System.exit(result);
    }
}
