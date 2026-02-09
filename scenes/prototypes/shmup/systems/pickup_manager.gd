extends Node
## Pickup system manager — drop rates, buff tracking, TURBO state, effect logic.
## Created by shmup_main, wired to enemy death signals.

signal buff_started(buff_id: String, duration: float)
signal buff_ended(buff_id: String)
signal turbo_letter_collected(letter: String, total: int)
signal turbo_activated()
signal pickup_effect_applied(pickup_type: int)

const Pickup := preload(
	"res://scenes/prototypes/shmup/collectibles/pickup.gd"
)

# =========================================================
# DROP RATE TABLES
# =========================================================

const DROP_RATES := {
	"grunt": 0.005,
	"weaver": 0.005,
	"leech": 0.005,
	"drone": 0.005,
	"spinner": 0.015,
	"spinner_child": 0.005,
	"rocket": 0.015,
	"sniper": 0.015,
	"charger": 0.02,
	"orbiter": 0.02,
	"pulser": 0.02,
	"minelayer": 0.01,
	"bomber": 0.01,
	"ghost": 0.01,
	"tank": 0.05,
	"hive": 0.05,
	"serpent": 0.08,
}

const RARE_ENEMY_TYPES := ["tank", "hive", "serpent"]

const COMMON_POOL := [
	Pickup.PickupType.MAGNET_PULSE,
	Pickup.PickupType.CHRONOFREEZE,
	Pickup.PickupType.HEALING_DROP,
	Pickup.PickupType.BERSERKS_RAGE,
	Pickup.PickupType.RAPID_FIRE,
]

const RARE_POOL := [
	Pickup.PickupType.INSTANT_LEVEL,
	Pickup.PickupType.ENEMY_CONVERSION,
	Pickup.PickupType.ANGELIC_BOON,
	Pickup.PickupType.POSITIONAL_CHALLENGE,
]

const CHALLENGE_REQUIRED := 3.0
const CHALLENGE_RADIUS := 40.0
const CHALLENGE_TIMEOUT := 12.0

# =========================================================
# REFERENCES (set via setup())
# =========================================================

var player: Area2D
var enemy_container: Node2D
var vfx_manager: Node2D
var game_main: Node2D

# =========================================================
# BUFF STATE
# =========================================================

var active_buffs: Dictionary = {}
var turbo_letters: Dictionary = {
	"T": false, "U": false, "R": false, "B": false, "O": false,
}
var turbo_active := false
var turbo_timer := 0.0
var converted_enemies: Array = []
var conversion_timer := 0.0
var challenge_active := false
var challenge_pickup: Area2D
var challenge_timer := 0.0
var challenge_progress := 0.0

var _base_fire_rate := 5.0
var _base_max_speed := 150.0
var _freeze_remaining := 0.0


func setup(
	p_player: Area2D, p_enemies: Node2D,
	p_vfx: Node2D, p_main: Node2D,
) -> void:
	player = p_player
	enemy_container = p_enemies
	vfx_manager = p_vfx
	game_main = p_main


# =========================================================
# DROP LOGIC
# =========================================================

func try_drop_pickup(
	_pos: Vector2, enemy_type: String,
) -> int:
	var base_rate: float = DROP_RATES.get(enemy_type, 0.005)
	var time_mult: float = 1.0 + game_main.elapsed_time / 600.0
	var final_rate: float = base_rate * time_mult

	if randf() > final_rate:
		return -1

	if enemy_type in RARE_ENEMY_TYPES:
		return _pick_rare()
	return _pick_common()


func _pick_common() -> int:
	var pool: Array = COMMON_POOL.duplicate()
	var missing_letter := _get_missing_turbo_letter()
	if missing_letter >= 0:
		pool.append(missing_letter)
		pool.append(missing_letter)
	return pool[randi() % pool.size()]


func _pick_rare() -> int:
	return RARE_POOL[randi() % RARE_POOL.size()]


func _get_missing_turbo_letter() -> int:
	if turbo_active:
		return -1
	var missing: Array = []
	if not turbo_letters["T"]:
		missing.append(Pickup.PickupType.TURBO_T)
	if not turbo_letters["U"]:
		missing.append(Pickup.PickupType.TURBO_U)
	if not turbo_letters["R"]:
		missing.append(Pickup.PickupType.TURBO_R)
	if not turbo_letters["B"]:
		missing.append(Pickup.PickupType.TURBO_B)
	if not turbo_letters["O"]:
		missing.append(Pickup.PickupType.TURBO_O)
	if missing.is_empty():
		return -1
	return missing[randi() % missing.size()]


# =========================================================
# EFFECT APPLICATION
# =========================================================

