extends Area2D
## Twin-stick player ship with movement, aiming, and shooting.

signal died(pos: Vector2)
signal fired_bullet(pos: Vector2, direction: Vector2)
signal bomb_used(pos: Vector2)

# Constants
const SPREAD_FAN_ANGLE := 30.0  # degrees, total fan width for spread shot
const SHIP_COLOR := Color(0.2, 0.9, 1.0)
const SHIP_COLOR_DIM := Color(0.1, 0.5, 0.6, 0.5)

# Movement
@export var max_speed := 150.0
@export var acceleration := 500.0
@export var deceleration := 300.0
@export var bounce_factor := 0.4

# Shooting
@export var fire_rate := 5.0
@export var bullet_spread := 2.0

# Upgrade-driven stats (set by upgrade_manager)
var spread_count := 1
var bullet_size_scale := 1.0
var pierce_count := 0
var burn_chance := 0.0
var freeze_chance := 0.0
var has_laser := false
var has_bullet_storm := false
var has_railgun := false

# State
var velocity := Vector2.ZERO
var aim_direction := Vector2.UP
var move_direction := Vector2.ZERO
var is_alive := true
var is_invincible := false
var invincible_timer := 0.0
var world_bounds := Rect2(-1600, -1600, 3200, 3200)

# Internal
var _fire_cooldown := 0.0
var _blink_timer := 0.0

# Node references
@onready var ship_polygon: Polygon2D = $ShipPolygon
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var engine_particles: GPUParticles2D = $EngineParticles


func _ready() -> void:
	_setup_visuals()
	_setup_particles()
	area_entered.connect(_on_area_entered)


func _setup_visuals() -> void:
	# Arrow/chevron shape
	ship_polygon.polygon = PackedVector2Array([
		Vector2(0, -8),     # Nose
		Vector2(6, 6),      # Right wing
		Vector2(3, 3),      # Right indent
		Vector2(0, 5),      # Tail center
		Vector2(-3, 3),     # Left indent
		Vector2(-6, 6),     # Left wing
	])
	ship_polygon.color = SHIP_COLOR

	# Collision shape
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	collision_shape.shape = circle


func _setup_particles() -> void:
	engine_particles.emitting = false
	engine_particles.amount = 12
	engine_particles.lifetime = 0.4
	engine_particles.local_coords = false

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)  # Emit backward
	mat.spread = 20.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 50.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 2.0
	mat.damping_max = 3.0
	mat.scale_min = 1.0
	mat.scale_max = 2.0
	mat.color = Color(0.15, 0.6, 0.8, 0.6)

	var color_ramp := Gradient.new()
	color_ramp.set_color(0, Color(0.2, 0.7, 0.9, 0.7))
	color_ramp.set_color(1, Color(0.1, 0.3, 0.5, 0.0))
	var color_texture := GradientTexture1D.new()
	color_texture.gradient = color_ramp
	mat.color_ramp = color_texture

	engine_particles.process_material = mat


func _process(delta: float) -> void:
	if not is_alive:
		return

	_handle_input()
	_update_movement(delta)
	_update_aim(delta)
	_update_shooting(delta)
	_update_invincibility(delta)
	_update_engine_particles()


func _handle_input() -> void:
	# Movement input (WASD + Left stick)
	move_direction = Vector2.ZERO
	move_direction.x = Input.get_axis("shmup_move_left", "shmup_move_right")
	move_direction.y = Input.get_axis("shmup_move_up", "shmup_move_down")
	if move_direction.length() > 1.0:
		move_direction = move_direction.normalized()

	# Aim: mouse (primary), arrow keys/stick (fallback)
	var mouse_world := get_global_mouse_position()
	var to_mouse := mouse_world - global_position
	if to_mouse.length() > 5.0:
		aim_direction = to_mouse.normalized()
	else:
		var aim_input := Vector2.ZERO
		aim_input.x = Input.get_axis("shmup_aim_left", "shmup_aim_right")
		aim_input.y = Input.get_axis("shmup_aim_up", "shmup_aim_down")
		if aim_input.length() > 0.3:
			aim_direction = aim_input.normalized()


func _update_movement(delta: float) -> void:
	if move_direction.length() > 0.1:
		velocity += move_direction * acceleration * delta
		if velocity.length() > max_speed:
			velocity = velocity.normalized() * max_speed
	else:
		# Decelerate with drift
		var speed := velocity.length()
		if speed > 0.0:
			speed = maxf(speed - deceleration * delta, 0.0)
			velocity = velocity.normalized() * speed

	position += velocity * delta

	# Soft world boundary — gentle pushback near edges
	var edge_margin := 80.0
	var push_strength := 400.0

	var left_dist := position.x - world_bounds.position.x
	if left_dist < edge_margin:
		velocity.x += (1.0 - left_dist / edge_margin) * push_strength * delta

	var right_dist := world_bounds.end.x - position.x
	if right_dist < edge_margin:
		velocity.x -= (1.0 - right_dist / edge_margin) * push_strength * delta

	var top_dist := position.y - world_bounds.position.y
	if top_dist < edge_margin:
		velocity.y += (1.0 - top_dist / edge_margin) * push_strength * delta

	var bottom_dist := world_bounds.end.y - position.y
	if bottom_dist < edge_margin:
		velocity.y -= (1.0 - bottom_dist / edge_margin) * push_strength * delta

	# Hard clamp as safety net
	position = position.clamp(
		world_bounds.position + Vector2(4, 4),
		world_bounds.end - Vector2(4, 4)
	)


