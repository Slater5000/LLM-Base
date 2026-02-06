class_name PoissonDisk
extends RefCounted
## Poisson Disk Sampling - generates evenly-spaced random points without clumping.
##
## Use this for placing trees, NPCs, items, rocks, or any objects that should
## feel naturally distributed but not overlap or clump together.
##
## Example usage:
##   var sampler = PoissonDisk.new()
##   var tree_positions = sampler.generate(Rect2(0, 0, 1024, 768), 48.0)
##   for pos in tree_positions:
##       place_tree(pos)
##
## With variable density:
##   var forest_noise = NoiseTerrain.new()
##   var positions = sampler.generate_variable_density(bounds, 32.0, 96.0, forest_noise)

# ============================================================================
# CONFIGURATION
# ============================================================================

## Maximum attempts to place a point near an active point
const DEFAULT_MAX_ATTEMPTS := 30

## Random number generator
var rng: RandomNumberGenerator

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
# CORE ALGORITHM (Bridson's Algorithm)
# ============================================================================

## Generate evenly-spaced points within bounds
## min_distance: minimum pixels between any two points
## max_attempts: tries per active point before giving up (higher = denser packing)
func generate(
	bounds: Rect2,
	min_distance: float,
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> Array[Vector2]:
	var cell_size := min_distance / sqrt(2.0)
	var grid_width := ceili(bounds.size.x / cell_size)
	var grid_height := ceili(bounds.size.y / cell_size)

	# Grid stores index into points array, -1 = empty
	var grid: Array[int] = []
	grid.resize(grid_width * grid_height)
	grid.fill(-1)

	var points: Array[Vector2] = []
	var active_list: Array[int] = []  # Indices of points we can still expand from

	# Helper to convert position to grid index
	var to_grid_idx := func(p: Vector2) -> int:
		var gx := int((p.x - bounds.position.x) / cell_size)
		var gy := int((p.y - bounds.position.y) / cell_size)
		gx = clampi(gx, 0, grid_width - 1)
		gy = clampi(gy, 0, grid_height - 1)
		return gy * grid_width + gx

	# Start with a random point
	var initial := Vector2(
		rng.randf() * bounds.size.x + bounds.position.x,
		rng.randf() * bounds.size.y + bounds.position.y
	)
	points.append(initial)
	active_list.append(0)
	grid[to_grid_idx.call(initial)] = 0

	# Main loop
	while not active_list.is_empty():
		# Pick a random active point
		var active_idx := rng.randi() % active_list.size()
		var point_idx := active_list[active_idx]
		var point := points[point_idx]

		var found_valid := false

		for _attempt in range(max_attempts):
			# Generate candidate point at random distance and angle
			var angle := rng.randf() * TAU
			var distance := rng.randf_range(min_distance, min_distance * 2.0)
			var candidate := point + Vector2.from_angle(angle) * distance

			# Check bounds
			if not bounds.has_point(candidate):
				continue

			# Check neighbors in grid
			var valid := true
			var gx := int((candidate.x - bounds.position.x) / cell_size)
			var gy := int((candidate.y - bounds.position.y) / cell_size)

			# Check 5x5 grid neighborhood
			for dy in range(-2, 3):
				if not valid:
					break
				for dx in range(-2, 3):
					var nx := gx + dx
					var ny := gy + dy
					if nx < 0 or nx >= grid_width or ny < 0 or ny >= grid_height:
						continue

					var neighbor_idx := grid[ny * grid_width + nx]
					if neighbor_idx != -1:
						if points[neighbor_idx].distance_to(candidate) < min_distance:
							valid = false
							break

			if valid:
				var new_idx := points.size()
				points.append(candidate)
				active_list.append(new_idx)
				grid[to_grid_idx.call(candidate)] = new_idx
				found_valid = true
				break

		if not found_valid:
			# Remove this point from active list
			active_list.remove_at(active_idx)

	return points


# ============================================================================
# VARIABLE DENSITY
# ============================================================================

## Generate points with density that varies based on noise
## min_distance_dense: spacing in high-density areas (noise = 1.0)
## min_distance_sparse: spacing in low-density areas (noise = 0.0)
## density_noise: NoiseTerrain instance for density lookup
func generate_variable_density(
	bounds: Rect2,
	min_distance_dense: float,
	min_distance_sparse: float,
	density_noise: NoiseTerrain,
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> Array[Vector2]:
	# Use the smaller distance for grid cell size
	var base_cell_size := min_distance_dense / sqrt(2.0)
	var grid_width := ceili(bounds.size.x / base_cell_size)
	var grid_height := ceili(bounds.size.y / base_cell_size)

	var grid: Array[int] = []
	grid.resize(grid_width * grid_height)
	grid.fill(-1)

	var points: Array[Vector2] = []
	var active_list: Array[int] = []

	var to_grid_idx := func(p: Vector2) -> int:
		var gx := int((p.x - bounds.position.x) / base_cell_size)
		var gy := int((p.y - bounds.position.y) / base_cell_size)
		gx = clampi(gx, 0, grid_width - 1)
		gy = clampi(gy, 0, grid_height - 1)
		return gy * grid_width + gx

	# Get minimum distance at a position based on noise
	var get_min_dist := func(p: Vector2) -> float:
		var noise_val := density_noise.sample(p.x, p.y)
		# High noise = dense (small distance), low noise = sparse (large distance)
		return lerpf(min_distance_sparse, min_distance_dense, noise_val)

	# Start with random point
	var initial := Vector2(
		rng.randf() * bounds.size.x + bounds.position.x,
		rng.randf() * bounds.size.y + bounds.position.y
	)
	points.append(initial)
	active_list.append(0)
	grid[to_grid_idx.call(initial)] = 0

	while not active_list.is_empty():
		var active_idx := rng.randi() % active_list.size()
		var point_idx := active_list[active_idx]
		var point := points[point_idx]
		var point_min_dist: float = get_min_dist.call(point)

		var found_valid := false

		for _attempt in range(max_attempts):
			var angle := rng.randf() * TAU
			var distance := rng.randf_range(point_min_dist, point_min_dist * 2.0)
			var candidate := point + Vector2.from_angle(angle) * distance

			if not bounds.has_point(candidate):
				continue

			var candidate_min_dist: float = get_min_dist.call(candidate)
			var check_dist := maxf(point_min_dist, candidate_min_dist)

			var valid := true
			var gx := int((candidate.x - bounds.position.x) / base_cell_size)
			var gy := int((candidate.y - bounds.position.y) / base_cell_size)

			# Check larger neighborhood for variable density
			var check_radius := ceili(check_dist / base_cell_size) + 1
			for dy in range(-check_radius, check_radius + 1):
				if not valid:
					break
				for dx in range(-check_radius, check_radius + 1):
					var nx := gx + dx
					var ny := gy + dy
					if nx < 0 or nx >= grid_width or ny < 0 or ny >= grid_height:
						continue

					var neighbor_idx := grid[ny * grid_width + nx]
					if neighbor_idx != -1:
						var neighbor_pos := points[neighbor_idx]
						var neighbor_min_dist: float = get_min_dist.call(neighbor_pos)
						var required_dist := maxf(candidate_min_dist, neighbor_min_dist)
						if neighbor_pos.distance_to(candidate) < required_dist:
							valid = false
							break

			if valid:
				var new_idx := points.size()
				points.append(candidate)
				active_list.append(new_idx)
				grid[to_grid_idx.call(candidate)] = new_idx
				found_valid = true
				break

		if not found_valid:
			active_list.remove_at(active_idx)

	return points


# ============================================================================
# FILTERED GENERATION
# ============================================================================

## Generate points, then filter based on a condition
func generate_filtered(
	bounds: Rect2,
	min_distance: float,
	filter_func: Callable,  # func(pos: Vector2) -> bool
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> Array[Vector2]:
	var all_points := generate(bounds, min_distance, max_attempts)
	var filtered: Array[Vector2] = []
	for point in all_points:
		if filter_func.call(point):
			filtered.append(point)
	return filtered


## Generate points only on valid terrain
func generate_on_terrain(
	bounds: Rect2,
	min_distance: float,
	valid_terrain_checker: Callable,  # func(pos: Vector2) -> bool
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> Array[Vector2]:
	return generate_filtered(bounds, min_distance, valid_terrain_checker, max_attempts)


## Generate points avoiding certain areas
func generate_avoiding(
	bounds: Rect2,
	min_distance: float,
	avoid_positions: Array[Vector2],
	avoid_radius: float,
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> Array[Vector2]:
	var is_valid := func(pos: Vector2) -> bool:
		for avoid_pos in avoid_positions:
			if pos.distance_to(avoid_pos) < avoid_radius:
				return false
		return true

	return generate_filtered(bounds, min_distance, is_valid, max_attempts)


# ============================================================================
# MULTIPLE OBJECT TYPES
# ============================================================================

## Result for multi-type generation
class MultiTypeResult:
	var positions_by_type: Dictionary = {}  # String -> Array[Vector2]

	func get_positions(type_name: String) -> Array[Vector2]:
		if positions_by_type.has(type_name):
			return positions_by_type[type_name]
		return []


## Generate multiple object types with different densities
## Each type defined as { "name": String, "min_distance": float, "probability": float }
func generate_multi_type(
	bounds: Rect2,
	type_definitions: Array[Dictionary],
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> MultiTypeResult:
	var result := MultiTypeResult.new()

	# Sort by distance (largest first for best results)
	var sorted_types := type_definitions.duplicate()
	sorted_types.sort_custom(func(a, b): return a.min_distance > b.min_distance)

	var all_placed_positions: Array[Vector2] = []

	for type_def in sorted_types:
		var type_name: String = type_def.name
		var min_dist: float = type_def.min_distance
		var probability: float = type_def.get("probability", 1.0)

		result.positions_by_type[type_name] = []

		# Generate candidates avoiding already-placed objects
		var candidates := generate_avoiding(
			bounds, min_dist, all_placed_positions, min_dist, max_attempts
		)

		# Apply probability filter
		for pos in candidates:
			if rng.randf() < probability:
				result.positions_by_type[type_name].append(pos)
				all_placed_positions.append(pos)

	return result


# ============================================================================
# CLUSTERING SUPPORT
# ============================================================================

## Generate points with clustering behavior
## cluster_probability: chance of starting a new cluster vs isolated point
## cluster_size_range: Vector2i(min_count, max_count) for cluster size
## cluster_radius: how spread out cluster members can be
func generate_clustered(
	bounds: Rect2,
	min_distance: float,
	cluster_probability: float = 0.3,
	cluster_size_range: Vector2i = Vector2i(3, 6),
	cluster_spread: float = 0.5,  # Multiplier for min_distance within cluster
	max_attempts: int = DEFAULT_MAX_ATTEMPTS
) -> Array[Vector2]:
	# First generate cluster centers
	var cluster_spacing := min_distance * (cluster_size_range.y + 1)
	var cluster_centers := generate(bounds, cluster_spacing, max_attempts)

	var all_points: Array[Vector2] = []
	var within_cluster_dist := min_distance * cluster_spread

	for center in cluster_centers:
		if rng.randf() < cluster_probability:
			# Create a cluster
			var cluster_size := rng.randi_range(cluster_size_range.x, cluster_size_range.y)
			var cluster_bounds := Rect2(
				center.x - cluster_spacing / 2,
				center.y - cluster_spacing / 2,
				cluster_spacing,
				cluster_spacing
			)
			cluster_bounds = cluster_bounds.intersection(bounds)

			if cluster_bounds.has_area():
				var cluster_points := generate(cluster_bounds, within_cluster_dist, max_attempts / 2)
				for p in cluster_points:
					if all_points.size() < cluster_size + all_points.size():
						all_points.append(p)
		else:
			# Single point
			all_points.append(center)

	return all_points


# ============================================================================
# UTILITY
# ============================================================================

## Visualize points as debug circles (call from _draw)
static func debug_draw(canvas: CanvasItem, points: Array[Vector2], radius: float = 4.0, color: Color = Color.WHITE) -> void:
	for point in points:
		canvas.draw_circle(point, radius, color)


## Get statistics about the distribution
func get_distribution_stats(points: Array[Vector2]) -> Dictionary:
	if points.size() < 2:
		return {"count": points.size(), "min_dist": 0.0, "max_dist": 0.0, "avg_dist": 0.0}

	var min_dist := INF
	var max_dist := 0.0
	var total_dist := 0.0
	var count := 0

	for i in range(points.size()):
		for j in range(i + 1, mini(i + 10, points.size())):  # Sample nearby points
			var dist := points[i].distance_to(points[j])
			min_dist = minf(min_dist, dist)
			max_dist = maxf(max_dist, dist)
			total_dist += dist
			count += 1

	return {
		"count": points.size(),
		"min_dist": min_dist,
		"max_dist": max_dist,
		"avg_dist": total_dist / count if count > 0 else 0.0
	}
