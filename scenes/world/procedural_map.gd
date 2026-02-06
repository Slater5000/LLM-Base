extends Node2D
## Procedural map generator for biome_01 tileset.
## Generates terrain with grass base, rivers, paths, dirt patches, and decorations.
## Creates interesting layouts similar to the biome_01 visualization reference.

class_name ProceduralMap

# ============================================================================
# CONFIGURATION
# ============================================================================

## Map dimensions in tiles
@export var map_width: int = 32
@export var map_height: int = 24

## Tile size in pixels (the base grass tile is 32x32)
@export var tile_size: int = 32

## Random seed (0 = random each time)
@export var map_seed: int = 0

## Feature generation toggles
@export_group("Features")
@export var generate_river: bool = true
@export var generate_path: bool = true
@export var generate_dirt_patches: bool = true
@export var generate_hills: bool = true
@export var generate_decorations: bool = true

## Decoration density (0.0 - 1.0)
@export_group("Density")
@export_range(0.0, 1.0) var tree_density: float = 0.025
@export_range(0.0, 1.0) var flower_density: float = 0.015
@export_range(0.0, 1.0) var rock_density: float = 0.008
@export_range(0.0, 1.0) var mushroom_density: float = 0.006
@export_range(0.0, 1.0) var bush_density: float = 0.012
@export_range(0.0, 1.0) var tree_cluster_chance: float = 0.4

# ============================================================================
# TERRAIN TYPES
# ============================================================================

enum TerrainType {
	GRASS,
	WATER,
	SAND,        # Beach/riverbank
	DIRT,
	STONE_PATH,
	HILL,        # Elevated terrain
	STONE_HILL   # Rocky elevated terrain
}

# ============================================================================
# INTERNAL STATE
# ============================================================================

var _rng: RandomNumberGenerator
var _terrain_grid: Array[Array]  # 2D array of TerrainType
var _decoration_positions: Array[Vector2i]  # Positions with decorations (to avoid overlap)
var _bridge_positions: Array[Vector2i]  # Positions where bridges should be placed
var _river_direction: String = "vertical"  # "vertical" or "horizontal"

# Node containers
var _floor_layer: Node2D
var _terrain_layer: Node2D
var _path_layer: Node2D
var _decoration_layer: Node2D

# ============================================================================
# TEXTURE REFERENCES
# ============================================================================

const BIOME_PATH := "res://assets/sprites/biome_01/"

# Base tiles
var _tex_grass: Texture2D
var _tex_stone_large: Texture2D
var _tex_stone_small: Texture2D

# Transition tiles (blob autotiles - 60x54, arranged as 5x3 grid of 12x18 subtiles)
var _tex_sand_around_water: Texture2D
var _tex_grass_around_sand: Texture2D
var _tex_grass_around_dirt: Texture2D
var _tex_dirt_around_grass: Texture2D

# Large features
var _tex_hill: Texture2D
var _tex_stone_hill: Texture2D
var _tex_big_rock: Texture2D
var _tex_barn: Texture2D
var _tex_bridge_parts: Array[Texture2D]
var _tex_fence: Texture2D

# Decorations
var _tex_trees: Array[Texture2D]
var _tex_flowers: Array[Texture2D]
var _tex_rocks: Array[Texture2D]
var _tex_mushrooms: Array[Texture2D]
var _tex_bushes: Array[Texture2D]
var _tex_shrubs: Array[Texture2D]
var _tex_leaves: Texture2D

# ============================================================================
# LIFECYCLE
# ============================================================================

func _ready() -> void:
	_load_textures()
	_setup_layers()
	generate()


