import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;
import javax.sound.sampled.*;

/*
Processing steps:
1. Parse Args & Config: Read inputs, output file, start addr ($9000 default). Infer sample rate from ext (.d8=8kHz, .d15=15kHz). Validate or error.
2. Collect WAVs: Scan paths for .wav files (files or dirs), sort, list valid ones. Skip non-WAVs.
3. Init Structures: Prep lists for addresses, lengths, data buffer. Set current addr to start_addr.
4 .Process Each WAV:

4a: SoX convert to 8-bit mono raw PCM at target rate (temp file).
4b: Read raw, scale to 4-bit (0-15).
4c: Pack pairs into bytes ((high<<4)|low); pad odd with 0.
4d: Pad to 256-byte multiple with 0x88 (silence).
4e: Record addr/len, append to buffer, advance addr.


5 .Build Table: 32-byte array: bytes 0-15 = start high-bytes (up to 16 samples); 16-31 = end high-bytes.
6 .Write Output: Table + packed data to file. Print summary (samples, addrs, lens, size).
7 .Cleanup: Delete temps, handle errors.
*/

public class WavToDigiConverter {

    public static void main(String[] args) {
        List<String> nonOptions = new ArrayList<>();
        int startAddr = 0x9000;
        for (String arg : args) {
            if (arg.startsWith("--start-addr=")) {
                String hexStr = arg.substring(13);
                try {
                    startAddr = Integer.parseInt(hexStr, 16);
                } catch (NumberFormatException e) {
                    System.err.println("Invalid start address: " + hexStr);
                    System.exit(1);
                }
            } else {
                nonOptions.add(arg);
            }
        }

        if (nonOptions.size() < 2) {
            System.err.println("Usage: java WavToDigiConverter [input_paths...] output_file [--start-addr=0xXXXX]");
            System.exit(1);
        }

        List<String> inputPaths = nonOptions.subList(0, nonOptions.size() - 1);
        String outputFilePath = nonOptions.get(nonOptions.size() - 1);

        String outLower = outputFilePath.toLowerCase();
        float sampleRate;
        if (outLower.endsWith(".d8")) {
            sampleRate = 8000f;
        } else if (outLower.endsWith(".d15")) {
            sampleRate = 15000f;
        } else {
            System.err.println("Error: Output file must end with .d8 or .d15");
            System.exit(1);
            return; // Unreachable
        }

        List<String> wavFiles = getWavFilesFromInput(inputPaths);
        if (wavFiles.isEmpty()) {
            System.err.println("Error: No WAV files found in the provided input paths.");
            System.exit(1);
        }

        System.out.println("Found " + wavFiles.size() + " WAV files to process:");
        for (String wav : wavFiles) {
            System.out.println("  - " + wav);
        }

        try {
            convertToMultiDigi(wavFiles, outputFilePath, startAddr, sampleRate);
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static List<String> getWavFilesFromInput(List<String> inputPaths) {
        List<String> wavFiles = new ArrayList<>();
        for (String path : inputPaths) {
            Path p = Paths.get(path);
            try {
                if (Files.isRegularFile(p) && path.toLowerCase().endsWith(".wav")) {
                    wavFiles.add(path);
                } else if (Files.isDirectory(p)) {
                    try (Stream<Path> stream = Files.list(p)) {
                        List<String> dirWavs = stream
                                .filter(file -> Files.isRegularFile(file) && file.toString().toLowerCase().endsWith(".wav"))
                                .map(Path::toString)
                                .sorted()
                                .collect(Collectors.toList());
                        if (dirWavs.isEmpty()) {
                            System.out.println("Warning: No WAV files found in directory " + path);
                        } else {
                            wavFiles.addAll(dirWavs);
                        }
                    }
                } else {
                    System.out.println("Error: " + path + " is neither a file nor a directory.");
                }
            } catch (IOException e) {
                System.err.println("Error accessing path " + path + ": " + e.getMessage());
            }
        }
        return wavFiles;
    }

    private static void convertToMultiDigi(List<String> inputWavs, String outputFile, int startAddr, float sampleRate) throws IOException, UnsupportedAudioFileException {
        ByteArrayOutputStream allData = new ByteArrayOutputStream();
        List<Integer> sampleAddresses = new ArrayList<>();
        List<Integer> sampleLengths = new ArrayList<>();

        int currentAddr = startAddr;

        for (String inputWav : inputWavs) {
            File wavFile = new File(inputWav);
            AudioInputStream sourceAIS = AudioSystem.getAudioInputStream(wavFile);

            AudioFormat targetFormat = new AudioFormat(
                    AudioFormat.Encoding.PCM_UNSIGNED,
                    sampleRate,
                    8,
                    1,
                    1,
                    sampleRate,
                    false
            );

            AudioInputStream ais = AudioSystem.getAudioInputStream(targetFormat, sourceAIS);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int len;
            while ((len = ais.read(buffer)) != -1) {
                baos.write(buffer, 0, len);
            }
            ais.close();
            sourceAIS.close();
            byte[] pcmData = baos.toByteArray();

            int[] pcm4bit = new int[pcmData.length];
            for (int i = 0; i < pcmData.length; i++) {
                int sample = pcmData[i] & 0xFF;
                pcm4bit[i] = (sample / 16) & 0x0F;
            }

            int originalLength = pcm4bit.length;
            if (originalLength % 2 != 0) {
                pcm4bit = Arrays.copyOf(pcm4bit, originalLength + 1);
                pcm4bit[originalLength] = 0;
            }

            byte[] packed = new byte[pcm4bit.length / 2];
            for (int i = 0; i < packed.length; i++) {
                int s1 = pcm4bit[i * 2];
                int s2 = pcm4bit[i * 2 + 1];
                packed[i] = (byte) ((s1 << 4) | s2);
            }

            int packedLen = packed.length;
            int padding = (256 - (packedLen % 256)) % 256;
            byte[] paddedPacked = Arrays.copyOf(packed, packedLen + padding);
            for (int j = packedLen; j < paddedPacked.length; j++) {
                paddedPacked[j] = (byte) 0x88;
            }
            int paddedPackedLength = paddedPacked.length;

            sampleAddresses.add(currentAddr);
            sampleLengths.add(paddedPackedLength);

            allData.write(paddedPacked);

            currentAddr += paddedPackedLength;

            System.out.printf("Processed %s: %d 4-bit samples (packed to %d bytes, padded by %d bytes)%n",
                    inputWav, originalLength, paddedPackedLength, padding);
        }

        byte[] table = createSampleTable(sampleAddresses, sampleLengths);

        try (FileOutputStream fos = new FileOutputStream(outputFile)) {
            fos.write(table);
            allData.writeTo(fos);
        }

        System.out.println("Created " + outputFile + " with " + inputWavs.size() + " samples.");
        System.out.print("Sample addresses: ");
        for (int addr : sampleAddresses) {
            System.out.print(String.format("$%04x ", addr));
        }
        System.out.println();
        System.out.print("Sample lengths: ");
        for (int length : sampleLengths) {
            System.out.print(length + " bytes ");
        }
        System.out.println();
        System.out.println("Total file size: " + (32 + allData.size()) + " bytes");
    }

    private static byte[] createSampleTable(List<Integer> sampleAddresses, List<Integer> sampleLengths) {
        byte[] table = new byte[32];
        int num = Math.min(16, sampleAddresses.size());
        for (int i = 0; i < num; i++) {
            int addr = sampleAddresses.get(i);
            table[i] = (byte) (addr >> 8);
            int endAddr = addr + sampleLengths.get(i);
            table[16 + i] = (byte) (endAddr >> 8);
        }
        return table;
    }
}