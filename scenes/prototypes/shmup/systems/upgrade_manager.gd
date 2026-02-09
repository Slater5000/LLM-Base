extends Node
## Manages upgrade state: current levels, random selection, evolution checks, stat application.

signal upgrade_applied(id: String, new_level: int)
signal evolution_unlocked(id: String)

const UpgradeData := preload("res://scenes/prototypes/shmup/systems/upgrade_data.gd")

# Upgrades to hide when a given upgrade/evolution is owned
const CONFLICTS: Dictionary = {
	"laser": ["piercing"],
	"piercing": ["laser"],
	"bullet_storm": ["fire_rate", "spread_shot", "laser"],
	"railgun": ["spread_shot", "fire_rate", "piercing", "laser"],
}

# Evolutions to hide when a given upgrade/evolution is owned
const EVOLUTION_CONFLICTS: Dictionary = {
	"laser": ["bullet_storm", "railgun"],
	"bullet_storm": ["railgun"],
	"railgun": ["bullet_storm"],
}

# Current upgrade levels — keys are upgrade IDs, values are current level (0 = not owned)
var current_levels: Dictionary = {}
# Acquired evolutions
var acquired_evolutions: Dictionary = {}
# Reference to game systems (set by shmup_main)
var player: Area2D
var xp_level_system: Node
var game_main: Node2D  # shmup_main — for lives/bombs
var locked_id: String = ""
var banished_upgrades: Dictionary = {}
var banish_charges := 3

# Cached data
var _upgrades: Dictionary = {}
var _evolutions: Dictionary = {}


func _ready() -> void:
	_upgrades = UpgradeData.get_all_upgrades()
	_evolutions = UpgradeData.get_all_evolutions()


func reset() -> void:
	current_levels.clear()
	acquired_evolutions.clear()
	locked_id = ""
	banished_upgrades.clear()
	banish_charges = 3


func get_level(id: String) -> int:
	return current_levels.get(id, 0)


func is_maxed(id: String) -> bool:
	if not _upgrades.has(id):
		return true
	return get_level(id) >= _upgrades[id]["max_level"]


## Returns random upgrade choices. Locked upgrade guaranteed first.
## If an evolution is available, it gets a guaranteed slot.
func get_random_choices(count: int = 3) -> Array:
	var choices: Array = []

	# Locked upgrade guaranteed first
	if locked_id != "" and _is_still_available(locked_id):
		if _evolutions.has(locked_id):
			choices.append(_make_evolution_choice(locked_id))
		else:
			choices.append(_make_upgrade_choice(locked_id))
	elif locked_id != "":
		locked_id = ""  # Auto-break: no longer available

	# Check for available evolutions — guaranteed slot
	var available_evos := _get_available_evolutions()
	if available_evos.size() > 0:
		var evo_id_pick: String = available_evos[
			randi() % available_evos.size()
		]
		if not _choices_has_id(choices, evo_id_pick):
			choices.append(_make_evolution_choice(evo_id_pick))

	# Fill remaining slots with non-maxed upgrades
	var pool := _get_available_upgrades()
	pool.shuffle()

	for upgrade_id in pool:
		if choices.size() >= count:
			break
		if _choices_has_id(choices, upgrade_id):
			continue
		choices.append(_make_upgrade_choice(upgrade_id))

	return choices


func _choices_has_id(choices_arr: Array, id: String) -> bool:
	for c in choices_arr:
		if c["id"] == id:
			return true
	return false


## Check if an upgrade/evolution is still available in the pool.
func _is_still_available(id: String) -> bool:
	if banished_upgrades.has(id):
		return false
	if _evolutions.has(id):
		return _is_evo_available(id)
	if _upgrades.has(id):
		var excluded := _get_excluded_upgrades()
		return not is_maxed(id) and id not in excluded
	return false


func _is_evo_available(id: String) -> bool:
	if acquired_evolutions.has(id):
		return false
	if id in _get_excluded_evolutions():
		return false
	var evo: Dictionary = _evolutions[id]
	var requires: Array = evo["requires"]
	for req_id in requires:
		if not is_maxed(req_id):
			return false
	return true


## Permanently remove an upgrade from the pool. Uses a charge.
func banish_upgrade(id: String) -> void:
	banished_upgrades[id] = true
	banish_charges -= 1
	if locked_id == id:
		locked_id = ""
	print(
		"[UPGRADE] Banished: %s (%d charges left)"
		% [id, banish_charges],
	)


## Apply a chosen upgrade and return the new level.
func apply_upgrade(id: String) -> int:
	# Check if it's an evolution
	if _evolutions.has(id):
		return _apply_evolution(id)

	# Regular upgrade
	var new_level := get_level(id) + 1
	current_levels[id] = new_level

	# Apply stat effects
	_apply_stat_effect(id, new_level)

	upgrade_applied.emit(id, new_level)
	return new_level


## Get a summary of current upgrades for display.
func get_upgrade_summary() -> String:
	var parts: Array = []
	for id in current_levels:
		if current_levels[id] > 0:
			var data: Dictionary = _upgrades.get(id, {})
			var name: String = data.get("name", id)
			parts.append("%s %d" % [name, current_levels[id]])
	for id in acquired_evolutions:
		var data: Dictionary = _evolutions.get(id, {})
		parts.append(data.get("name", id))
	if parts.is_empty():
		return "None"
	return " | ".join(parts)