func apply_pickup_effect(pickup_type: int) -> void:
	pickup_effect_applied.emit(pickup_type)

	match pickup_type:
		Pickup.PickupType.MAGNET_PULSE:
			_apply_magnet_pulse()
		Pickup.PickupType.CHRONOFREEZE:
			_apply_chronofreeze()
		Pickup.PickupType.HEALING_DROP:
			_apply_healing()
		Pickup.PickupType.INSTANT_LEVEL:
			_apply_instant_level()
		Pickup.PickupType.TURBO_T:
			_collect_turbo_letter("T")
		Pickup.PickupType.TURBO_U:
			_collect_turbo_letter("U")
		Pickup.PickupType.TURBO_R:
			_collect_turbo_letter("R")
		Pickup.PickupType.TURBO_B:
			_collect_turbo_letter("B")
		Pickup.PickupType.TURBO_O:
			_collect_turbo_letter("O")
		Pickup.PickupType.ENEMY_CONVERSION:
			_apply_enemy_conversion()
		Pickup.PickupType.POSITIONAL_CHALLENGE:
			_start_challenge()
		Pickup.PickupType.ANGELIC_BOON:
			_apply_angelic_boon()
		Pickup.PickupType.BERSERKS_RAGE:
			_apply_berserks_rage()
		Pickup.PickupType.RAPID_FIRE:
			_apply_rapid_fire()


func _apply_magnet_pulse() -> void:
	for geom in game_main.geom_pool:
		if not geom.is_active:
			continue
		var tween: Tween = game_main.create_tween()
		tween.tween_property(
			geom, "position",
			player.position, 0.3,
		).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	vfx_manager.spawn_explosion(
		player.position, Color(0.9, 0.3, 1.0), 20, 4.0,
	)


func _apply_chronofreeze() -> void:
	var duration := 8.0
	active_buffs["chronofreeze"] = duration
	_freeze_remaining = duration
	buff_started.emit("chronofreeze", duration)

	for enemy in enemy_container.get_children():
		if enemy.get("is_active") and enemy.has_method("apply_freeze"):
			enemy.apply_freeze(duration, 1.0)

	vfx_manager.flash_screen(Color(0.5, 0.85, 1.0, 0.3), 0.2)


func _apply_healing() -> void:
	game_main.lives += 1
	game_main._update_ui()
	vfx_manager.flash_screen(Color(0.2, 1.0, 0.3, 0.15), 0.15)


func _apply_instant_level() -> void:
	var xp_sys: Node = game_main.xp_level_system
	var needed: int = xp_sys.xp_to_next - xp_sys.xp
	if needed > 0:
		xp_sys.add_xp(needed)
	vfx_manager.flash_screen(Color(1.0, 0.9, 0.2, 0.3), 0.2)


func _collect_turbo_letter(letter: String) -> void:
	turbo_letters[letter] = true
	var total := _count_turbo_letters()
	turbo_letter_collected.emit(letter, total)

	if total >= 5:
		_activate_turbo()


func _count_turbo_letters() -> int:
	var count := 0
	for key in turbo_letters:
		if turbo_letters[key]:
			count += 1
	return count


func _activate_turbo() -> void:
	turbo_active = true
	turbo_timer = 10.0
	turbo_activated.emit()

	player.is_invincible = true
	player.invincible_timer = 10.0
	_recalculate_player_stats()

	vfx_manager.flash_screen(Color(1.0, 1.0, 1.0, 0.5), 0.25)
	vfx_manager.spawn_explosion(
		player.position, Color(1.0, 0.5, 0.0), 40, 6.0,
	)


func _deactivate_turbo() -> void:
	turbo_active = false
	turbo_timer = 0.0
	for key in turbo_letters:
		turbo_letters[key] = false
	_recalculate_player_stats()


func _apply_enemy_conversion() -> void:
	conversion_timer = 10.0
	converted_enemies.clear()

	var radius := 120.0
	var count := 0
	for enemy in enemy_container.get_children():
		if not enemy.get("is_active"):
			continue
		if enemy.get("is_converted"):
			continue
		if enemy.position.distance_squared_to(
			player.position
		) > radius * radius:
			continue
		enemy.is_converted = true
		converted_enemies.append(enemy)
		count += 1
		if count >= 8:
			break

	vfx_manager.spawn_explosion(
		player.position, Color(0.7, 0.2, 1.0), 25, 5.0,
	)
	buff_started.emit("conversion", 10.0)


func _end_conversion() -> void:
	for enemy in converted_enemies:
		if is_instance_valid(enemy) and enemy.get("is_active"):
			enemy.is_converted = false
			enemy.queue_redraw()
	converted_enemies.clear()
	conversion_timer = 0.0
	buff_ended.emit("conversion")


func _start_challenge() -> void:
	challenge_active = true
	challenge_progress = 0.0
	challenge_timer = CHALLENGE_TIMEOUT
	buff_started.emit("challenge", CHALLENGE_TIMEOUT)


func set_challenge_pickup(pickup: Area2D) -> void:
	challenge_pickup = pickup


func _update_challenge(delta: float) -> void:
	if not challenge_active:
		return
	if not is_instance_valid(challenge_pickup):
		challenge_active = false
		buff_ended.emit("challenge")
		return

	challenge_timer -= delta
	if challenge_timer <= 0.0:
		challenge_active = false
		challenge_pickup.deactivate()
		buff_ended.emit("challenge")
		return

	var dist := player.position.distance_to(
		challenge_pickup.position,
	)
	if dist < CHALLENGE_RADIUS:
		challenge_progress += delta
	else:
		challenge_progress = maxf(
			challenge_progress - delta * 0.5, 0.0,
		)

	if challenge_progress >= CHALLENGE_REQUIRED:
		_complete_challenge()


