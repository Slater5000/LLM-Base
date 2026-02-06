class_name BSPDungeon
extends RefCounted
## Binary Space Partitioning dungeon generator.
##
## Use this for caves, dungeons, team hideouts, research facilities,
## or any indoor multi-room layout that needs guaranteed connectivity.
##
## Example usage:
##   var dungeon = BSPDungeon.new()
##   dungeon.configure(32, 24, 6, 10)  # 32x24 tiles, rooms 6-10 tiles
##   var result = dungeon.generate()
##   for room in result.rooms:
##       carve_room(room)
##   for corridor in result.corridors:
##       carve_corridor(corridor)

# ============================================================================
# CONFIGURATION
# ============================================================================

## Minimum room dimension (width or height)
var min_room_size: int = 5

## Maximum room dimension
var max_room_size: int = 12

## Minimum partition size that can still be split
var min_split_size: int = 12

## Margin between room edge and partition edge
var room_margin: int = 1

## Corridor width (1 = tight, 2-3 = spacious)
var corridor_width: int = 1

## Chance to stop splitting early (0.0 - 0.3 recommended)
var early_stop_chance: float = 0.15

## Maximum recursion depth
var max_depth: int = 8

## Random number generator
var rng: RandomNumberGenerator

# ============================================================================
# DATA STRUCTURES
# ============================================================================

## A node in the BSP tree
class BSPNode:
	var rect: Rect2i
	var left_child: BSPNode
	var right_child: BSPNode
	var room: Rect2i  # Only set for leaf nodes
	var room_type: String = "normal"  # Can be tagged for special rooms

	func is_leaf() -> bool:
		return left_child == null and right_child == null

	func get_center() -> Vector2i:
		return Vector2i(
			rect.position.x + rect.size.x / 2,
			rect.position.y + rect.size.y / 2
		)

	## Get all leaf nodes (rooms) in this subtree
	func get_leaves() -> Array[BSPNode]:
		if is_leaf():
			return [self]
		var leaves: Array[BSPNode] = []
		if left_child:
			leaves.append_array(left_child.get_leaves())
		if right_child:
			leaves.append_array(right_child.get_leaves())
		return leaves


## Result of dungeon generation
class DungeonResult:
	var root: BSPNode
	var rooms: Array[Rect2i] = []
	var corridors: Array[Rect2i] = []
	var room_nodes: Array[BSPNode] = []  # Nodes with their room types

	## Get the entrance room (first room, typically)
	func get_entrance() -> Rect2i:
		if rooms.is_empty():
			return Rect2i()
		return rooms[0]

	## Get the deepest room (good for boss/treasure)
	func get_deepest_room() -> Rect2i:
		if rooms.is_empty():
			return Rect2i()
		return rooms[-1]

	## Get room by type tag
	func get_rooms_by_type(type: String) -> Array[Rect2i]:
		var result: Array[Rect2i] = []
		for node in room_nodes:
			if node.room_type == type:
				result.append(node.room)
		return result

	## Check if a position is inside any room
	func is_in_room(pos: Vector2i) -> bool:
		for room in rooms:
			if room.has_point(pos):
				return true
		return false

	## Check if a position is inside any corridor
	func is_in_corridor(pos: Vector2i) -> bool:
		for corridor in corridors:
			if corridor.has_point(pos):
				return true
		return false

	## Check if a position is floor (room or corridor)
	func is_floor(pos: Vector2i) -> bool:
		return is_in_room(pos) or is_in_corridor(pos)


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


## Configure dungeon parameters
func configure(
	width: int,
	height: int,
	min_room: int = 5,
	max_room: int = 12,
	min_split: int = 0,  # 0 = auto-calculate
	margin: int = 1,
	corridor_w: int = 1
) -> void:
	min_room_size = min_room
	max_room_size = max_room
	min_split_size = min_split if min_split > 0 else min_room * 2 + margin * 2
	room_margin = margin
	corridor_width = corridor_w


# ============================================================================
# GENERATION
# ============================================================================

## Generate a dungeon within the given dimensions
func generate(width: int, height: int) -> DungeonResult:
	var result := DungeonResult.new()

	# Create root node covering entire area
	result.root = BSPNode.new()
	result.root.rect = Rect2i(0, 0, width, height)

	# Recursively split
	_split(result.root, 0)

	# Create rooms in leaf nodes
	_create_rooms(result.root)

	# Connect rooms via corridors
	_connect_rooms(result.root, result.corridors)

	# Collect all rooms
	var leaves := result.root.get_leaves()
	for leaf in leaves:
		if leaf.room.has_area():
			result.rooms.append(leaf.room)
			result.room_nodes.append(leaf)

	return result