func _load_textures() -> void:
	# Base tiles
	_tex_grass = load(BIOME_PATH + "grass_tile.png")
	_tex_stone_large = load(BIOME_PATH + "larger_tile.png")
	_tex_stone_small = load(BIOME_PATH + "smaller_tile.png")

	# Transitions
	_tex_sand_around_water = load(BIOME_PATH + "sand_around_water.png")
	_tex_grass_around_sand = load(BIOME_PATH + "grass_around_sand.png")
	_tex_grass_around_dirt = load(BIOME_PATH + "grass_around_dirt.png")
	_tex_dirt_around_grass = load(BIOME_PATH + "dirt_around_grass.png")

	# Trees
	_tex_trees = [
		load(BIOME_PATH + "tree_conifer.png")
	]

	# Flowers
	_tex_flowers = [
		load(BIOME_PATH + "tulip_pink.png"),
		load(BIOME_PATH + "flower_potted.png")
	]

	# Rocks
	_tex_rocks = [
		load(BIOME_PATH + "rock_gray.png"),
		load(BIOME_PATH + "rock_gray_small.png"),
		load(BIOME_PATH + "small_rock_cluster.png"),
		load(BIOME_PATH + "2_small_rocks.png"),
		load(BIOME_PATH + "medium_rock.png")
	]

	# Mushrooms
	_tex_mushrooms = [
		load(BIOME_PATH + "mushroom_blue.png"),
		load(BIOME_PATH + "mushroom_green.png"),
		load(BIOME_PATH + "mushroom_yellow.png"),
		load(BIOME_PATH + "2_blue_mushrooms.png"),
		load(BIOME_PATH + "2_green_mushrooms.png"),
		load(BIOME_PATH + "2_yellow_mushrooms.png"),
		load(BIOME_PATH + "large mushroom.png"),
		load(BIOME_PATH + "large green mushroom.png"),
		load(BIOME_PATH + "large blue mushroom.png")
	]

	# Bushes
	_tex_bushes = [
		load(BIOME_PATH + "bush.png"),
		load(BIOME_PATH + "bush_round_green.png"),
		load(BIOME_PATH + "bush_round_spotted.png"),
		load(BIOME_PATH + "bush_round_plain.png"),
		load(BIOME_PATH + "bush_pink_flowers_.png"),
		load(BIOME_PATH + "bush_white.png"),
		load(BIOME_PATH + "bush_yellow.png")
	]

	# Shrubs
	_tex_shrubs = [
		load(BIOME_PATH + "shrub.png"),
		load(BIOME_PATH + "shrub_white.png"),
		load(BIOME_PATH + "shrub_yellow_flowers.png"),
		load(BIOME_PATH + "shrub_red_berries.png")
	]

	# Large features
	_tex_hill = load(BIOME_PATH + "hill.png")
	_tex_stone_hill = load(BIOME_PATH + "stone_hill.png")
	_tex_big_rock = load(BIOME_PATH + "big_rock.png")
	_tex_barn = load(BIOME_PATH + "barn.png")
	_tex_fence = load(BIOME_PATH + "fence.png")

	# Bridge parts
	_tex_bridge_parts = [
		load(BIOME_PATH + "bridge1.png"),
		load(BIOME_PATH + "bridge_2.png"),
		load(BIOME_PATH + "bridge_3.png"),
		load(BIOME_PATH + "bridge_4.png")
	]

	# Leaves
	_tex_leaves = load(BIOME_PATH + "2_leaves.png")


func _setup_layers() -> void:
	# Floor layer (grass base)
	_floor_layer = Node2D.new()
	_floor_layer.name = "FloorLayer"
	_floor_layer.z_index = -10
	add_child(_floor_layer)

	# Terrain layer (water, sand, dirt transitions)
	_terrain_layer = Node2D.new()
	_terrain_layer.name = "TerrainLayer"
	_terrain_layer.z_index = -5
	add_child(_terrain_layer)

	# Path layer
	_path_layer = Node2D.new()
	_path_layer.name = "PathLayer"
	_path_layer.z_index = -3
	add_child(_path_layer)

	# Decoration layer (y-sorted)
	_decoration_layer = Node2D.new()
	_decoration_layer.name = "DecorationLayer"
	_decoration_layer.y_sort_enabled = true
	add_child(_decoration_layer)


