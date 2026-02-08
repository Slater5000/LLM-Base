extends Area2D
## Base enemy with 15 configurable types, elite/champion system, status effects.

signal killed(pos: Vector2, enemy_type: String, points: int)
signal fired_bullet(pos: Vector2, direction: Vector2)
signal spawned_drone(pos: Vector2)  # Hive → spawns mini enemies
signal bomber_exploded(pos: Vector2, radius: float, damage: int)  # Bomber chain reactions
signal mine_placed(pos: Vector2)  # Minelayer → drops mines

# 15 enemy types
enum EnemyType {
	GRUNT, WEAVER, SPINNER, ROCKET, TANK,
	SNIPER, CHARGER, ORBITER, HIVE, MINELAYER,
	GHOST, PULSER, LEECH, BOMBER, SERPENT
}
enum ChargerState { APPROACH, TELEGRAPH, CHARGE, COOLDOWN }

# =================================================================
# CONSTANTS
# =================================================================

const ORBIT_RADIUS := 30.0
const SHIELD_AURA_RADIUS := 40.0
const HIVE_SPAWN_INTERVAL := 3.5
const MINE_DROP_INTERVAL := 2.5
const GHOST_SOLID_DURATION := 2.0
const GHOST_PHASE_DURATION := 1.5
const LEECH_ATTACH_DURATION := 0.3
const BOMBER_EXPLOSION_RADIUS := 45.0
const BOMBER_EXPLOSION_DAMAGE := 2
const ELITE_MODIFIERS := [
	"shielded", "explosive", "splitting",
	"regenerating", "hasting",
]

const TYPE_COLORS := {
	EnemyType.GRUNT: Color(0.3, 0.4, 1.0),
	EnemyType.WEAVER: Color(0.2, 1.0, 0.4),
	EnemyType.SPINNER: Color(0.75, 0.3, 1.0),
	EnemyType.ROCKET: Color(1.0, 0.5, 0.1),
	EnemyType.TANK: Color(1.0, 0.15, 0.15),
	EnemyType.SNIPER: Color(0.3, 0.9, 1.0),
	EnemyType.CHARGER: Color(0.8, 0.1, 0.1),
	EnemyType.ORBITER: Color(1.0, 0.85, 0.2),
	EnemyType.HIVE: Color(0.6, 0.2, 0.9),
	EnemyType.MINELAYER: Color(0.5, 1.0, 0.2),
	EnemyType.GHOST: Color(0.8, 0.85, 1.0),
	EnemyType.PULSER: Color(0.55, 0.2, 1.0),
	EnemyType.LEECH: Color(0.7, 0.1, 0.2),
	EnemyType.BOMBER: Color(1.0, 0.7, 0.1),
	EnemyType.SERPENT: Color(0.4, 0.3, 0.9),
}

const TYPE_NAMES := {
	EnemyType.GRUNT: "grunt",
	EnemyType.WEAVER: "weaver",
	EnemyType.SPINNER: "spinner",
	EnemyType.ROCKET: "rocket",
	EnemyType.TANK: "tank",
	EnemyType.SNIPER: "sniper",
	EnemyType.CHARGER: "charger",
	EnemyType.ORBITER: "orbiter",
	EnemyType.HIVE: "hive",
	EnemyType.MINELAYER: "minelayer",
	EnemyType.GHOST: "ghost",
	EnemyType.PULSER: "pulser",
	EnemyType.LEECH: "leech",
	EnemyType.BOMBER: "bomber",
	EnemyType.SERPENT: "serpent",
}

# =================================================================
# VARIABLES
# =================================================================

@export var enemy_type := EnemyType.GRUNT

# Stats
var hp := 1
var max_hp := 1
var base_speed := 65.0
var speed := 65.0
var points := 100
var geom_count := 1
var has_large_geom := false
var shoot_cooldown := 0.0
var shoot_timer := 0.0
var can_shoot := false
var bullet_spread := 0
var bullet_count_per_shot := 1

# Behavior
var velocity := Vector2.ZERO
var target: Node2D
var world_rect := Rect2(-1600, -1600, 3200, 3200)
var is_active := false
var type_name := "grunt"

# Scaling
var hp_scale := 1.0
var speed_scale := 1.0

# Spinner splitting
var is_split_child := false
var split_scale := 1.0

# Status effects
var burn_timer := 0.0
var burn_dps := 0.0
var freeze_timer := 0.0
var freeze_slow := 0.0
var poison_timer := 0.0
var poison_dps := 0.0

# Elite/Champion
var is_elite := false
var is_champion := false
var elite_modifiers: Array = []
var enemy_polygon: Polygon2D
var collision_shape: CollisionShape2D

