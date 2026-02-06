extends Node2D
## APPROACH B: Overlay-based blending
## Places full blob sprites as overlays, letting them blend together

@export var blob_texture: Texture2D  # dirt_around_grass.png (96x96)
@export var base_texture: Texture2D  # dirt_tile.png

const TILE_SIZE := 32

enum Terrain { DIRT = 0, GRASS = 1 }

var terrain_map: Array[Array] = []
var map_width: int = 0
var map_height: int = 0

var base_layer: Node2D
var blob_layer: Node2D


func _ready() -> void:
	base_layer = Node2D.new()
	base_layer.name = "BaseLayer"
	add_child(base_layer)

	blob_layer = Node2D.new()
	blob_layer.name = "BlobLayer"
	add_child(blob_layer)


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
	for child in blob_layer.get_children():
		child.queue_free()

	await get_tree().process_frame
	_render_base()
	_render_blobs_as_overlays()


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


func _render_blobs_as_overlays() -> void:
	if not blob_texture:
		return

	# Find connected grass regions and place full 3x3 blobs centered on them
	var visited: Dictionary = {}

	for y in range(map_height):
		for x in range(map_width):
			if get_terrain(x, y) == Terrain.GRASS and not visited.has(Vector2i(x, y)):
				# Found a grass region - find its bounds
				var region := _flood_fill_region(x, y, visited)
				_place_blob_for_region(region)


func _flood_fill_region(start_x: int, start_y: int, visited: Dictionary) -> Dictionary:
	var region := {
		"min_x": start_x,
		"max_x": start_x,
		"min_y": start_y,
		"max_y": start_y,
		"cells": []
	}

	var queue: Array[Vector2i] = [Vector2i(start_x, start_y)]

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front()
		if visited.has(pos):
			continue
		if get_terrain(pos.x, pos.y) != Terrain.GRASS:
			continue

		visited[pos] = true
		region.cells.append(pos)
		region.min_x = min(region.min_x, pos.x)
		region.max_x = max(region.max_x, pos.x)
		region.min_y = min(region.min_y, pos.y)
		region.max_y = max(region.max_y, pos.y)

		# Add neighbors
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var nx: int = pos.x + dx
				var ny: int = pos.y + dy
				if not visited.has(Vector2i(nx, ny)):
					queue.append(Vector2i(nx, ny))

	return region


func _place_blob_for_region(region: Dictionary) -> void:
	# Place the full 96x96 blob sprite scaled/positioned to cover the region
	var width: int = region.max_x - region.min_x + 1
	var height: int = region.max_y - region.min_y + 1

	# Center position of the region
	var center_x: float = (region.min_x + region.max_x) / 2.0
	var center_y: float = (region.min_y + region.max_y) / 2.0

	# Place a scaled blob sprite
	var sprite := Sprite2D.new()
	sprite.texture = blob_texture
	sprite.centered = true

	# Scale to fit the region (add padding for edges)
	var target_width: int = (width + 1) * TILE_SIZE
	var target_height: int = (height + 1) * TILE_SIZE
	var scale_x: float = target_width / 96.0
	var scale_y: float = target_height / 96.0
	sprite.scale = Vector2(scale_x, scale_y)

	# Position at center of region
	sprite.position = Vector2(
		(center_x + 0.5) * TILE_SIZE,
		(center_y + 0.5) * TILE_SIZE
	)

	blob_layer.add_child(sprite)


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