# ============================================================================
# GENERATION
# ============================================================================

## Clear and regenerate the map
func generate() -> void:
	_clear_map()
	_init_rng()
	_init_terrain_grid()

	# Generate terrain features in order of priority
	if generate_hills:
		_generate_hills()
	if generate_river:
		_generate_river()
	if generate_dirt_patches:
		_generate_dirt_patches()
	if generate_path:
		_generate_stone_path()

	# Render terrain
	_render_grass_floor()
	_render_terrain_transitions()
	_render_large_features()

	# Place decorations
	if generate_decorations:
		_place_decorations()
		_place_tree_clusters()
		_place_scattered_details()


func _clear_map() -> void:
	for child in _floor_layer.get_children():
		child.queue_free()
	for child in _terrain_layer.get_children():
		child.queue_free()
	for child in _path_layer.get_children():
		child.queue_free()
	for child in _decoration_layer.get_children():
		child.queue_free()
	_decoration_positions.clear()
	_bridge_positions.clear()


func _init_rng() -> void:
	_rng = RandomNumberGenerator.new()
	if map_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = map_seed


func _init_terrain_grid() -> void:
	_terrain_grid = []
	for x in range(map_width):
		var column: Array = []
		column.resize(map_height)
		column.fill(TerrainType.GRASS)
		_terrain_grid.append(column)


# ============================================================================
# HILL GENERATION
# ============================================================================

func _generate_hills() -> void:
	# Place 1-3 hills in corners or edges
	var num_hills := _rng.randi_range(1, 3)
	var placed_positions: Array[Vector2i] = []

	for _i in range(num_hills):
		# Try to place hills in different quadrants
		var quadrant := _rng.randi_range(0, 3)
		var pos := _get_hill_position(quadrant, placed_positions)
		if pos.x >= 0:
			placed_positions.append(pos)
			var is_stone := _rng.randf() < 0.4
			var hill_type := TerrainType.STONE_HILL if is_stone else TerrainType.HILL
			_place_organic_patch(pos.x, pos.y, _rng.randi_range(2, 3), hill_type)


func _get_hill_position(quadrant: int, existing: Array[Vector2i]) -> Vector2i:
	var margin := 4
	var attempts := 10

	for _attempt in range(attempts):
		var x: int
		var y: int

		match quadrant:
			0:  # Top-left
				x = _rng.randi_range(margin, map_width / 2 - margin)
				y = _rng.randi_range(margin, map_height / 2 - margin)
			1:  # Top-right
				x = _rng.randi_range(map_width / 2 + margin, map_width - margin)
				y = _rng.randi_range(margin, map_height / 2 - margin)
			2:  # Bottom-left
				x = _rng.randi_range(margin, map_width / 2 - margin)
				y = _rng.randi_range(map_height / 2 + margin, map_height - margin)
			_:  # Bottom-right
				x = _rng.randi_range(map_width / 2 + margin, map_width - margin)
				y = _rng.randi_range(map_height / 2 + margin, map_height - margin)

		# Check distance from existing hills
		var too_close := false
		for existing_pos in existing:
			if abs(x - existing_pos.x) < 8 and abs(y - existing_pos.y) < 6:
				too_close = true
				break

		if not too_close:
			return Vector2i(x, y)

	return Vector2i(-1, -1)


# ============================================================================
# RIVER GENERATION
# ============================================================================

func _generate_river() -> void:
	# Generate a meandering river from top to bottom (or side to side)
	var vertical := _rng.randf() > 0.5

	if vertical:
		_river_direction = "vertical"
		_generate_vertical_river()
	else:
		_river_direction = "horizontal"
		_generate_horizontal_river()