# Private state
var _dodge_cooldown := 0.0
var _weaver_jink_timer := 0.0
var _weaver_jink_dir := Vector2.ZERO
var _rocket_direction := Vector2.ZERO
var _damage_flash_timer := 0.0
var _status_damage_accumulator := 0.0
var _sniper_telegraph_timer := 0.0
var _sniper_telegraphing := false
var _sniper_target_pos := Vector2.ZERO
var _sniper_preferred_dist := 130.0
var _charger_state := ChargerState.APPROACH
var _charger_timer := 0.0
var _charger_flash_count := 0
var _charger_direction := Vector2.ZERO
var _charger_charge_speed := 350.0
var _orbit_target: Node2D
var _orbit_angle := 0.0
var _hive_spawn_timer := 0.0
var _mine_timer := 0.0
var _mine_wander_target := Vector2.ZERO
var _ghost_phase_timer := 0.0
var _ghost_solid := true
var _pulser_settled := false
var _pulser_target_pos := Vector2.ZERO
var _pulser_cross_angle := 0.0
var _leech_attached := false
var _leech_attach_timer := 0.0
var _shield_hits := 0
var _regen_timer := 0.0
var _haste_timer := 0.0
var _haste_cooldown := 0.0
var _haste_active := false
var _base_size := 7.0


func _ready() -> void:
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)


func configure(
	type: EnemyType, player: Node2D, rect: Rect2,
	scale_factor: float = 1.0,
	p_hp_scale: float = 1.0,
	p_speed_scale: float = 1.0,
) -> void:
	enemy_type = type
	target = player
	world_rect = rect
	type_name = TYPE_NAMES[type]
	split_scale = scale_factor
	hp_scale = p_hp_scale
	speed_scale = p_speed_scale
	enemy_polygon = get_node("EnemyPolygon")
	collision_shape = get_node("CollisionShape")

	# Reset status effects
	burn_timer = 0.0; burn_dps = 0.0
	freeze_timer = 0.0; freeze_slow = 0.0
	poison_timer = 0.0; poison_dps = 0.0
	_status_damage_accumulator = 0.0
	_damage_flash_timer = 0.0

	# Reset elite
	is_elite = false; is_champion = false
	elite_modifiers.clear()
	_shield_hits = 0; _regen_timer = 0.0
	_haste_timer = 0.0; _haste_cooldown = 0.0; _haste_active = false

	# Reset type-specific state
	_sniper_telegraphing = false; _sniper_telegraph_timer = 0.0
	_charger_state = ChargerState.APPROACH; _charger_timer = 0.0
	_orbit_target = null; _orbit_angle = randf() * TAU
	_hive_spawn_timer = 1.0  # Brief delay before first spawn
	_mine_timer = 1.0; _mine_wander_target = Vector2.ZERO
	_ghost_phase_timer = 0.0; _ghost_solid = true
	_pulser_settled = false; _pulser_cross_angle = 0.0
	_leech_attached = false; _leech_attach_timer = 0.0
	_dodge_cooldown = 0.0; _weaver_jink_timer = 0.0; _weaver_jink_dir = Vector2.ZERO

	match type:
		EnemyType.GRUNT:
			hp = 1; base_speed = 65.0; points = 100; geom_count = 1
			can_shoot = false
		EnemyType.WEAVER:
			hp = 1; base_speed = 80.0; points = 150; geom_count = 1
			can_shoot = false
		EnemyType.SPINNER:
			hp = 2; base_speed = 60.0; points = 200; geom_count = 2
			can_shoot = true; shoot_cooldown = 2.5
		EnemyType.ROCKET:
			hp = 1; base_speed = 120.0; points = 100; geom_count = 1
			can_shoot = false
			_rocket_direction = Vector2.from_angle(randf() * TAU)
		EnemyType.TANK:
			hp = 6; base_speed = 28.0; points = 500; geom_count = 5
			has_large_geom = true
			can_shoot = true; shoot_cooldown = 3.0; bullet_spread = 3
		EnemyType.SNIPER:
			hp = 2; base_speed = 50.0; points = 200; geom_count = 2
			can_shoot = true; shoot_cooldown = 2.5
			_sniper_preferred_dist = randf_range(110.0, 150.0)
		EnemyType.CHARGER:
			hp = 3; base_speed = 30.0; points = 300; geom_count = 3
			can_shoot = false
		EnemyType.ORBITER:
			hp = 2; base_speed = 70.0; points = 250; geom_count = 2
			can_shoot = false
		EnemyType.HIVE:
			hp = 8; base_speed = 12.0; points = 400; geom_count = 4
			has_large_geom = true
			can_shoot = false
		EnemyType.MINELAYER:
			hp = 1; base_speed = 55.0; points = 150; geom_count = 1
			can_shoot = false
		EnemyType.GHOST:
			hp = 2; base_speed = 85.0; points = 200; geom_count = 2
			can_shoot = false
		EnemyType.PULSER:
			hp = 4; base_speed = 25.0; points = 300; geom_count = 3
			can_shoot = true; shoot_cooldown = 3.0; bullet_count_per_shot = 8
			_pulser_target_pos = _pick_pulser_position()
		EnemyType.LEECH:
			hp = 1; base_speed = 100.0; points = 50; geom_count = 1
			can_shoot = false
		EnemyType.BOMBER:
			hp = 2; base_speed = 50.0; points = 200; geom_count = 2
			can_shoot = false
		EnemyType.SERPENT:
			hp = 3; base_speed = 55.0; points = 500; geom_count = 5
			has_large_geom = true
			can_shoot = false

	# Apply HP scaling
	hp = maxi(int(hp * hp_scale), 1)
	max_hp = hp
	speed = base_speed * speed_scale

	if can_shoot:
		shoot_timer = randf_range(0.5, shoot_cooldown)

	_setup_shape()
	is_active = true
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	modulate.a = 1.0


