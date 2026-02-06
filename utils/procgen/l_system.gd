class_name LSystem
extends RefCounted
## L-System (Lindenmayer System) generator for branching structures.
##
## Use this for rivers, cave tunnel networks, road systems, lightning effects,
## tree/plant shapes, or any naturally branching pattern.
##
## Example - River delta:
##   var lsys = LSystem.new()
##   lsys.set_river_preset()
##   var segments = lsys.generate_and_interpret(Vector2(512, 0), Vector2.DOWN)
##   for segment in segments:
##       draw_river_segment(segment)
##
## Example - Cave tunnels:
##   var lsys = LSystem.new()
##   lsys.set_cave_preset()
##   var tunnels = lsys.generate_and_interpret(entrance_pos, Vector2.RIGHT)

# ============================================================================
# CONFIGURATION
# ============================================================================

## Starting string
var axiom: String = "F"

## Rewriting rules: character -> replacement string
## Can be String (deterministic) or Array[Dictionary] for stochastic rules
## Stochastic format: [{"rule": "FF", "weight": 0.5}, {"rule": "F", "weight": 0.5}]
var rules: Dictionary = {}

## Number of iterations to apply rules
var iterations: int = 3

## Interpretation parameters
var angle_delta: float = 25.0  # Degrees to turn
var step_length: float = 32.0  # Pixels per F
var length_decay: float = 0.8  # Multiplier when entering branch
var width_start: float = 8.0   # Starting line width (for rivers)
var width_decay: float = 0.7   # Width multiplier per branch level

## Random number generator
var rng: RandomNumberGenerator

# ============================================================================
# DATA STRUCTURES
# ============================================================================

## A segment of the generated structure
class Segment:
	var start: Vector2
	var end: Vector2
	var width: float
	var depth: int  # Branch depth (0 = main trunk)

	func _init(s: Vector2, e: Vector2, w: float = 1.0, d: int = 0) -> void:
		start = s
		end = e
		width = w
		depth = d

	func get_length() -> float:
		return start.distance_to(end)

	func get_direction() -> Vector2:
		return (end - start).normalized()

	func get_center() -> Vector2:
		return (start + end) / 2.0


## Turtle state for interpretation
class TurtleState:
	var position: Vector2
	var angle: float  # Radians
	var length: float
	var width: float
	var depth: int

	func duplicate() -> TurtleState:
		var copy := TurtleState.new()
		copy.position = position
		copy.angle = angle
		copy.length = length
		copy.width = width
		copy.depth = depth
		return copy


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


# ============================================================================
# PRESETS
# ============================================================================

## River/stream preset - gentle curves, branching tributaries
func set_river_preset() -> void:
	axiom = "F"
	rules = {
		"F": [
			{"rule": "F[+F]F[-F]F", "weight": 0.3},   # Branch both sides
			{"rule": "F[+F]F", "weight": 0.25},       # Branch right
			{"rule": "F[-F]F", "weight": 0.25},       # Branch left
			{"rule": "FF", "weight": 0.2}             # Just extend
		]
	}
	iterations = 4
	angle_delta = 20.0
	step_length = 40.0
	length_decay = 0.75
	width_start = 12.0
	width_decay = 0.6


## Cave tunnel preset - more irregular, tighter turns
func set_cave_preset() -> void:
	axiom = "F"
	rules = {
		"F": [
			{"rule": "F[+F][-F]", "weight": 0.4},     # Fork
			{"rule": "F[++F]F", "weight": 0.2},       # Sharp right branch
			{"rule": "F[--F]F", "weight": 0.2},       # Sharp left branch
			{"rule": "FF", "weight": 0.2}             # Extend
		]
	}
	iterations = 4
	angle_delta = 35.0
	step_length = 30.0
	length_decay = 0.85
	width_start = 6.0
	width_decay = 0.8


## Road network preset - more regular, grid-influenced
func set_road_preset() -> void:
	axiom = "F"
	rules = {
		"F": [
			{"rule": "F[+F]F[-F]", "weight": 0.5},    # Crossroads
			{"rule": "FF[+F]", "weight": 0.25},       # T-junction right
			{"rule": "FF[-F]", "weight": 0.25}        # T-junction left
		]
	}
	iterations = 4
	angle_delta = 90.0  # Grid-aligned
	step_length = 64.0
	length_decay = 1.0  # Roads don't shrink
	width_start = 4.0
	width_decay = 1.0


## Lightning/crack pattern - chaotic branching
func set_lightning_preset() -> void:
	axiom = "F"
	rules = {
		"F": [
			{"rule": "F[+F][--F]F", "weight": 0.4},
			{"rule": "F[-F][++F]F", "weight": 0.4},
			{"rule": "FF", "weight": 0.2}
		]
	}
	iterations = 5
	angle_delta = 30.0
	step_length = 20.0
	length_decay = 0.7
	width_start = 3.0
	width_decay = 0.5


