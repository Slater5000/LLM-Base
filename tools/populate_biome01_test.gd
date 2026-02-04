@tool
extends EditorScript
## Run this script in Godot: Project > Tools > Run
## Or from script editor: File > Run (Ctrl+Shift+X)
##
## This recreates the Biome 01 Visualization in the test scene.
## Make sure tilemap_test.tscn is open before running.

func _run() -> void:
	var root := get_editor_interface().get_edited_scene_root()
	if root == null:
		print("ERROR: No scene open. Open tilemap_test.tscn first!")
		return

	var bg := root.get_node_or_null("Background") as TileMapLayer
	var terrain := root.get_node_or_null("Terrain") as TileMapLayer
	var objects := root.get_node_or_null("Objects") as TileMapLayer

	if bg == null or terrain == null or objects == null:
		print("ERROR: TileMapLayers not found. Make sure you have Background, Terrain, Objects nodes.")
		return

	print("Populating Biome 01 visualization...")

	# Clear existing tiles
	bg.clear()
	terrain.clear()
	objects.clear()

	# The visualization is approximately 40x40 tiles
	var width := 40
	var height := 40

	# === BACKGROUND LAYER (grass) ===
	# Fill with grass tiles - using tiles from rows 14-17
	# Main grass tile appears to be at (0,14), (1,14), (2,14)
	for y in range(height):
		for x in range(width):
			# Vary the grass slightly for visual interest
			var grass_col := (x + y) % 3  # 0, 1, or 2
			bg.set_cell(Vector2i(x, y), 0, Vector2i(grass_col, 14))

	# === TERRAIN LAYER ===

	# Brown dirt area (top-right corner) - using dirt tiles from rows 16-17
	for y in range(0, 10):
		for x in range(28, 40):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(3, 16))

	# River running vertically on right side - water tiles from rows 18-20
	for y in range(5, 35):
		terrain.set_cell(Vector2i(26, y), 0, Vector2i(0, 18))
		terrain.set_cell(Vector2i(27, y), 0, Vector2i(1, 18))
		terrain.set_cell(Vector2i(28, y), 0, Vector2i(2, 18))

	# Stone path (L-shaped) - tiles from rows 24-29
	# Horizontal part
	for x in range(5, 14):
		terrain.set_cell(Vector2i(x, 15), 0, Vector2i(0, 24))
		terrain.set_cell(Vector2i(x, 16), 0, Vector2i(0, 25))
		terrain.set_cell(Vector2i(x, 17), 0, Vector2i(0, 26))
	# Vertical part
	for y in range(17, 28):
		terrain.set_cell(Vector2i(5, y), 0, Vector2i(0, 24))
		terrain.set_cell(Vector2i(6, y), 0, Vector2i(1, 24))
		terrain.set_cell(Vector2i(7, y), 0, Vector2i(2, 24))

	# Bridge over river - tiles from rows 30-35
	# Bridge is 6 tiles wide, 4 tiles tall approximately
	for bx in range(6):
		for by in range(4):
			terrain.set_cell(Vector2i(24 + bx, 18 + by), 0, Vector2i(bx % 8, 30 + by))

	# Rocky cliff area (bottom-right)
	for y in range(32, 40):
		for x in range(32, 40):
			terrain.set_cell(Vector2i(x, y), 0, Vector2i(6, 24))

	# === OBJECTS LAYER ===

	# Large tree (top-left) - 3x4 tiles at tileset cols 4-6, rows 2-5
	place_tree(objects, 1, 3)

	# Another large tree (left side, lower)
	place_tree(objects, 1, 30)

	# Smaller tree (bottom-left area)
	place_small_tree(objects, 6, 34)

	# Red Barn - 8x5 tiles at tileset rows 40-44
	place_barn(objects, 4, 5)

	# Hedge (square) - 3x3 tiles
	place_hedge(objects, 10, 20)

	# Fence sections - rows 6-7
	for i in range(4):
		objects.set_cell(Vector2i(8 + i, 32), 0, Vector2i(0, 6))
		objects.set_cell(Vector2i(8 + i, 33), 0, Vector2i(0, 7))

	# Small decorations scattered around
	# Mushrooms at (0,0) and (1,0)
	objects.set_cell(Vector2i(15, 22), 0, Vector2i(0, 0))  # red mushroom
	objects.set_cell(Vector2i(32, 30), 0, Vector2i(1, 0))  # yellow mushroom

	# Eggs at (3,0) and (4,0)
	objects.set_cell(Vector2i(12, 25), 0, Vector2i(3, 0))  # green egg
	objects.set_cell(Vector2i(18, 24), 0, Vector2i(4, 0))  # blue egg

	# Slimes at (5,0) and (6,0)
	objects.set_cell(Vector2i(20, 8), 0, Vector2i(5, 0))   # green slime

	# Water drop at (7,0)
	objects.set_cell(Vector2i(35, 8), 0, Vector2i(7, 0))   # blue water drop

	# Rock at (2,0)
	objects.set_cell(Vector2i(8, 12), 0, Vector2i(2, 0))

	# Boulder - 3x4 at tileset cols 0-2, rows 2-5
	place_boulder(objects, 33, 2)

	print("Done! Visualization recreated.")
	print("You may need to save the scene to see changes persist.")


func place_tree(layer: TileMapLayer, x: int, y: int) -> void:
	# Large tree: 3 cols (4-6) x 4 rows (2-5) in tileset
	for ty in range(4):
		for tx in range(3):
			layer.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(4 + tx, 2 + ty))


func place_small_tree(layer: TileMapLayer, x: int, y: int) -> void:
	# Use same tree but smaller placement
	for ty in range(3):
		for tx in range(2):
			layer.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(4 + tx, 2 + ty))


func place_barn(layer: TileMapLayer, x: int, y: int) -> void:
	# Red barn: 8 cols x 5 rows at tileset rows 40-44
	for ty in range(5):
		for tx in range(8):
			layer.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(tx, 40 + ty))


func place_hedge(layer: TileMapLayer, x: int, y: int) -> void:
	# Hedge: 3x3 tiles from rows 8-10
	for ty in range(3):
		for tx in range(3):
			layer.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(tx, 8 + ty))


func place_boulder(layer: TileMapLayer, x: int, y: int) -> void:
	# Boulder: 3 cols (0-2) x 4 rows (2-5) in tileset
	for ty in range(4):
		for tx in range(3):
			layer.set_cell(Vector2i(x + tx, y + ty), 0, Vector2i(tx, 2 + ty))
