#!/usr/bin/env python3
"""Auto-extract separated sprites from Buttons.png"""

from PIL import Image
import numpy as np
from scipy import ndimage
import os
import sys

def find_sprites(img_path, min_size=10):
    """Find all sprites in an image with transparency gaps."""
    img = Image.open(img_path).convert("RGBA")
    arr = np.array(img)

    # Create mask of non-transparent pixels
    alpha = arr[:, :, 3]
    mask = alpha > 0

    # Label connected regions
    labeled, num_features = ndimage.label(mask)
    print(f"Found {num_features} regions")

    sprites = []
    for i in range(1, num_features + 1):
        region = (labeled == i)
        rows = np.any(region, axis=1)
        cols = np.any(region, axis=0)

        y_min, y_max = np.where(rows)[0][[0, -1]]
        x_min, x_max = np.where(cols)[0][[0, -1]]

        w = x_max - x_min + 1
        h = y_max - y_min + 1

        # Skip tiny sprites
        if w < min_size or h < min_size:
            continue

        sprites.append({
            'x': int(x_min),
            'y': int(y_min),
            'w': int(w),
            'h': int(h)
        })

    # Sort by y then x
    sprites.sort(key=lambda s: (s['y'], s['x']))
    return sprites, img

def main():
    img_path = "assets/sprites/craftpix_ui/Buttons.png"
    output_dir = "assets/sprites/ui/buttons_new"

    if not os.path.exists(img_path):
        print(f"Not found: {img_path}")
        return

    sprites, img = find_sprites(img_path, min_size=15)
    print(f"Found {len(sprites)} buttons")

    os.makedirs(output_dir, exist_ok=True)

    for i, s in enumerate(sprites):
        region = img.crop((s['x'], s['y'], s['x'] + s['w'], s['y'] + s['h']))
        out_path = os.path.join(output_dir, f"button_{i:03d}_{s['w']}x{s['h']}.png")
        region.save(out_path, "PNG")
        print(f"  {out_path}")

    print(f"\nExtracted {len(sprites)} buttons to {output_dir}")

if __name__ == "__main__":
    main()
