extends Node
class_name GameStateClass
## GameState - Manages save data, settings, story progress, and party.
## Autoload that persists across scenes.
##
## Usage:
##   GameState.save_game()
##   GameState.set_story_flag("talked_to_professor", true)
##   GameState.set_master_volume(0.8)

signal game_saved
signal game_loaded
signal settings_changed
signal story_flag_set(flag_name: String, value: bool)
signal party_changed

const SAVE_PATH := "user://save.json"
const CURRENT_VERSION := 1

## Settings
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false

## Story progress
var story_flags: Dictionary = {}
var events_completed: Array[String] = []

## Party and storage
var party: Array[CreatureInstance] = []
var storage: Array[CreatureInstance] = []

## Play time tracking
var play_time_seconds: int = 0
var _session_start_time: int = 0

## Creature/move data cache
var _species_cache: Dictionary = {}
var _move_cache: Dictionary = {}


func _ready() -> void:
	_session_start_time = int(Time.get_unix_time_from_system())
	_apply_settings()
	_load_resources()


func _process(_delta: float) -> void:
	# Update play time every frame (cheap operation)
	play_time_seconds = _get_total_play_time()


## Get total play time including current session
func _get_total_play_time() -> int:
	var session_time := int(Time.get_unix_time_from_system()) - _session_start_time
	return play_time_seconds + session_time


## Load all creature species and move resources
func _load_resources() -> void:
	_load_species()
	_load_moves()


func _load_species() -> void:
	var dir := DirAccess.open("res://data/creatures/")
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://data/creatures/" + file_name
			var species := load(path) as CreatureSpecies
			if species:
				_species_cache[species.species_id] = species
		file_name = dir.get_next()


func _load_moves() -> void:
	var dir := DirAccess.open("res://data/moves/")
	if not dir:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := "res://data/moves/" + file_name
			var move := load(path) as MoveData
			if move:
				_move_cache[move.move_id] = move
		file_name = dir.get_next()


## Get a creature species by ID
func get_species(species_id: String) -> CreatureSpecies:
	return _species_cache.get(species_id, null)


## Get a move by ID
func get_move(move_id: String) -> MoveData:
	return _move_cache.get(move_id, null)


# =============================================================================
# SAVE / LOAD
# =============================================================================

## Check if a save file exists
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Save game to disk
func save_game() -> bool:
	var scene_manager := get_node_or_null("/root/SceneManager")
	var player: CharacterBody2D = null
	var current_scene := ""

	if scene_manager:
		player = scene_manager.get_player()
		if scene_manager._current_world:
			current_scene = scene_manager._current_world.scene_file_path

	# Build party data
	var party_data: Array = []
	for creature in party:
		party_data.append(creature.to_dict())

	var storage_data: Array = []
	for creature in storage:
		storage_data.append(creature.to_dict())

	var save_data := {
		"version": CURRENT_VERSION,
		"timestamp": int(Time.get_unix_time_from_system()),
		"play_time_seconds": _get_total_play_time(),
		"player_scene": current_scene,
		"player_position": {
			"x": player.global_position.x if player else 0.0,
			"y": player.global_position.y if player else 0.0
		},
		"player_facing": player.facing_direction if player else "down",
		"story_flags": story_flags,
		"events_completed": events_completed,
		"party": party_data,
		"storage": storage_data,
		"settings": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"fullscreen": fullscreen
		}
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("GameState: Failed to open save file for writing")
		return false

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()

	game_saved.emit()
	return true


## Load game from disk
func load_game() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("GameState: Failed to open save file for reading")
		return false

	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if not data is Dictionary:
		push_error("GameState: Invalid save file format")
		return false

	# Migrate if needed
	data = _migrate_save(data)

	# Load settings
	var settings: Dictionary = data.get("settings", {})
	master_volume = settings.get("master_volume", 1.0)
	music_volume = settings.get("music_volume", 0.8)
	sfx_volume = settings.get("sfx_volume", 1.0)
	fullscreen = settings.get("fullscreen", false)
	_apply_settings()

	# Load story progress
	story_flags = data.get("story_flags", {})
	events_completed = []
	for event in data.get("events_completed", []):
		events_completed.append(str(event))

	# Load play time
	play_time_seconds = data.get("play_time_seconds", 0)
	_session_start_time = int(Time.get_unix_time_from_system())

	# Load party
	party.clear()
	for creature_data in data.get("party", []):
		var creature := CreatureInstance.from_dict(creature_data)
		party.append(creature)

	# Load storage
	storage.clear()
	for creature_data in data.get("storage", []):
		var creature := CreatureInstance.from_dict(creature_data)
		storage.append(creature)

	# Position player (handled by SceneManager during scene load)
	# Store for SceneManager to use
	_pending_load_data = data

	game_loaded.emit()
	party_changed.emit()
	return true


