extends Node2D
## APPROACH A: Full 8-neighbor blob autotile
## Checks all 8 neighbors (including diagonals) for smoother shapes

@export var blob_texture: Texture2D  # dirt_around_grass.png (96x96)
@export var base_texture: Texture2D  # dirt_tile.png

const TILE_SIZE := 32

enum Terrain { DIRT = 0, GRASS = 1 }

var terrain_map: Array[Array] = []
var map_width: int = 0
var map_height: int = 0

var base_layer: Node2D
var transition_layer: Node2D


func _ready() -> void:
	base_layer = Node2D.new()
	base_layer.name = "BaseLayer"
	add_child(base_layer)

	transition_layer = Node2D.new()
	transition_layer.name = "TransitionLayer"
	add_child(transition_layer)


func init_map(width: int, height: int) -> void:
	map_width = width
	map_height = height
	terrain_map.clear()
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(Terrain.DIRT)
		terrain_map.append(row)


func set_terrain(x: int, y: int, terrain: Terrain) -> void:
	if x >= 0 and x < map_width and y >= 0 and y < map_height:
		terrain_map[y][x] = terrain


func get_terrain(x: int, y: int) -> Terrain:
	if x >= 0 and x < map_width and y >= 0 and y < map_height:
		return terrain_map[y][x]
	return Terrain.DIRT


func render() -> void:
	for child in base_layer.get_children():
		child.queue_free()
	for child in transition_layer.get_children():
		child.queue_free()

	await get_tree().process_frame
	_render_base()
	_render_transitions_8neighbor()


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


func _render_transitions_8neighbor() -> void:
	if not blob_texture:
		return

	for y in range(map_height):
		for x in range(map_width):
			if get_terrain(x, y) == Terrain.GRASS:
				_place_tile_8neighbor(x, y)


func _place_tile_8neighbor(x: int, y: int) -> void:
	# Check all 8 neighbors
	var n  := get_terrain(x, y - 1) == Terrain.GRASS  # North
	var s  := get_terrain(x, y + 1) == Terrain.GRASS  # South
	var w  := get_terrain(x - 1, y) == Terrain.GRASS  # West
	var e  := get_terrain(x + 1, y) == Terrain.GRASS  # East
	var nw := get_terrain(x - 1, y - 1) == Terrain.GRASS  # Northwest
	var ne := get_terrain(x + 1, y - 1) == Terrain.GRASS  # Northeast
	var sw := get_terrain(x - 1, y + 1) == Terrain.GRASS  # Southwest
	var se := get_terrain(x + 1, y + 1) == Terrain.GRASS  # Southeast

	# The 3x3 blob layout:
	#   (0,0)=NW outer  (1,0)=N edge   (2,0)=NE outer
	#   (0,1)=W edge    (1,1)=center   (2,1)=E edge
	#   (0,2)=SW outer  (1,2)=S edge   (2,2)=SE outer

	# For 8-neighbor, we need to handle inner corners too
	# Inner corner = when diagonal is dirt but both adjacent cardinals are grass

	var blob_x: int = 1  # Default center
	var blob_y: int = 1

	# Determine base position from cardinal neighbors
	if not w and not e:
		blob_x = 1  # Vertical strip or isolated
	elif not w:
		blob_x = 0  # Left edge
	elif not e:
		blob_x = 2  # Right edge
	else:
		blob_x = 1  # Center column

	if not n and not s:
		blob_y = 1  # Horizontal strip or isolated
	elif not n:
		blob_y = 0  # Top edge
	elif not s:
		blob_y = 2  # Bottom edge
	else:
		blob_y = 1  # Center row

	# Place the main tile
	_add_blob_sprite(x, y, blob_x, blob_y)

	# Handle inner corners (diagonal dirt when both cardinals are grass)
	# These need additional corner overlay sprites
	if n and w and not nw:
		_add_inner_corner(x, y, "nw")
	if n and e and not ne:
		_add_inner_corner(x, y, "ne")
	if s and w and not sw:
		_add_inner_corner(x, y, "sw")
	if s and e and not se:
		_add_inner_corner(x, y, "se")


func _add_blob_sprite(x: int, y: int, blob_x: int, blob_y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = blob_texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(blob_x * TILE_SIZE, blob_y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	transition_layer.add_child(sprite)


func _add_inner_corner(x: int, y: int, corner: String) -> void:
	# Inner corners need special handling - we'll use a small overlay from the corners
	# This creates the "bite" effect where diagonal dirt shows through
	var sprite := Sprite2D.new()
	sprite.texture = blob_texture
	sprite.centered = false
	sprite.region_enabled = true

	# Extract just the corner portion (16x16) from the appropriate outer corner tile
	var region_x: int = 0
	var region_y: int = 0
	var offset_x: int = 0
	var offset_y: int = 0

	match corner:
		"nw":
			region_x = 0
			region_y = 0
			offset_x = 0
			offset_y = 0
		"ne":
			region_x = 2 * TILE_SIZE + 16  # Right half of NE corner tile
			region_y = 0
			offset_x = 16
			offset_y = 0
		"sw":
			region_x = 0
			region_y = 2 * TILE_SIZE + 16  # Bottom half of SW corner tile
			offset_x = 0
			offset_y = 16
		"se":
			region_x = 2 * TILE_SIZE + 16
			region_y = 2 * TILE_SIZE + 16
			offset_x = 16
			offset_y = 16

	sprite.region_rect = Rect2(region_x, region_y, 16, 16)
	sprite.position = Vector2(x * TILE_SIZE + offset_x, y * TILE_SIZE + offset_y)
	sprite.z_index = 1  # Above the main tile
	transition_layer.add_child(sprite)


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
			if char == "#" or char == "G" or char == "g":
				set_terrain(x, y, Terrain.GRASS)