func make_elite(modifier_pool: Array = []) -> void:
	is_elite = true
	hp = int(hp * 3.0)
	max_hp = hp
	speed *= 1.15
	split_scale = 1.3

	# Pick one random modifier
	var pool := modifier_pool if modifier_pool.size() > 0 else ELITE_MODIFIERS.duplicate()
	pool.shuffle()
	elite_modifiers.append(pool[0])
	_apply_modifier(pool[0])

	_rescale_shape()
	queue_redraw()


func make_champion(modifier_pool: Array = []) -> void:
	is_champion = true
	hp = int(hp * 5.0)
	max_hp = hp
	speed *= 1.2
	split_scale = 1.6
	geom_count *= 3

	# Pick two different random modifiers
	var pool := modifier_pool if modifier_pool.size() > 0 else ELITE_MODIFIERS.duplicate()
	pool.shuffle()
	elite_modifiers.append(pool[0])
	_apply_modifier(pool[0])
	if pool.size() > 1:
		elite_modifiers.append(pool[1])
		_apply_modifier(pool[1])

	_rescale_shape()
	queue_redraw()


func _apply_modifier(mod: String) -> void:
	match mod:
		"shielded":
			_shield_hits = 3
		"regenerating":
			_regen_timer = 0.0
		"hasting":
			_haste_cooldown = 3.0


func _setup_shape() -> void:
	var color: Color = TYPE_COLORS[enemy_type]
	var s := 7.0 * split_scale

	match enemy_type:
		EnemyType.GRUNT:
			s = 7.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)
			])
		EnemyType.WEAVER:
			s = 6.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)
			])
		EnemyType.SPINNER:
			s = 8.0 * split_scale
			var pts := PackedVector2Array()
			for i in 8:
				var angle := (TAU / 8.0) * i - PI / 8.0
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.ROCKET:
			s = 6.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(0, -s), Vector2(s * 0.6, s), Vector2(-s * 0.6, s)
			])
		EnemyType.TANK:
			s = 14.0 * split_scale
			var pts := PackedVector2Array()
			for i in 6:
				var angle := (TAU / 6.0) * i - PI / 6.0
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.SNIPER:
			# Thin elongated diamond
			s = 5.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(0, -s * 2.4), Vector2(s * 0.4, 0), Vector2(0, s * 2.4), Vector2(-s * 0.4, 0)
			])
		EnemyType.CHARGER:
			# Pentagon
			s = 9.0 * split_scale
			var pts := PackedVector2Array()
			for i in 5:
				var angle := (TAU / 5.0) * i - PI / 2.0
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.ORBITER:
			# Hexagonal ring (draw as hexagon, inner is via _draw)
			s = 5.0 * split_scale
			var pts := PackedVector2Array()
			for i in 6:
				var angle := (TAU / 6.0) * i
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.HIVE:
			# Large circle approximation (12 points)
			s = 16.0 * split_scale
			var pts := PackedVector2Array()
			for i in 12:
				var angle := (TAU / 12.0) * i
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.MINELAYER:
			# Inverted triangle
			s = 5.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(-s, -s * 0.6), Vector2(s, -s * 0.6), Vector2(0, s)
			])
		EnemyType.GHOST:
			# Diamond with tail (5 points)
			s = 6.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(0, -s * 1.2), Vector2(s * 0.7, 0), Vector2(s * 0.3, s * 0.8),
				Vector2(0, s * 1.8), Vector2(-s * 0.3, s * 0.8), Vector2(-s * 0.7, 0)
			])
		EnemyType.PULSER:
			# Circle (10-point)
			s = 8.0 * split_scale
			var pts := PackedVector2Array()
			for i in 10:
				var angle := (TAU / 10.0) * i
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.LEECH:
			# Tiny crescent (3 points)
			s = 4.0 * split_scale
			enemy_polygon.polygon = PackedVector2Array([
				Vector2(-s, -s * 0.4), Vector2(s * 0.3, 0), Vector2(-s, s * 0.4)
			])
		EnemyType.BOMBER:
			# Circle with fuse (drawn as circle, fuse via _draw)
			s = 8.0 * split_scale
			var pts := PackedVector2Array()
			for i in 10:
				var angle := (TAU / 10.0) * i
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts
		EnemyType.SERPENT:
			# Head circle (body segments handled separately)
			s = 8.0 * split_scale
			var pts := PackedVector2Array()
			for i in 8:
				var angle := (TAU / 8.0) * i
				pts.append(Vector2.from_angle(angle) * s)
			enemy_polygon.polygon = pts

	_base_size = s
	enemy_polygon.color = color

	# Reuse existing CircleShape2D to avoid orphaned resource creation
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = s * 0.8
	else:
		var circle := CircleShape2D.new()
		circle.radius = s * 0.8
		collision_shape.shape = circle


