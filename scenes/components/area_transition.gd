@tool
extends Area2D
class_name AreaTransition
## Triggers scene transitions when player enters/interacts.
## Supports both automatic (map edges) and interactive (doors) transitions.
##
## Usage:
## - For doors: Set trigger_mode to INTERACT, player presses E to enter
## - For map edges: Set trigger_mode to AUTOMATIC, triggers on contact

## How the transition is triggered
enum TriggerMode {
	AUTOMATIC,  ## Triggers immediately when player enters (map edges)
	INTERACT    ## Requires player to press interact key (doors, stairs)
}

## Path to the scene to load
@export_file("*.tscn") var target_scene: String = ""

## Spawn point ID in the target scene
@export var target_spawn_id: String = "default"

## How this transition is triggered
@export var trigger_mode: TriggerMode = TriggerMode.INTERACT

## For edge transitions: which direction player is coming from
## Used to auto-calculate spawn point on other side
@export_enum("none", "left", "right", "top", "bottom") var edge_direction: String = "none"

## Visual indicator shown when player can interact (for INTERACT mode)
@export var show_interact_prompt: bool = true

## Editor visualization
@export var editor_color: Color = Color(0.8, 0.4, 0.2, 0.5)

## Internal state
var _player_in_area: bool = false
var _prompt_label: Label = null


func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Set up collision
	collision_layer = 0
	collision_mask = 1  # Detect player (layer 1)

	# Create interact prompt (hidden by default)
	if not Engine.is_editor_hint() and trigger_mode == TriggerMode.INTERACT and show_interact_prompt:
		_create_interact_prompt()


func _create_interact_prompt() -> void:
	_prompt_label = Label.new()
	_prompt_label.text = "E"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.position = Vector2(-8, -50)
	_prompt_label.z_index = 100
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color.BLACK)
	_prompt_label.add_theme_color_override("font_outline_color", Color.WHITE)
	_prompt_label.add_theme_constant_override("outline_size", 3)
	_prompt_label.hide()
	add_child(_prompt_label)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	# Check for interact input when player is in area
	if _player_in_area and trigger_mode == TriggerMode.INTERACT:
		if Input.is_action_just_pressed("interact"):
			_trigger_transition()


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if body.is_in_group("player") or body.name == "Player":
		_player_in_area = true

		if trigger_mode == TriggerMode.AUTOMATIC:
			_trigger_transition()
		elif _prompt_label:
			_prompt_label.show()


func _on_body_exited(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if body.is_in_group("player") or body.name == "Player":
		_player_in_area = false
		if _prompt_label:
			_prompt_label.hide()


func _trigger_transition() -> void:
	if target_scene.is_empty():
		push_error("AreaTransition: No target scene set!")
		return

	# Use SceneManager for transition
	var scene_manager := get_node_or_null("/root/SceneManager")
	if not scene_manager:
		push_error("AreaTransition: SceneManager autoload not found!")
		return

	if edge_direction != "none":
		scene_manager.transition_to_edge(target_scene, edge_direction)
	else:
		scene_manager.transition_to(target_scene, target_spawn_id)


func _draw() -> void:
	if Engine.is_editor_hint():
		# Draw area bounds
		var collision_shape := get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape:
			var shape = collision_shape.shape
			if shape is RectangleShape2D:
				var rect := Rect2(-shape.size / 2, shape.size)
				draw_rect(rect, editor_color, true)
				draw_rect(rect, editor_color.lightened(0.3), false, 2.0)

		# Draw label
		var mode_text := "AUTO" if trigger_mode == TriggerMode.AUTOMATIC else "INTERACT"
		var label_text := "%s\n→ %s" % [mode_text, target_spawn_id]
		draw_string(ThemeDB.fallback_font, Vector2(-30, -20), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 8, Color.WHITE)
