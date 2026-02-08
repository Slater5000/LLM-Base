extends Node
## XP tracking and level-up system. Geom pickups → XP → level-ups → upgrade choices.

signal leveled_up(level: int)
signal xp_changed(current_xp: int, xp_to_next: int)

var xp := 0
var level := 1
var xp_to_next := 10
var xp_multiplier := 1.0  # Modified by XP Boost upgrade

const BASE_XP := 10
const GROWTH_RATE := 1.18  # Each level needs 18% more XP

# Queue for multiple level-ups at once (collecting many geoms)
var _pending_levels := 0


func add_xp(amount: int) -> void:
	xp += int(amount * xp_multiplier)
	xp_changed.emit(xp, xp_to_next)

	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = _calculate_xp_threshold(level)
		_pending_levels += 1
		leveled_up.emit(level)
		xp_changed.emit(xp, xp_to_next)


func has_pending_levels() -> bool:
	return _pending_levels > 0


func consume_pending_level() -> void:
	_pending_levels = maxi(_pending_levels - 1, 0)


func get_progress() -> float:
	if xp_to_next <= 0:
		return 1.0
	return float(xp) / float(xp_to_next)


func _calculate_xp_threshold(lvl: int) -> int:
	return int(BASE_XP * pow(GROWTH_RATE, lvl - 1))


func reset() -> void:
	xp = 0
	level = 1
	xp_to_next = BASE_XP
	xp_multiplier = 1.0
	_pending_levels = 0