func _process(delta: float) -> void:
	if not is_active:
		return

	# Ghost invulnerability check
	if enemy_type == EnemyType.GHOST and not _ghost_solid:
		set_deferred("monitoring", false)
	elif enemy_type != EnemyType.GHOST or _ghost_solid:
		set_deferred("monitoring", true)

	if target:
		_update_behavior(delta)
		_update_shooting(delta)

	_update_status_effects(delta)
	_update_elite_modifiers(delta)
	_update_visual(delta)

	# Safety clamp to world bounds (except Ghost when phased)
	if not (enemy_type == EnemyType.GHOST and not _ghost_solid):
		position = position.clamp(world_rect.position + Vector2(5, 5), world_rect.end - Vector2(5, 5))


func _update_behavior(delta: float) -> void:
	var effective_speed := speed * (1.0 - freeze_slow)

	match enemy_type:
		EnemyType.GRUNT:
			_behavior_grunt(delta, effective_speed)
		EnemyType.WEAVER:
			_behavior_weaver(delta, effective_speed)
		EnemyType.SPINNER:
			_behavior_spinner(delta, effective_speed)
		EnemyType.ROCKET:
			_behavior_rocket(delta, effective_speed)
		EnemyType.TANK:
			_behavior_tank(delta, effective_speed)
		EnemyType.SNIPER:
			_behavior_sniper(delta, effective_speed)
		EnemyType.CHARGER:
			_behavior_charger(delta, effective_speed)
		EnemyType.ORBITER:
			_behavior_orbiter(delta, effective_speed)
		EnemyType.HIVE:
			_behavior_hive(delta, effective_speed)
		EnemyType.MINELAYER:
			_behavior_minelayer(delta, effective_speed)
		EnemyType.GHOST:
			_behavior_ghost(delta, effective_speed)
		EnemyType.PULSER:
			_behavior_pulser(delta, effective_speed)
		EnemyType.LEECH:
			_behavior_leech(delta, effective_speed)
		EnemyType.BOMBER:
			_behavior_bomber(delta, effective_speed)
		EnemyType.SERPENT:
			_behavior_serpent(delta, effective_speed)


# --- Original behaviors ---

func _behavior_grunt(delta: float, spd: float) -> void:
	var to_player := (target.position - position).normalized()
	velocity = to_player * spd
	position += velocity * delta
	rotation += delta * 2.0


func _behavior_weaver(delta: float, spd: float) -> void:
	var to_player := (target.position - position).normalized()

	_dodge_cooldown -= delta
	if _dodge_cooldown <= 0.0:
		_dodge_cooldown = randf_range(0.8, 1.5)
		# Sharp perpendicular jink — very visible sideways dash
		_weaver_jink_dir = to_player.orthogonal() * (1.0 if randf() > 0.5 else -1.0)
		_weaver_jink_timer = 0.15

	if _weaver_jink_timer > 0.0:
		_weaver_jink_timer -= delta
		velocity = (_weaver_jink_dir * spd * 2.5) + (to_player * spd * 0.3)
	else:
		velocity = to_player * spd

	position += velocity * delta
	rotation += delta * 3.0


func _behavior_spinner(delta: float, spd: float) -> void:
	var to_player := (target.position - position).normalized()
	velocity = to_player * spd
	position += velocity * delta
	rotation += delta * 5.0


func _behavior_rocket(delta: float, spd: float) -> void:
	position += _rocket_direction * spd * delta
	# Bounce off camera viewport edges (like Runetracer)
	var cam := get_viewport().get_camera_2d()
	var cp: Vector2 = cam.global_position if cam else target.position
	var half := Vector2(320, 180)
	var bounds := Rect2(cp - half, Vector2(640, 360))
	if position.x <= bounds.position.x and _rocket_direction.x < 0:
		_rocket_direction.x = -_rocket_direction.x
	elif position.x >= bounds.end.x and _rocket_direction.x > 0:
		_rocket_direction.x = -_rocket_direction.x
	if position.y <= bounds.position.y and _rocket_direction.y < 0:
		_rocket_direction.y = -_rocket_direction.y
	elif position.y >= bounds.end.y and _rocket_direction.y > 0:
		_rocket_direction.y = -_rocket_direction.y
	rotation = _rocket_direction.angle() + PI / 2.0


func _behavior_tank(delta: float, spd: float) -> void:
	var to_player := (target.position - position).normalized()
	velocity = to_player * spd
	position += velocity * delta


# --- New behaviors ---

func _behavior_sniper(delta: float, spd: float) -> void:
	var dist := position.distance_to(target.position)
	var to_player := (target.position - position).normalized()

	if dist < 80.0:
		# Retreat
		velocity = -to_player * spd * 1.2
	elif dist > 180.0:
		# Approach
		velocity = to_player * spd
	else:
		# Strafe slightly
		velocity = to_player.orthogonal() * spd * 0.3

	position += velocity * delta
	rotation = to_player.angle() + PI / 2.0

	# Telegraph before shot
	if _sniper_telegraphing:
		_sniper_telegraph_timer -= delta
		_sniper_target_pos = target.position  # Track during telegraph
		if _sniper_telegraph_timer <= 0.0:
			_sniper_telegraphing = false
			fired_bullet.emit(position, (target.position - position).normalized())
			shoot_timer = shoot_cooldown
		queue_redraw()


