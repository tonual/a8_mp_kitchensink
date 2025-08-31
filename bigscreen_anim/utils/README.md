Converts a 160x96 PNG (4-color, indexed) to Atari 800XL binary files for 
ANTIC Mode D (Graphics 7, 160x96, 4 colors). 

Extracts a 128x96 main image (main_image.bin, 3072 bytes) from (0,0) 
and six 32x16 frames (frame0.bin to frame5.bin, 128 bytes each) stacked vertically at x=128 (y=0,16,32,48,64,80). 
Each .bin file is raw binary, with 1 byte encoding 4 pixels (2 bits per pixel, indices 0-3 mapping to PF0-PF3 registers). 

Main image: 32 bytes/line x 96 lines. 
Frames: 8 bytes/line x 16 lines. Run with python png2bin.py input.png