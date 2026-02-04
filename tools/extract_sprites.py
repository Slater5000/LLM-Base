#!/usr/bin/env python3
"""
Smart Sprite Extractor - Detects actual sprite boundaries using transparency.
Finds connected regions of non-transparent pixels and extracts each as a separate PNG.
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
    from scipy import ndimage
except ImportError:
    print("Installing required packages...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow", "numpy", "scipy"])
    from PIL import Image
    import numpy as np
    from scipy import ndimage


def extract_sprites(input_path: str, output_dir: str, min_size: int = 4, max_size: int = 200, padding: int = 0):
    """
    Extract individual sprites from a tileset using connected component analysis.

    Args:
        input_path: Path to the tileset PNG (must have transparency)
        output_dir: Directory to save extracted sprites
        min_size: Minimum sprite dimension (filters out tiny noise)
        padding: Extra pixels around each sprite (0 = tight crop)
    """
    # Load image with alpha channel
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)

    # Create binary mask from alpha channel (non-transparent = True)
    alpha = data[:, :, 3]
    mask = alpha > 10  # Threshold to ignore near-transparent pixels

    # Find connected components (each sprite becomes a labeled region)
    labeled_array, num_features = ndimage.label(mask)
    print(f"Found {num_features} sprites in {Path(input_path).name}")

    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    # Get the base name for output files
    base_name = Path(input_path).stem.replace(" - Tileset - Transparent", "").replace(" ", "_").lower()

    # Extract each sprite
    sprites_info = []
    for i in range(1, num_features + 1):
        # Find bounding box for this component
        positions = np.where(labeled_array == i)
        if len(positions[0]) == 0:
            continue

        y_min, y_max = positions[0].min(), positions[0].max() + 1
        x_min, x_max = positions[1].min(), positions[1].max() + 1

        width = x_max - x_min
        height = y_max - y_min

        # Skip tiny sprites (noise) and oversized regions (visualization areas)
        if width < min_size or height < min_size:
            continue
        if width > max_size or height > max_size:
            print(f"  Skipped oversized region: {width}x{height} (likely visualization area)")
            continue

        # Apply padding
        y_min = max(0, y_min - padding)
        y_max = min(data.shape[0], y_max + padding)
        x_min = max(0, x_min - padding)
        x_max = min(data.shape[1], x_max + padding)

        # Extract sprite region
        sprite_data = data[y_min:y_max, x_min:x_max].copy()

        # Create sprite image
        sprite_img = Image.fromarray(sprite_data, "RGBA")

        # Generate filename with size info
        filename = f"{base_name}_{i:03d}_{width}x{height}.png"
        output_path = os.path.join(output_dir, filename)

        sprite_img.save(output_path, "PNG")
        sprites_info.append({
            "filename": filename,
            "width": width,
            "height": height,
            "original_x": x_min,
            "original_y": y_min
        })

    # Save manifest file for reference
    manifest_path = os.path.join(output_dir, "_manifest.txt")
    with open(manifest_path, "w") as f:
        f.write(f"# Sprites extracted from: {Path(input_path).name}\n")
        f.write(f"# Total sprites: {len(sprites_info)}\n\n")
        for info in sorted(sprites_info, key=lambda x: (x["height"], x["width"]), reverse=True):
            f.write(f"{info['filename']}: {info['width']}x{info['height']} @ ({info['original_x']}, {info['original_y']})\n")

    print(f"Extracted {len(sprites_info)} sprites to {output_dir}")
    print(f"Manifest saved to {manifest_path}")
    return sprites_info


def process_biome_folder(biome_path: str, output_base: str):
    """Process all transparent tilesets in a biome folder."""
    biome_path = Path(biome_path)
    output_base = Path(output_base)

    # Find all transparent tileset PNGs
    for png_file in biome_path.glob("*Transparent*.png"):
        biome_name = biome_path.name.lower().replace(" ", "_")
        output_dir = output_base / biome_name / png_file.stem.replace(" ", "_").lower()
        extract_sprites(str(png_file), str(output_dir))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage:")
        print("  Single file:  python extract_sprites.py <tileset.png> [output_dir]")
        print("  Biome folder: python extract_sprites.py --biome <biome_folder> [output_base]")
        print()
        print("Example:")
        print('  python extract_sprites.py "assets/tilesets/biomes/Biome 01/01 - Tileset - Transparent.png"')
        sys.exit(1)

    if sys.argv[1] == "--biome":
        biome_folder = sys.argv[2]
        output_base = sys.argv[3] if len(sys.argv) > 3 else "assets/sprites/extracted"
        process_biome_folder(biome_folder, output_base)
    else:
        input_file = sys.argv[1]
        output_dir = sys.argv[2] if len(sys.argv) > 2 else str(Path(input_file).parent / "extracted")
        extract_sprites(input_file, output_dir)
