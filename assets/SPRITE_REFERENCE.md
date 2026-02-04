# Sprite Reference Map

Exact coordinates for extracting sprites from tilesets.

---

## core/tileset.png (832x400)

### Gyms (y=0, 80x80 each)
| Sprite | Region |
|--------|--------|
| Gym Leaf | Rect2(496, 0, 80, 80) |
| Gym Fire | Rect2(576, 0, 80, 80) |
| Gym Water | Rect2(656, 0, 80, 80) |
| Gym Ice | Rect2(736, 0, 80, 80) |

### Buildings Row 1 (y=80)
| Sprite | Region |
|--------|--------|
| Pokemon Center | Rect2(416, 80, 96, 80) |
| House Blue Roof | Rect2(512, 80, 80, 80) |
| House Purple Roof | Rect2(592, 80, 96, 80) |
| House Tan | Rect2(688, 80, 80, 80) |

### Buildings Row 2 (y=160)
| Sprite | Region |
|--------|--------|
| Pokemart | Rect2(416, 160, 80, 64) |
| House Purple Small | Rect2(496, 160, 80, 64) |
| House Green Roof | Rect2(576, 160, 96, 64) |

### Terrain (left side)
| Sprite | Region |
|--------|--------|
| Grass Base | Rect2(0, 0, 16, 16) |
| Water Center | Rect2(112, 80, 16, 16) |
| Path Dirt | Rect2(176, 0, 16, 16) |

### Trees (bottom left, ~y=240)
| Sprite | Region |
|--------|--------|
| Blue Pine | Rect2(0, 240, 32, 48) |
| Palm Tree | Rect2(48, 240, 32, 48) |
| Green Tree 1 | Rect2(96, 240, 32, 48) |
| Green Tree 2 | Rect2(128, 240, 32, 48) |

---

## terrain/3_plants.png (480x128)

| Sprite | Region |
|--------|--------|
| Big Tree Left | Rect2(0, 0, 48, 64) |
| Big Tree Right | Rect2(48, 0, 48, 64) |
| Well | Rect2(96, 32, 32, 32) |
| Big Rock | Rect2(128, 0, 48, 48) |
| Small Rocks | Rect2(176, 16, 32, 16) |
| Grass Tuft | Rect2(208, 48, 16, 16) |

---

## biomes/Biome 01/01 - Tileset.png (128x720)

| Sprite | Region | Notes |
|--------|--------|-------|
| Rocks Small | Rect2(0, 0, 48, 32) | Gray rocks cluster |
| Mushroom Red | Rect2(64, 0, 16, 16) | Red spotted |
| Mushroom Brown | Rect2(80, 0, 16, 16) | Brown cap |
| Flowers Yellow | Rect2(96, 16, 16, 16) | Yellow flowers |
| Big Boulder | Rect2(0, 48, 48, 48) | Large gray rock |
| Tree Large | Rect2(0, 96, 64, 80) | Round green tree |
| Fence Picket | Rect2(0, 176, 80, 16) | White picket fence |
| Hedge Round | Rect2(0, 208, 48, 32) | Round bush |
| Hedge Square | Rect2(48, 208, 32, 32) | Square trimmed |
| Water Pond | Rect2(0, 272, 48, 48) | Small pond |
| Stone Path | Rect2(0, 336, 64, 48) | Gray stone walkway |
| Grass Ground | Rect2(0, 400, 48, 48) | Green grass tile |
| Dirt Path | Rect2(64, 400, 48, 48) | Brown dirt |
| Flowers Row | Rect2(0, 464, 64, 16) | White flowers |
| Red Barn | Rect2(0, 640, 128, 80) | Full barn building |

---

## terrain/1_terrain.png (480x768)

16x16 tile grid (30 columns x 48 rows)

| Sprite | Region | Notes |
|--------|--------|-------|
| Grass Plain | Rect2(0, 0, 48, 48) | Solid green grass |
| Water Full | Rect2(96, 96, 48, 48) | Blue water center |
| Sand/Beach | Rect2(96, 192, 48, 48) | Tan sand |
| Stone Path | Rect2(288, 288, 48, 48) | Gray stone tiles |
| Dirt Ground | Rect2(192, 192, 48, 48) | Brown earth |

---

## sprites/characters/ow1.png

Character spritesheet with 4 columns x 5 rows (walking animations)
- Each frame: 32x32
- Row 0: Down walk
- Row 1: Up walk
- Row 2: Side walk (flip for other direction)