## Tree/plant preset - botanical growth
func set_tree_preset() -> void:
	axiom = "X"
	rules = {
		"X": "F[+X][-X]FX",
		"F": "FF"
	}
	iterations = 5
	angle_delta = 25.0
	step_length = 10.0
	length_decay = 0.9
	width_start = 4.0
	width_decay = 0.8


# ============================================================================
# STRING GENERATION
# ============================================================================

## Generate the L-system string
func generate() -> String:
	var current := axiom

	for _i in range(iterations):
		var next := ""
		for symbol in current:
			if rules.has(symbol):
				var rule = rules[symbol]
				if rule is String:
					next += rule
				elif rule is Array:
					next += _weighted_choice(rule)
				else:
					next += symbol
			else:
				next += symbol
		current = next

	return current


func _weighted_choice(options: Array) -> String:
	var total_weight := 0.0
	for option in options:
		total_weight += option.weight

	var roll := rng.randf() * total_weight
	var cumulative := 0.0

	for option in options:
		cumulative += option.weight
		if roll <= cumulative:
			return option.rule

	return options[-1].rule


# ============================================================================
# INTERPRETATION (String -> Geometry)
# ============================================================================

## Standard symbols:
## F, G = move forward (draw)
## f, g = move forward (no draw)
## + = turn right by angle_delta
## - = turn left by angle_delta
## [ = push state (start branch)
## ] = pop state (end branch)
## | = turn 180 degrees

## Interpret the string and return segments
func interpret(instructions: String, start_pos: Vector2, start_direction: Vector2 = Vector2.DOWN) -> Array[Segment]:
	var segments: Array[Segment] = []
	var stack: Array[TurtleState] = []

	var state := TurtleState.new()
	state.position = start_pos
	state.angle = start_direction.angle()
	state.length = step_length
	state.width = width_start
	state.depth = 0

	for symbol in instructions:
		match symbol:
			"F", "G":
				# Move forward and draw
				var direction := Vector2.from_angle(state.angle)
				var new_pos := state.position + direction * state.length
				segments.append(Segment.new(
					state.position,
					new_pos,
					state.width,
					state.depth
				))
				state.position = new_pos

			"f", "g":
				# Move forward without drawing
				var direction := Vector2.from_angle(state.angle)
				state.position += direction * state.length

			"+":
				# Turn right
				state.angle += deg_to_rad(angle_delta)

			"-":
				# Turn left
				state.angle -= deg_to_rad(angle_delta)

			"|":
				# Turn around
				state.angle += PI

			"[":
				# Push state (start branch)
				var saved := state.duplicate()
				saved.length *= length_decay
				saved.width *= width_decay
				saved.depth += 1
				stack.append(state)
				state = saved

			"]":
				# Pop state (end branch)
				if not stack.is_empty():
					state = stack.pop_back()

	return segments


## Generate and interpret in one call
func generate_and_interpret(start_pos: Vector2, start_direction: Vector2 = Vector2.DOWN) -> Array[Segment]:
	var instructions := generate()
	return interpret(instructions, start_pos, start_direction)


# ============================================================================
# COLLISION-AWARE INTERPRETATION
# ============================================================================

## Interpret with collision checking - stops branches that hit occupied areas
func interpret_with_collision(
	instructions: String,
	start_pos: Vector2,
	start_direction: Vector2,
	is_blocked: Callable,  # func(pos: Vector2) -> bool
	bounds: Rect2 = Rect2()
) -> Array[Segment]:
	var segments: Array[Segment] = []
	var stack: Array[TurtleState] = []
	var branch_blocked: Array[bool] = [false]  # Stack of blocked states

	var state := TurtleState.new()
	state.position = start_pos
	state.angle = start_direction.angle()
	state.length = step_length
	state.width = width_start
	state.depth = 0

	for symbol in instructions:
		# Skip if current branch is blocked
		if branch_blocked[-1] and symbol != "]":
			if symbol == "[":
				stack.append(state.duplicate())
				branch_blocked.append(true)
			continue

		match symbol:
			"F", "G":
				var direction := Vector2.from_angle(state.angle)
				var new_pos := state.position + direction * state.length

				# Check bounds
				if bounds.has_area() and not bounds.has_point(new_pos):
					branch_blocked[-1] = true
					continue

				# Check collision
				if is_blocked.call(new_pos):
					branch_blocked[-1] = true
					continue

				segments.append(Segment.new(
					state.position,
					new_pos,
					state.width,
					state.depth
				))
				state.position = new_pos

			"f", "g":
				var direction := Vector2.from_angle(state.angle)
				var new_pos := state.position + direction * state.length
				if bounds.has_area() and not bounds.has_point(new_pos):
					branch_blocked[-1] = true
					continue
				if is_blocked.call(new_pos):
					branch_blocked[-1] = true
					continue
				state.position = new_pos

			"+":
				state.angle += deg_to_rad(angle_delta)

			"-":
				state.angle -= deg_to_rad(angle_delta)

			"|":
				state.angle += PI

			"[":
				stack.append(state.duplicate())
				branch_blocked.append(false)
				state.length *= length_decay
				state.width *= width_decay
				state.depth += 1

			"]":
				if not stack.is_empty():
					state = stack.pop_back()
				if branch_blocked.size() > 1:
					branch_blocked.pop_back()

	return segments


