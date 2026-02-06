class_name WFCSimple
extends RefCounted
## Wave Function Collapse - simplified implementation.
##
## WFC generates tile layouts that respect adjacency rules, producing results
## that look hand-crafted. This is a basic implementation suitable for
## small-to-medium grids. For large maps, consider an addon or chunked approach.
##
## Use this for:
## - Town layouts where buildings, paths, and fences need to connect properly
## - Cave walls that tile correctly
## - Puzzle rooms with specific tile patterns
##
## Example usage:
##   var wfc = WFCSimple.new()
##   wfc.add_tile("grass", 1.0, ["grass", "path", "dirt"], ...)  # Define adjacencies
##   wfc.add_tile("path", 0.3, ["path", "grass"], ...)
##   var result = wfc.generate(16, 16)
##   for y in 16:
##       for x in 16:
##           place_tile(result[x][y], Vector2i(x, y))
##
## NOTE: WFC can fail (contradiction) if rules are too strict.
## This implementation will retry a few times before giving up.

# ============================================================================
# CONFIGURATION
# ============================================================================

## Maximum retries when contradiction occurs
var max_retries: int = 10

## Maximum propagation iterations (prevents infinite loops)
var max_propagation: int = 10000

## Random number generator
var rng: RandomNumberGenerator

# ============================================================================
# DATA STRUCTURES
# ============================================================================

## A tile definition with adjacency rules
class WFCTile:
	var id: String
	var weight: float  # Higher = more common
	## Which tile IDs can be adjacent on each side
	var valid_north: Array[String] = []
	var valid_south: Array[String] = []
	var valid_east: Array[String] = []
	var valid_west: Array[String] = []

	func can_be_north_of(other_id: String) -> bool:
		return valid_south.has(other_id)

	func can_be_south_of(other_id: String) -> bool:
		return valid_north.has(other_id)

	func can_be_east_of(other_id: String) -> bool:
		return valid_west.has(other_id)

	func can_be_west_of(other_id: String) -> bool:
		return valid_east.has(other_id)


## A cell in the grid during generation
class WFCCell:
	var possible_tiles: Array[String] = []  # Tiles that could still go here
	var collapsed_tile: String = ""  # Final tile (empty until collapsed)

	func is_collapsed() -> bool:
		return collapsed_tile != ""

	func entropy() -> int:
		return possible_tiles.size() if not is_collapsed() else 0


## Registered tiles
var tiles: Dictionary = {}  # id -> WFCTile

## All tile IDs (for initialization)
var all_tile_ids: Array[String] = []


# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(seed_value: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value


func set_seed(seed_value: int) -> void:
	rng.seed = seed_value


## Add a tile with its adjacency rules
## valid_* arrays list which tile IDs can be adjacent on that side
func add_tile(
	id: String,
	weight: float,
	valid_north: Array[String],
	valid_south: Array[String],
	valid_east: Array[String],
	valid_west: Array[String]
) -> void:
	var tile := WFCTile.new()
	tile.id = id
	tile.weight = weight
	tile.valid_north = valid_north
	tile.valid_south = valid_south
	tile.valid_east = valid_east
	tile.valid_west = valid_west
	tiles[id] = tile
	all_tile_ids.append(id)


## Add a tile that can be adjacent to itself on all sides (simple case)
func add_simple_tile(id: String, weight: float, compatible_with: Array[String]) -> void:
	add_tile(id, weight, compatible_with, compatible_with, compatible_with, compatible_with)


## Add symmetric adjacency (A can be next to B = B can be next to A)
func add_symmetric_adjacency(tile_a: String, tile_b: String) -> void:
	if tiles.has(tile_a):
		if not tiles[tile_a].valid_north.has(tile_b):
			tiles[tile_a].valid_north.append(tile_b)
		if not tiles[tile_a].valid_south.has(tile_b):
			tiles[tile_a].valid_south.append(tile_b)
		if not tiles[tile_a].valid_east.has(tile_b):
			tiles[tile_a].valid_east.append(tile_b)
		if not tiles[tile_a].valid_west.has(tile_b):
			tiles[tile_a].valid_west.append(tile_b)

	if tiles.has(tile_b):
		if not tiles[tile_b].valid_north.has(tile_a):
			tiles[tile_b].valid_north.append(tile_a)
		if not tiles[tile_b].valid_south.has(tile_a):
			tiles[tile_b].valid_south.append(tile_a)
		if not tiles[tile_b].valid_east.has(tile_a):
			tiles[tile_b].valid_east.append(tile_a)
		if not tiles[tile_b].valid_west.has(tile_a):
			tiles[tile_b].valid_west.append(tile_a)


