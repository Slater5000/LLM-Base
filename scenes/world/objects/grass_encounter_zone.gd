extends Node2D
class_name GrassEncounterZone
## Manages rustling grass encounters for a patch of tall grass.
## Periodically spawns creatures into random grass tiles.
## Based on Pokemon Black/White rustling grass mechanic.

## Possible creatures that can spawn in this zone
@export var spawn_table: Array[String] = ["zephyrix", "pyrathos"]

## Minimum seconds between spawn attempts
@export var spawn_interval_min: float = 8.0
## Maximum seconds between spawn attempts
@export var spawn_interval_max: float = 20.0
## Chance for a creature to actually spawn when interval fires (0.0 - 1.0)
@export var spawn_chance: float = 0.4

## How long the creature stays before leaving (if player doesn't interact)
@export var creature_linger_min: float = 30.0
@export var creature_linger_max: float = 60.0

## Distance to consider grass "adjacent" (tiles are 24px apart, diagonal ~34px)
const ADJACENT_DISTANCE := 40.0

var grass_tiles: Array[TallGrass] = []
var spawn_timer: float = 0.0
var next_spawn_time: float = 0.0

## Track active grass with their linger timers
var active_creatures: Dictionary = {}  # TallGrass -> {timer: float, duration: float}


func _ready() -> void:
	# Collect all TallGrass children
	_collect_grass_tiles()

	# Initial spawn delay
	next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)


func _collect_grass_tiles() -> void:
	grass_tiles.clear()
	for child in get_children():
		if child is TallGrass:
			grass_tiles.append(child)
			# Connect to know when creature is scanned
			if not child.creature_scanned.is_connected(_on_creature_scanned):
				child.creature_scanned.connect(_on_creature_scanned)


func _process(delta: float) -> void:
	# Update linger timers for all active creatures
	var to_remove: Array[TallGrass] = []
	for grass: TallGrass in active_creatures.keys():
		active_creatures[grass].timer += delta
		if active_creatures[grass].timer >= active_creatures[grass].duration:
			to_remove.append(grass)

	# Remove expired creatures
	for grass in to_remove:
		_creature_leaves(grass)

	# Spawn timer
	spawn_timer += delta
	if spawn_timer >= next_spawn_time:
		_attempt_spawn()
		spawn_timer = 0.0
		next_spawn_time = randf_range(spawn_interval_min, spawn_interval_max)


func _attempt_spawn() -> void:
	# Random chance check
	if randf() > spawn_chance:
		return

	if grass_tiles.is_empty():
		return

	# Get valid grass tiles (not player inside, not adjacent to active creature)
	var valid_tiles: Array[TallGrass] = []
	for grass in grass_tiles:
		if _is_valid_spawn_tile(grass):
			valid_tiles.append(grass)

	if valid_tiles.is_empty():
		return

	var chosen_grass = valid_tiles.pick_random()

	# Pick a random creature from spawn table
	if spawn_table.is_empty():
		return

	var chosen_creature = spawn_table.pick_random()

	# Spawn the creature
	_spawn_creature(chosen_grass, chosen_creature)


func _is_valid_spawn_tile(grass: TallGrass) -> bool:
	# Don't spawn if player is standing on this grass
	if grass.player_inside:
		return false

	# Don't spawn if this grass already has a creature
	if grass.has_creature:
		return false

	# Don't spawn if adjacent to another grass with a creature
	for active_grass: TallGrass in active_creatures.keys():
		var dist = grass.global_position.distance_to(active_grass.global_position)
		if dist < ADJACENT_DISTANCE and dist > 0.1:  # Adjacent but not same tile
			return false

	return true


func _spawn_creature(grass: TallGrass, species: String) -> void:
	var duration = randf_range(creature_linger_min, creature_linger_max)
	active_creatures[grass] = {"timer": 0.0, "duration": duration}
	grass.spawn_creature(species)


func _creature_leaves(grass: TallGrass) -> void:
	if grass in active_creatures:
		active_creatures.erase(grass)
		grass.creature_leaves()


func _on_creature_scanned(grass: TallGrass, _species: String) -> void:
	# Player scanned the creature - it's been found
	if grass in active_creatures:
		active_creatures.erase(grass)
