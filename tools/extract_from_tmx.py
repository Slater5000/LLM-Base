#!/usr/bin/env python3
"""
Extract tiles from Tiled TMX tileset definitions.
Parses the TMX file to get grid info, then extracts individual tiles.

Usage:
    python extract_from_tmx.py <tmx_file> <tileset_name> <output_dir>

Example:
    python extract_from_tmx.py Cursed_land.tmx Ground ./ground_tiles/
"""

import os
import sys
import re
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: PIL/Pillow not installed. Run: pip install Pillow")
    sys.exit(1)


def parse_tmx_tilesets(tmx_path):
    """Parse TMX file to extract tileset definitions."""
    with open(tmx_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all tileset definitions with embedded image
    # Pattern: <tileset ... name="X" tilewidth="Y" tileheight="Z" tilecount="N" columns="C">
    #          <image source="file.png" .../>
    pattern = r'<tileset[^>]*name="([^"]+)"[^>]*tilewidth="(\d+)"[^>]*tileheight="(\d+)"[^>]*tilecount="(\d+)"[^>]*columns="(\d+)"[^>]*>\s*<image source="([^"]+)"'

    tilesets = {}
    for match in re.finditer(pattern, content):
        name, tw, th, count, cols, source = match.groups()
        tilesets[name] = {
            'name': name,
            'tilewidth': int(tw),
            'tileheight': int(th),
            'tilecount': int(count),
            'columns': int(cols),
            'source': source
        }

    return tilesets


def extract_tileset(tmx_dir, tileset_info, output_dir, skip_empty=True):
    """Extract all tiles from a tileset."""
    source_path = os.path.join(tmx_dir, tileset_info['source'])

    if not os.path.exists(source_path):
        print(f"ERROR: Image not found: {source_path}")
        return

    img = Image.open(source_path).convert("RGBA")

    tw = tileset_info['tilewidth']
    th = tileset_info['tileheight']
    cols = tileset_info['columns']
    total = tileset_info['tilecount']
    rows = (total + cols - 1) // cols

    print(f"Tileset: {tileset_info['name']}")
    print(f"  Image: {source_path} ({img.width}x{img.height})")
    print(f"  Grid: {cols}x{rows} tiles of {tw}x{th}px")
    print(f"  Total tiles: {total}")

    os.makedirs(output_dir, exist_ok=True)

    extracted = 0
    skipped = 0

    for tile_id in range(total):
        col = tile_id % cols
        row = tile_id // cols
        x = col * tw
        y = row * th

        # Crop tile
        tile = img.crop((x, y, x + tw, y + th))

        # Check if empty (all transparent)
        if skip_empty:
            extrema = tile.getextrema()
            if extrema[3][1] < 10:  # Alpha channel max < 10 = basically empty
                skipped += 1
                continue

        # Save tile
        filename = f"tile_{tile_id:04d}_r{row:02d}_c{col:02d}.png"
        tile.save(os.path.join(output_dir, filename), "PNG")
        extracted += 1

    print(f"\nExtracted: {extracted} tiles")
    print(f"Skipped (empty): {skipped} tiles")
    print(f"Output: {output_dir}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        print("\nTo list available tilesets in a TMX file:")
        print("  python extract_from_tmx.py <tmx_file> --list")
        sys.exit(0)

    tmx_path = sys.argv[1]

    if not os.path.exists(tmx_path):
        print(f"ERROR: TMX file not found: {tmx_path}")
        sys.exit(1)

    tmx_dir = os.path.dirname(os.path.abspath(tmx_path))
    tilesets = parse_tmx_tilesets(tmx_path)

    if len(sys.argv) == 2 or sys.argv[2] == "--list":
        print(f"Tilesets in {tmx_path}:\n")
        for name, info in tilesets.items():
            print(f"  {name}:")
            print(f"    Size: {info['tilewidth']}x{info['tileheight']}")
            print(f"    Tiles: {info['tilecount']} ({info['columns']} columns)")
            print(f"    Source: {info['source']}")
            print()
        sys.exit(0)

    tileset_name = sys.argv[2]
    output_dir = sys.argv[3] if len(sys.argv) > 3 else f"./{tileset_name}_tiles"

    if tileset_name not in tilesets:
        print(f"ERROR: Tileset '{tileset_name}' not found.")
        print(f"Available: {', '.join(tilesets.keys())}")
        sys.exit(1)

    extract_tileset(tmx_dir, tilesets[tileset_name], output_dir)


if __name__ == "__main__":
    main()
