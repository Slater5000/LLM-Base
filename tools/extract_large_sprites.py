#!/usr/bin/env python3
"""
Batch Sprite Extractor
======================
Extracts sprites from tilesets using coordinate files.

Usage:
    python extract_large_sprites.py <tileset.png> <coords.txt> <output_dir>

Coords file format (one per line):
    name,x,y,width,height
    # Comments start with #

Example coords.txt:
    # Buildings
    dark_building_1,0,64,64,96
    dark_building_2,64,64,48,80
    # Decorations
    street_lamp,128,0,16,48
    crate,144,32,32,32
"""

from PIL import Image
import os
import sys
from pathlib import Path


def load_coords(filepath):
    """Load coordinates from text file."""
    sprites = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            # Skip empty lines and comments
            if not line or line.startswith('#'):
                continue
            parts = [p.strip() for p in line.split(',')]
            if len(parts) < 5:
                print(f"  Warning: Line {line_num} invalid (need name,x,y,w,h): {line}")
                continue
            try:
                sprites.append({
                    'name': parts[0],
                    'x': int(parts[1]),
                    'y': int(parts[2]),
                    'w': int(parts[3]),
                    'h': int(parts[4])
                })
            except ValueError as e:
                print(f"  Warning: Line {line_num} has invalid numbers: {line}")
    return sprites


def extract_sprites(tileset_path, coords, output_dir):
    """Extract all sprites from tileset."""
    img = Image.open(tileset_path).convert("RGBA")
    print(f"Tileset: {tileset_path} ({img.width}x{img.height})")

    os.makedirs(output_dir, exist_ok=True)

    extracted = 0
    for sprite in coords:
        name = sprite['name']
        x, y, w, h = sprite['x'], sprite['y'], sprite['w'], sprite['h']

        # Validate bounds
        if x + w > img.width or y + h > img.height:
            print(f"  SKIP {name}: Out of bounds ({x},{y} + {w}x{h} exceeds {img.width}x{img.height})")
            continue

        region = img.crop((x, y, x + w, y + h))
        output_path = os.path.join(output_dir, f"{name}.png")
        region.save(output_path, "PNG")
        print(f"  OK: {name}.png ({w}x{h})")
        extracted += 1

    print(f"\nExtracted {extracted}/{len(coords)} sprites to {output_dir}")


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        print("\nQuick start:")
        print("  1. Create coords.txt with: name,x,y,width,height (one per line)")
        print("  2. Run: python extract_large_sprites.py tileset.png coords.txt output/")
        print("\nTip: Use GIMP/Photoshop to find coordinates - hover shows X,Y position")
        sys.exit(0)

    tileset_path = sys.argv[1]
    coords_file = sys.argv[2]
    output_dir = sys.argv[3]

    if not os.path.exists(tileset_path):
        print(f"ERROR: Tileset not found: {tileset_path}")
        sys.exit(1)
    if not os.path.exists(coords_file):
        print(f"ERROR: Coords file not found: {coords_file}")
        sys.exit(1)

    coords = load_coords(coords_file)
    if not coords:
        print("ERROR: No valid coordinates found in file")
        sys.exit(1)

    print(f"Loaded {len(coords)} sprite definitions")
    extract_sprites(tileset_path, coords, output_dir)


if __name__ == "__main__":
    main()