# ============================================================================
# PRESET CONFIGURATIONS
# ============================================================================

## Simple grass/path/water tileset
func setup_basic_terrain() -> void:
	# Grass - most common, connects to everything
	add_tile("grass", 1.0,
		["grass", "path", "dirt", "sand"],
		["grass", "path", "dirt", "sand"],
		["grass", "path", "dirt", "sand"],
		["grass", "path", "dirt", "sand"]
	)

	# Path - less common, connects to grass and itself
	add_tile("path", 0.3,
		["path", "grass"],
		["path", "grass"],
		["path", "grass"],
		["path", "grass"]
	)

	# Dirt - connects to grass and sand
	add_tile("dirt", 0.2,
		["dirt", "grass", "sand"],
		["dirt", "grass", "sand"],
		["dirt", "grass", "sand"],
		["dirt", "grass", "sand"]
	)

	# Sand - only near water or dirt
	add_tile("sand", 0.15,
		["sand", "water", "dirt", "grass"],
		["sand", "water", "dirt", "grass"],
		["sand", "water", "dirt", "grass"],
		["sand", "water", "dirt", "grass"]
	)

	# Water - only next to sand or itself
	add_tile("water", 0.1,
		["water", "sand"],
		["water", "sand"],
		["water", "sand"],
		["water", "sand"]
	)


## Town buildings and streets
func setup_town() -> void:
	add_tile("ground", 1.0,
		["ground", "road_h", "road_v", "building_edge"],
		["ground", "road_h", "road_v", "building_edge"],
		["ground", "road_h", "road_v", "building_edge"],
		["ground", "road_h", "road_v", "building_edge"]
	)

	add_tile("road_h", 0.2,
		["ground", "building_edge"],
		["ground", "building_edge"],
		["road_h", "crossroad"],
		["road_h", "crossroad"]
	)

	add_tile("road_v", 0.2,
		["road_v", "crossroad"],
		["road_v", "crossroad"],
		["ground", "building_edge"],
		["ground", "building_edge"]
	)

	add_tile("crossroad", 0.05,
		["road_v"],
		["road_v"],
		["road_h"],
		["road_h"]
	)

	add_tile("building_edge", 0.15,
		["building_edge", "building", "ground"],
		["building_edge", "building", "ground"],
		["building_edge", "building", "ground"],
		["building_edge", "building", "ground"]
	)

	add_tile("building", 0.1,
		["building", "building_edge"],
		["building", "building_edge"],
		["building", "building_edge"],
		["building", "building_edge"]
	)


# ============================================================================
# GENERATION
# ============================================================================

## Generate a tile grid
## Returns 2D array of tile IDs, or empty array if failed
func generate(width: int, height: int) -> Array[Array]:
	for _retry in range(max_retries):
		var result := _try_generate(width, height)
		if not result.is_empty():
			return result
		# Retry with different random choices
		rng.randomize()

	push_warning("WFC failed after %d retries" % max_retries)
	return []


func _try_generate(width: int, height: int) -> Array[Array]:
	# Initialize grid with all possibilities
	var grid: Array[Array] = []
	for x in range(width):
		var column: Array[WFCCell] = []
		for y in range(height):
			var cell := WFCCell.new()
			cell.possible_tiles = all_tile_ids.duplicate()
			column.append(cell)
		grid.append(column)

	# Main loop
	var propagation_count := 0
	while true:
		# Find cell with lowest entropy (most constrained)
		var min_entropy := INF
		var candidates: Array[Vector2i] = []

		for x in range(width):
			for y in range(height):
				var cell: WFCCell = grid[x][y]
				if cell.is_collapsed():
					continue
				var entropy := cell.entropy()
				if entropy == 0:
					# Contradiction! No valid tiles for this cell
					return []
				if entropy < min_entropy:
					min_entropy = entropy
					candidates = [Vector2i(x, y)]
				elif entropy == min_entropy:
					candidates.append(Vector2i(x, y))

		if candidates.is_empty():
			# All cells collapsed - done!
			break

		# Collapse a random candidate
		var pos: Vector2i = candidates[rng.randi() % candidates.size()]
		var cell: WFCCell = grid[pos.x][pos.y]

		# Weighted random selection
		var chosen := _weighted_tile_choice(cell.possible_tiles)
		cell.collapsed_tile = chosen
		cell.possible_tiles = [chosen]

		# Propagate constraints
		var changed := true
		while changed and propagation_count < max_propagation:
			changed = false
			propagation_count += 1

			for x in range(width):
				for y in range(height):
					var current: WFCCell = grid[x][y]
					if current.is_collapsed():
						continue

					var original_count := current.possible_tiles.size()

					# Check each neighbor and filter possibilities
					# North neighbor (y - 1)
					if y > 0:
						var neighbor: WFCCell = grid[x][y - 1]
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, neighbor, "south"
						)

					# South neighbor (y + 1)
					if y < height - 1:
						var neighbor: WFCCell = grid[x][y + 1]
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, neighbor, "north"
						)

					# West neighbor (x - 1)
					if x > 0:
						var neighbor: WFCCell = grid[x - 1][y]
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, neighbor, "east"
						)

					# East neighbor (x + 1)
					if x < width - 1:
						var neighbor: WFCCell = grid[x + 1][y]
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, neighbor, "west"
						)

					if current.possible_tiles.size() != original_count:
						changed = true

					if current.possible_tiles.is_empty():
						# Contradiction
						return []

	# Extract result
	var result: Array[Array] = []
	for x in range(width):
		var column: Array[String] = []
		for y in range(height):
			column.append(grid[x][y].collapsed_tile)
		result.append(column)

	return result


