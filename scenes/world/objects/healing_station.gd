extends Interactable
class_name HealingStation
## Healing Station - Restores all party creatures to full HP.
## Player approaches and presses E to heal.

@onready var sprite: Sprite2D = $Sprite2D

## Healing dialogue
var heal_dialogue: Array[String] = [
	"Your creatures have been restored to full health!",
]

var no_creatures_dialogue: Array[String] = [
	"You don't have any creatures to heal.",
]


func _ready() -> void:
	super._ready()
	interact_prompt = "(E)"


func _on_interact() -> void:
	var party := GameState.get_party()
	var has_creatures := false
	var needed_healing := false

	# Check if player has creatures and if any need healing
	for creature in party:
		if creature != null:
			has_creatures = true
			if creature.current_hp < creature.max_hp:
				needed_healing = true
				break

	if not has_creatures:
		_show_dialogue(no_creatures_dialogue)
		return

	# Heal all creatures
	for creature in party:
		if creature != null:
			creature.current_hp = creature.max_hp

	# Save the game after healing
	GameState.save_game()

	# Show confirmation
	if needed_healing:
		_show_dialogue(heal_dialogue)
	else:
		_show_dialogue(["Your creatures are already at full health!"])


func _show_dialogue(lines: Array) -> void:
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.show_dialogue(lines)
		_prompt_control.hide()
		dialogue_manager.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)


func _on_dialogue_finished() -> void:
	_interact_cooldown = INTERACT_COOLDOWN
	if _player_in_range:
		_prompt_control.show()
