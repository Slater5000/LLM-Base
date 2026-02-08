extends Node
## Continuous time-based enemy spawning with difficulty curve peaking at 10 minutes.
## Replaces wave system. Enemies scale in quantity, variety, HP, and composition.

signal enemy_spawned(enemy: Area2D)

var enemies_alive := 0
var elapsed_time := 0.0
var world_rect := Rect2(-1600, -1600, 3200, 3200)
var player: Node2D
var enemy_scene: PackedScene
var game_main: Node2D  # For get_camera_rect()
var is_running := false

# Spawn timing
var _spawn_timer := 0.0
var _despawn_timer := 0.0
const DESPAWN_CHECK_INTERVAL := 1.0
const DESPAWN_DISTANCE := 600.0

# Enemy type reference
const EnemyType = preload("res://scenes/prototypes/shmup/enemies/enemy_base.gd").EnemyType

# --- Enemy Introduction Timeline (seconds) ---
# TESTING: Compressed to ~3 min. Original times in comments.
const TYPE_UNLOCK_TIMES := {
	EnemyType.GRUNT: 0.0,       # 0s
	EnemyType.WEAVER: 10.0,     # was 30
	EnemyType.LEECH: 10.0,      # was 30
	EnemyType.ROCKET: 30.0,     # was 90
	EnemyType.BOMBER: 30.0,     # was 90
	EnemyType.SPINNER: 60.0,    # was 180
	EnemyType.SNIPER: 60.0,     # was 180
	EnemyType.TANK: 90.0,       # was 300
	EnemyType.CHARGER: 90.0,    # was 300
	EnemyType.GHOST: 120.0,     # was 420
	EnemyType.MINELAYER: 120.0,  # was 420
	EnemyType.PULSER: 150.0,    # was 480
	EnemyType.ORBITER: 150.0,   # was 480
	EnemyType.HIVE: 170.0,      # was 540
	EnemyType.SERPENT: 170.0,    # was 540
}

# Base spawn weights per type (how likely to be picked once unlocked)
const TYPE_WEIGHTS := {
	EnemyType.GRUNT: 30.0,
	EnemyType.WEAVER: 15.0,
	EnemyType.LEECH: 12.0,
	EnemyType.ROCKET: 10.0,
	EnemyType.BOMBER: 8.0,
	EnemyType.SPINNER: 10.0,
	EnemyType.SNIPER: 7.0,
	EnemyType.TANK: 6.0,
	EnemyType.CHARGER: 7.0,
	EnemyType.GHOST: 6.0,
	EnemyType.MINELAYER: 5.0,
	EnemyType.PULSER: 4.0,
	EnemyType.ORBITER: 5.0,
	EnemyType.HIVE: 3.0,
	EnemyType.SERPENT: 3.0,
}

# Leech always spawns in packs
const LEECH_PACK_SIZE_MIN := 3
const LEECH_PACK_SIZE_MAX := 5


func setup(p_world_rect: Rect2, p_player: Node2D, p_enemy_scene: PackedScene, p_game_main: Node2D = null) -> void:
	world_rect = p_world_rect
	player = p_player
	enemy_scene = p_enemy_scene
	game_main = p_game_main


func start() -> void:
	elapsed_time = 0.0
	enemies_alive = 0
	is_running = true
	_spawn_timer = 1.5  # Brief warmup before first spawn


func _process(delta: float) -> void:
	if not is_running:
		return

	elapsed_time += delta

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_do_spawn_tick()
		_spawn_timer = _get_spawn_interval()

	# Despawn enemies too far from camera
	_despawn_timer -= delta
	if _despawn_timer <= 0.0:
		_despawn_timer = DESPAWN_CHECK_INTERVAL
		_despawn_far_enemies()


## --- Difficulty Curve Functions ---

## Spawn interval decreases over time (more frequent spawns)
func _get_spawn_interval() -> float:
	if elapsed_time < 30.0:
		return 2.0
	elif elapsed_time < 90.0:
		return 1.5
	elif elapsed_time < 180.0:
		return 1.2
	elif elapsed_time < 300.0:
		return 1.0
	elif elapsed_time < 420.0:
		return 0.8
	elif elapsed_time < 600.0:
		return 0.6
	else:
		# INSANO MODE: 10+ min, ramps from 0.5 to 0.3
		return maxf(0.3, 0.5 - (elapsed_time - 600.0) / 3000.0)


## Batch size increases over time (more enemies per tick)
func _get_batch_size() -> int:
	if elapsed_time < 30.0:
		return 1
	elif elapsed_time < 90.0:
		return randi_range(1, 2)
	elif elapsed_time < 180.0:
		return randi_range(2, 3)
	elif elapsed_time < 300.0:
		return randi_range(3, 5)
	elif elapsed_time < 420.0:
		return randi_range(5, 7)
	elif elapsed_time < 600.0:
		return randi_range(7, 10)
	else:
		# INSANO MODE
		return randi_range(10, 15)


## Max enemies alive — scales with time, hard cap 1000
func _get_max_enemies() -> int:
	var cap := int(40.0 + elapsed_time / 3.0)
	return mini(cap, 1000)


## HP scaling: enemies get tougher over time
func _get_hp_scale() -> float:
	var base := 1.0 + elapsed_time / 300.0  # 3x at 10 min, 5x at 20 min
	if elapsed_time > 600.0:
		# Exponential kick after 10 min
		base *= pow(1.0 + (elapsed_time - 600.0) / 300.0, 1.3)
	return base


## Speed scaling: very subtle, capped at 1.3x
func _get_speed_scale() -> float:
	return minf(1.0 + elapsed_time / 3000.0, 1.3)