# --- Internal ---

func _get_available_upgrades() -> Array:
	var excluded := _get_excluded_upgrades()
	var pool: Array = []
	for id in _upgrades:
		if banished_upgrades.has(id):
			continue
		if not is_maxed(id) and id not in excluded:
			pool.append(id)
	return pool


func _get_available_evolutions() -> Array:
	var excluded := _get_excluded_evolutions()
	var available: Array = []
	for evo_id in _evolutions:
		if acquired_evolutions.has(evo_id):
			continue
		if evo_id in excluded:
			continue
		if banished_upgrades.has(evo_id):
			continue
		var evo: Dictionary = _evolutions[evo_id]
		var requires: Array = evo["requires"]
		var all_maxed := true
		for req_id in requires:
			if not is_maxed(req_id):
				all_maxed = false
				break
		if all_maxed:
			available.append(evo_id)
	return available


func _get_excluded_upgrades() -> Array:
	var excluded: Array = []
	for owned_id in current_levels:
		if int(current_levels[owned_id]) > 0 and CONFLICTS.has(owned_id):
			var blocked: Array = CONFLICTS[owned_id]
			excluded.append_array(blocked)
	for evo_id in acquired_evolutions:
		if CONFLICTS.has(evo_id):
			var blocked: Array = CONFLICTS[evo_id]
			excluded.append_array(blocked)
	return excluded


func _get_excluded_evolutions() -> Array:
	var excluded: Array = []
	for owned_id in current_levels:
		if int(current_levels[owned_id]) > 0:
			if EVOLUTION_CONFLICTS.has(owned_id):
				var blocked: Array = EVOLUTION_CONFLICTS[owned_id]
				excluded.append_array(blocked)
	for evo_id in acquired_evolutions:
		if EVOLUTION_CONFLICTS.has(evo_id):
			var blocked: Array = EVOLUTION_CONFLICTS[evo_id]
			excluded.append_array(blocked)
	return excluded


func _make_upgrade_choice(id: String) -> Dictionary:
	var data: Dictionary = _upgrades[id]
	var next_level := get_level(id) + 1
	var desc_idx := clampi(next_level - 1, 0, data["descriptions"].size() - 1)
	return {
		"id": id,
		"name": data["name"],
		"description": data["descriptions"][desc_idx],
		"category": data["category"],
		"icon_shape": data["icon_shape"],
		"color": data["color"],
		"current_level": get_level(id),
		"max_level": data["max_level"],
		"is_evolution": false,
	}


func _make_evolution_choice(id: String) -> Dictionary:
	var data: Dictionary = _evolutions[id]
	return {
		"id": id,
		"name": data["name"],
		"description": data["description"],
		"category": data["category"],
		"icon_shape": data["icon_shape"],
		"color": data["color"],
		"current_level": 0,
		"max_level": 1,
		"is_evolution": true,
	}


func _apply_evolution(id: String) -> int:
	acquired_evolutions[id] = true
	evolution_unlocked.emit(id)
	print("[UPGRADE] Evolution unlocked: %s" % id)
	return 1


func _apply_stat_effect(id: String, level: int) -> void:
	match id:
		# --- Stat upgrades (immediate effect) ---
		"move_speed":
			if player:
				player.max_speed = 150.0 * (1.0 + level * 0.10)
		"magnet":
			# Magnet range is applied by shmup_main when spawning geoms
			pass  # Stored in current_levels, read by main
		"xp_boost":
			if xp_level_system:
				xp_level_system.xp_multiplier = 1.0 + level * 0.15
		"extra_life":
			if game_main:
				game_main.lives += 1
				game_main._update_ui()
		"extra_bomb":
			if game_main:
				game_main.bombs = mini(
					game_main.bombs + 1, game_main.BOMB_CAP,
				)
				game_main._update_ui()
		"extra_banish":
			banish_charges += 1

		# --- Bullet mods (applied to player, read by shmup_main when firing) ---
		"fire_rate":
			if player:
				player.fire_rate = 5.0 * (1.0 + level * 0.20)
		"bullet_size":
			if player:
				player.bullet_size_scale = 1.0 + level * 0.30
		"spread_shot":
			if player:
				player.spread_count = level + 1  # lv1=2, lv2=3, lv3=4, lv4=5, lv5=6
		"piercing":
			if player:
				var pierce_values := [1, 2, 3, 5, 8]
				player.pierce_count = pierce_values[clampi(level - 1, 0, 4)]
		"laser":
			pass  # Handled by shmup_main in Phase D

		# --- Status effects (applied to player, read by bullet on hit) ---
		"burn":
			if player:
				player.burn_chance = 0.05 + level * 0.10  # 15%, 25%, 35%
		"freeze":
			if player:
				player.freeze_chance = 0.05 + level * 0.10  # 15%, 25%, 35%

		# --- Passive weapons (routed via upgrade_applied signal) ---
		# shmup_main listens for upgrade_applied and forwards to passive_weapon_manager
		_:
			pass

	print("[UPGRADE] %s → level %d" % [id, level])