## Split a node into two children
func _split(node: BSPNode, depth: int) -> void:
	# Check stopping conditions
	if depth >= max_depth:
		return

	if node.rect.size.x < min_split_size and node.rect.size.y < min_split_size:
		return

	if depth > 0 and rng.randf() < early_stop_chance:
		return

	# Decide split direction
	var split_horizontal: bool
	if node.rect.size.x < min_split_size:
		split_horizontal = true
	elif node.rect.size.y < min_split_size:
		split_horizontal = false
	elif float(node.rect.size.x) / float(node.rect.size.y) > 1.25:
		split_horizontal = false  # Too wide, split vertically
	elif float(node.rect.size.y) / float(node.rect.size.x) > 1.25:
		split_horizontal = true  # Too tall, split horizontally
	else:
		split_horizontal = rng.randf() < 0.5

	# Calculate split position
	var min_pos: int
	var max_pos: int

	if split_horizontal:
		min_pos = min_room_size + room_margin
		max_pos = node.rect.size.y - min_room_size - room_margin
	else:
		min_pos = min_room_size + room_margin
		max_pos = node.rect.size.x - min_room_size - room_margin

	if max_pos <= min_pos:
		return  # Can't split

	var split_pos := rng.randi_range(min_pos, max_pos)

	# Create children
	node.left_child = BSPNode.new()
	node.right_child = BSPNode.new()

	if split_horizontal:
		node.left_child.rect = Rect2i(
			node.rect.position,
			Vector2i(node.rect.size.x, split_pos)
		)
		node.right_child.rect = Rect2i(
			node.rect.position + Vector2i(0, split_pos),
			Vector2i(node.rect.size.x, node.rect.size.y - split_pos)
		)
	else:
		node.left_child.rect = Rect2i(
			node.rect.position,
			Vector2i(split_pos, node.rect.size.y)
		)
		node.right_child.rect = Rect2i(
			node.rect.position + Vector2i(split_pos, 0),
			Vector2i(node.rect.size.x - split_pos, node.rect.size.y)
		)

	# Recurse
	_split(node.left_child, depth + 1)
	_split(node.right_child, depth + 1)


## Create rooms in leaf nodes
func _create_rooms(node: BSPNode) -> void:
	if node.is_leaf():
		# Calculate room bounds within partition
		var available_width := node.rect.size.x - room_margin * 2
		var available_height := node.rect.size.y - room_margin * 2

		if available_width < min_room_size or available_height < min_room_size:
			# Partition too small, create minimal room
			node.room = Rect2i(
				node.rect.position.x + room_margin,
				node.rect.position.y + room_margin,
				maxi(1, available_width),
				maxi(1, available_height)
			)
			return

		var room_width := rng.randi_range(
			min_room_size,
			mini(max_room_size, available_width)
		)
		var room_height := rng.randi_range(
			min_room_size,
			mini(max_room_size, available_height)
		)

		var room_x := node.rect.position.x + rng.randi_range(
			room_margin,
			node.rect.size.x - room_width - room_margin
		)
		var room_y := node.rect.position.y + rng.randi_range(
			room_margin,
			node.rect.size.y - room_height - room_margin
		)

		node.room = Rect2i(room_x, room_y, room_width, room_height)
	else:
		if node.left_child:
			_create_rooms(node.left_child)
		if node.right_child:
			_create_rooms(node.right_child)


## Connect rooms through the BSP tree
func _connect_rooms(node: BSPNode, corridors: Array[Rect2i]) -> void:
	if node.is_leaf():
		return

	# Connect children first
	if node.left_child:
		_connect_rooms(node.left_child, corridors)
	if node.right_child:
		_connect_rooms(node.right_child, corridors)

	# Connect a room from left subtree to a room from right subtree
	if node.left_child and node.right_child:
		var left_room := _get_random_room(node.left_child)
		var right_room := _get_random_room(node.right_child)

		if left_room.has_area() and right_room.has_area():
			_create_corridor(left_room, right_room, corridors)


## Get a random room from a subtree
func _get_random_room(node: BSPNode) -> Rect2i:
	if node.is_leaf():
		return node.room

	var leaves := node.get_leaves()
	var valid_leaves: Array[BSPNode] = []
	for leaf in leaves:
		if leaf.room.has_area():
			valid_leaves.append(leaf)

	if valid_leaves.is_empty():
		return Rect2i()

	return valid_leaves[rng.randi() % valid_leaves.size()].room


## Create an L-shaped corridor between two rooms
func _create_corridor(room_a: Rect2i, room_b: Rect2i, corridors: Array[Rect2i]) -> void:
	var center_a := Vector2i(
		room_a.position.x + room_a.size.x / 2,
		room_a.position.y + room_a.size.y / 2
	)
	var center_b := Vector2i(
		room_b.position.x + room_b.size.x / 2,
		room_b.position.y + room_b.size.y / 2
	)

	# Randomly choose L-shape direction
	if rng.randf() < 0.5:
		# Horizontal then vertical
		corridors.append(_horizontal_corridor(center_a.x, center_b.x, center_a.y))
		corridors.append(_vertical_corridor(center_a.y, center_b.y, center_b.x))
	else:
		# Vertical then horizontal
		corridors.append(_vertical_corridor(center_a.y, center_b.y, center_a.x))
		corridors.append(_horizontal_corridor(center_a.x, center_b.x, center_b.y))