func _behavior_charger(delta: float, spd: float) -> void:
	match _charger_state:
		ChargerState.APPROACH:
			var to_player := (target.position - position).normalized()
			velocity = to_player * spd
			position += velocity * delta

			# Start telegraph when close enough or after some time
			if position.distance_to(target.position) < 120.0:
				_charger_state = ChargerState.TELEGRAPH
				_charger_timer = 0.5
				_charger_flash_count = 0

		ChargerState.TELEGRAPH:
			velocity = Vector2.ZERO
			_charger_timer -= delta
			var flash_interval := 0.5 / 3.0
			var expected_flashes := int((0.5 - _charger_timer) / flash_interval)
			if expected_flashes > _charger_flash_count:
				_charger_flash_count = expected_flashes
				enemy_polygon.color = Color.WHITE

			if _charger_timer <= 0.0:
				_charger_state = ChargerState.CHARGE
				_charger_direction = (target.position - position).normalized()
				_charger_timer = 0.5
				rotation = _charger_direction.angle() + PI / 2.0

		ChargerState.CHARGE:
			velocity = _charger_direction * _charger_charge_speed
			position += velocity * delta
			_charger_timer -= delta
			if _charger_timer <= 0.0:
				_charger_state = ChargerState.COOLDOWN
				_charger_timer = 1.5
				velocity = Vector2.ZERO

		ChargerState.COOLDOWN:
			_charger_timer -= delta
			if _charger_timer <= 0.0:
				_charger_state = ChargerState.APPROACH


func _behavior_orbiter(delta: float, spd: float) -> void:
	# Find nearest high-value target to orbit
	if not _orbit_target or not is_instance_valid(_orbit_target) or not _orbit_target.is_active:
		_orbit_target = _find_orbit_target()

	if _orbit_target and is_instance_valid(_orbit_target):
		_orbit_angle += delta * 3.0
		var target_pos := _orbit_target.position + Vector2.from_angle(_orbit_angle) * ORBIT_RADIUS
		velocity = (target_pos - position) * 5.0
		position += velocity * delta
	else:
		# No target, chase player slowly
		var to_player := (target.position - position).normalized()
		velocity = to_player * spd * 0.5
		position += velocity * delta

	rotation += delta * 2.0
	# Throttle redraws — aura pulse is subtle, every 3 frames is fine
	if Engine.get_process_frames() % 3 == 0:
		queue_redraw()


func _behavior_hive(delta: float, spd: float) -> void:
	# Crawl slowly toward player
	var to_player := (target.position - position).normalized()
	velocity = to_player * spd
	position += velocity * delta

	# Spawn drones
	_hive_spawn_timer -= delta
	if _hive_spawn_timer <= 0.0:
		_hive_spawn_timer = HIVE_SPAWN_INTERVAL
		var drone_count := randi_range(2, 3)
		for i in drone_count:
			spawned_drone.emit(position + Vector2(randf_range(-8, 8), randf_range(-8, 8)))


func _behavior_minelayer(delta: float, spd: float) -> void:
	# Wander near player area
	if _mine_wander_target == Vector2.ZERO or position.distance_to(_mine_wander_target) < 10.0:
		_mine_wander_target = _pick_wander_point()

	var to_target := (_mine_wander_target - position).normalized()
	velocity = to_target * spd
	position += velocity * delta
	rotation += delta * 1.5

	# Drop mines
	_mine_timer -= delta
	if _mine_timer <= 0.0:
		_mine_timer = MINE_DROP_INTERVAL
		mine_placed.emit(position)


func _behavior_ghost(delta: float, spd: float) -> void:
	# Phase in/out cycle
	_ghost_phase_timer -= delta
	if _ghost_phase_timer <= 0.0:
		_ghost_solid = not _ghost_solid
		_ghost_phase_timer = GHOST_SOLID_DURATION if _ghost_solid else GHOST_PHASE_DURATION

	# Smooth alpha transition
	var target_alpha := 1.0 if _ghost_solid else 0.15
	modulate.a = lerpf(modulate.a, target_alpha, 8.0 * delta)

	# Chase player
	var to_player := (target.position - position).normalized()
	velocity = to_player * spd
	position += velocity * delta
	rotation += delta * 2.0


func _behavior_pulser(delta: float, spd: float) -> void:
	if not _pulser_settled:
		# Move to target position
		var to_target := (_pulser_target_pos - position).normalized()
		velocity = to_target * spd
		position += velocity * delta
		if position.distance_to(_pulser_target_pos) < 5.0:
			_pulser_settled = true
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	# Rotate cross
	_pulser_cross_angle += delta * 1.5
	# Throttle redraws — cross rotation looks fine at every 2 frames
	if Engine.get_process_frames() % 2 == 0:
		queue_redraw()


