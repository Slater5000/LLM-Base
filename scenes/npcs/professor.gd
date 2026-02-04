extends NPC
class_name ProfessorOak
## Professor Oak - Gives the player their first creature.
## Tracks whether player has spoken to him before via story flags.

const FLAG_MET_PROFESSOR := "met_professor"

## Dialogue for first meeting
var first_meeting_dialogue: Array[String] = [
	"Ah, a new trainer! Welcome!",
	"I'm Professor Oak. I study creatures in this region.",
	"Would you like to receive your first creature?",
	"Come visit me in the lab when you're ready!"
]

## Dialogue after first meeting
var return_dialogue: Array[String] = [
	"Welcome back!",
	"Ready to choose your first creature?",
	"The lab is just south of here."
]


func _ready() -> void:
	super._ready()
	_update_dialogue()


func _update_dialogue() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.get_story_flag(FLAG_MET_PROFESSOR):
		dialogue_lines = return_dialogue
	else:
		dialogue_lines = first_meeting_dialogue


func _on_interact() -> void:
	# Set the flag on first interaction
	var game_state := get_node_or_null("/root/GameState")
	if game_state and not game_state.get_story_flag(FLAG_MET_PROFESSOR):
		game_state.set_story_flag(FLAG_MET_PROFESSOR, true)

	# Call parent to show dialogue
	super._on_interact()

	# Update dialogue for next time
	_update_dialogue()
