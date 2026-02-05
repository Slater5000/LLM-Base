class_name CreatureSpecies extends Resource
## Defines a creature species - the template for all instances of this creature.
## Create .tres files in the editor to define each species.

@export var species_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

@export_enum("fire", "water", "earth", "air")
var element: String = "fire"

@export_group("Base Stats")
@export var base_hp: int = 40
@export var base_attack: int = 50
@export var base_defense: int = 40
@export var base_speed: int = 60

@export_group("Evolution")
@export var evolves_from: String = ""
@export var evolves_at_level: int = 0
@export var evolves_to: String = ""

@export_group("Moves")
## Move IDs this species can learn (up to 9 from its element's 30-move pool)
@export var learnable_moves: Array[String] = []
## Level at which each move is learned (parallel array with learnable_moves)
@export var move_learn_levels: Array[int] = []

@export_group("Visuals")
@export var color_primary: Color = Color.WHITE
@export var color_secondary: Color = Color.GRAY


## Get display name, falling back to species_id if empty
func get_display_name() -> String:
	return display_name if display_name != "" else species_id


## Get moves available at a given level
func get_available_moves(level: int) -> Array[String]:
	var available: Array[String] = []
	for i in learnable_moves.size():
		if i < move_learn_levels.size() and move_learn_levels[i] <= level:
			available.append(learnable_moves[i])
	return available


## Check if this species evolves
func can_evolve() -> bool:
	return evolves_to != "" and evolves_at_level > 0


## Check if ready to evolve at given level
func should_evolve(level: int) -> bool:
	return can_evolve() and level >= evolves_at_level
