#!/usr/bin/env python3
"""
Manual extraction of large sprites that auto-detection misses.
Specify exact regions to extract.
"""

from PIL import Image
import os

def extract_region(input_path: str, output_path: str, x: int, y: int, width: int, height: int):
    """Extract a specific region from an image."""
    img = Image.open(input_path).convert("RGBA")
    region = img.crop((x, y, x + width, y + height))
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    region.save(output_path, "PNG")
    print(f"Extracted {width}x{height} from ({x}, {y}) -> {output_path}")

if __name__ == "__main__":
    tileset = "assets/tilesets/biomes/Biome 01/01 - Tileset - Transparent.png"
    output_dir = "assets/sprites/biome_01"

    # Get image dimensions first
    img = Image.open(tileset)
    print(f"Tileset dimensions: {img.width}x{img.height}")

    # Large sprites to extract (x, y, width, height, name)
    large_sprites = [
        # Red barn - just the building (skip hedge on left)
        (64, 1296, 192, 144, "barn"),
        # Bridge/staircase sections
        (192, 288, 64, 160, "bridge_upper"),
        (192, 448, 64, 160, "bridge_lower"),
        (192, 608, 64, 160, "bridge_bottom"),
        # Large green tree
        (192, 96, 64, 96, "tileset_tree"),
        # Hedge row at bottom left
        (0, 1280, 64, 80, "hedge_row"),
    ]

    for x, y, w, h, name in large_sprites:
        try:
            output = os.path.join(output_dir, f"{name}.png")
            extract_region(tileset, output, x, y, w, h)
        except Exception as e:
            print(f"Failed to extract {name}: {e}")