# ============================================================================
# TILEMAP CONVERSION
# ============================================================================

## Convert segments to tile positions
func segments_to_tiles(segments: Array[Segment], tile_size: float) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var tile_set: Dictionary = {}  # For deduplication

	for segment in segments:
		# Bresenham-like line rasterization
		var steps := int(ceil(segment.get_length() / tile_size))
		for i in range(steps + 1):
			var t := float(i) / float(maxi(steps, 1))
			var pos := segment.start.lerp(segment.end, t)
			var tile := Vector2i(int(pos.x / tile_size), int(pos.y / tile_size))

			if not tile_set.has(tile):
				tile_set[tile] = true
				tiles.append(tile)

			# Add width tiles perpendicular to segment
			if segment.width > tile_size:
				var perp := segment.get_direction().orthogonal()
				var half_width := int(segment.width / tile_size / 2)
				for w in range(-half_width, half_width + 1):
					var offset_tile := tile + Vector2i(
						int(perp.x * w),
						int(perp.y * w)
					)
					if not tile_set.has(offset_tile):
						tile_set[offset_tile] = true
						tiles.append(offset_tile)

	return tiles


## Convert to a 2D grid
func segments_to_grid(segments: Array[Segment], width: int, height: int, tile_size: float) -> Array[Array]:
	var grid: Array[Array] = []
	for x in range(width):
		var column: Array[int] = []
		column.resize(height)
		column.fill(0)
		grid.append(column)

	var tiles := segments_to_tiles(segments, tile_size)
	for tile in tiles:
		if tile.x >= 0 and tile.x < width and tile.y >= 0 and tile.y < height:
			grid[tile.x][tile.y] = 1

	return grid


# ============================================================================
# NODE-BASED GENERATION (Alternative approach)
# ============================================================================

## A node in a branching structure (tree-like data structure)
class BranchNode:
	var position: Vector2
	var children: Array[BranchNode] = []
	var width: float
	var depth: int

	func get_all_positions() -> Array[Vector2]:
		var positions: Array[Vector2] = [position]
		for child in children:
			positions.append_array(child.get_all_positions())
		return positions


## Generate a tree structure instead of segments
func generate_branch_tree(start_pos: Vector2, start_direction: Vector2, max_depth: int = 4) -> BranchNode:
	var root := BranchNode.new()
	root.position = start_pos
	root.width = width_start
	root.depth = 0

	_grow_branches(root, start_direction, 0, max_depth)
	return root


func _grow_branches(node: BranchNode, direction: Vector2, depth: int, max_depth: int) -> void:
	if depth >= max_depth:
		return

	# Decide how many branches
	var num_branches := 1
	if rng.randf() < 0.4:
		num_branches = 2
	if rng.randf() < 0.1:
		num_branches = 3

	var current_length := step_length * pow(length_decay, depth)
	var angle_spread := deg_to_rad(angle_delta)

	for i in range(num_branches):
		# Calculate branch direction
		var angle_offset := 0.0
		if num_branches > 1:
			angle_offset = (float(i) / float(num_branches - 1) - 0.5) * angle_spread * 2
		angle_offset += rng.randf_range(-angle_spread * 0.3, angle_spread * 0.3)

		var branch_dir := direction.rotated(angle_offset)
		var branch_pos := node.position + branch_dir * current_length

		var child := BranchNode.new()
		child.position = branch_pos
		child.width = node.width * width_decay
		child.depth = depth + 1
		node.children.append(child)

		_grow_branches(child, branch_dir, depth + 1, max_depth)


# ============================================================================
# UTILITY
# ============================================================================

## Get all segment endpoints (useful for placing objects at branch tips)
func get_endpoints(segments: Array[Segment]) -> Array[Vector2]:
	var endpoints: Array[Vector2] = []
	var end_positions: Dictionary = {}
	var start_positions: Dictionary = {}

	for segment in segments:
		end_positions[segment.end] = true
		start_positions[segment.start] = true

	# Endpoints are positions that are ends but not starts of other segments
	for pos in end_positions:
		if not start_positions.has(pos):
			endpoints.append(pos)

	return endpoints


## Get the longest continuous path
func get_main_trunk(segments: Array[Segment]) -> Array[Segment]:
	var trunk: Array[Segment] = []
	for segment in segments:
		if segment.depth == 0:
			trunk.append(segment)
	return trunk
