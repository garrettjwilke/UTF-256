{-# LANGUAGE OverloadedStrings #-}

import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC
import Data.Word (Word8)
import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)
import Data.Bits (shiftR, (.&.), shiftL, (.|.))
import Numeric (showHex)
import Control.Monad (when)

chunkSize :: Int
chunkSize = 8

printHelp :: String -> IO ()
printHelp progname = do
    hPutStrLn stderr ""
    hPutStrLn stderr "UTF-256 Encoder/Decoder"
    hPutStrLn stderr ""
    hPutStrLn stderr "Usage:"
    hPutStrLn stderr ("  " ++ progname ++ " -e UTF-8_FILE -o OUTPUT_FILE")
    hPutStrLn stderr ("  " ++ progname ++ " -d UTF-256_FILE -o OUTPUT_FILE")
    hPutStrLn stderr ""

encode :: FilePath -> FilePath -> IO Int
encode infile outfile = do
    content <- BS.readFile infile
    let encoded = BS.concatMap encodeByte content
    BS.writeFile outfile encoded
    return 0
  where
    encodeByte :: Word8 -> BS.ByteString
    encodeByte byte = BS.pack [if testBit byte i then 0xFF else 0x00 | i <- [7,6..0]]
    testBit b i = (b `shiftR` i) .&. 1 == 1

decode :: FilePath -> FilePath -> IO Int
decode infile outfile = do
    content <- BS.readFile infile
    if BS.length content `mod` chunkSize /= 0
      then do
        hPutStrLn stderr "Error: file is not a multiple of 8 bytes"
        return 1
      else do
        let chunks = chunkBS chunkSize content
        decodedEither <- mapM decodeChunk chunks
        case sequence decodedEither of
          Left err -> do
            hPutStrLn stderr err
            return 1
          Right decoded -> do
            BS.writeFile outfile (BS.pack decoded)
            return 0

  where
    chunkBS :: Int -> BS.ByteString -> [BS.ByteString]
    chunkBS n bs
      | BS.null bs = []
      | otherwise = let (h, t) = BS.splitAt n bs in h : chunkBS n t

    decodeChunk :: BS.ByteString -> IO (Either String Word8)
    decodeChunk chunk = do
        let bytes = BS.unpack chunk
        decodeBits bytes 0

    decodeBits :: [Word8] -> Word8 -> IO (Either String Word8)
    decodeBits [] acc = return $ Right acc
    decodeBits (b:bs) acc
      | b == 0x00 = decodeBits bs (acc `shiftL` 1)
      | b == 0xFF = decodeBits bs ((acc `shiftL` 1) .|. 1)
      | otherwise = return $ Left ("Invalid byte in UTF-256 file: 0x" ++ showHex b "")

main :: IO ()
main = do
    args <- getArgs
    progname <- getProgName

    if length args < 1
      then printHelp progname >> exitFailure
      else parseArgs args Nothing Nothing Nothing

  where
    parseArgs :: [String] -> Maybe FilePath -> Maybe FilePath -> Maybe FilePath -> IO ()
    parseArgs [] (Just encodeFile) Nothing (Just outputFile) = do
        r <- encode encodeFile outputFile
        when (r == 0) $ putStrLn $ "Encoded successfully to '" ++ outputFile ++ "'"
        if r /= 0 then exitFailure else return ()

    parseArgs [] Nothing (Just decodeFile) (Just outputFile) = do
        r <- decode decodeFile outputFile
        when (r == 0) $ putStrLn $ "Decoded successfully to '" ++ outputFile ++ "'"
        if r /= 0 then exitFailure else return ()

    parseArgs [] _ _ _ = do
        hPutStrLn stderr "Error: Invalid or missing arguments."
        printHelp =<< getProgName
        exitFailure

    parseArgs ("-e":file:rest) Nothing Nothing output = parseArgs rest (Just file) Nothing output
    parseArgs ("-d":file:rest) encode Nothing output = parseArgs rest encode (Just file) output
    parseArgs ("-o":file:rest) encode decode Nothing = parseArgs rest encode decode (Just file)

    parseArgs (arg:_) _ _ _ = do
        hPutStrLn stderr $ "Unknown or malformed argument: " ++ arg
        printHelp =<< getProgName
        exitFailure