func _behavior_leech(delta: float, spd: float) -> void:
	if _leech_attached:
		_leech_attach_timer -= delta
		velocity = Vector2.ZERO
		if _leech_attach_timer <= 0.0:
			_leech_attached = false
			hp = max_hp  # Heal to full
	else:
		var to_player := (target.position - position).normalized()
		velocity = to_player * spd
		position += velocity * delta

	rotation += delta * 4.0


func _behavior_bomber(delta: float, spd: float) -> void:
	# Direct chase like grunt but slower
	var to_player := (target.position - position).normalized()
	velocity = to_player * spd
	position += velocity * delta
	rotation += delta * 1.5


func _behavior_serpent(delta: float, spd: float) -> void:
	# Head tracks player with sinusoidal wave
	var to_player := (target.position - position).normalized()
	var wave_offset := sin(Time.get_ticks_msec() * 0.003) * 0.5
	var dir := to_player.rotated(wave_offset)
	velocity = dir * spd
	position += velocity * delta
	rotation = velocity.angle() + PI / 2.0


# --- Shooting ---

func _update_shooting(delta: float) -> void:
	if not can_shoot or not target:
		return

	# Sniper uses telegraph system instead of direct shooting
	if enemy_type == EnemyType.SNIPER:
		if not _sniper_telegraphing:
			shoot_timer -= delta
			if shoot_timer <= 0.0:
				_sniper_telegraphing = true
				_sniper_telegraph_timer = 0.3
				_sniper_target_pos = target.position
		return

	# Pulser fires ring of bullets
	if enemy_type == EnemyType.PULSER and _pulser_settled:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			shoot_timer = shoot_cooldown
			_fire_ring()
		return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = shoot_cooldown
		_fire_at_player()


func _fire_at_player() -> void:
	var to_player := (target.position - position).normalized()
	if bullet_spread > 1:
		var spread_angle := deg_to_rad(15.0)
		for i in bullet_spread:
			var offset := (float(i) - float(bullet_spread - 1) / 2.0) * spread_angle
			fired_bullet.emit(position, to_player.rotated(offset))
	else:
		fired_bullet.emit(position, to_player)


func _fire_ring() -> void:
	for i in 8:
		var angle := (TAU / 8.0) * i + _pulser_cross_angle
		var dir := Vector2.from_angle(angle)
		fired_bullet.emit(position, dir)
	# Alternate cross angle for next shot
	_pulser_cross_angle += PI / 8.0


# --- Status Effects ---

func _update_status_effects(delta: float) -> void:
	var has_status := false

	if burn_timer > 0.0:
		burn_timer -= delta
		_status_damage_accumulator += burn_dps * delta
		has_status = true
		if burn_timer <= 0.0:
			burn_dps = 0.0

	if freeze_timer > 0.0:
		freeze_timer -= delta
		has_status = true
		if freeze_timer <= 0.0:
			freeze_slow = 0.0

	if poison_timer > 0.0:
		poison_timer -= delta
		_status_damage_accumulator += poison_dps * delta
		has_status = true
		if poison_timer <= 0.0:
			poison_dps = 0.0

	# Apply accumulated status damage
	if _status_damage_accumulator >= 1.0:
		var dmg := int(_status_damage_accumulator)
		_status_damage_accumulator -= dmg
		hp -= dmg
		if hp <= 0:
			die()

	# Redraw for status VFX indicators (throttled to every 3 frames)
	if has_status and Engine.get_process_frames() % 3 == 0:
		queue_redraw()


func apply_burn(duration: float = 3.0, dps: float = 1.0) -> void:
	burn_timer = maxf(burn_timer, duration)
	burn_dps = maxf(burn_dps, dps)


func apply_freeze(duration: float = 1.5, slow: float = 0.5) -> void:
	freeze_timer = maxf(freeze_timer, duration)
	freeze_slow = maxf(freeze_slow, slow)


func apply_poison(duration: float = 4.0, dps: float = 0.5) -> void:
	poison_timer = maxf(poison_timer, duration)
	poison_dps = maxf(poison_dps, dps)


# --- Elite Modifiers ---

func _update_elite_modifiers(delta: float) -> void:
	if not is_elite and not is_champion:
		return

	# Redraw for pulsing outline (throttled)
	if Engine.get_process_frames() % 3 == 0:
		queue_redraw()

	for mod in elite_modifiers:
		match mod:
			"regenerating":
				_regen_timer -= delta
				if _regen_timer <= 0.0:
					_regen_timer = 1.0
					hp = mini(hp + 1, max_hp)
			"hasting":
				_haste_cooldown -= delta
				if _haste_active:
					_haste_timer -= delta
					if _haste_timer <= 0.0:
						_haste_active = false
						speed = base_speed * speed_scale * (1.15 if is_elite else 1.2)
				elif _haste_cooldown <= 0.0:
					_haste_active = true
					_haste_timer = 0.8
					_haste_cooldown = 3.0
					speed = base_speed * speed_scale * 2.5


# --- Visual ---