func _generate_vertical_river() -> void:
	var river_x := _rng.randi_range(map_width / 3, 2 * map_width / 3)
	var river_width := _rng.randi_range(2, 4)

	for y in range(map_height):
		# Meander the river
		if _rng.randf() < 0.3:
			river_x += _rng.randi_range(-1, 1)
			river_x = clampi(river_x, river_width + 1, map_width - river_width - 2)

		# Vary width slightly
		var current_width := river_width + _rng.randi_range(-1, 1)
		current_width = maxi(2, current_width)

		# Place water and sand banks
		for dx in range(-current_width - 1, current_width + 2):
			var x := river_x + dx
			if x < 0 or x >= map_width:
				continue

			if abs(dx) <= current_width / 2:
				_terrain_grid[x][y] = TerrainType.WATER
			elif abs(dx) <= current_width:
				if _terrain_grid[x][y] == TerrainType.GRASS:
					_terrain_grid[x][y] = TerrainType.SAND


func _generate_horizontal_river() -> void:
	var river_y := _rng.randi_range(map_height / 3, 2 * map_height / 3)
	var river_width := _rng.randi_range(2, 4)

	for x in range(map_width):
		# Meander
		if _rng.randf() < 0.3:
			river_y += _rng.randi_range(-1, 1)
			river_y = clampi(river_y, river_width + 1, map_height - river_width - 2)

		var current_width := river_width + _rng.randi_range(-1, 1)
		current_width = maxi(2, current_width)

		for dy in range(-current_width - 1, current_width + 2):
			var y := river_y + dy
			if y < 0 or y >= map_height:
				continue

			if abs(dy) <= current_width / 2:
				_terrain_grid[x][y] = TerrainType.WATER
			elif abs(dy) <= current_width:
				if _terrain_grid[x][y] == TerrainType.GRASS:
					_terrain_grid[x][y] = TerrainType.SAND


# ============================================================================
# DIRT PATCHES
# ============================================================================

func _generate_dirt_patches() -> void:
	var num_patches := _rng.randi_range(2, 5)

	for _i in range(num_patches):
		var center_x := _rng.randi_range(3, map_width - 4)
		var center_y := _rng.randi_range(3, map_height - 4)
		var radius := _rng.randi_range(2, 4)

		_place_organic_patch(center_x, center_y, radius, TerrainType.DIRT)


func _place_organic_patch(center_x: int, center_y: int, radius: int, terrain: TerrainType) -> void:
	# Create an organic-looking patch using noise-like randomness
	for dx in range(-radius - 1, radius + 2):
		for dy in range(-radius - 1, radius + 2):
			var x := center_x + dx
			var y := center_y + dy

			if x < 1 or x >= map_width - 1 or y < 1 or y >= map_height - 1:
				continue

			var dist := sqrt(dx * dx + dy * dy)
			var threshold := radius + _rng.randf_range(-0.5, 0.5)

			if dist < threshold:
				# Don't overwrite water
				if _terrain_grid[x][y] != TerrainType.WATER and _terrain_grid[x][y] != TerrainType.SAND:
					_terrain_grid[x][y] = terrain


# ============================================================================
# STONE PATH
# ============================================================================