func _update_aim(delta: float) -> void:
	# Rotate to face aim direction, or movement direction if no aim input
	var target_dir := aim_direction
	if target_dir.length() < 0.1 and move_direction.length() > 0.1:
		target_dir = move_direction

	if target_dir.length() > 0.1:
		var target_angle := target_dir.angle() + PI / 2.0
		rotation = lerp_angle(rotation, target_angle, 15.0 * delta)


func _update_shooting(delta: float) -> void:
	if has_laser:
		return  # Laser beam handles damage directly
	_fire_cooldown -= delta
	if _fire_cooldown <= 0.0:
		_fire_cooldown = 1.0 / fire_rate
		var muzzle_pos := position + aim_direction * 10.0

		if has_bullet_storm:
			_fire_bullet_storm(muzzle_pos)
		elif spread_count <= 1:
			# Single bullet with slight random spread
			var spread := deg_to_rad(
				randf_range(-bullet_spread, bullet_spread),
			)
			var dir := aim_direction.rotated(spread)
			fired_bullet.emit(muzzle_pos, dir)
		else:
			_fire_spread(muzzle_pos)


func _fire_spread(muzzle_pos: Vector2) -> void:
	var half_fan := deg_to_rad(SPREAD_FAN_ANGLE / 2.0)
	for i in spread_count:
		var t: float = float(i) / float(spread_count - 1)
		var fan_angle := lerpf(-half_fan, half_fan, t)
		var jitter := deg_to_rad(
			randf_range(
				-bullet_spread * 0.5, bullet_spread * 0.5,
			),
		)
		var dir := aim_direction.rotated(fan_angle + jitter)
		fired_bullet.emit(muzzle_pos, dir)


func _fire_bullet_storm(muzzle_pos: Vector2) -> void:
	# Smart-aim: fire toward nearest enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	var targets: Array[Vector2] = []
	# Sort enemies by distance, take nearest 8
	enemies.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return position.distance_squared_to(a.position) < position.distance_squared_to(b.position)
	)
	for j in mini(enemies.size(), spread_count):
		var e: Node2D = enemies[j]
		if position.distance_to(e.position) < 400.0:
			targets.append(e.position)
	# Fire aimed bullets at targets
	for tgt in targets:
		var dir := (tgt - muzzle_pos).normalized()
		var jitter := deg_to_rad(randf_range(-3.0, 3.0))
		fired_bullet.emit(muzzle_pos, dir.rotated(jitter))
	# Remaining bullets: normal fan spread
	var remaining := spread_count - targets.size()
	if remaining > 0:
		var half_fan := deg_to_rad(SPREAD_FAN_ANGLE / 2.0)
		for i in remaining:
			var t := float(i) / maxf(float(remaining - 1), 1.0)
			var fan_angle := lerpf(-half_fan, half_fan, t)
			var dir := aim_direction.rotated(fan_angle)
			fired_bullet.emit(muzzle_pos, dir)


func _update_invincibility(delta: float) -> void:
	if is_invincible:
		invincible_timer -= delta
		_blink_timer += delta * 15.0
		ship_polygon.visible = int(_blink_timer) % 2 == 0
		if invincible_timer <= 0.0:
			is_invincible = false
			ship_polygon.visible = true


func _update_engine_particles() -> void:
	var speed := velocity.length()
	engine_particles.emitting = speed > 10.0
	if speed > 10.0:
		# Scale particle emission with speed
		var speed_ratio := clampf(speed / max_speed, 0.0, 1.0)
		engine_particles.amount = int(lerp(6.0, 16.0, speed_ratio))


func die() -> void:
	if not is_alive or is_invincible:
		return
	is_alive = false
	visible = false
	engine_particles.emitting = false
	died.emit(position)


func respawn(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	is_alive = true
	visible = true
	is_invincible = true
	invincible_timer = 2.0
	_blink_timer = 0.0
	ship_polygon.visible = true


func set_world_bounds(rect: Rect2) -> void:
	world_bounds = rect


func _on_area_entered(area: Area2D) -> void:
	if not is_alive or is_invincible:
		return
	if area.is_in_group("enemies") and area.get("is_active"):
		die()
	elif area.is_in_group("enemy_bullets") and area.get("is_active"):
		die()
	elif area.is_in_group("mines"):
		die()
