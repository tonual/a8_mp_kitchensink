using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

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

class Program
{
    static void Main(string[] args)
    {
        if (args.Length < 2)
        {
            Console.WriteLine("Usage: program.exe <input_paths...> <output_file> [--start-addr=0x9000]");
            return;
        }

        List<string> inputPaths = new List<string>();
        string outputFile = null;
        int startAddr = 0x9000;

        for (int i = 0; i < args.Length; i++)
        {
            if (args[i].StartsWith("--start-addr="))
            {
                string hexStr = args[i].Substring("--start-addr=".Length);
                startAddr = Convert.ToInt32(hexStr, 16);
            }
            else if (outputFile == null && i == args.Length - 1)
            {
                outputFile = args[i];
            }
            else
            {
                inputPaths.Add(args[i]);
            }
        }

        if (outputFile == null)
        {
            Console.WriteLine("Error: Output file not specified.");
            return;
        }

        int sampleRate;
        string ext = Path.GetExtension(outputFile).ToLower();
        if (ext == ".d8")
        {
            sampleRate = 8000;
        }
        else if (ext == ".d15")
        {
            sampleRate = 15000;
        }
        else
        {
            Console.WriteLine("Error: Output file must end with .d8 or .d15");
            return;
        }

        List<string> wavFiles = GetWavFilesFromInput(inputPaths);
        if (wavFiles == null || wavFiles.Count == 0)
        {
            Console.WriteLine("Error: No WAV files found in the provided input paths.");
            return;
        }

        Console.WriteLine($"Found {wavFiles.Count} WAV files to process:");
        foreach (var wav in wavFiles)
        {
            Console.WriteLine($"  - {wav}");
        }

        try
        {
            ConvertToMultiDigi(wavFiles, outputFile, startAddr, sampleRate);
        }
        catch (Exception e)
        {
            Console.WriteLine($"Error: {e.Message}");
        }
    }

    static List<string> GetWavFilesFromInput(List<string> inputPaths)
    {
        List<string> wavFiles = new List<string>();

        foreach (var path in inputPaths)
        {
            if (File.Exists(path))
            {
                if (Path.GetExtension(path).ToLower() == ".wav")
                {
                    wavFiles.Add(path);
                }
                else
                {
                    Console.WriteLine($"Warning: {path} is not a WAV file, skipping.");
                }
            }
            else if (Directory.Exists(path))
            {
                string[] dirWavs = Directory.GetFiles(path, "*.wav", SearchOption.TopDirectoryOnly);
                if (dirWavs.Length == 0)
                {
                    Console.WriteLine($"Warning: No WAV files found in directory {path}");
                }
                else
                {
                    wavFiles.AddRange(dirWavs.OrderBy(f => f));
                }
            }
            else
            {
                Console.WriteLine($"Error: {path} is neither a file nor a directory.");
                return null;
            }
        }

        return wavFiles;
    }

    static void ConvertToMultiDigi(List<string> inputWavs, string outputFile, int startAddr, int sampleRate)
    {
        List<byte> allData = new List<byte>();
        List<int> sampleAddresses = new List<int>();
        List<int> sampleLengths = new List<int>();

        int currentAddr = startAddr;

        foreach (var inputWav in inputWavs)
        {
            string tempRaw = RunSoxCommand(inputWav, sampleRate);

            try
            {
                byte[] pcmData = File.ReadAllBytes(tempRaw);

                List<byte> pcm4bit = ConvertTo4Bit(pcmData);

                if (pcm4bit.Count % 2 != 0)
                {
                    pcm4bit.Add(0);
                }

                List<byte> packedData = new List<byte>();
                for (int i = 0; i < pcm4bit.Count; i += 2)
                {
                    byte sample1 = pcm4bit[i];
                    byte sample2 = pcm4bit[i + 1];
                    byte packedByte = (byte)((sample1 << 4) | sample2);
                    packedData.Add(packedByte);
                }

                int packedLength = packedData.Count;
                int padding = (256 - (packedLength % 256)) % 256;
                packedData.AddRange(Enumerable.Repeat((byte)0x88, padding));
                int paddedPackedLength = packedData.Count;

                sampleAddresses.Add(currentAddr);
                sampleLengths.Add(paddedPackedLength);

                allData.AddRange(packedData);

                currentAddr += paddedPackedLength;

                Console.WriteLine($"Processed {inputWav}: {pcm4bit.Count} 4-bit samples " +
                                  $"(packed to {paddedPackedLength} bytes, padded by {padding} bytes)");
            }
            finally
            {
                if (File.Exists(tempRaw))
                {
                    File.Delete(tempRaw);
                }
            }
        }

        byte[] table = CreateSampleTable(sampleAddresses, sampleLengths);

        using (FileStream fs = new FileStream(outputFile, FileMode.Create))
        {
            fs.Write(table, 0, table.Length);
            fs.Write(allData.ToArray(), 0, allData.Count);
        }

        Console.WriteLine($"Created {outputFile} with {inputWavs.Count} samples.");
        Console.WriteLine($"Sample addresses: [{string.Join(", ", sampleAddresses.Select(a => $"${a:X4}"))}]");
        Console.WriteLine($"Sample lengths: [{string.Join(", ", sampleLengths.Select(l => $"{l} bytes"))}]");
        Console.WriteLine($"Total file size: {32 + allData.Count} bytes");
    }

    static string RunSoxCommand(string inputFile, int sampleRate)
    {
        string tempRaw = Path.GetTempFileName() + ".raw";

        ProcessStartInfo psi = new ProcessStartInfo
        {
            FileName = "sox",
            Arguments = $"\"{inputFile}\" -e unsigned-integer -b 8 -c 1 -r {sampleRate} \"{tempRaw}\"",
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using (Process process = Process.Start(psi))
        {
            string error = process.StandardError.ReadToEnd();
            process.WaitForExit();

            if (process.ExitCode != 0)
            {
                throw new Exception($"SoX error for {inputFile}: {error}");
            }
        }

        return tempRaw;
    }

    static List<byte> ConvertTo4Bit(byte[] pcmData)
    {
        List<byte> pcm4bit = new List<byte>();
        foreach (byte sample in pcmData)
        {
            byte val = (byte)((sample / 16) & 0x0F);
            pcm4bit.Add(val);
        }
        return pcm4bit;
    }

    static byte[] CreateSampleTable(List<int> sampleAddresses, List<int> sampleLengths)
    {
        byte[] table = new byte[32];

        for (int i = 0; i < Math.Min(16, sampleAddresses.Count); i++)
        {
            table[i] = (byte)(sampleAddresses[i] >> 8); // High byte of start address
        }

        for (int i = 0; i < Math.Min(16, sampleAddresses.Count); i++)
        {
            int endAddr = sampleAddresses[i] + sampleLengths[i];
            table[16 + i] = (byte)(endAddr >> 8); // High byte of end address
        }

        return table;
    }
}
