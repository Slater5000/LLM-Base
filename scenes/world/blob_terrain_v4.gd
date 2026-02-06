extends Node2D
## APPROACH C: Strategic hand-crafted blob placement
## Uses predefined patterns for common shapes (circle, oval, strip)

@export var blob_texture: Texture2D  # dirt_around_grass.png (96x96)
@export var base_texture: Texture2D  # dirt_tile.png

const TILE_SIZE := 32

var base_layer: Node2D
var pattern_layer: Node2D


func _ready() -> void:
	base_layer = Node2D.new()
	base_layer.name = "BaseLayer"
	add_child(base_layer)

	pattern_layer = Node2D.new()
	pattern_layer.name = "PatternLayer"
	add_child(pattern_layer)


## Fill base with dirt
func fill_base(width: int, height: int) -> void:
	for child in base_layer.get_children():
		child.queue_free()

	if not base_texture:
		return

	for y in range(height):
		for x in range(width):
			var sprite := Sprite2D.new()
			sprite.texture = base_texture
			sprite.centered = false
			sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			base_layer.add_child(sprite)


## Place a single full 3x3 grass blob (96x96 scaled to 3 tiles = 96px)
func place_blob(tile_x: int, tile_y: int, scale: float = 1.0) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = blob_texture
	sprite.centered = true
	sprite.scale = Vector2(scale, scale)
	# Position at center of 3x3 area (1.5 tiles from corner)
	sprite.position = Vector2(
		(tile_x + 1.5) * TILE_SIZE,
		(tile_y + 1.5) * TILE_SIZE
	)
	pattern_layer.add_child(sprite)


## Place a horizontal grass strip using edge tiles
func place_horizontal_strip(start_x: int, y: int, length: int) -> void:
	if length < 3:
		place_blob(start_x, y - 1)
		return

	# Left cap (left column of blob)
	_place_blob_column(start_x, y, 0)

	# Middle sections (center column repeated)
	for x in range(start_x + 1, start_x + length - 1):
		_place_blob_column(x, y, 1)

	# Right cap (right column of blob)
	_place_blob_column(start_x + length - 1, y, 2)


## Place a vertical grass strip using edge tiles
func place_vertical_strip(x: int, start_y: int, length: int) -> void:
	if length < 3:
		place_blob(x - 1, start_y)
		return

	# Top cap
	_place_blob_row(x, start_y, 0)

	# Middle sections
	for y in range(start_y + 1, start_y + length - 1):
		_place_blob_row(x, y, 1)

	# Bottom cap
	_place_blob_row(x, start_y + length - 1, 2)


## Place an oval/ellipse grass patch
func place_oval(center_x: int, center_y: int, radius_x: int, radius_y: int) -> void:
	# Use multiple overlapping blobs to create an oval shape
	# Place blobs in an elliptical pattern

	for angle in range(0, 360, 30):
		var rad := deg_to_rad(angle)
		var ox := cos(rad) * (radius_x - 1) * 0.7
		var oy := sin(rad) * (radius_y - 1) * 0.7
		place_blob(
			int(center_x + ox - 1),
			int(center_y + oy - 1),
			0.8
		)

	# Center blob
	place_blob(center_x - 1, center_y - 1, 1.0)


## Place a single column of blob tiles (for horizontal strips)
func _place_blob_column(x: int, y: int, blob_col: int) -> void:
	# Place 3 tiles vertically from the specified blob column
	for row in range(3):
		var sprite := Sprite2D.new()
		sprite.texture = blob_texture
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(blob_col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		sprite.position = Vector2(x * TILE_SIZE, (y + row - 1) * TILE_SIZE)
		pattern_layer.add_child(sprite)


## Place a single row of blob tiles (for vertical strips)
func _place_blob_row(x: int, y: int, blob_row: int) -> void:
	# Place 3 tiles horizontally from the specified blob row
	for col in range(3):
		var sprite := Sprite2D.new()
		sprite.texture = blob_texture
		sprite.centered = false
		sprite.region_enabled = true
		sprite.region_rect = Rect2(col * TILE_SIZE, blob_row * TILE_SIZE, TILE_SIZE, TILE_SIZE)
		sprite.position = Vector2((x + col - 1) * TILE_SIZE, y * TILE_SIZE)
		pattern_layer.add_child(sprite)


## Place individual blob tile piece by grid position
func place_piece(x: int, y: int, blob_x: int, blob_y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = blob_texture
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(blob_x * TILE_SIZE, blob_y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	sprite.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
	pattern_layer.add_child(sprite)


## Clear all patterns
func clear_patterns() -> void:
	for child in pattern_layer.get_children():
		child.queue_free()