func _generate_stone_path() -> void:
	# Create a winding path across the map
	var start_edge := _rng.randi_range(0, 3)  # 0=top, 1=right, 2=bottom, 3=left
	var end_edge := (start_edge + 2) % 4  # Opposite edge

	var start_pos := _get_edge_position(start_edge)
	var end_pos := _get_edge_position(end_edge)

	# Simple pathfinding - walk from start to end with some randomness
	var current := start_pos
	var path_width := 2
	var max_iterations := map_width * map_height * 2  # Prevent infinite loops
	var iterations := 0

	while current != end_pos and iterations < max_iterations:
		iterations += 1

		# Check if we're crossing water - mark for bridge
		var on_water := false
		if current.x >= 0 and current.x < map_width and current.y >= 0 and current.y < map_height:
			if _terrain_grid[current.x][current.y] == TerrainType.WATER:
				on_water = true
				if not _bridge_positions.has(current):
					_bridge_positions.append(current)

		# Mark path tiles (don't overwrite water - bridges go there instead)
		for dx_inner in range(-path_width / 2, path_width / 2 + 1):
			for dy_inner in range(-path_width / 2, path_width / 2 + 1):
				var x := current.x + dx_inner
				var y := current.y + dy_inner
				if x >= 0 and x < map_width and y >= 0 and y < map_height:
					if _terrain_grid[x][y] != TerrainType.WATER:
						_terrain_grid[x][y] = TerrainType.STONE_PATH
					else:
						# Mark adjacent water tiles for bridge
						if not _bridge_positions.has(Vector2i(x, y)):
							_bridge_positions.append(Vector2i(x, y))

		# Move toward end with some randomness
		var dx: int = signi(end_pos.x - current.x)
		var dy: int = signi(end_pos.y - current.y)

		if _rng.randf() < 0.7:
			# Move in primary direction
			if abs(end_pos.x - current.x) > abs(end_pos.y - current.y):
				current.x += dx
			else:
				current.y += dy
		else:
			# Random perpendicular movement
			if _rng.randf() < 0.5:
				current.x += dx if dx != 0 else _rng.randi_range(-1, 1)
			else:
				current.y += dy if dy != 0 else _rng.randi_range(-1, 1)

		current.x = clampi(current.x, 0, map_width - 1)
		current.y = clampi(current.y, 0, map_height - 1)


func _get_edge_position(edge: int) -> Vector2i:
	match edge:
		0:  # Top
			return Vector2i(_rng.randi_range(map_width / 4, 3 * map_width / 4), 0)
		1:  # Right
			return Vector2i(map_width - 1, _rng.randi_range(map_height / 4, 3 * map_height / 4))
		2:  # Bottom
			return Vector2i(_rng.randi_range(map_width / 4, 3 * map_width / 4), map_height - 1)
		3:  # Left
			return Vector2i(0, _rng.randi_range(map_height / 4, 3 * map_height / 4))
	return Vector2i.ZERO


# ============================================================================
# RENDERING
# ============================================================================

func _render_grass_floor() -> void:
	# Fill entire map with grass tiles
	for x in range(map_width):
		for y in range(map_height):
			var sprite := Sprite2D.new()
			sprite.texture = _tex_grass
			sprite.position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
			_floor_layer.add_child(sprite)


func _render_terrain_transitions() -> void:
	# Render terrain features with proper transitions
	for x in range(map_width):
		for y in range(map_height):
			var terrain := _terrain_grid[x][y] as TerrainType

			match terrain:
				TerrainType.WATER:
					_render_water_tile(x, y)
				TerrainType.SAND:
					_render_sand_tile(x, y)
				TerrainType.DIRT:
					_render_dirt_tile(x, y)
				TerrainType.STONE_PATH:
					_render_path_tile(x, y)


func _render_water_tile(x: int, y: int) -> void:
	# Use the sand_around_water blob tile for water with sandy edges
	var sprite := Sprite2D.new()
	sprite.texture = _tex_sand_around_water
	sprite.position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)

	# Scale down to fit tile size (60x54 -> 16x16 approximately, or use region)
	var tex_size := _tex_sand_around_water.get_size()
	sprite.scale = Vector2(tile_size / tex_size.x * 1.5, tile_size / tex_size.y * 1.5)

	_terrain_layer.add_child(sprite)


func _render_sand_tile(x: int, y: int) -> void:
	# Render sand/beach transition
	# Check neighbors to determine which transition tile to use
	var has_water := _has_neighbor_type(x, y, TerrainType.WATER)

	if has_water:
		# Use grass_around_sand when adjacent to water
		var sprite := Sprite2D.new()
		sprite.texture = _tex_grass_around_sand
		sprite.position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
		var tex_size := _tex_grass_around_sand.get_size()
		sprite.scale = Vector2(tile_size / tex_size.x * 1.5, tile_size / tex_size.y * 1.5)
		_terrain_layer.add_child(sprite)