var _pending_load_data: Dictionary = {}


## Get pending load data (used by SceneManager after load_game)
func get_pending_load_data() -> Dictionary:
	var data := _pending_load_data
	_pending_load_data = {}
	return data


## Migrate old save versions to current
func _migrate_save(data: Dictionary) -> Dictionary:
	var version: int = data.get("version", 1)

	# Add migrations here as versions increase
	# if version < 2:
	#     data = _migrate_v1_to_v2(data)

	data["version"] = CURRENT_VERSION
	return data


## Delete save file
func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


# =============================================================================
# SETTINGS
# =============================================================================

func _apply_settings() -> void:
	# Apply audio settings to AudioServer
	var master_db := linear_to_db(master_volume)
	var music_db := linear_to_db(music_volume * master_volume)
	var sfx_db := linear_to_db(sfx_volume * master_volume)

	# Assuming bus indices: 0=Master, 1=Music, 2=SFX
	# These would need to be set up in Godot's Audio tab
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_volume_db(0, master_db)
	if AudioServer.bus_count > 1:
		AudioServer.set_bus_volume_db(1, music_db)
	if AudioServer.bus_count > 2:
		AudioServer.set_bus_volume_db(2, sfx_db)

	# Apply fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_settings()
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_settings()
	settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_settings()
	settings_changed.emit()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_settings()
	settings_changed.emit()


func get_settings() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen
	}


# =============================================================================
# STORY PROGRESS
# =============================================================================

func set_story_flag(flag: String, value: bool) -> void:
	story_flags[flag] = value
	story_flag_set.emit(flag, value)


func get_story_flag(flag: String) -> bool:
	return story_flags.get(flag, false)


func mark_event_completed(event_id: String) -> void:
	if event_id not in events_completed:
		events_completed.append(event_id)


func is_event_completed(event_id: String) -> bool:
	return event_id in events_completed


# =============================================================================
# PARTY MANAGEMENT
# =============================================================================

func get_party() -> Array[CreatureInstance]:
	return party


func get_party_size() -> int:
	return party.size()


func add_to_party(creature: CreatureInstance) -> bool:
	if party.size() >= 6:
		# Party full, add to storage instead
		storage.append(creature)
		party_changed.emit()
		return false
	party.append(creature)
	party_changed.emit()
	return true


func remove_from_party(index: int) -> CreatureInstance:
	if index < 0 or index >= party.size():
		return null
	var creature := party[index]
	party.remove_at(index)
	party_changed.emit()
	return creature


func swap_party_positions(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_a >= party.size():
		return
	if index_b < 0 or index_b >= party.size():
		return
	var temp := party[index_a]
	party[index_a] = party[index_b]
	party[index_b] = temp
	party_changed.emit()


func move_to_storage(party_index: int) -> void:
	if party_index < 0 or party_index >= party.size():
		return
	if party.size() <= 1:
		return  # Can't remove last party member
	var creature := party[party_index]
	party.remove_at(party_index)
	storage.append(creature)
	party_changed.emit()


func move_from_storage(storage_index: int) -> bool:
	if storage_index < 0 or storage_index >= storage.size():
		return false
	if party.size() >= 6:
		return false
	var creature := storage[storage_index]
	storage.remove_at(storage_index)
	party.append(creature)
	party_changed.emit()
	return true


func heal_party() -> void:
	for creature in party:
		creature.full_heal()
	party_changed.emit()


## Create a new creature and add to party
func create_creature(species_id: String, level: int = 1, location: String = "") -> CreatureInstance:
	var species := get_species(species_id)
	if not species:
		push_error("GameState: Unknown species: " + species_id)
		return null

	var creature := CreatureInstance.create(species_id, level)
	creature.caught_location = location
	creature.calculate_stats(species)

	# Learn moves available at this level
	var available_moves := species.get_available_moves(level)
	for move_id in available_moves:
		creature.learn_move(move_id)

	# Set first 3 learned moves as active (or fewer if not enough moves)
	var active: Array[String] = []
	for i in mini(3, creature.learned_moves.size()):
		active.append(creature.learned_moves[i])
	creature.set_active_moves(active)

	return creature