## Filter possible tiles based on a neighbor's possibilities
## direction = which side the neighbor is on (from neighbor's perspective)
func _filter_by_neighbor(possible: Array[String], neighbor: WFCCell, direction: String) -> Array[String]:
	var valid: Array[String] = []

	for tile_id in possible:
		var tile: WFCTile = tiles[tile_id]
		var can_place := false

		for neighbor_id in neighbor.possible_tiles:
			var neighbor_tile: WFCTile = tiles[neighbor_id]

			match direction:
				"north":  # Neighbor is to our north, check if tile can be south of neighbor
					if tile.valid_north.has(neighbor_id):
						can_place = true
						break
				"south":
					if tile.valid_south.has(neighbor_id):
						can_place = true
						break
				"east":
					if tile.valid_east.has(neighbor_id):
						can_place = true
						break
				"west":
					if tile.valid_west.has(neighbor_id):
						can_place = true
						break

		if can_place:
			valid.append(tile_id)

	return valid


func _weighted_tile_choice(tile_ids: Array[String]) -> String:
	var total_weight := 0.0
	for id in tile_ids:
		total_weight += tiles[id].weight

	var roll := rng.randf() * total_weight
	var cumulative := 0.0

	for id in tile_ids:
		cumulative += tiles[id].weight
		if roll <= cumulative:
			return id

	return tile_ids[-1]


# ============================================================================
# CONSTRAINED GENERATION
# ============================================================================

## Generate with fixed tiles at certain positions
func generate_with_constraints(
	width: int,
	height: int,
	constraints: Dictionary  # Vector2i -> String (tile_id)
) -> Array[Array]:
	for _retry in range(max_retries):
		var result := _try_generate_constrained(width, height, constraints)
		if not result.is_empty():
			return result
		rng.randomize()

	push_warning("WFC with constraints failed after %d retries" % max_retries)
	return []


func _try_generate_constrained(width: int, height: int, constraints: Dictionary) -> Array[Array]:
	# Initialize grid
	var grid: Array[Array] = []
	for x in range(width):
		var column: Array[WFCCell] = []
		for y in range(height):
			var cell := WFCCell.new()
			var pos := Vector2i(x, y)
			if constraints.has(pos):
				# Pre-collapse this cell
				cell.collapsed_tile = constraints[pos]
				cell.possible_tiles = [constraints[pos]]
			else:
				cell.possible_tiles = all_tile_ids.duplicate()
			column.append(cell)
		grid.append(column)

	# Continue with normal generation...
	# (Same logic as _try_generate from here)
	var propagation_count := 0
	while true:
		var min_entropy := INF
		var candidates: Array[Vector2i] = []

		for x in range(width):
			for y in range(height):
				var cell: WFCCell = grid[x][y]
				if cell.is_collapsed():
					continue
				var entropy := cell.entropy()
				if entropy == 0:
					return []
				if entropy < min_entropy:
					min_entropy = entropy
					candidates = [Vector2i(x, y)]
				elif entropy == min_entropy:
					candidates.append(Vector2i(x, y))

		if candidates.is_empty():
			break

		var pos: Vector2i = candidates[rng.randi() % candidates.size()]
		var cell: WFCCell = grid[pos.x][pos.y]
		var chosen := _weighted_tile_choice(cell.possible_tiles)
		cell.collapsed_tile = chosen
		cell.possible_tiles = [chosen]

		var changed := true
		while changed and propagation_count < max_propagation:
			changed = false
			propagation_count += 1

			for x in range(width):
				for y in range(height):
					var current: WFCCell = grid[x][y]
					if current.is_collapsed():
						continue

					var original_count := current.possible_tiles.size()

					if y > 0:
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, grid[x][y - 1], "south"
						)
					if y < height - 1:
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, grid[x][y + 1], "north"
						)
					if x > 0:
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, grid[x - 1][y], "east"
						)
					if x < width - 1:
						current.possible_tiles = _filter_by_neighbor(
							current.possible_tiles, grid[x + 1][y], "west"
						)

					if current.possible_tiles.size() != original_count:
						changed = true

					if current.possible_tiles.is_empty():
						return []

	var result: Array[Array] = []
	for x in range(width):
		var column: Array[String] = []
		for y in range(height):
			column.append(grid[x][y].collapsed_tile)
		result.append(column)

	return result


