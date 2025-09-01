# ANTIC Mode D Animation Display

Displays a **128x96 main image** with a **32x16 animated rectangle** (6 frames) in **ANTIC Mode D** (160x96, 4 colors).  
Loads `main_image.bin` (3072 bytes) and `frame0.bin` to `frame5.bin` (128 bytes each) via `{$R resources.rc}`.  
Animates at `x=64, y=40` by copying frames to screen memory (`$9000`).

## Road Map

### Milestone 1
- POC: Main static image and animation frame successfully displayed, frames swapped.
- `.png` successfully converted to Atari 8-bit `.bin` format using Python utility.
- Encoding clarifications:  
  - Encoding: 1 byte encodes 4 pixels (2 bits per pixel, indices 0-3 mapping to `PF0-PF3` registers).  
  - **Main image**: 32 bytes/line × 96 lines.  
  - **Frames**: 8 bytes/line × 16 lines.
- Resources compiled into final build (included in executable).

### Milestone 2
- Screen colors configured in `.rc` file.
- Each frame with delay time (ms) configured in `.rc` file.
- Animation position (x, y) configured in `.rc` file (single x, y coordinates).

### Milestone 3
- Frame setup configured in `.rc` file (generated from Python utility):  
  - 6 × 32×16, or  
  - 3 × 32×32, or  
  - 2 × 32×48, or  
  - 6 × 16×32.
- Each frame can have associated position (x, y coordinates) configured in `.rc` file.

### Milestone 4
- `.bin` resources loaded from `D:` drive at runtime (not compiled into executable).
- All configuration previously in `.rc` file now loaded from `D:` drive and associated with `.bin` resources.
- New configuration entry: Duration of loaded animation on screen.
- Slideshow POC (multiple animation sets executed).

### Milestone 5
- Display list consists of:  
  - Margin.  
  - ANTIC Mode D: Main image with animation (centered).  
  - Margin.  
  - ANTIC Mode 2: 2 lines of text.  
  - Margin.

### Milestone 6
- Text lines with associated delay times configured in `.rc` file.
- Text lines slideshow (main image and frame animation run independently).

### Milestone 7
- Integration with MPT player (solving memory occupation conflicts, possible VBl issues etc)