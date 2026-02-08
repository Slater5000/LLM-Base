extends Node
## Manages upgrade state: current levels, random selection, evolution checks, stat application.

signal upgrade_applied(id: String, new_level: int)
signal evolution_unlocked(id: String)

const UpgradeData := preload("res://scenes/prototypes/shmup/systems/upgrade_data.gd")

# Current upgrade levels — keys are upgrade IDs, values are current level (0 = not owned)
var current_levels: Dictionary = {}
# Acquired evolutions
var acquired_evolutions: Dictionary = {}
# Reference to game systems (set by shmup_main)
var player: Area2D
var xp_level_system: Node
var game_main: Node2D  # shmup_main — for lives/bombs

# Cached data
var _upgrades: Dictionary = {}
var _evolutions: Dictionary = {}


func _ready() -> void:
	_upgrades = UpgradeData.get_all_upgrades()
	_evolutions = UpgradeData.get_all_evolutions()


func reset() -> void:
	current_levels.clear()
	acquired_evolutions.clear()


func get_level(id: String) -> int:
	return current_levels.get(id, 0)


func is_maxed(id: String) -> bool:
	if not _upgrades.has(id):
		return true
	return get_level(id) >= _upgrades[id]["max_level"]


## Returns 3 random upgrade choices. If an evolution is available, it's guaranteed as one choice.
func get_random_choices(count: int = 3) -> Array:
	var choices: Array = []

	# Check for available evolutions first — guaranteed slot
	var available_evos := _get_available_evolutions()
	if available_evos.size() > 0:
		var evo_id: String = available_evos[randi() % available_evos.size()]
		choices.append(_make_evolution_choice(evo_id))

	# Fill remaining slots with non-maxed upgrades
	var pool := _get_available_upgrades()

	# Shuffle pool
	pool.shuffle()

	for upgrade_id in pool:
		if choices.size() >= count:
			break
		# Don't duplicate
		var already_picked := false
		for c in choices:
			if c["id"] == upgrade_id:
				already_picked = true
				break
		if already_picked:
			continue
		choices.append(_make_upgrade_choice(upgrade_id))

	# If we couldn't fill all slots (very late game, most maxed), that's fine
	return choices


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
	var pool: Array = []
	for id in _upgrades:
		if not is_maxed(id):
			pool.append(id)
	return pool


func _get_available_evolutions() -> Array:
	var available: Array = []
	for evo_id in _evolutions:
		if acquired_evolutions.has(evo_id):
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
				game_main.bombs += 1
				game_main._update_ui()

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
				player.pierce_count = level  # lv1=1, lv2=2, lv3=3
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
