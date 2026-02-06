extends NPC
class_name ProfessorOak
## Professor Oak - Gives the player their first creature.
## Tracks whether player has spoken to him before via story flags.

const FLAG_MET_PROFESSOR := "met_professor"
const FLAG_RECEIVED_STARTER := "received_starter"

## Dialogue for first meeting (before receiving creature)
var first_meeting_dialogue: Array[String] = [
	"Ah, a new trainer! Welcome!",
	"I'm Professor Oak. I study creatures in this region.",
	"Here, take this creature as your first partner!",
]

## Dialogue for receiving the creature
var receive_creature_dialogue: Array[String] = [
	"This is Primordius, the First.",
	"An ancient being, forged from meteorite and carved with unknowable glyphs.",
	"Take good care of it!",
]

## Dialogue after receiving creature
var return_dialogue: Array[String] = [
	"How is Primordius doing?",
	"That creature has been with us since the beginning of time.",
	"Treat it well, trainer!"
]


func _ready() -> void:
	super._ready()
	_update_dialogue()


func _update_dialogue() -> void:
	if GameState.get_story_flag(FLAG_RECEIVED_STARTER):
		dialogue_lines = return_dialogue
	elif GameState.get_story_flag(FLAG_MET_PROFESSOR):
		dialogue_lines = receive_creature_dialogue
	else:
		dialogue_lines = first_meeting_dialogue


func _on_interact() -> void:
	var should_give_creature := false

	# First interaction - set met flag
	if not GameState.get_story_flag(FLAG_MET_PROFESSOR):
		GameState.set_story_flag(FLAG_MET_PROFESSOR, true)
		should_give_creature = true
	# Second interaction - give the creature
	elif not GameState.get_story_flag(FLAG_RECEIVED_STARTER):
		should_give_creature = true

	# Call parent to show dialogue
	super._on_interact()

	# Give creature after dialogue
	if should_give_creature and not GameState.get_story_flag(FLAG_RECEIVED_STARTER):
		_give_starter_creature()

	# Update dialogue for next time
	_update_dialogue()


func _give_starter_creature() -> void:
	# Create Primordius at level 10
	var primordius := GameState.create_creature("legendary_earth_gorilla", 10, "Professor Oak's Lab")
	if primordius:
		GameState.add_to_party(primordius)
		GameState.set_story_flag(FLAG_RECEIVED_STARTER, true)
		print("Professor gave you Primordius!")