func _update_visual(delta: float) -> void:
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		enemy_polygon.color = Color.WHITE
		return

	var base_color: Color = TYPE_COLORS[enemy_type]

	# Status effect tints
	if burn_timer > 0.0:
		base_color = base_color.lerp(Color(1.0, 0.4, 0.1), 0.4)
	if freeze_timer > 0.0:
		base_color = base_color.lerp(Color(0.7, 0.85, 1.0), 0.5)
	if poison_timer > 0.0:
		base_color = base_color.lerp(Color(0.3, 0.9, 0.2), 0.3)

	# Tank low HP warning
	if enemy_type == EnemyType.TANK and hp <= 2:
		var flash := absf(sin(Time.get_ticks_msec() * 0.01))
		base_color = base_color.lerp(Color.WHITE, flash * 0.5)

	# Bomber fuse glow (brighter as HP decreases)
	if enemy_type == EnemyType.BOMBER:
		var hp_pct := float(hp) / float(max_hp)
		if hp_pct < 1.0:
			var glow := 1.0 - hp_pct
			base_color = base_color.lerp(Color.WHITE, glow * 0.4)

	enemy_polygon.color = base_color


## Rescale shape for elite/champion after split_scale change.
## Safe to call multiple times — reuses existing CircleShape2D.
func _rescale_shape() -> void:
	_setup_shape()


func _draw() -> void:
	# Elite outline
	if is_elite and not is_champion:
		var pulse := 0.3 + absf(sin(Time.get_ticks_msec() * 0.005)) * 0.4
		_draw_outline(Color(1, 1, 1, pulse), 1.3)

	# Champion outline
	if is_champion:
		var pulse := 0.5 + absf(sin(Time.get_ticks_msec() * 0.004)) * 0.5
		_draw_outline(Color(1.0, 0.85, 0.2, pulse), 1.6)

	# Sniper telegraph line
	if enemy_type == EnemyType.SNIPER and _sniper_telegraphing:
		var local_target := to_local(_sniper_target_pos)
		draw_line(Vector2.ZERO, local_target, Color(1, 0.2, 0.2, 0.6), 0.5)

	# Pulser rotating cross
	if enemy_type == EnemyType.PULSER:
		var cross_len := _base_size * 0.7
		for i in 4:
			var angle := _pulser_cross_angle + (TAU / 4.0) * i
			var end := Vector2.from_angle(angle) * cross_len
			draw_line(Vector2.ZERO, end, TYPE_COLORS[EnemyType.PULSER].lightened(0.3), 1.0)

	# Bomber fuse
	if enemy_type == EnemyType.BOMBER:
		var fuse_brightness := 0.5 + absf(sin(Time.get_ticks_msec() * 0.008)) * 0.5
		var fuse_color := Color(1.0, 0.9, 0.3, fuse_brightness)
		draw_line(Vector2(0, -_base_size), Vector2(0, -_base_size - 4), fuse_color, 1.0)

	# Orbiter shield aura
	if enemy_type == EnemyType.ORBITER:
		var aura_alpha := 0.15 + absf(sin(Time.get_ticks_msec() * 0.003)) * 0.1
		draw_arc(Vector2.ZERO, SHIELD_AURA_RADIUS, 0, TAU, 16, Color(1.0, 0.85, 0.2, aura_alpha), 1.0)

	# Hive inner circles
	if enemy_type == EnemyType.HIVE:
		var inner_color := TYPE_COLORS[EnemyType.HIVE].lightened(0.2)
		inner_color.a = 0.4
		for offset in [Vector2(-5, -3), Vector2(5, -3), Vector2(0, 5)]:
			draw_arc(offset, 4.0, 0, TAU, 8, inner_color, 0.5)

	# --- Status Effect VFX ---
	# Burn: flickering flame shapes above enemy
	if burn_timer > 0.0:
		var flame_t := fmod(Time.get_ticks_msec() * 0.008, TAU)
		var flame_alpha := 0.5 + sin(flame_t * 3.0) * 0.3
		var flame_h := _base_size * 0.6
		# Two small flame shapes dancing above
		for f_i in 2:
			var fx := (f_i - 0.5) * _base_size * 0.5
			var fy := -_base_size - 2.0 + sin(flame_t + f_i * 2.5) * 2.0
			draw_line(Vector2(fx, fy), Vector2(fx, fy - flame_h),
				Color(1.0, 0.5, 0.1, flame_alpha), 1.5)
			draw_line(Vector2(fx - 1.5, fy - flame_h * 0.3), Vector2(fx, fy - flame_h),
				Color(1.0, 0.3, 0.0, flame_alpha * 0.6), 1.0)

	# Freeze: ice crystal lines radiating from center
	if freeze_timer > 0.0:
		var ice_alpha := 0.4 + sin(Time.get_ticks_msec() * 0.004) * 0.2
		var ice_r := _base_size * 0.8
		for c_i in 4:
			var c_angle := (TAU / 4.0) * c_i + PI / 4.0
			var c_end := Vector2.from_angle(c_angle) * ice_r
			draw_line(Vector2.ZERO, c_end, Color(0.7, 0.9, 1.0, ice_alpha), 0.8)
			# Small perpendicular ticks at midpoint
			var mid := c_end * 0.6
			var perp := Vector2.from_angle(c_angle + PI / 2.0) * ice_r * 0.25
			draw_line(mid - perp, mid + perp, Color(0.8, 0.95, 1.0, ice_alpha * 0.6), 0.5)

	# Poison: green drip dots below enemy
	if poison_timer > 0.0:
		var drip_t := fmod(Time.get_ticks_msec() * 0.003, 1.0)
		var drip_alpha := 0.5 + sin(Time.get_ticks_msec() * 0.005) * 0.2
		for d_i in 3:
			var dx := (d_i - 1.0) * _base_size * 0.4
			var dy := _base_size + 2.0 + drip_t * 4.0 + d_i * 1.5
			var dot_r := 1.2 - drip_t * 0.5
			draw_circle(Vector2(dx, dy), maxf(dot_r, 0.3),
				Color(0.3, 0.9, 0.2, drip_alpha * (1.0 - drip_t)))


