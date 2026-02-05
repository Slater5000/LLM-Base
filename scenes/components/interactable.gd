extends Area2D
class_name Interactable
## Base class for objects the player can interact with.
## Subclass this for NPCs, signs, items, etc.
##
## Override _on_interact() to define behavior when player presses E.

signal interacted

## Text shown when player can interact
@export var interact_prompt: String = "(E)"

## Whether this interactable is currently enabled
@export var enabled: bool = true

## Internal state
var _player_in_range: bool = false
var _prompt_control: Control = null
var _interact_cooldown: float = 0.0

## Cooldown duration after dialogue ends (prevents re-trigger)
const INTERACT_COOLDOWN: float = 0.2

## Prompt scene
var _prompt_scene: PackedScene = preload("res://scenes/ui/interact_prompt.tscn")


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Set up collision to detect player
	collision_layer = 0
	collision_mask = 1

	_create_prompt()


func _create_prompt() -> void:
	_prompt_control = _prompt_scene.instantiate()
	_prompt_control.prompt_text = interact_prompt
	_prompt_control.position = Vector2(-40, -40)
	_prompt_control.hide()
	add_child(_prompt_control)


func _process(delta: float) -> void:
	if not enabled:
		return

	# Handle cooldown
	if _interact_cooldown > 0.0:
		_interact_cooldown -= delta
		return

	if _player_in_range and not _is_dialogue_active():
		if Input.is_action_just_pressed("interact"):
			_on_interact()
			interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if not enabled:
		return

	if body.is_in_group("player"):
		_player_in_range = true
		if not _is_dialogue_active():
			_prompt_control.show()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		_prompt_control.hide()


## Override this in subclasses to define interaction behavior
func _on_interact() -> void:
	pass


## Check if dialogue is currently active (to hide prompt during dialogue)
func _is_dialogue_active() -> bool:
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager and dialogue_manager.has_method("is_dialogue_active"):
		return dialogue_manager.is_dialogue_active()
	return false


## Update prompt visibility based on dialogue state
func _update_prompt_visibility() -> void:
	if _player_in_range and not _is_dialogue_active():
		_prompt_control.show()
	else:
		_prompt_control.hide()
