extends Node
## Continuous spawner with horde density focus and scripted surge events.
## Background layer: weighted random spawning (85%+ fodder).
## Surge layer: scripted tsunami moments at key minute marks.

signal enemy_spawned(enemy: Area2D)

# gdlint: ignore=constant-name
const EnemyType = preload(
	"res://scenes/prototypes/shmup/enemies/enemy_base.gd"
).EnemyType

const DESPAWN_CHECK_INTERVAL := 1.0
const DESPAWN_DISTANCE := 600.0
const LEECH_PACK_SIZE_MIN := 3
const LEECH_PACK_SIZE_MAX := 5

# Fodder types: stay 1-2 hit kills throughout. No elites/champions.
const FODDER_TYPES := [
	EnemyType.GRUNT, EnemyType.WEAVER, EnemyType.LEECH,
	EnemyType.ROCKET, EnemyType.MINELAYER, EnemyType.BOMBER,
]

# --- Enemy Introduction Timeline (seconds) ---
# Spread across 10 min for smooth difficulty curve.
const TYPE_UNLOCK_TIMES := {
	EnemyType.GRUNT: 0.0,        # Immediate
	EnemyType.WEAVER: 60.0,      # 1 min
	EnemyType.LEECH: 120.0,      # 2 min
	EnemyType.ROCKET: 180.0,     # 3 min
	EnemyType.BOMBER: 180.0,     # 3 min
	EnemyType.SPINNER: 240.0,    # 4 min
	EnemyType.SNIPER: 240.0,     # 4 min
	EnemyType.TANK: 300.0,       # 5 min
	EnemyType.CHARGER: 300.0,    # 5 min
	EnemyType.GHOST: 360.0,      # 6 min
	EnemyType.MINELAYER: 360.0,  # 6 min
	EnemyType.PULSER: 420.0,     # 7 min
	EnemyType.ORBITER: 420.0,    # 7 min
	EnemyType.HIVE: 480.0,       # 8 min
	EnemyType.SERPENT: 540.0,    # 9 min
}

# Spawn weights: heavily favor fodder (85%+ of composition)
const TYPE_WEIGHTS := {
	EnemyType.GRUNT: 50.0,
	EnemyType.WEAVER: 25.0,
	EnemyType.LEECH: 20.0,
	EnemyType.ROCKET: 8.0,
	EnemyType.BOMBER: 6.0,
	EnemyType.SPINNER: 4.0,
	EnemyType.SNIPER: 3.0,
	EnemyType.TANK: 3.0,
	EnemyType.CHARGER: 3.0,
	EnemyType.GHOST: 3.0,
	EnemyType.MINELAYER: 3.0,
	EnemyType.PULSER: 2.0,
	EnemyType.ORBITER: 2.0,
	EnemyType.HIVE: 2.0,
	EnemyType.SERPENT: 2.0,
}

var enemies_alive := 0
var elapsed_time := 0.0
var world_rect := Rect2(-1600, -1600, 3200, 3200)
var player: Node2D
var enemy_scene: PackedScene
var game_main: Node2D  # For get_camera_rect()
var is_running := false

var _spawn_timer := 0.0
var _despawn_timer := 0.0
var _surge_index := 0
var _insano_surge_timer := 0.0

# Scripted surge events — bypass alive cap for tsunami moments
var _surge_events := [
	{time = 90.0, type = EnemyType.GRUNT, count = 40},
	{time = 180.0, type = EnemyType.LEECH, count = 60},
	{time = 270.0, type = EnemyType.WEAVER, count = 50},
	{time = 360.0, type = EnemyType.GRUNT, count = 150},
	{time = 450.0, type = EnemyType.GRUNT, count = 100},
	{time = 540.0, type = EnemyType.GRUNT, count = 300},
]


func setup(
	p_world_rect: Rect2,
	p_player: Node2D,
	p_enemy_scene: PackedScene,
	p_game_main: Node2D = null,
) -> void:
	world_rect = p_world_rect
	player = p_player
	enemy_scene = p_enemy_scene
	game_main = p_game_main


func start() -> void:
	elapsed_time = 0.0
	enemies_alive = 0
	is_running = true
	_spawn_timer = 1.5
	_surge_index = 0
	_insano_surge_timer = 0.0