## Shoot cooldown scaling: ranged enemies fire faster over time
func _get_shoot_cooldown_scale() -> float:
	return 1.0 - clampf(elapsed_time / 600.0, 0.0, 0.4)


## Elite chance: TESTING — starts at 1.5 min (was 5 min)
func _get_elite_chance() -> float:
	if elapsed_time < 90.0:
		return 0.0
	return clampf(0.05 + (elapsed_time - 90.0) / 60.0 * 0.04, 0.0, 0.25)


## Champion chance: TESTING — starts at 2.5 min (was 8 min)
func _get_champion_chance() -> float:
	if elapsed_time < 150.0:
		return 0.0
	return clampf(0.02 + (elapsed_time - 150.0) / 60.0 * 0.02, 0.0, 0.08)


## --- Spawn Logic ---

func _do_spawn_tick() -> void:
	var max_enemies := _get_max_enemies()
	if enemies_alive >= max_enemies:
		return  # At cap, skip this tick

	var batch := _get_batch_size()
	# Don't exceed cap
	batch = mini(batch, max_enemies - enemies_alive)

	var hp_scale := _get_hp_scale()
	var spd_scale := _get_speed_scale()

	for i in batch:
		var type := _pick_enemy_type()

		# Leech spawns in packs
		if type == EnemyType.LEECH:
			var pack_size := randi_range(LEECH_PACK_SIZE_MIN, LEECH_PACK_SIZE_MAX)
			var pack_center := _get_spawn_position()
			for j in pack_size:
				if enemies_alive >= max_enemies:
					break
				var offset := Vector2(randf_range(-15, 15), randf_range(-15, 15))
				var pos := _clamp_to_world(pack_center + offset)
				_spawn_enemy(type, pos, hp_scale, spd_scale)
		else:
			var pos := _get_spawn_position()
			_spawn_enemy(type, pos, hp_scale, spd_scale)


func _spawn_enemy(type: EnemyType, pos: Vector2, hp_scale: float, spd_scale: float) -> void:
	var enemy := enemy_scene.instantiate() as Area2D
	enemy.configure(type, player, world_rect, 1.0, hp_scale, spd_scale)
	enemy.position = pos

	# Roll for elite/champion
	var champion_roll := randf()
	var elite_roll := randf()

	if champion_roll < _get_champion_chance():
		enemy.make_champion()
	elif elite_roll < _get_elite_chance():
		enemy.make_elite()

	enemy.killed.connect(_on_enemy_killed)
	enemies_alive += 1
	enemy_spawned.emit(enemy)


func _pick_enemy_type() -> EnemyType:
	# Build pool of unlocked types with weights
	var pool: Array[Dictionary] = []
	var total_weight := 0.0

	for type: EnemyType in TYPE_UNLOCK_TIMES:
		if elapsed_time >= TYPE_UNLOCK_TIMES[type]:
			var weight: float = TYPE_WEIGHTS[type]

			# Reduce Grunt weight as more types unlock (variety increases)
			if type == EnemyType.GRUNT and elapsed_time > 300.0:
				weight *= 0.6  # Grunts become less common after 5 min

			# Boost recently unlocked types briefly (novelty)
			var unlock_time: float = TYPE_UNLOCK_TIMES[type]
			var since_unlock := elapsed_time - unlock_time
			if since_unlock < 30.0 and unlock_time > 0.0:
				weight *= 1.5  # 50% boost for first 30s after unlock

			pool.append({"type": type, "weight": weight})
			total_weight += weight

	if pool.is_empty():
		return EnemyType.GRUNT

	# Weighted random pick
	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in pool:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.type as EnemyType

	return pool[-1].type as EnemyType


## --- Spawn Position (radial around camera viewport) ---

func _get_spawn_position() -> Vector2:
	if not player:
		return world_rect.get_center()

	# Spawn just outside the camera viewport
	var cam_rect: Rect2 = game_main.get_camera_rect() if game_main else Rect2(player.position - Vector2(320, 180), Vector2(640, 360))
	var viewport_half_diag := cam_rect.size.length() / 2.0
	var spawn_dist := viewport_half_diag + 40.0  # Just offscreen

	var angle := randf() * TAU
	var spawn_pos := player.position + Vector2.from_angle(angle) * spawn_dist

	# Clamp to world bounds
	spawn_pos = spawn_pos.clamp(
		world_rect.position + Vector2(10, 10),
		world_rect.end - Vector2(10, 10)
	)
	return spawn_pos


func _clamp_to_world(pos: Vector2) -> Vector2:
	var margin := 10.0
	return Vector2(
		clampf(pos.x, world_rect.position.x + margin, world_rect.end.x - margin),
		clampf(pos.y, world_rect.position.y + margin, world_rect.end.y - margin)
	)


func _despawn_far_enemies() -> void:
	if not player or not game_main:
		return
	var cam_rect: Rect2 = game_main.camera_rect
	var cam_center: Vector2 = cam_rect.get_center()
	var parent: Node2D = game_main.enemy_container
	if not parent:
		return
	for child in parent.get_children():
		if not child.get("is_active"):
			continue
		if child.position.distance_to(cam_center) > DESPAWN_DISTANCE:
			if child.has_method("deactivate"):
				child.deactivate()
			child.queue_free()
			enemies_alive = maxi(enemies_alive - 1, 0)


## --- Enemy Tracking ---

func _on_enemy_killed(_pos: Vector2, _type: String, _points: int) -> void:
	enemies_alive = maxi(enemies_alive - 1, 0)


func on_enemy_removed() -> void:
	enemies_alive = maxi(enemies_alive - 1, 0)


func get_max_enemies() -> int:
	return _get_max_enemies()


func reset() -> void:
	elapsed_time = 0.0
	enemies_alive = 0
	is_running = false
	_spawn_timer = 0.0
