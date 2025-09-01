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


## Big Picure

### Mission
Allow non-technical creators to develop story-telling/multimedia-rich experience, for stock A8 XL/XE.

### DDD
Single engine with data/resources driven execution.

# "Story Engine" Overview

The **Story Engine** is designed to load and display interactive story pages from `.atr` disk images.  
Each story page consists of configuration data, images, and music resources.

---

## Example `.atr` Image Contents

- `STORY_PAGE1.DAT`  
- `STORY_PAGE2.DAT`  
- ...  
- `STORY_ENGINE.XEX`  

---

## Story Page Structure (~40KB)

Each story page includes:  
1. **Page Configuration Data**:  
   - Animation settings  
   - Text sequences  
   - Timing information  

2. **Image Resource Data**:  
   - Up to 3-5 images  
   - Includes looped animation frames  

3. **Music Resource Data**

---

## Engine Behavior

- The engine loads `STORY_PAGE1.DAT` by default.  
- It retrieves the configuration data and processes the slides sequentially.  

---

## Configuration Example

### Slide 1

#### Image Animation
- **Animation Setup**: `32x16`  
- **Frame 1**:  
  - Position: `(56, 67)`  
  - Delay: `200ms`  
- **Frame 2**:  
  - Position: `(20, 30)`  
  - Delay: `100ms`  
- **Frame 3**:  
  - ...

#### Text Animation
- **Text 1**:  
  - Content: `"Hello world"`  
  - Delay: `2000ms`  
- **Text 2**:  
  - Content: `"Such a beautiful day we have!"`  
  - Delay: `3000ms`  

---

### Slide 2
- **Image Animation**: ...  
- **Text Animation**: ...  

---

## Slide Progression

Once all text and animations for a slide are completed, the engine automatically loads the next page:  
`D:STORY_PAGE2.DAT`