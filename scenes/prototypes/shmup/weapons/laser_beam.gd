extends Node2D
## Continuous laser beam weapon — replaces bullets when LASER BEAM upgrade is taken.
## Triple-layer glow via _draw(), point-to-line distance for damage.
## Supports spread_count for multiple beams in a fan.

# Colors — cyan core with blue glow
const CORE_COLOR := Color(0.8, 1.0, 1.0, 0.9)
const MID_COLOR := Color(0.3, 0.7, 1.0, 0.4)
const GLOW_COLOR := Color(0.2, 0.4, 1.0, 0.12)
const SPREAD_FAN_ANGLE := 30.0  # degrees, matches player_ship

var is_active := false
var beam_length := 400.0  # Covers viewport diagonal
var base_width := 2.0
var damage_per_tick := 1
var damage_tick_rate := 0.06  # Fast ticks for continuous feel

# References
var player: Area2D
var enemy_container: Node2D
var spring_grid: Node2D

# Internal
var _damage_timer := 0.0
var _pulse_time := 0.0
var _spatial_grid: RefCounted


func setup(
	p_player: Area2D, p_enemies: Node2D,
	p_grid: Node2D, p_spatial: RefCounted = null,
) -> void:
	player = p_player
	enemy_container = p_enemies
	spring_grid = p_grid
	_spatial_grid = p_spatial


func activate() -> void:
	is_active = true
	visible = true
	_damage_timer = 0.0


func deactivate() -> void:
	is_active = false
	visible = false


func _process(delta: float) -> void:
	if not is_active or not player or not player.is_alive:
		visible = false
		return

	visible = true
	_pulse_time += delta

	# Position at player, rotate to aim
	global_position = player.position
	rotation = player.aim_direction.angle() + PI / 2.0

	# Damage tick
	_damage_timer -= delta
	if _damage_timer <= 0.0:
		_damage_timer = damage_tick_rate
		_apply_beam_damage()

	# Grid warp — continuous directed force along beam
	if spring_grid:
		spring_grid.apply_directed_force(
			player.position, player.aim_direction, 0.06, 15.0
		)

	queue_redraw()


## Returns an array of angle offsets (radians) for each beam in the spread fan.
func _get_beam_angles() -> Array:
	var spread_count: int = player.spread_count if player else 1
	if spread_count <= 1:
		return [0.0]
	var half_fan := deg_to_rad(SPREAD_FAN_ANGLE / 2.0)
	var angles: Array = []
	for i in spread_count:
		var t: float = float(i) / float(spread_count - 1)
		angles.append(lerpf(-half_fan, half_fan, t))
	return angles


func _apply_beam_damage() -> void:
	if not enemy_container:
		return

	var beam_start: Vector2 = player.position
	var base_dir: Vector2 = player.aim_direction
	var hit_width := base_width * 4.0 + _get_pulse_width() * 2.0

	# Build beam endpoints for all beams in the fan
	var beam_ends: Array = []
	for angle_offset in _get_beam_angles():
		var beam_dir: Vector2 = base_dir.rotated(angle_offset)
		var beam_end: Vector2 = beam_start + beam_dir * beam_length
		beam_ends.append(beam_end)

	# Pre-filter with spatial grid (beam_length radius from player)
	var candidates: Array
	if _spatial_grid:
		candidates = _spatial_grid.query_radius(
			beam_start, beam_length + hit_width,
		)
	else:
		candidates = []
		for c in enemy_container.get_children():
			if c.get("is_active"):
				candidates.append(c)

	for enemy in candidates:
		for beam_end in beam_ends:
			var end_vec: Vector2 = beam_end as Vector2
			var dist := _point_to_segment_distance(
				enemy.position, beam_start, end_vec,
			)
			if dist <= hit_width:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage_per_tick)
				break


func _point_to_segment_distance(point: Vector2, seg_start: Vector2, seg_end: Vector2) -> float:
	var seg := seg_end - seg_start
	var seg_len_sq := seg.length_squared()
	if seg_len_sq < 0.01:
		return point.distance_to(seg_start)

	# Project point onto segment
	var t := clampf((point - seg_start).dot(seg) / seg_len_sq, 0.0, 1.0)
	var proj := seg_start + seg * t
	return point.distance_to(proj)


func _get_pulse_width() -> float:
	return sin(_pulse_time * 5.0) * base_width * 0.2


func _draw() -> void:
	if not is_active:
		return

	var pulse := _get_pulse_width()
	var w := base_width + pulse
	var length := beam_length

	# Draw each beam in the spread fan
	for angle_offset in _get_beam_angles():
		# -PI/2 = "up" in local space (matches node rotation setup)
		var dir := Vector2.from_angle(-PI / 2.0 + angle_offset)
		var start := Vector2.ZERO
		var end := dir * length

		# Outer glow
		draw_line(start, end, GLOW_COLOR, w * 6.0)
		# Mid glow
		draw_line(start, end, MID_COLOR, w * 2.5)
		# Core
		draw_line(start, end, CORE_COLOR, w * 0.8)

	# Bright muzzle flash at origin
	var flash_alpha := 0.4 + sin(_pulse_time * 8.0) * 0.2
	draw_circle(Vector2.ZERO, w * 2.0, Color(0.6, 0.9, 1.0, flash_alpha))