func _render_dirt_tile(x: int, y: int) -> void:
	# Use dirt_around_grass for dirt patches (dirt in center, grass edges)
	var sprite := Sprite2D.new()
	sprite.texture = _tex_dirt_around_grass
	sprite.position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)
	var tex_size := _tex_dirt_around_grass.get_size()
	sprite.scale = Vector2(tile_size / tex_size.x * 1.5, tile_size / tex_size.y * 1.5)
	_terrain_layer.add_child(sprite)


func _render_path_tile(x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _tex_stone_small
	sprite.position = Vector2(x * tile_size + tile_size / 2, y * tile_size + tile_size / 2)

	# Scale to fit
	var tex_size := _tex_stone_small.get_size()
	var scale_factor: float = float(tile_size) / minf(tex_size.x, tex_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)

	_path_layer.add_child(sprite)


func _has_neighbor_type(x: int, y: int, terrain: TerrainType) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
				if _terrain_grid[nx][ny] == terrain:
					return true
	return false


func _render_large_features() -> void:
	# Render hills and large rock features at their terrain positions
	var hill_positions: Array[Vector2i] = []
	var stone_hill_positions: Array[Vector2i] = []

	# Find hill center positions
	for x in range(map_width):
		for y in range(map_height):
			var terrain := _terrain_grid[x][y] as TerrainType
			if terrain == TerrainType.HILL:
				if not _is_near_positions(Vector2i(x, y), hill_positions, 3):
					hill_positions.append(Vector2i(x, y))
			elif terrain == TerrainType.STONE_HILL:
				if not _is_near_positions(Vector2i(x, y), stone_hill_positions, 3):
					stone_hill_positions.append(Vector2i(x, y))

	# Place hill sprites at center of each hill region
	for pos in hill_positions:
		var sprite := Sprite2D.new()
		sprite.texture = _tex_hill
		sprite.position = Vector2(pos.x * tile_size + tile_size / 2, pos.y * tile_size + tile_size / 2)
		_decoration_layer.add_child(sprite)
		_mark_occupied(pos.x, pos.y, 3)

	for pos in stone_hill_positions:
		var sprite := Sprite2D.new()
		sprite.texture = _tex_stone_hill
		sprite.position = Vector2(pos.x * tile_size + tile_size / 2, pos.y * tile_size + tile_size / 2)
		_decoration_layer.add_child(sprite)
		_mark_occupied(pos.x, pos.y, 3)

	# Render bridges where path crosses water
	_render_bridges()


func _render_bridges() -> void:
	if _bridge_positions.is_empty():
		return

	# Find the center of the bridge area
	var min_x := map_width
	var max_x := 0
	var min_y := map_height
	var max_y := 0

	for pos in _bridge_positions:
		min_x = mini(min_x, pos.x)
		max_x = maxi(max_x, pos.x)
		min_y = mini(min_y, pos.y)
		max_y = maxi(max_y, pos.y)

	var center_x := (min_x + max_x) / 2
	var center_y := (min_y + max_y) / 2

	# Determine bridge orientation based on river direction
	var is_vertical_bridge := _river_direction == "vertical"

	# Place bridge sprite(s)
	if _tex_bridge_parts.size() >= 4:
		# Use the main bridge piece (bridge_3 is the arch)
		var bridge_sprite := Sprite2D.new()
		bridge_sprite.texture = _tex_bridge_parts[2]  # bridge_3 (arch)
		bridge_sprite.position = Vector2(
			center_x * tile_size + tile_size / 2,
			center_y * tile_size + tile_size / 2
		)

		# Rotate if needed for horizontal rivers
		if not is_vertical_bridge:
			bridge_sprite.rotation_degrees = 90

		bridge_sprite.z_index = 5  # Above water
		_decoration_layer.add_child(bridge_sprite)

		# Mark bridge area as occupied
		for pos in _bridge_positions:
			_decoration_positions.append(pos)


func _is_near_positions(pos: Vector2i, positions: Array[Vector2i], dist: int) -> bool:
	for p in positions:
		if abs(pos.x - p.x) < dist and abs(pos.y - p.y) < dist:
			return true
	return false


# ============================================================================
# DECORATIONS
# ============================================================================

func _place_decorations() -> void:
	# Place decorations on grass tiles, avoiding water and paths
	for x in range(map_width):
		for y in range(map_height):
			if _terrain_grid[x][y] != TerrainType.GRASS:
				continue

			var pos := Vector2i(x, y)
			if _decoration_positions.has(pos):
				continue

			# Try to place various decorations based on density
			if _rng.randf() < tree_density:
				_place_tree(x, y)
			elif _rng.randf() < bush_density:
				_place_bush(x, y)
			elif _rng.randf() < flower_density:
				_place_flower(x, y)
			elif _rng.randf() < rock_density:
				_place_rock(x, y)
			elif _rng.randf() < mushroom_density:
				_place_mushroom(x, y)


func _place_tree(x: int, y: int) -> void:
	# Trees need more clearance - check surroundings
	if not _has_clearance(x, y, 2):
		return

	var sprite := Sprite2D.new()
	sprite.texture = _tex_trees[_rng.randi() % _tex_trees.size()]

	# Position at bottom of tree for y-sorting
	var tex_size := sprite.texture.get_size()
	sprite.position = Vector2(
		x * tile_size + tile_size / 2 + _rng.randf_range(-4, 4),
		y * tile_size + tex_size.y / 2
	)
	sprite.z_index = 0

	_decoration_layer.add_child(sprite)
	_mark_occupied(x, y, 2)


func _place_bush(x: int, y: int) -> void:
	if not _has_clearance(x, y, 1):
		return

	var tex: Texture2D
	if _rng.randf() < 0.5:
		tex = _tex_bushes[_rng.randi() % _tex_bushes.size()]
	else:
		tex = _tex_shrubs[_rng.randi() % _tex_shrubs.size()]

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.position = Vector2(
		x * tile_size + tile_size / 2 + _rng.randf_range(-2, 2),
		y * tile_size + tile_size / 2 + _rng.randf_range(-2, 2)
	)

	_decoration_layer.add_child(sprite)
	_mark_occupied(x, y, 1)


func _place_flower(x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _tex_flowers[_rng.randi() % _tex_flowers.size()]
	sprite.position = Vector2(
		x * tile_size + tile_size / 2 + _rng.randf_range(-4, 4),
		y * tile_size + tile_size / 2 + _rng.randf_range(-4, 4)
	)

	_decoration_layer.add_child(sprite)
	_decoration_positions.append(Vector2i(x, y))


func _place_rock(x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _tex_rocks[_rng.randi() % _tex_rocks.size()]
	sprite.position = Vector2(
		x * tile_size + tile_size / 2 + _rng.randf_range(-2, 2),
		y * tile_size + tile_size / 2 + _rng.randf_range(-2, 2)
	)

	_decoration_layer.add_child(sprite)
	_decoration_positions.append(Vector2i(x, y))


func _place_mushroom(x: int, y: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _tex_mushrooms[_rng.randi() % _tex_mushrooms.size()]
	sprite.position = Vector2(
		x * tile_size + tile_size / 2 + _rng.randf_range(-2, 2),
		y * tile_size + tile_size / 2 + _rng.randf_range(-2, 2)
	)

	_decoration_layer.add_child(sprite)
	_decoration_positions.append(Vector2i(x, y))


func _has_clearance(x: int, y: int, radius: int) -> bool:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var pos := Vector2i(x + dx, y + dy)
			if _decoration_positions.has(pos):
				return false
			# Also check if terrain is suitable (grass, hills are OK)
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
				var terrain := _terrain_grid[nx][ny] as TerrainType
				if terrain != TerrainType.GRASS and terrain != TerrainType.HILL and terrain != TerrainType.STONE_HILL:
					return false
	return true


func _mark_occupied(x: int, y: int, radius: int) -> void:
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			_decoration_positions.append(Vector2i(x + dx, y + dy))


func _place_tree_clusters() -> void:
	# Place clusters of trees at map edges and corners for a more natural look
	var cluster_count := _rng.randi_range(2, 4)

	for _i in range(cluster_count):
		# Choose a position near the edge
		var edge := _rng.randi_range(0, 3)
		var center_x: int
		var center_y: int

		match edge:
			0:  # Top edge
				center_x = _rng.randi_range(2, map_width - 3)
				center_y = _rng.randi_range(1, 4)
			1:  # Right edge
				center_x = _rng.randi_range(map_width - 5, map_width - 2)
				center_y = _rng.randi_range(2, map_height - 3)
			2:  # Bottom edge
				center_x = _rng.randi_range(2, map_width - 3)
				center_y = _rng.randi_range(map_height - 5, map_height - 2)
			_:  # Left edge
				center_x = _rng.randi_range(1, 4)
				center_y = _rng.randi_range(2, map_height - 3)

		# Check if area is grass
		if not _has_clearance(center_x, center_y, 2):
			continue

		# Place cluster of 2-4 trees
		var trees_in_cluster := _rng.randi_range(2, 4)
		for _t in range(trees_in_cluster):
			var tx := center_x + _rng.randi_range(-2, 2)
			var ty := center_y + _rng.randi_range(-2, 2)

			if tx >= 1 and tx < map_width - 1 and ty >= 1 and ty < map_height - 1:
				if _has_clearance(tx, ty, 1):
					_place_tree(tx, ty)


func _place_scattered_details() -> void:
	# Add scattered leaves, small details for visual interest
	for x in range(map_width):
		for y in range(map_height):
			if _terrain_grid[x][y] != TerrainType.GRASS:
				continue

			var pos := Vector2i(x, y)
			if _decoration_positions.has(pos):
				continue

			# Scattered leaves (very low chance)
			if _rng.randf() < 0.005:
				var sprite := Sprite2D.new()
				sprite.texture = _tex_leaves
				sprite.position = Vector2(
					x * tile_size + tile_size / 2 + _rng.randf_range(-6, 6),
					y * tile_size + tile_size / 2 + _rng.randf_range(-6, 6)
				)
				_decoration_layer.add_child(sprite)
				_decoration_positions.append(pos)


# ============================================================================
# PUBLIC API
# ============================================================================

## Regenerate with a new seed
func regenerate_with_seed(new_seed: int) -> void:
	map_seed = new_seed
	generate()


## Get the terrain type at a position (in tiles)
func get_terrain_at(tile_x: int, tile_y: int) -> TerrainType:
	if tile_x < 0 or tile_x >= map_width or tile_y < 0 or tile_y >= map_height:
		return TerrainType.GRASS
	return _terrain_grid[tile_x][tile_y]


## Convert world position to tile position
func world_to_tile(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))


## Get map bounds in world coordinates
func get_map_bounds() -> Rect2:
	return Rect2(0, 0, map_width * tile_size, map_height * tile_size)


## Check if a tile position is walkable (not water)
func is_walkable(tile_x: int, tile_y: int) -> bool:
	var terrain := get_terrain_at(tile_x, tile_y)
	return terrain != TerrainType.WATER


## Get a random walkable spawn position
func get_random_spawn_position() -> Vector2:
	var attempts := 100
	for _i in range(attempts):
		var tile_x := _rng.randi_range(2, map_width - 3)
		var tile_y := _rng.randi_range(2, map_height - 3)
		if is_walkable(tile_x, tile_y):
			return Vector2(tile_x * tile_size + tile_size / 2, tile_y * tile_size + tile_size / 2)
	# Fallback to center
	return Vector2(map_width * tile_size / 2, map_height * tile_size / 2)


## Get the current seed (useful if generated randomly)
func get_current_seed() -> int:
	return _rng.seed if _rng else map_seed