# ============================================================================
# LEARNING FROM SAMPLES
# ============================================================================

## Learn adjacency rules from a sample tilemap
## sample: Dictionary mapping Vector2i -> String (tile_id)
## bounds: Rect2i defining the sample area
func learn_from_sample(sample: Dictionary, bounds: Rect2i) -> void:
	var learned_adjacencies: Dictionary = {}  # tile_id -> {north: Set, south: Set, ...}

	# First pass: collect all tiles
	for pos_key in sample:
		var tile_id: String = sample[pos_key]
		if not learned_adjacencies.has(tile_id):
			learned_adjacencies[tile_id] = {
				"north": {},
				"south": {},
				"east": {},
				"west": {}
			}

	# Second pass: record adjacencies
	for pos_key in sample:
		var pos: Vector2i = pos_key as Vector2i
		var tile_id: String = sample[pos]
		var adjacencies: Dictionary = learned_adjacencies[tile_id]

		# Check each direction
		var north_pos: Vector2i = pos + Vector2i(0, -1)
		if sample.has(north_pos):
			adjacencies["north"][sample[north_pos]] = true

		var south_pos: Vector2i = pos + Vector2i(0, 1)
		if sample.has(south_pos):
			adjacencies["south"][sample[south_pos]] = true

		var east_pos: Vector2i = pos + Vector2i(1, 0)
		if sample.has(east_pos):
			adjacencies["east"][sample[east_pos]] = true

		var west_pos: Vector2i = pos + Vector2i(-1, 0)
		if sample.has(west_pos):
			adjacencies["west"][sample[west_pos]] = true

	# Convert to tile definitions
	for tile_id in learned_adjacencies:
		var adj: Dictionary = learned_adjacencies[tile_id]

		# Count occurrences for weight
		var count := 0
		for pos_key in sample:
			if sample[pos_key] == tile_id:
				count += 1
		var weight := float(count) / float(sample.size())

		var north_arr: Array[String] = []
		north_arr.assign(adj["north"].keys())
		var south_arr: Array[String] = []
		south_arr.assign(adj["south"].keys())
		var east_arr: Array[String] = []
		east_arr.assign(adj["east"].keys())
		var west_arr: Array[String] = []
		west_arr.assign(adj["west"].keys())

		add_tile(tile_id, weight, north_arr, south_arr, east_arr, west_arr)


# ============================================================================
# UTILITY
# ============================================================================

## Print tile configuration for debugging
func debug_print_tiles() -> void:
	for id in tiles:
		var tile: WFCTile = tiles[id]
		print("Tile '%s' (weight: %.2f)" % [id, tile.weight])
		print("  North: %s" % str(tile.valid_north))
		print("  South: %s" % str(tile.valid_south))
		print("  East: %s" % str(tile.valid_east))
		print("  West: %s" % str(tile.valid_west))


## Visualize result as ASCII
func debug_print_result(result: Array[Array], char_map: Dictionary = {}) -> void:
	if result.is_empty():
		print("(empty result)")
		return

	var width := result.size()
	var height := result[0].size() if width > 0 else 0

	for y in range(height):
		var line := ""
		for x in range(width):
			var tile_id: String = result[x][y]
			if char_map.has(tile_id):
				line += char_map[tile_id]
			else:
				line += tile_id[0] if tile_id.length() > 0 else "?"
		print(line)
