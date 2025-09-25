import argparse
import os
import subprocess
import tempfile
import glob

#Processing steps:
#1. Parse Args & Config: Read inputs, output file, start addr ($9000 default). Infer sample rate from ext (.d8=8kHz, .d15=15kHz). Validate or error.
#2. Collect WAVs: Scan paths for .wav files (files or dirs), sort, list valid ones. Skip non-WAVs.
#3. Init Structures: Prep lists for addresses, lengths, data buffer. Set current addr to start_addr.
#4 .Process Each WAV:

#4a: SoX convert to 8-bit mono raw PCM at target rate (temp file).
#4b: Read raw, scale to 4-bit (0-15).
#4c: Pack pairs into bytes ((high<<4)|low); pad odd with 0.
#4d: Pad to 256-byte multiple with 0x88 (silence).
#4e: Record addr/len, append to buffer, advance addr.

#5 .Build Table: 32-byte array: bytes 0-15 = start high-bytes (up to 16 samples); 16-31 = end high-bytes.
#6 .Write Output: Table + packed data to file. Print summary (samples, addrs, lens, size).
#7 .Cleanup: Delete temps, handle errors.

def run_sox_command(input_file, output_file, sample_rate=8000):
    """Run SoX to convert input audio to 8-bit unsigned PCM raw file."""
    try:
        temp_fd, temp_path = tempfile.mkstemp(suffix='.raw')
        os.close(temp_fd)
        cmd = [
            'sox', input_file,
            '-e', 'unsigned-integer',
            '-b', '8',
            '-c', '1',
            '-r', str(sample_rate),
            temp_path
        ]
        subprocess.run(cmd, check=True, stderr=subprocess.PIPE, text=True)
        return temp_path
    except subprocess.CalledProcessError as e:
        print(f"SoX error for {input_file}: {e.stderr}")
        raise
    except FileNotFoundError:
        print("Error: SoX is not installed or not found in PATH.")
        raise

def convert_to_4bit(pcm_data):
    """Convert 8-bit PCM (0-255) to 4-bit PCM (0-15)."""
    return [int((sample & 0xFF) / 16) & 0x0F for sample in pcm_data]

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
    
    # Start address for first sample (after 32-byte table)
    current_addr = start_addr
    
    for input_wav in input_wavs:
        # Convert WAV to 8-bit PCM
        temp_raw = run_sox_command(input_wav, 'temp.raw', sample_rate)
        
        try:
            # Read 8-bit PCM
            with open(temp_raw, 'rb') as f:
                pcm_data = f.read()
            
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
            
            # Pad to 256-byte multiple with silence (0x88 bytes - middle value for silence)
            packed_length = len(packed_data)
            padding = (256 - (packed_length % 256)) % 256
            packed_data.extend([0x88] * padding)
            padded_packed_length = len(packed_data)
            
            # Store sample info
            sample_addresses.append(current_addr)
            sample_lengths.append(padded_packed_length)
            
            # Add sample data to output
            all_data.extend(packed_data)
            
            # Update address for next sample
            current_addr += padded_packed_length
            
            print(f"Processed {input_wav}: {len(pcm_4bit)} 4-bit samples "
                  f"(packed to {padded_packed_length} bytes, padded by {padding} bytes)")
        
        finally:
            if os.path.exists(temp_raw):
                os.remove(temp_raw)
    
    # Create sample table
    table = create_sample_table(sample_addresses, sample_lengths)
    
    # Write to output file (table first, then sample data)
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
            # Single file
            if path.lower().endswith('.wav'):
                wav_files.append(path)
            else:
                print(f"Warning: {path} is not a WAV file, skipping.")
        elif os.path.isdir(path):
            # Directory - find all WAV files
            pattern = os.path.join(path, "*.wav")
            dir_wavs = glob.glob(pattern)
            if not dir_wavs:
                print(f"Warning: No WAV files found in directory {path}")
            else:
                wav_files.extend(sorted(dir_wavs))  # Sort for consistent ordering
        else:
            print(f"Error: {path} is neither a file nor a directory.")
            return None
    
    return wav_files

def main():
    parser = argparse.ArgumentParser(description="Convert multiple WAVs to a single .D8 or .D15 file. Brought to you by tonual/GPT")
    parser.add_argument("input_paths", nargs='+', 
                        help="Input WAV files or directories containing WAV files")
    parser.add_argument("output_file", help="Output .D8 or .D15 file")
    parser.add_argument("--start-addr", type=lambda x: int(x, 0), default=0x9000,
                        help="Start address in hex (default: 0x9000)")
    args = parser.parse_args()
    
    # Determine sample rate based on output file extension
    if args.output_file.lower().endswith('.d8'):
        sample_rate = 8000
    elif args.output_file.lower().endswith('.d15'):
        sample_rate = 15000
    else:
        print("Error: Output file must end with .d8 or .d15")
        return
    
    # Get WAV files from input paths
    wav_files = get_wav_files_from_input(args.input_paths)
    if wav_files is None:
        return
    
    if not wav_files:
        print("Error: No WAV files found in the provided input paths.")
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