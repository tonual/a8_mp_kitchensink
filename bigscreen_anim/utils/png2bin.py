from PIL import Image
import sys

def validate_png(image, expected_width=160, expected_height=96, max_colors=4):
    """Validate PNG dimensions and palette size."""
    if image.mode != 'P':
        raise ValueError("Image must be in indexed color mode (P).")
    if image.size[0] != expected_width or image.size[1] != expected_height:
        raise ValueError(f"Image must be exactly {expected_width}x{expected_height} pixels.")
    palette = image.getpalette()
    if palette is None or len(palette) // 3 > max_colors:
        raise ValueError(f"Image must have at most {max_colors} colors in palette.")

def pixels_to_atari_byte(pixels):
    """Convert 4 pixels (palette indices 0-3) to a single Atari Mode D byte."""
    if len(pixels) != 4:
        raise ValueError("Exactly 4 pixels required per byte.")
    for p in pixels:
        if p > 3:
            raise ValueError(f"Pixel value {p} exceeds max palette index (3).")
    # Pack 4 pixels (2 bits each) into 1 byte: p0<<6 | p1<<4 | p2<<2 | p3
    return (pixels[0] << 6) | (pixels[1] << 4) | (pixels[2] << 2) | pixels[3]

def extract_main_image(image, width=128, height=96):
    """Extract main image (128x96) and convert to Atari Mode D binary format."""
    data = []
    for y in range(height):
        row = []
        for x in range(0, width, 4):
            pixels = [image.getpixel((x + i, y)) for i in range(4)]
            row.append(pixels_to_atari_byte(pixels))
        data.extend(row)
    return bytes(data)

def extract_frame(image, x, y, width=32, height=16):
    """Extract a single frame (32x16) and convert to Atari Mode D binary format."""
    data = []
    for dy in range(height):
        row = []
        for dx in range(0, width, 4):
            pixels = [image.getpixel((x + dx + i, y + dy)) for i in range(4)]
            row.append(pixels_to_atari_byte(pixels))
        data.extend(row)
    return bytes(data)

def main(input_png, output_dir="."):
    # Open and validate PNG
    image = Image.open(input_png)
    validate_png(image)

    # Extract main image (128x96 at 0,0)
    main_data = extract_main_image(image)
    with open(f"{output_dir}/main_image.bin", "wb") as f:
        f.write(main_data)

    # Extract 6 frames (32x16 each, stacked vertically at x=128)
    frame_positions = [(128, i * 16) for i in range(6)]  # Frames at (128,0), (128,16), ..., (128,80)
    for i, (x, y) in enumerate(frame_positions):
        frame_data = extract_frame(image, x, y)
        with open(f"{output_dir}/frame{i}.bin", "wb") as f:
            f.write(frame_data)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python create_atari_resources.py input.png")
        sys.exit(1)
    main(sys.argv[1])