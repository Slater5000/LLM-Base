extends Node2D
## Blob Autotile Terrain System
## Uses 3x3 blob tiles to create natural terrain transitions

# The blob tile texture (96x96 = 3x3 grid of 32x32 tiles)
@export var blob_texture: Texture2D  # dirt_around_grass.png
@export var base_texture: Texture2D  # dirt_tile.png (solid fill for base)

const TILE_SIZE := 32
const BLOB_COLS := 3
const BLOB_ROWS := 3

# Terrain types
enum Terrain { DIRT = 0, GRASS = 1 }

# The terrain map - 2D array of Terrain values
var terrain_map: Array[Array] = []
var map_width: int = 0
var map_height: int = 0

# Node references
var base_layer: Node2D
var transition_layer: Node2D


func _ready() -> void:
	base_layer = Node2D.new()
	base_layer.name = "BaseLayer"
	add_child(base_layer)

	transition_layer = Node2D.new()
	transition_layer.name = "TransitionLayer"
	add_child(transition_layer)


## Initialize terrain map with given dimensions (all dirt by default)
func init_map(width: int, height: int) -> void:
	map_width = width
	map_height = height
	terrain_map.clear()
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(Terrain.DIRT)
		terrain_map.append(row)


## Set terrain at position
func set_terrain(x: int, y: int, terrain: Terrain) -> void:
	if x >= 0 and x < map_width and y >= 0 and y < map_height:
		terrain_map[y][x] = terrain


## Get terrain at position (returns DIRT for out of bounds)
func get_terrain(x: int, y: int) -> Terrain:
	if x >= 0 and x < map_width and y >= 0 and y < map_height:
		return terrain_map[y][x]
	return Terrain.DIRT  # Out of bounds = dirt


## Paint a grass blob at position (for natural patches)
func paint_grass_blob(center_x: int, center_y: int, radius: int = 2) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			# Circular-ish shape
			if dx * dx + dy * dy <= radius * radius:
				set_terrain(center_x + dx, center_y + dy, Terrain.GRASS)


## Render the terrain
func render() -> void:
	# Clear existing
	for child in base_layer.get_children():
		child.queue_free()
	for child in transition_layer.get_children():
		child.queue_free()

	# Wait a frame for cleanup
	await get_tree().process_frame

	# Render base layer (solid dirt everywhere)
	_render_base()

	# Render grass blobs with transitions
	_render_grass_transitions()


func _render_base() -> void:
	if not base_texture:
		return

	for y in range(map_height):
		for x in range(map_width):
			var sprite := Sprite2D.new()
			sprite.texture = base_texture
			sprite.centered = false
			sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			base_layer.add_child(sprite)


func _render_grass_transitions() -> void:
	if not blob_texture:
		return

	for y in range(map_height):
		for x in range(map_width):
			if get_terrain(x, y) == Terrain.GRASS:
				_place_grass_tile(x, y)


func _place_grass_tile(x: int, y: int) -> void:
	# Check cardinal neighbors
	var north := get_terrain(x, y - 1) == Terrain.GRASS
	var south := get_terrain(x, y + 1) == Terrain.GRASS
	var west := get_terrain(x - 1, y) == Terrain.GRASS
	var east := get_terrain(x + 1, y) == Terrain.GRASS

	# Determine which blob tile piece to use
	# The blob is laid out as:
	#   (0,0)=NW corner  (1,0)=N edge  (2,0)=NE corner
	#   (0,1)=W edge     (1,1)=center  (2,1)=E edge
	#   (0,2)=SW corner  (1,2)=S edge  (2,2)=SE corner
	#
	# We select based on which ADJACENT cells are DIRT (not grass)

	var blob_x: int
	var blob_y: int

	# Determine X position in blob
	if not west and not east:
		# Both sides are dirt - this shouldn't happen for blobs, use center
		blob_x = 1
	elif not west:
		blob_x = 0  # Dirt on west, grass extends east
	elif not east:
		blob_x = 2  # Dirt on east, grass extends west
	else:
		blob_x = 1  # Grass on both sides, use center/edge

	# Determine Y position in blob
	if not north and not south:
		blob_y = 1
	elif not north:
		blob_y = 0  # Dirt on north
	elif not south:
		blob_y = 2  # Dirt on south
	else:
		blob_y = 1  # Grass on both sides

	# Create sprite with region from blob texture
	var sprite := Sprite2D.new()
	sprite.texture = blob_texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		blob_x * TILE_SIZE,
		blob_y * TILE_SIZE,
		TILE_SIZE,
		TILE_SIZE
	)
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	transition_layer.add_child(sprite)


## Helper: Create terrain from ASCII map
## Example:
##   ...###...
##   ..#####..
##   ...###...
## Where . = dirt, # = grass
func load_from_ascii(ascii_map: String) -> void:
	var lines := ascii_map.strip_edges().split("\n")
	var height := lines.size()
	var width := 0
	for line in lines:
		width = max(width, line.length())

	init_map(width, height)

	for y in range(height):
		var line: String = lines[y] if y < lines.size() else ""
		for x in range(width):
			var char := line[x] if x < line.length() else "."
			match char:
				"#", "G", "g":
					set_terrain(x, y, Terrain.GRASS)
				_:
					set_terrain(x, y, Terrain.DIRT)
