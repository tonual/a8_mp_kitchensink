Displays a 128x96 main image with a 32x16 animated rectangle (6 frames) 
in ANTIC Mode D (160x96, 4 colors). 
Loads main_image.bin (3072 bytes) and frame0.bin to frame5.bin (128 bytes each) via {$R resources.rc}. 
Animates at x=64, y=40 by copying frames to screen memory ($9000). 