#!/usr/bin/env python3
"""
Create a BMFont .fnt file from Craftpix Text1.png spritesheet.
Uses grid-based extraction since characters are on a regular grid.
"""

from PIL import Image
import os

# Grid layout based on visual inspection
CELL_WIDTH = 7    # Each character cell is 7 pixels wide
CELL_HEIGHT = 9   # Each row is 9 pixels tall
COLS_PER_ROW = 10 # 10 characters per row (70px / 7px)

# Character sequences for each row in the brown variant (first 4 rows)
# Based on actual image analysis:
ROW_CHARS = [
    "ABCDEFGHIJ",  # Row 0: A-J
    "KLMNOPQRST",  # Row 1: K-T
    "UVWXYZ",      # Row 2: U-Z (only 6 chars, positions 0-5)
    "1234567890",  # Row 3: digits
]

# Additional characters if needed (punctuation in later rows)
ROW4_CHARS = ".,:;!?'\"()"  # Estimate - may need adjustment

def create_font_from_grid(img_path, output_dir, font_name="pixel_brown"):
    """Create BMFont using grid-based character positions."""
    img = Image.open(img_path).convert("RGBA")

    print(f"Image size: {img.width}x{img.height}")
    print(f"Grid: {CELL_WIDTH}x{CELL_HEIGHT} cells, {COLS_PER_ROW} cols")

    os.makedirs(output_dir, exist_ok=True)

    chars = []

    for row_idx, row_chars in enumerate(ROW_CHARS):
        for col_idx, char in enumerate(row_chars):
            x = col_idx * CELL_WIDTH
            y = row_idx * CELL_HEIGHT

            # Trim actual character bounds within the cell
            cell = img.crop((x, y, x + CELL_WIDTH, y + CELL_HEIGHT))
            bbox = cell.getbbox()

            if bbox:
                # Adjust bounds relative to full image
                char_x = x + bbox[0]
                char_y = y + bbox[1]
                char_w = bbox[2] - bbox[0]
                char_h = bbox[3] - bbox[1]

                chars.append({
                    'char': char,
                    'x': char_x,
                    'y': char_y,
                    'width': char_w,
                    'height': char_h
                })
                print(f"  '{char}': ({char_x}, {char_y}) {char_w}x{char_h}")

    # Try to get punctuation from row 4 (if exists)
    row_idx = 4
    for col_idx, char in enumerate(ROW4_CHARS):
        x = col_idx * CELL_WIDTH
        y = row_idx * CELL_HEIGHT

        cell = img.crop((x, y, x + CELL_WIDTH, y + CELL_HEIGHT))
        bbox = cell.getbbox()

        if bbox:
            char_x = x + bbox[0]
            char_y = y + bbox[1]
            char_w = bbox[2] - bbox[0]
            char_h = bbox[3] - bbox[1]

            chars.append({
                'char': char,
                'x': char_x,
                'y': char_y,
                'width': char_w,
                'height': char_h
            })
            print(f"  '{char}': ({char_x}, {char_y}) {char_w}x{char_h}")

    # Extract font texture (enough rows to cover our characters)
    section_height = 5 * CELL_HEIGHT  # 5 rows
    font_img = img.crop((0, 0, img.width, section_height))

    texture_path = os.path.join(output_dir, f"{font_name}.png")
    font_img.save(texture_path)
    print(f"\nSaved font texture: {texture_path}")

    # Generate .fnt file
    max_height = max(c['height'] for c in chars) if chars else 7
    line_height = max_height + 2

    fnt_path = os.path.join(output_dir, f"{font_name}.fnt")

    with open(fnt_path, 'w') as f:
        f.write(f'info face="{font_name}" size={max_height} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1\n')
        f.write(f'common lineHeight={line_height} base={max_height} scaleW={img.width} scaleH={section_height} pages=1 packed=0\n')
        f.write(f'page id=0 file="{font_name}.png"\n')

        # Count total chars
        upper_count = sum(1 for c in chars if c['char'].isupper())
        total_count = len(chars) + upper_count + 1
        f.write(f'chars count={total_count}\n')

        # Write character definitions
        for c in chars:
            char_id = ord(c['char'])
            f.write(f"char id={char_id} x={c['x']} y={c['y']} width={c['width']} height={c['height']} xoffset=0 yoffset={max_height - c['height']} xadvance={c['width'] + 1} page=0 chnl=15\n")

        # Add lowercase copies
        for c in chars:
            if c['char'].isupper():
                lower_id = ord(c['char'].lower())
                f.write(f"char id={lower_id} x={c['x']} y={c['y']} width={c['width']} height={c['height']} xoffset=0 yoffset={max_height - c['height']} xadvance={c['width'] + 1} page=0 chnl=15\n")

        # Add space
        avg_width = sum(c['width'] for c in chars) // len(chars) if chars else 4
        f.write(f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance={avg_width} page=0 chnl=15\n")

    print(f"Saved font file: {fnt_path}")
    print(f"Total characters: {len(chars)} + {upper_count} lowercase + space")

    return fnt_path

def main():
    img_path = "assets/sprites/craftpix_ui/Text1.png"
    output_dir = "assets/fonts"

    create_font_from_grid(img_path, output_dir, "pixel_brown")

if __name__ == "__main__":
    main()