func _horizontal_corridor(x1: int, x2: int, y: int) -> Rect2i:
	var min_x := mini(x1, x2)
	var width := absi(x1 - x2) + corridor_width
	return Rect2i(min_x, y, width, corridor_width)


func _vertical_corridor(y1: int, y2: int, x: int) -> Rect2i:
	var min_y := mini(y1, y2)
	var height := absi(y1 - y2) + corridor_width
	return Rect2i(x, min_y, corridor_width, height)


# ============================================================================
# POST-PROCESSING
# ============================================================================

## Add extra corridors for loops (makes dungeon feel less linear)
func add_loops(result: DungeonResult, loop_count: int = 2) -> void:
	if result.rooms.size() < 3:
		return

	for _i in range(loop_count):
		var room_a := result.rooms[rng.randi() % result.rooms.size()]
		var room_b := result.rooms[rng.randi() % result.rooms.size()]

		if room_a != room_b:
			_create_corridor(room_a, room_b, result.corridors)


## Tag special rooms (entrance, boss, treasure)
func tag_special_rooms(result: DungeonResult) -> void:
	if result.room_nodes.is_empty():
		return

	# Tag first room as entrance
	result.room_nodes[0].room_type = "entrance"

	# Tag last room as boss
	if result.room_nodes.size() > 1:
		result.room_nodes[-1].room_type = "boss"

	# Tag a random middle room as treasure
	if result.room_nodes.size() > 2:
		var treasure_idx := rng.randi_range(1, result.room_nodes.size() - 2)
		result.room_nodes[treasure_idx].room_type = "treasure"


# ============================================================================
# TILEMAP HELPERS
# ============================================================================

## Generate a 2D grid representing the dungeon
## 0 = wall, 1 = floor, 2 = corridor
func to_grid(result: DungeonResult, width: int, height: int) -> Array[Array]:
	var grid: Array[Array] = []
	for x in range(width):
		var column: Array[int] = []
		column.resize(height)
		column.fill(0)  # Wall
		grid.append(column)

	# Carve rooms
	for room in result.rooms:
		for x in range(room.position.x, room.position.x + room.size.x):
			for y in range(room.position.y, room.position.y + room.size.y):
				if x >= 0 and x < width and y >= 0 and y < height:
					grid[x][y] = 1  # Floor

	# Carve corridors
	for corridor in result.corridors:
		for x in range(corridor.position.x, corridor.position.x + corridor.size.x):
			for y in range(corridor.position.y, corridor.position.y + corridor.size.y):
				if x >= 0 and x < width and y >= 0 and y < height:
					if grid[x][y] == 0:
						grid[x][y] = 2  # Corridor

	return grid


## Get valid spawn positions within a room
func get_spawn_positions_in_room(room: Rect2i, margin: int = 1) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for x in range(room.position.x + margin, room.position.x + room.size.x - margin):
		for y in range(room.position.y + margin, room.position.y + room.size.y - margin):
			positions.append(Vector2i(x, y))
	return positions


## Get a random spawn position in the dungeon
func get_random_floor_position(result: DungeonResult) -> Vector2i:
	if result.rooms.is_empty():
		return Vector2i.ZERO

	var room := result.rooms[rng.randi() % result.rooms.size()]
	return Vector2i(
		rng.randi_range(room.position.x + 1, room.position.x + room.size.x - 2),
		rng.randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
	)


# ============================================================================
# CAVE VARIANT (organic shapes via cellular automata post-process)
# ============================================================================

## Convert rectangular rooms to organic cave shapes
func make_organic(result: DungeonResult, width: int, height: int, iterations: int = 4) -> Array[Array]:
	var grid := to_grid(result, width, height)

	# Add some randomness to floor tiles
	for x in range(width):
		for y in range(height):
			if grid[x][y] > 0:
				# Expand floors slightly with random chance
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var nx := x + dx
						var ny := y + dy
						if nx >= 0 and nx < width and ny >= 0 and ny < height:
							if grid[nx][ny] == 0 and rng.randf() < 0.3:
								grid[nx][ny] = 1

	# Run cellular automata smoothing
	for _iter in range(iterations):
		var new_grid: Array[Array] = []
		for x in range(width):
			var column: Array[int] = []
			column.resize(height)
			for y in range(height):
				var floor_neighbors := _count_floor_neighbors(grid, x, y, width, height)
				if grid[x][y] > 0:
					# Floor stays floor if enough neighbors
					column[y] = 1 if floor_neighbors >= 4 else 0
				else:
					# Wall becomes floor if many neighbors
					column[y] = 1 if floor_neighbors >= 5 else 0
			new_grid.append(column)
		grid = new_grid

	return grid


func _count_floor_neighbors(grid: Array[Array], x: int, y: int, width: int, height: int) -> int:
	var count := 0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := x + dx
			var ny := y + dy
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				if grid[nx][ny] > 0:
					count += 1
			else:
				# Treat out-of-bounds as wall
				pass
	return count