func get_challenge_fill() -> float:
	if not challenge_active:
		return 0.0
	return clampf(
		challenge_progress / CHALLENGE_REQUIRED, 0.0, 1.0,
	)


func _complete_challenge() -> void:
	challenge_active = false

	game_main.score += 500
	game_main.bombs = mini(
		game_main.bombs + 1, game_main.BOMB_CAP,
	)
	game_main._update_ui()
	_apply_magnet_pulse()

	vfx_manager.flash_screen(Color(1.0, 1.0, 0.85, 0.4), 0.2)
	vfx_manager.spawn_explosion(
		challenge_pickup.position,
		Color(1.0, 1.0, 0.85), 30, 5.0,
	)

	if is_instance_valid(challenge_pickup):
		challenge_pickup.deactivate()
	buff_ended.emit("challenge")


func _apply_angelic_boon() -> void:
	active_buffs["angelic_boon"] = 10.0
	player.is_invincible = true
	player.invincible_timer = 10.0
	buff_started.emit("angelic_boon", 10.0)
	_recalculate_player_stats()


func _apply_berserks_rage() -> void:
	active_buffs["berserks_rage"] = 15.0
	buff_started.emit("berserks_rage", 15.0)
	_recalculate_player_stats()


func _apply_rapid_fire() -> void:
	active_buffs["rapid_fire"] = 10.0
	buff_started.emit("rapid_fire", 10.0)
	_recalculate_player_stats()


# =========================================================
# STAT RECALCULATION — order-independent buff stacking
# =========================================================

func update_base_stats(fire_rate: float, max_speed: float) -> void:
	_base_fire_rate = fire_rate
	_base_max_speed = max_speed
	_recalculate_player_stats()


func _recalculate_player_stats() -> void:
	var rate := _base_fire_rate
	var spd := _base_max_speed

	if active_buffs.has("berserks_rage"):
		rate *= 2.0
	if active_buffs.has("rapid_fire"):
		rate *= 1.67
		spd *= 1.5
	if active_buffs.has("angelic_boon"):
		spd *= 1.5
	if turbo_active:
		rate *= 2.0
		spd *= 2.0

	player.fire_rate = rate
	player.max_speed = spd


# =========================================================
# PER-FRAME UPDATE
# =========================================================

func _process(delta: float) -> void:
	_tick_buffs(delta)
	_tick_turbo(delta)
	_tick_conversion(delta)
	_tick_freeze(delta)
	if challenge_active:
		_update_challenge(delta)


func _tick_buffs(delta: float) -> void:
	var expired: Array = []
	for buff_id in active_buffs:
		active_buffs[buff_id] -= delta
		if active_buffs[buff_id] <= 0.0:
			expired.append(buff_id)

	for buff_id in expired:
		active_buffs.erase(buff_id)
		buff_ended.emit(buff_id)
		_recalculate_player_stats()


func _tick_turbo(delta: float) -> void:
	if not turbo_active:
		return
	turbo_timer -= delta
	if turbo_timer <= 0.0:
		_deactivate_turbo()


func _tick_conversion(delta: float) -> void:
	if conversion_timer <= 0.0:
		return
	conversion_timer -= delta
	var still_alive: Array = []
	for enemy in converted_enemies:
		if is_instance_valid(enemy) and enemy.get("is_active"):
			still_alive.append(enemy)
	converted_enemies = still_alive

	if conversion_timer <= 0.0:
		_end_conversion()


func _tick_freeze(delta: float) -> void:
	if _freeze_remaining <= 0.0:
		return
	_freeze_remaining -= delta
	if _freeze_remaining <= 0.0:
		_freeze_remaining = 0.0
		return
	for enemy in enemy_container.get_children():
		if not enemy.get("is_active"):
			continue
		if not enemy.has_method("apply_freeze"):
			continue
		if enemy.freeze_timer < 0.5:
			enemy.apply_freeze(_freeze_remaining, 1.0)


# =========================================================
# PICKUP COLOR LOOKUP (for VFX in shmup_main)
# =========================================================

func get_pickup_color(pickup_type: int) -> Color:
	var cfg: Dictionary = Pickup.TYPE_CONFIG.get(
		pickup_type, {},
	)
	return cfg.get("color", Color.WHITE)


# =========================================================
# RESET
# =========================================================

func reset() -> void:
	active_buffs.clear()
	turbo_letters = {
		"T": false, "U": false,
		"R": false, "B": false, "O": false,
	}
	turbo_active = false
	turbo_timer = 0.0
	converted_enemies.clear()
	conversion_timer = 0.0
	challenge_active = false
	challenge_pickup = null
	challenge_progress = 0.0
	challenge_timer = 0.0
	_freeze_remaining = 0.0
	_base_fire_rate = 5.0
	_base_max_speed = 150.0
