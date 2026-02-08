extends Node2D
## Spring-based background grid — THE signature Geometry Wars visual.
## Grid of point masses connected by springs that react to gameplay forces.

# Grid dimensions (points, not cells)
var cols: int = 32
var rows: int = 18
var spacing: float = 20.0

# Physics properties
var damping: float = 0.70  # Heavy damping — recoil dies in ~0.25s (0.70^15 = 0.5%)
var stiffness: float = 0.15  # Gentle return — no oscillation, just snap-back
var mass: float = 1.0
var max_velocity: float = 2.0  # Clamp velocity magnitude per frame
var max_displacement: float = 4.0  # Max distance from rest position (very subtle)

# Visual properties
var line_color := Color(0.08, 0.15, 0.35, 0.35)
var line_color_bright := Color(0.15, 0.3, 0.6, 0.6)
var line_width: float = 1.0

# Grid data arrays
var positions: PackedVector2Array
var velocities: PackedVector2Array
var rest_positions: PackedVector2Array
var is_anchored: PackedFloat32Array  # 1.0 = anchored (border), 0.0 = free

# Offset to center grid in viewport
var grid_offset := Vector2.ZERO

# Camera reference for world → grid coordinate conversion
var camera_ref: Camera2D
var viewport_size := Vector2(640, 360)


func _ready() -> void:
	_init_grid()


func setup(p_viewport_size: Vector2, p_offset: Vector2) -> void:
	viewport_size = p_viewport_size
	grid_offset = p_offset
	cols = int(viewport_size.x / spacing) + 1
	rows = int(viewport_size.y / spacing) + 1
	_init_grid()


func _init_grid() -> void:
	var total := cols * rows
	positions.resize(total)
	velocities.resize(total)
	rest_positions.resize(total)
	is_anchored.resize(total)

	for y in rows:
		for x in cols:
			var idx := y * cols + x
			var pos := Vector2(x * spacing, y * spacing) + grid_offset
			positions[idx] = pos
			rest_positions[idx] = pos
			velocities[idx] = Vector2.ZERO
			# No anchored borders in scrolling world — all points are free
			is_anchored[idx] = 0.0


func _physics_process(delta: float) -> void:
	_update_springs(delta)
	queue_redraw()


func _update_springs(_delta: float) -> void:
	for y in rows:
		for x in cols:
			var idx := y * cols + x

			# Skip anchored points
			if is_anchored[idx] > 0.5:
				positions[idx] = rest_positions[idx]
				velocities[idx] = Vector2.ZERO
				continue

			# Spring force toward rest position
			var to_rest := rest_positions[idx] - positions[idx]
			var acceleration := to_rest * stiffness

			# Springs to neighbors (pull only, like rubber bands)
			if x > 0:
				acceleration += _spring_force(idx, idx - 1)
			if x < cols - 1:
				acceleration += _spring_force(idx, idx + 1)
			if y > 0:
				acceleration += _spring_force(idx, idx - cols)
			if y < rows - 1:
				acceleration += _spring_force(idx, idx + cols)

			# Apply physics
			velocities[idx] += acceleration / mass
			velocities[idx] *= damping

			# Clamp velocity to prevent runaway
			var vel := velocities[idx]
			var vel_len := vel.length()
			if vel_len > max_velocity:
				velocities[idx] = vel * (max_velocity / vel_len)
			elif is_nan(vel.x) or is_nan(vel.y):
				velocities[idx] = Vector2.ZERO
				positions[idx] = rest_positions[idx]
				continue

			positions[idx] += velocities[idx]

			# Clamp displacement from rest position
			var disp := positions[idx] - rest_positions[idx]
			if disp.length() > max_displacement:
				positions[idx] = rest_positions[idx] + disp.normalized() * max_displacement


func _spring_force(idx_a: int, idx_b: int) -> Vector2:
	var diff := positions[idx_b] - positions[idx_a]
	var rest_diff := rest_positions[idx_b] - rest_positions[idx_a]
	var displacement := diff - rest_diff
	return displacement * stiffness * 0.5


func _draw() -> void:
	# Draw horizontal lines
	for y in rows:
		for x in range(cols - 1):
			var idx_a := y * cols + x
			var idx_b := y * cols + x + 1
			var vel_mag := velocities[idx_a].length() + velocities[idx_b].length()
			var color := line_color.lerp(line_color_bright, clampf(vel_mag * 0.1, 0.0, 1.0))
			draw_line(positions[idx_a], positions[idx_b], color, line_width)

	# Draw vertical lines
	for y in range(rows - 1):
		for x in cols:
			var idx_a := y * cols + x
			var idx_b := (y + 1) * cols + x
			var vel_mag := velocities[idx_a].length() + velocities[idx_b].length()
			var color := line_color.lerp(line_color_bright, clampf(vel_mag * 0.1, 0.0, 1.0))
			draw_line(positions[idx_a], positions[idx_b], color, line_width)


## Convert world position to grid (screen) position.
func world_to_grid(world_pos: Vector2) -> Vector2:
	if camera_ref:
		return world_pos - camera_ref.global_position + viewport_size / 2.0
	return world_pos


## Apply an explosive (outward) force at a world position.
func apply_explosive_force(world_pos: Vector2, force: float, radius: float) -> void:
	var grid_pos := world_to_grid(world_pos)
	for i in positions.size():
		var diff := positions[i] - grid_pos
		var dist := diff.length()
		if dist < radius and dist > 0.01:
			var falloff := 1.0 - (dist / radius)
			falloff = falloff * falloff  # Quadratic falloff
			velocities[i] += diff.normalized() * force * falloff


## Apply an implosive (inward) force — for gravity wells / black holes.
func apply_implosive_force(world_pos: Vector2, force: float, radius: float) -> void:
	var grid_pos := world_to_grid(world_pos)
	for i in positions.size():
		var diff := grid_pos - positions[i]
		var dist := diff.length()
		if dist < radius and dist > 0.01:
			var falloff := 1.0 - (dist / radius)
			velocities[i] += diff.normalized() * force * falloff


## Apply a directional force at a position — for bullets, movement.
func apply_directed_force(
	world_pos: Vector2, direction: Vector2,
	force: float, radius: float,
) -> void:
	var grid_pos := world_to_grid(world_pos)
	for i in positions.size():
		var dist := positions[i].distance_to(grid_pos)
		if dist < radius:
			var falloff := 1.0 - (dist / radius)
			velocities[i] += direction * force * falloff