func _process(delta: float) -> void:
	if not is_running:
		return

	elapsed_time += delta

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_do_spawn_tick()
		_spawn_timer = _get_spawn_interval()

	_check_surges(delta)

	_despawn_timer -= delta
	if _despawn_timer <= 0.0:
		_despawn_timer = DESPAWN_CHECK_INTERVAL
		_despawn_far_enemies()


## --- Difficulty Curve Functions ---

func _get_spawn_interval() -> float:
	if elapsed_time >= 600.0:
		return maxf(0.2, 0.25 - (elapsed_time - 600.0) / 6000.0)
	# Stepped decrease: 0.8s at start → 0.3s at 7 min
	var result := 0.3
	if elapsed_time < 420.0:
		result = 0.4
	if elapsed_time < 300.0:
		result = 0.5
	if elapsed_time < 180.0:
		result = 0.6
	if elapsed_time < 90.0:
		result = 0.7
	if elapsed_time < 30.0:
		result = 0.8
	return result


func _get_batch_size() -> int:
	if elapsed_time >= 600.0:
		return randi_range(20, 30)
	# Ascending overrides: each bracket replaces previous
	var lo := 3
	var hi := 3
	if elapsed_time >= 30.0:
		lo = 3; hi = 5
	if elapsed_time >= 90.0:
		lo = 5; hi = 7
	if elapsed_time >= 180.0:
		lo = 7; hi = 10
	if elapsed_time >= 300.0:
		lo = 10; hi = 14
	if elapsed_time >= 420.0:
		lo = 14; hi = 20
	return randi_range(lo, hi)


## Max enemies alive — scales aggressively, hard cap 800
func _get_max_enemies() -> int:
	var cap := int(60.0 + elapsed_time * 1.1)
	return mini(cap, 800)


## HP scaling for fodder: stays 1-2 hit kills (1.6x at 10 min)
func _get_fodder_hp_scale() -> float:
	var base := 1.0 + elapsed_time / 1000.0
	if elapsed_time > 600.0:
		base *= pow(1.0 + (elapsed_time - 600.0) / 900.0, 1.2)
	return base


## HP scaling for threats: full scaling (3x at 10 min)
func _get_threat_hp_scale() -> float:
	var base := 1.0 + elapsed_time / 300.0
	if elapsed_time > 600.0:
		base *= pow(1.0 + (elapsed_time - 600.0) / 300.0, 1.3)
	return base


## Speed scaling: very subtle, capped at 1.3x
func _get_speed_scale() -> float:
	return minf(1.0 + elapsed_time / 3000.0, 1.3)


## Shoot cooldown scaling: ranged enemies fire faster over time
func _get_shoot_cooldown_scale() -> float:
	return 1.0 - clampf(elapsed_time / 600.0, 0.0, 0.4)


## Elite chance: starts at 4 min, only threat-tier enemies
func _get_elite_chance() -> float:
	if elapsed_time < 240.0:
		return 0.0
	return clampf(
		0.05 + (elapsed_time - 240.0) / 60.0 * 0.03, 0.0, 0.20
	)


## Champion chance: starts at 7 min, only threat-tier enemies
func _get_champion_chance() -> float:
	if elapsed_time < 420.0:
		return 0.0
	return clampf(
		0.02 + (elapsed_time - 420.0) / 60.0 * 0.02, 0.0, 0.08
	)


## --- Surge Event System ---

func _check_surges(delta: float) -> void:
	if _surge_index < _surge_events.size():
		var surge: Dictionary = _surge_events[_surge_index]
		if elapsed_time >= float(surge.time):
			_spawn_surge(surge)
			_surge_index += 1

	if elapsed_time > 600.0:
		_insano_surge_timer -= delta
		if _insano_surge_timer <= 0.0:
			_spawn_surge({
				type = EnemyType.GRUNT,
				count = 100 + randi() % 100,
			})
			_insano_surge_timer = 30.0