func _draw_outline(color: Color, scale_mult: float) -> void:
	if not enemy_polygon:
		return
	var pts := enemy_polygon.polygon
	if pts.size() < 3:
		return
	for i in pts.size():
		var a := pts[i] * scale_mult
		var b := pts[(i + 1) % pts.size()] * scale_mult
		draw_line(a, b, color, 1.0)


# --- Damage & Death ---

func take_damage(amount: int = 1) -> void:
	# Shield modifier absorbs hits
	if _shield_hits > 0:
		_shield_hits -= 1
		_damage_flash_timer = 0.05
		if _shield_hits == 0:
			queue_redraw()  # Shield broken visual
		return

	# Ghost invulnerability
	if enemy_type == EnemyType.GHOST and not _ghost_solid:
		return

	# Orbiter damage reduction (applied by external code checking nearby orbiters)
	hp -= amount
	_damage_flash_timer = 0.08

	if hp <= 0:
		die()


func die() -> void:
	if not is_active:
		return
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Bomber explosion
	if enemy_type == EnemyType.BOMBER:
		bomber_exploded.emit(position, BOMBER_EXPLOSION_RADIUS, BOMBER_EXPLOSION_DAMAGE)

	# Elite modifier: explosive
	if "explosive" in elite_modifiers and enemy_type != EnemyType.BOMBER:
		bomber_exploded.emit(position, BOMBER_EXPLOSION_RADIUS, BOMBER_EXPLOSION_DAMAGE)

	killed.emit(position, type_name, points)
	queue_free()


func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	if area.is_in_group("player_bullets"):
		take_damage(1)
	elif area.is_in_group("player") and not area.get("is_invincible"):
		if enemy_type == EnemyType.LEECH and not _leech_attached:
			_leech_attached = true
			_leech_attach_timer = LEECH_ATTACH_DURATION


# --- Helpers ---

func _find_orbit_target() -> Node2D:
	var best: Node2D = null
	var best_dist := 999999.0
	var high_value := [
		EnemyType.TANK, EnemyType.CHARGER,
		EnemyType.HIVE, EnemyType.PULSER,
		EnemyType.SERPENT,
	]
	var parent := get_parent()
	if not parent:
		return null
	for child in parent.get_children():
		if child == self or not child.is_in_group("enemies"):
			continue
		if not child.get("is_active"):
			continue
		var child_type = child.get("enemy_type")
		if child_type in high_value:
			var d := position.distance_to(child.position)
			if d < best_dist:
				best_dist = d
				best = child
	# Fallback: orbit nearest enemy
	if not best:
		for child in parent.get_children():
			if child == self or not child.is_in_group("enemies"):
				continue
			if not child.get("is_active"):
				continue
			var d := position.distance_to(child.position)
			if d < best_dist:
				best_dist = d
				best = child
	return best


func _pick_wander_point() -> Vector2:
	var margin := 30.0
	var center := target.position if target else world_rect.get_center()
	var rx := center.x + randf_range(-100, 100)
	var ry := center.y + randf_range(-100, 100)
	var min_p := world_rect.position
	var max_p := world_rect.end
	return Vector2(
		clampf(rx, min_p.x + margin, max_p.x - margin),
		clampf(ry, min_p.y + margin, max_p.y - margin),
	)


func _pick_pulser_position() -> Vector2:
	# Settle near spawn point, offset toward player
	var toward_player := Vector2.ZERO
	if target:
		toward_player = (target.position - position).normalized() * 50.0
	var offset := Vector2(randf_range(-60, 60), randf_range(-60, 60))
	return position + toward_player + offset


## Check if this enemy is protected by an Orbiter's shield aura.
func is_shielded_by_orbiter() -> bool:
	var parent := get_parent()
	if not parent:
		return false
	for child in parent.get_children():
		if child == self:
			continue
		if child.get("enemy_type") == EnemyType.ORBITER and child.get("is_active"):
			if position.distance_to(child.position) <= SHIELD_AURA_RADIUS:
				return true
	return false
