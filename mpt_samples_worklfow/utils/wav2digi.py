import argparse
import os
import wave
import glob

# Input format requirements: 8-bit unsigned PCM WAV files (mono, 8kHz or 15kHz)

# Processing steps:
# 1. Parse Args & Config: Read inputs, output file, start addr ($9000 default). Infer sample rate from ext (.d8=8kHz, .d15=15kHz).
# 2. Collect WAVs: Scan paths for .wav files, sort, list valid ones.
# 3. Init Structures: Prep lists for addresses, lengths, data buffer.
# 4. Process Each WAV:
#    a. Read raw, scale to 4-bit (0-15).
#    b. Pack pairs into bytes ((high<<4)|low); pad odd with 0.
#    c. Pad to 256-byte multiple with 0x88 (silence).
#    d. Record addr/len, append to buffer, advance addr.
# 5. Build Table: 32-byte array: bytes 0-15 = start high-bytes; 16-31 = end high-bytes.
# 6. Write Output: Table + packed data to file. Print summary.

def read_pcm_samples(path):
    """Read unsigned 8-bit PCM samples from a mono WAV file."""
    with wave.open(path, 'rb') as wf:
        n_channels = wf.getnchannels()
        sampwidth = wf.getsampwidth()
        framerate = wf.getframerate()
        n_frames = wf.getnframes()

        if n_channels != 1 or sampwidth != 1:
            raise ValueError(f"{path} must be 8-bit mono PCM")

        pcm_data = wf.readframes(n_frames)
        return list(pcm_data), framerate

def convert_to_4bit(pcm_data):
    """Convert 8-bit PCM (0-255) to 4-bit PCM (0-15)."""
    return [int(sample / 16) & 0x0F for sample in pcm_data]

def create_sample_table(sample_addresses, sample_lengths):
    """Create a proper sample table with addresses and lengths."""
    table = bytearray(32)
    
    # Fill sample start addresses (first 16 bytes)
    for i, addr in enumerate(sample_addresses[:16]):
        table[i] = addr >> 8  # High byte of start address
    
    # Fill sample end addresses (last 16 bytes)
    for i, (addr, length) in enumerate(zip(sample_addresses[:16], sample_lengths[:16])):
        end_addr = addr + length
        table[16 + i] = end_addr >> 8  # High byte of end address
    
    return bytes(table)

def convert_to_multi_digi(input_wavs, output_file, start_addr=0x9000, sample_rate=8000):
    """Convert multiple WAV files to a single .D8 or .D15 file with headers and sample table."""
    all_data = bytearray()
    sample_addresses = []
    sample_lengths = []
    current_addr = start_addr

    for input_wav in input_wavs:
        # Read PCM frames properly
        pcm_data, framerate = read_pcm_samples(input_wav)

        if framerate != sample_rate:
            raise ValueError(f"{input_wav} has {framerate} Hz, expected {sample_rate} Hz")

        # Convert to 4-bit PCM
        pcm_4bit = convert_to_4bit(pcm_data)

        # Ensure even number of samples for packing
        if len(pcm_4bit) % 2 != 0:
            pcm_4bit.append(0)

        # Pack two 4-bit samples into one byte
        packed_data = bytearray()
        for i in range(0, len(pcm_4bit), 2):
            sample1 = pcm_4bit[i]
            sample2 = pcm_4bit[i + 1]
            packed_byte = (sample1 << 4) | sample2
            packed_data.append(packed_byte)

        # Pad to 256-byte multiple with silence (0x88)
        packed_length = len(packed_data)
        padding = (256 - (packed_length % 256)) % 256
        packed_data.extend([0x88] * padding)
        padded_packed_length = len(packed_data)

        # Store sample info
        sample_addresses.append(current_addr)
        sample_lengths.append(padded_packed_length)

        # Add to output
        all_data.extend(packed_data)
        current_addr += padded_packed_length

        print(f"Processed {input_wav}: {len(pcm_data)} PCM samples → {len(pcm_4bit)} 4-bit → "
              f"{packed_length} bytes (padded {padding}, final {padded_packed_length})")

    # Create sample table
    table = create_sample_table(sample_addresses, sample_lengths)

    # Write to output file
    with open(output_file, 'wb') as f:
        f.write(table)
        f.write(all_data)

    print(f"Created {output_file} with {len(input_wavs)} samples.")
    print(f"Sample addresses: {[f'${addr:04x}' for addr in sample_addresses]}")
    print(f"Sample lengths: {[f'{length} bytes' for length in sample_lengths]}")
    print(f"Total file size: {32 + len(all_data)} bytes")

def get_wav_files_from_input(input_paths):
    """Get list of WAV files from either individual files or directory."""
    wav_files = []
    for path in input_paths:
        if os.path.isfile(path):
            if path.lower().endswith('.wav'):
                wav_files.append(path)
            else:
                print(f"Warning: {path} is not a WAV file, skipping.")
        elif os.path.isdir(path):
            pattern = os.path.join(path, "*.wav")
            dir_wavs = glob.glob(pattern)
            if not dir_wavs:
                print(f"Warning: No WAV files found in directory {path}")
            else:
                wav_files.extend(sorted(dir_wavs))
        else:
            print(f"Error: {path} is neither a file nor a directory.")
            return None
    return wav_files

def main():
    parser = argparse.ArgumentParser(description="Convert multiple WAVs (8bit unsigned) to a single .D8 or .D15 file.")
    parser.add_argument("input_paths", nargs='+', help="Input WAV files or directories containing WAV files")
    parser.add_argument("output_file", help="Output .D8 or .D15 file")
    parser.add_argument("--start-addr", type=lambda x: int(x, 0), default=0x9000,
                        help="Start address in hex (default: 0x9000)")
    args = parser.parse_args()

    # Determine sample rate
    if args.output_file.lower().endswith('.d8'):
        sample_rate = 8000
    elif args.output_file.lower().endswith('.d15'):
        sample_rate = 15000
    else:
        print("Error: Output file must end with .d8 or .d15")
        return

    wav_files = get_wav_files_from_input(args.input_paths)
    if wav_files is None or not wav_files:
        print("Error: No WAV files found.")
        return

    print(f"Found {len(wav_files)} WAV files to process:")
    for wav in wav_files:
        print(f"  - {wav}")

    try:
        convert_to_multi_digi(wav_files, args.output_file, args.start_addr, sample_rate)
    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    main()