func _spawn_surge(surge: Dictionary) -> void:
	var count: int = int(surge.count)
	var surge_type: EnemyType = surge.type as EnemyType
	var hp_scale := _get_fodder_hp_scale()
	var spd_scale := _get_speed_scale()
	# Center on camera so surge enemies spawn off-screen at borders
	var cam_center := Vector2.ZERO
	if game_main:
		cam_center = game_main.get_camera_rect().get_center()
	elif player:
		cam_center = player.position

	for i in count:
		var angle := TAU * float(i) / float(count)
		var spawn_dist := 500.0 + randf() * 60.0
		var pos := cam_center + Vector2(
			cos(angle), sin(angle)
		) * spawn_dist

		var enemy := enemy_scene.instantiate() as Area2D
		enemy.configure(
			surge_type, player, world_rect,
			1.0, hp_scale, spd_scale
		)
		enemy.position = pos
		enemy.killed.connect(_on_enemy_killed)
		enemies_alive += 1
		enemy_spawned.emit(enemy)


## --- Spawn Logic ---

func _do_spawn_tick() -> void:
	var max_enemies := _get_max_enemies()
	if enemies_alive >= max_enemies:
		return

	var batch := _get_batch_size()
	batch = mini(batch, max_enemies - enemies_alive)
	var spd_scale := _get_speed_scale()

	for i in batch:
		var type := _pick_enemy_type()
		var hp_scale := _get_fodder_hp_scale() if type in FODDER_TYPES \
			else _get_threat_hp_scale()

		if type == EnemyType.LEECH:
			var pack_size := randi_range(
				LEECH_PACK_SIZE_MIN, LEECH_PACK_SIZE_MAX
			)
			var pack_center := _get_spawn_position()
			for j in pack_size:
				if enemies_alive >= max_enemies:
					break
				var offset := Vector2(
					randf_range(-15, 15), randf_range(-15, 15)
				)
				var pos := pack_center + offset
				_spawn_enemy(type, pos, hp_scale, spd_scale)
		else:
			var pos := _get_spawn_position()
			_spawn_enemy(type, pos, hp_scale, spd_scale)


func _spawn_enemy(
	type: EnemyType,
	pos: Vector2,
	hp_scale: float,
	spd_scale: float,
) -> void:
	var enemy := enemy_scene.instantiate() as Area2D
	enemy.configure(type, player, world_rect, 1.0, hp_scale, spd_scale)
	enemy.position = pos

	# Elite/Champion only for threat-tier enemies (never fodder)
	if not (type in FODDER_TYPES):
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
	var pool: Array[Dictionary] = []
	var total_weight := 0.0

	for type: EnemyType in TYPE_UNLOCK_TIMES:
		if elapsed_time >= TYPE_UNLOCK_TIMES[type]:
			var weight: float = TYPE_WEIGHTS[type]

			var unlock_time: float = TYPE_UNLOCK_TIMES[type]
			var since_unlock := elapsed_time - unlock_time
			if since_unlock < 30.0 and unlock_time > 0.0:
				weight *= 1.5

			pool.append({"type": type, "weight": weight})
			total_weight += weight

	if pool.is_empty():
		return EnemyType.GRUNT

	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in pool:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.type as EnemyType

	return pool[-1].type as EnemyType


## --- Spawn Position ---

func _get_spawn_position() -> Vector2:
	if not player:
		return world_rect.get_center()

	var cam_rect: Rect2 = game_main.get_camera_rect() if game_main \
		else Rect2(
			player.position - Vector2(320, 180), Vector2(640, 360)
		)
	# Spawn well outside viewport so enemies walk in visibly.
	# Center on CAMERA (not player) so enemies are always off-screen
	# even when the player is offset near a clamped world border.
	var viewport_half_diag := cam_rect.size.length() / 2.0
	var spawn_dist := viewport_half_diag + 120.0
	var cam_center := cam_rect.get_center()

	var angle := randf() * TAU
	var spawn_pos := cam_center + Vector2(
		cos(angle), sin(angle)
	) * spawn_dist

	return spawn_pos


func _clamp_to_world(pos: Vector2) -> Vector2:
	# Generous margin — allow spawning 200px outside border
	var margin := -200.0
	return Vector2(
		clampf(
			pos.x,
			world_rect.position.x + margin,
			world_rect.end.x - margin,
		),
		clampf(
			pos.y,
			world_rect.position.y + margin,
			world_rect.end.y - margin,
		),
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

func _on_enemy_killed(
	_pos: Vector2, _type: String, _points: int
) -> void:
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
	_surge_index = 0
	_insano_surge_timer = 0.0
