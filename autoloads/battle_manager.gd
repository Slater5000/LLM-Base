extends Node
class_name BattleManagerClass
## BattleManager - Central coordinator for the combat system.
## Handles battle transitions, state management, and combat flow.

signal battle_starting(is_wild: bool)
signal battle_paused
signal battle_resumed
signal battle_ended(result: String)  # "victory", "defeat", "fled"

enum State {
	IDLE,
	TRANSITIONING_IN,
	ACTIVE,
	PAUSED,
	SWAPPING,
	FLEEING,
	VICTORY,
	DEFEAT,
	TRANSITIONING_OUT
}

## Current battle state
var _state: State = State.IDLE

## Battle context
var _is_wild_encounter: bool = false
var _was_scanned: bool = false
var _target_species: String = ""
var _flee_attempts: int = 0
var _actions_since_last_flee: int = 0

## Scene references
var _battle_scene: Node = null
var _return_scene_path: String = ""
var _return_spawn_id: String = "default"

## Battle scene path
const BATTLE_SCENE_PATH := "res://scenes/battle/battle_scene.tscn"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if _state == State.IDLE:
		return

	# Pause toggle with spacebar
	if event.is_action_pressed("pause_combat"):  # Spacebar
		if _state == State.ACTIVE:
			_pause_battle()
		elif _state == State.PAUSED:
			_resume_battle()
		get_viewport().set_input_as_handled()
		return

	# ESC to exit battle (temporary for testing)
	if event.is_action_pressed("ui_cancel"):
		if _state in [State.ACTIVE, State.PAUSED]:
			_end_battle("fled")
			get_viewport().set_input_as_handled()


## Start a wild encounter battle
## target_species: The species ID of the creature engaged
## was_scanned: True if player scanned before engaging (affects flee mechanics)
func start_wild_battle(target_species: String, was_scanned: bool) -> void:
	if _state != State.IDLE:
		push_warning("[BattleManager] Cannot start battle - already in battle")
		return

	print("[BattleManager] Starting wild battle: ", target_species, " (scanned: ", was_scanned, ")")

	_is_wild_encounter = true
	_was_scanned = was_scanned
	_target_species = target_species
	_flee_attempts = 0
	_actions_since_last_flee = 0

	# Store return location
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		_return_scene_path = scene_manager.get_current_scene_path()
		_return_spawn_id = "default"

	_state = State.TRANSITIONING_IN
	battle_starting.emit(true)

	# Transition to battle scene
	_load_battle_scene()


## Start a trainer battle
func start_trainer_battle(trainer_creatures: Array) -> void:
	if _state != State.IDLE:
		push_warning("[BattleManager] Cannot start battle - already in battle")
		return

	print("[BattleManager] Starting trainer battle")

	_is_wild_encounter = false
	_was_scanned = false
	_target_species = ""
	_flee_attempts = 0

	_state = State.TRANSITIONING_IN
	battle_starting.emit(false)

	_load_battle_scene()


func _load_battle_scene() -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("transition_to_battle"):
		scene_manager.transition_to_battle(BATTLE_SCENE_PATH)
	else:
		# Fallback: direct scene change
		_direct_load_battle()


func _direct_load_battle() -> void:
	var battle_scene_res := load(BATTLE_SCENE_PATH)
	if not battle_scene_res:
		push_error("[BattleManager] Failed to load battle scene")
		_state = State.IDLE
		return

	_battle_scene = battle_scene_res.instantiate()

	# Hide current scene and all its children (including CanvasLayers)
	var current_scene := get_tree().current_scene
	if current_scene:
		_hide_scene_recursive(current_scene)

	# Add battle scene
	get_tree().root.add_child(_battle_scene)

	# Setup battle
	_setup_battle()


## Recursively hide a scene and all CanvasLayer children
func _hide_scene_recursive(node: Node) -> void:
	# Hide CanvasLayer nodes
	if node is CanvasLayer:
		node.hide()
	# Hide visual nodes
	elif node is CanvasItem:
		node.hide()

	# Disable processing
	node.set_process(false)
	node.set_physics_process(false)

	# Recurse into children
	for child in node.get_children():
		_hide_scene_recursive(child)


## Recursively show a scene and all children
func _show_scene_recursive(node: Node) -> void:
	# Show CanvasLayer nodes
	if node is CanvasLayer:
		node.show()
	# Show visual nodes
	elif node is CanvasItem:
		node.show()

	# Enable processing
	node.set_process(true)
	node.set_physics_process(true)

	# Recurse into children
	for child in node.get_children():
		_show_scene_recursive(child)


func _setup_battle() -> void:
	if _battle_scene and _battle_scene.has_method("setup"):
		_battle_scene.setup(_target_species, _is_wild_encounter, _was_scanned)

	_state = State.ACTIVE
	print("[BattleManager] Battle active")


func _pause_battle() -> void:
	_state = State.PAUSED
	get_tree().paused = true
	battle_paused.emit()
	print("[BattleManager] Battle paused")


func _resume_battle() -> void:
	_state = State.ACTIVE
	get_tree().paused = false
	battle_resumed.emit()
	print("[BattleManager] Battle resumed")


func _end_battle(result: String) -> void:
	print("[BattleManager] Battle ended: ", result)
	_state = State.TRANSITIONING_OUT

	# Ensure game is unpaused
	get_tree().paused = false

	# Clean up battle scene
	if _battle_scene and is_instance_valid(_battle_scene):
		_battle_scene.queue_free()
		_battle_scene = null

	# Restore previous scene
	var current_scene := get_tree().current_scene
	if current_scene:
		_show_scene_recursive(current_scene)

	_state = State.IDLE
	battle_ended.emit(result)


## Attempt to flee from wild encounter
func attempt_flee() -> bool:
	if not _is_wild_encounter:
		print("[BattleManager] Cannot flee from trainer battles")
		return false

	if _actions_since_last_flee < 1 and _flee_attempts > 0:
		print("[BattleManager] Must take an action before fleeing again")
		return false

	_flee_attempts += 1
	_actions_since_last_flee = 0

	var chance := _calculate_flee_chance()
	var roll := randf()

	print("[BattleManager] Flee attempt ", _flee_attempts, " - chance: ", chance, " roll: ", roll)

	if roll < chance:
		_end_battle("fled")
		return true
	else:
		# Reset action bars unless first attempt after scanning
		if not (_flee_attempts == 1 and _was_scanned):
			_reset_player_action_bars()
		return false


func _calculate_flee_chance() -> float:
	# TODO: Get difficulty from target creature
	var difficulty := "medium"

	match difficulty:
		"easy":
			return minf(0.8 + (_flee_attempts - 1) * 0.2, 1.0)
		"medium":
			return minf(0.5 + (_flee_attempts - 1) * 0.2, 1.0)
		"hard":
			return minf(0.2 + (_flee_attempts - 1) * 0.2, 1.0)

	return 0.5


func _reset_player_action_bars() -> void:
	if _battle_scene and _battle_scene.has_method("reset_player_action_bars"):
		_battle_scene.reset_player_action_bars()


## Called when a player creature takes an action
func on_player_action() -> void:
	_actions_since_last_flee += 1


## Toggle pause state
func toggle_pause() -> void:
	if _state == State.ACTIVE:
		_pause_battle()
	elif _state == State.PAUSED:
		_resume_battle()


## Check if battle is currently active
func is_in_battle() -> bool:
	return _state != State.IDLE


## Check if battle is paused
func is_paused() -> bool:
	return _state == State.PAUSED


## Get current battle state
func get_state() -> State:
	return _state
