extends CanvasLayer
## SceneManager - Handles all scene transitions with fade effects.
## Autoload that persists across scenes, manages player instance.
##
## Usage:
##   SceneManager.transition_to("res://scenes/world/house_interior.tscn", "door_exit")
##   SceneManager.transition_to_edge("res://scenes/world/route_2.tscn", "left")

signal transition_started
signal transition_completed

## Transition state
enum State { IDLE, FADING_OUT, LOADING, FADING_IN }
var _state: State = State.IDLE

## Fade duration in seconds
@export var fade_duration: float = 0.3

## Reference to the current world scene
var _current_world: Node = null

## Reference to the player (persists across transitions)
var _player: CharacterBody2D = null

## Spawn point ID to use after loading
var _target_spawn_id: String = ""

## UI elements
@onready var _fade_rect: ColorRect = $FadeRect


func _ready() -> void:
	# Start transparent
	_fade_rect.color.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Register the player instance (called by player on ready)
func register_player(player: CharacterBody2D) -> void:
	_player = player


## Register the current world scene
func register_world(world: Node) -> void:
	_current_world = world


## Get the current player reference
func get_player() -> CharacterBody2D:
	return _player


## Transition to a new scene, spawning at the given spawn point ID.
## For doors, interiors, specific locations.
func transition_to(scene_path: String, spawn_point_id: String = "default") -> void:
	if _state != State.IDLE:
		return

	_target_spawn_id = spawn_point_id
	_start_transition(scene_path)


## Transition triggered by map edge. Spawn point is inferred from direction.
## direction: "left", "right", "top", "bottom"
func transition_to_edge(scene_path: String, from_direction: String) -> void:
	if _state != State.IDLE:
		return

	# Spawn at opposite edge
	match from_direction:
		"left":
			_target_spawn_id = "from_right"
		"right":
			_target_spawn_id = "from_left"
		"top":
			_target_spawn_id = "from_bottom"
		"bottom":
			_target_spawn_id = "from_top"
		_:
			_target_spawn_id = "default"

	_start_transition(scene_path)


func _start_transition(scene_path: String) -> void:
	_state = State.FADING_OUT
	transition_started.emit()

	# Disable player input during transition
	if _player:
		_player.set_physics_process(false)

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	tween.tween_callback(_load_scene.bind(scene_path))


func _load_scene(scene_path: String) -> void:
	_state = State.LOADING

	# IMPORTANT: Save reference to existing player BEFORE loading new scene
	# (because embedded player's _ready() will call register_player and overwrite _player)
	var existing_player: CharacterBody2D = _player

	# Remove player from current world (but don't free it)
	if existing_player and existing_player.get_parent():
		existing_player.get_parent().remove_child(existing_player)

	# Free current world
	if _current_world:
		_current_world.queue_free()
		_current_world = null

	# Load new scene (this may trigger embedded player's _ready -> register_player)
	var packed_scene: PackedScene = load(scene_path)
	var new_scene: Node = packed_scene.instantiate()

	# Add to tree (main node)
	get_tree().root.get_node("Main").add_child(new_scene)
	_current_world = new_scene

	# Handle player management
	var embedded_player := _find_embedded_player(new_scene)

	if existing_player:
		# We had a player before this transition - reuse it
		if embedded_player and embedded_player != existing_player:
			# Remove the duplicate embedded player
			embedded_player.queue_free()
		_player = existing_player
		new_scene.add_child(_player)
	elif embedded_player:
		# No existing player, but scene has one - use it (already registered via _ready)
		_player = embedded_player
	else:
		# No player anywhere - instantiate one
		_instantiate_player(new_scene)

	# Position player (spawn point or saved position)
	_position_player_at_spawn()

	# Fade in
	_state = State.FADING_IN
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	tween.tween_callback(_finish_transition)


## Find a player node embedded in the scene
func _find_embedded_player(scene: Node) -> CharacterBody2D:
	# Look for node named "Player" or in "player" group
	var player_node := scene.get_node_or_null("Player")
	if player_node is CharacterBody2D:
		return player_node

	# Check for player group
	for child in scene.get_children():
		if child.is_in_group("player") and child is CharacterBody2D:
			return child

	return null


## Instantiate a new player when scene doesn't have one
func _instantiate_player(parent: Node) -> void:
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	if not player_scene:
		push_error("SceneManager: Failed to load player scene")
		return

	_player = player_scene.instantiate()
	parent.add_child(_player)


func _position_player_at_spawn() -> void:
	if not _player:
		return

	# If restoring from save, use saved position directly
	if _restoring_from_save:
		_player.global_position = _saved_position
		if _player.has_method("set_facing_direction"):
			_player.set_facing_direction(_saved_facing)
		_restoring_from_save = false

		# Snap camera to player immediately (skip smoothing)
		# Deferred so camera processes player's new position first
		var camera := _player.get_node_or_null("Camera2D") as Camera2D
		if camera:
			camera.reset_smoothing()
			camera.call_deferred("reset_smoothing")

		return

	# Find spawn point in new scene
	var spawn_points := get_tree().get_nodes_in_group("spawn_points")
	var target_spawn: Node2D = null

	for spawn in spawn_points:
		if spawn.has_method("get_spawn_id") and spawn.get_spawn_id() == _target_spawn_id:
			target_spawn = spawn
			break

	# Fallback to default spawn or first spawn found
	if not target_spawn:
		for spawn in spawn_points:
			if spawn.has_method("get_spawn_id"):
				if spawn.get_spawn_id() == "default":
					target_spawn = spawn
					break
		# Last resort: use first spawn point
		if not target_spawn and spawn_points.size() > 0:
			target_spawn = spawn_points[0]

	# Position player
	if target_spawn:
		_player.global_position = target_spawn.global_position
		# Also set facing direction from spawn point if available
		if target_spawn.has_method("get_facing_direction") and _player.has_method("set_facing_direction"):
			var facing: String = target_spawn.get_facing_direction()
			if facing != "":
				_player.set_facing_direction(facing)
	else:
		push_warning("No spawn point found for ID: %s" % _target_spawn_id)


func _finish_transition() -> void:
	_state = State.IDLE

	# Re-enable player input
	if _player:
		_player.set_physics_process(true)

	transition_completed.emit()


## Check if currently in a transition
func is_transitioning() -> bool:
	return _state != State.IDLE


## Load game from save file and restore player to saved position.
## Call this instead of loading a scene directly when continuing a saved game.
func load_from_save() -> bool:
	var game_state := get_node_or_null("/root/GameState")
	if not game_state:
		push_error("SceneManager: GameState autoload not found")
		return false

	if not game_state.has_save():
		return false

	if not game_state.load_game():
		return false

	var data: Dictionary = game_state.get_pending_load_data()

	if data.is_empty():
		return false

	var scene_path: String = data.get("player_scene", "")
	if scene_path.is_empty():
		return false

	# Store position data for after scene loads
	_saved_position = Vector2(
		data.get("player_position", {}).get("x", 0.0),
		data.get("player_position", {}).get("y", 0.0)
	)
	_saved_facing = data.get("player_facing", "down")
	_restoring_from_save = true

	# Load the saved scene
	_start_transition(scene_path)
	return true


## Saved position data for restore
var _saved_position: Vector2 = Vector2.ZERO
var _saved_facing: String = "down"
var _restoring_from_save: bool = false
