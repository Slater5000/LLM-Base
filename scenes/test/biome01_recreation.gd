extends Node2D
## Recreates the Biome 01 Visualization using TileMap
## Run this scene (F5 or F6) to see the result

@onready var bg: TileMapLayer = $Background
@onready var terrain: TileMapLayer = $Terrain
@onready var objects: TileMapLayer = $Objects

# Tileset coordinate reference (col, row):
# Rows 0-1: Small decorations (mushrooms, eggs, slimes, rocks)
# Rows 2-5: Boulder (cols 0-2), Tree (cols 4-6)
# Rows 6-7: Fence posts
# Rows 8-11: Hedges - round (cols 0-2), square (cols 0-2 offset), small bushes (cols 5-7)
# Rows 12-15: GREEN GRASS tiles (cols 0-2 are solid green)
# Rows 16-19: Water pond tiles (blue circles with sand border)
# Rows 20-23: Brown dirt/sand ground
# Rows 24-27: Stone path (gray bricks)
# Rows 28-31: Stone path corners/edges
# Rows 32-35: Bridge
# Rows 36-39: Grass strips with flowers
# Rows 40-44: Red barn (full 8 cols wide)

func _ready() -> void:
	populate_visualization()


func populate_visualization() -> void:
	var width := 40
	var height := 40

	# === BACKGROUND LAYER (green grass) ===
	# Grass tiles are at rows 12-15, cols 0-2 are the nice green ones
	for y in range(height):
		for x in range(width):
			# Use grass tiles from row 12-13, varying columns 0-2
			var grass_col := x % 3
			var grass_row := 12 + (y % 2)
			bg.set_cell(Vector2i(x, y), 0, Vector2i(grass_col, grass_row))

	# === TERRAIN LAYER ===

	# Brown dirt area (top-right corner) - rows 20-23
	for y in range(0, 10):
		for x in range(28, 40):
			var dirt_col := x % 3
			var dirt_row := 20 + (y % 3)
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(dirt_col, dirt_row))

	# River running down right side - water/pond tiles rows 16-19
	# These are the blue circle water tiles
	for y in range(8, 34):
		# River is 3 tiles wide
		terrain.set_cell(Vector2i(26, y), 0, Vector2i(0, 17))
		terrain.set_cell(Vector2i(27, y), 0, Vector2i(1, 17))
		terrain.set_cell(Vector2i(28, y), 0, Vector2i(2, 17))

	# Water edges (sand border) - row 16 has the bordered water
	for y in range(8, 34):
		terrain.set_cell(Vector2i(25, y), 0, Vector2i(0, 16))  # left edge
		terrain.set_cell(Vector2i(29, y), 0, Vector2i(2, 16))  # right edge

	# Stone path (L-shaped) - rows 24-27
	# Horizontal section
	for x in range(5, 15):
		terrain.set_cell(Vector2i(x, 14), 0, Vector2i(0, 24))
		terrain.set_cell(Vector2i(x, 15), 0, Vector2i(0, 25))
		terrain.set_cell(Vector2i(x, 16), 0, Vector2i(0, 26))

	# Vertical section of path
	for y in range(16, 27):
		terrain.set_cell(Vector2i(5, y), 0, Vector2i(0, 24))
		terrain.set_cell(Vector2i(6, y), 0, Vector2i(1, 24))
		terrain.set_cell(Vector2i(7, y), 0, Vector2i(2, 24))

	# Bridge over river - rows 32-35
	for bx in range(8):
		for by in range(4):
			terrain.set_cell(Vector2i(22 + bx, 18 + by), 0, Vector2i(bx, 32 + by))

	# Rocky cliff (bottom-right) - using stone tiles rows 28-31
	for y in range(30, 40):
		for x in range(32, 40):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(6 + (x % 2), 28 + (y % 3)))

	# === OBJECTS LAYER ===

	# Large tree (top-left) - cols 4-6, rows 2-5 (3x4 tiles)
	place_tree(1, 2)

	# Large tree (left side, lower)
	place_tree(1, 28)

	# Small tree (bottom-left)
	place_small_tree(6, 33)

	# Red Barn - rows 40-44 (8x5 tiles)
	place_barn(4, 5)

	# Green hedge (round) - rows 8-11, cols 0-2 (3x4 tiles but visually 3x3)
	place_hedge(11, 18)

	# Fence sections - rows 6-7
	for i in range(5):
		objects.set_cell(Vector2i(8 + i, 31), 0, Vector2i(i % 3, 6))
		objects.set_cell(Vector2i(8 + i, 32), 0, Vector2i(i % 3, 7))

	# Boulder (top-right) - cols 0-2, rows 2-5
	place_boulder(34, 3)

	# Scattered decorations from row 0
	objects.set_cell(Vector2i(16, 23), 0, Vector2i(0, 0))  # red mushroom
	objects.set_cell(Vector2i(14, 29), 0, Vector2i(1, 0))  # yellow mushroom
	objects.set_cell(Vector2i(5, 12), 0, Vector2i(2, 0))   # rock
	objects.set_cell(Vector2i(15, 26), 0, Vector2i(3, 0))  # green egg
	objects.set_cell(Vector2i(18, 24), 0, Vector2i(4, 0))  # blue egg
	objects.set_cell(Vector2i(20, 8), 0, Vector2i(5, 0))   # green slime
	objects.set_cell(Vector2i(19, 12), 0, Vector2i(6, 0))  # blue slime
	objects.set_cell(Vector2i(35, 7), 0, Vector2i(7, 0))   # water drop

	# More rocks scattered
	objects.set_cell(Vector2i(31, 33), 0, Vector2i(2, 0))

	# Flower grass strips - rows 36-39
	for fx in range(4):
		objects.set_cell(Vector2i(10 + fx, 30), 0, Vector2i(fx % 8, 36))
		objects.set_cell(Vector2i(16 + fx, 26), 0, Vector2i(fx % 8, 37))

	# Small bushes from hedge rows (cols 5-7, rows 8-11)
	objects.set_cell(Vector2i(21, 9), 0, Vector2i(5, 8))
	objects.set_cell(Vector2i(21, 10), 0, Vector2i(5, 9))
	objects.set_cell(Vector2i(32, 18), 0, Vector2i(6, 8))
	objects.set_cell(Vector2i(32, 19), 0, Vector2i(6, 9))

	print("Biome 01 visualization recreated with corrected coordinates!")


func place_tree(x: int, y: int) -> void:
	# Large tree: cols 4-6, rows 2-5 in tileset (3x4 tiles)
	for ty in range(4):
		for tx in range(3):
			objects.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(4 + tx, 2 + ty))


func place_small_tree(x: int, y: int) -> void:
	# Use bottom portion of tree (trunk + lower canopy)
	for ty in range(3):
		for tx in range(2):
			objects.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(4 + tx, 3 + ty))


func place_barn(x: int, y: int) -> void:
	# Red barn: all 8 cols, rows 40-44 (8x5 tiles)
	for ty in range(5):
		for tx in range(8):
			objects.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(tx, 40 + ty))


func place_hedge(x: int, y: int) -> void:
	# Round hedge: cols 0-2, rows 8-11 (3x4 tiles, but top row may be mostly empty)
	for ty in range(3):
		for tx in range(3):
			objects.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(tx, 9 + ty))


func place_boulder(x: int, y: int) -> void:
	# Boulder: cols 0-2, rows 2-5 (3x4 tiles)
	for ty in range(4):
		for tx in range(3):
			objects.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(tx, 2 + ty))
