extends Interactable
class_name NPC
## Base class for NPCs that can talk to the player.
## Has a sprite and dialogue. Extend for specific NPCs.

## Dialogue lines to show when interacted with
@export var dialogue_lines: Array[String] = ["Hello!"]

## NPC display name (for future use with name labels)
@export var npc_name: String = "NPC"

## Reference to sprite (set in scene)
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super._ready()
	interact_prompt = "[E] Talk"
	_prompt_label.text = interact_prompt


func _on_interact() -> void:
	if dialogue_lines.is_empty():
		return

	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		# Convert typed array to regular array for the function call
		var lines: Array = []
		for line in dialogue_lines:
			lines.append(line)
		dialogue_manager.show_dialogue(lines)
		_prompt_label.hide()

		# Re-show prompt when dialogue ends
		dialogue_manager.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)


func _on_dialogue_finished() -> void:
	# Set cooldown to prevent immediate re-trigger
	_interact_cooldown = INTERACT_COOLDOWN
	if _player_in_range:
		_prompt_label.show()
