class_name MoveData extends Resource
## Defines a single move that creatures can use in battle.
## Create .tres files in the editor to define each move.

@export var move_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_enum("fire", "water", "earth", "air")
var element: String = "fire"

@export_group("Targeting")
@export_enum("single_enemy", "all_enemies", "single_ally", "all_allies", "self")
var target_type: String = "single_enemy"

@export_group("Effect")
@export_enum("damage", "heal", "shield", "buff", "debuff")
var effect_type: String = "damage"

@export var power: int = 50
## For buffs/debuffs: percentage change (0.2 = +20%, -0.2 = -20%)
@export var stat_modifier: float = 0.0
## Which stat is affected for buffs/debuffs (none for damage/heal moves)
@export_enum("none", "attack", "defense", "speed", "bar_fill_rate")
var stat_affected: String = "none"
## 0 = instant effect, >0 = lasts N turns
@export var duration_turns: int = 0

@export_group("Action Bar")
## Multiplier for action bar fill rate (1.0 = normal speed)
@export var speed_modifier: float = 1.0


## Get display name, falling back to move_id if empty
func get_display_name() -> String:
	return display_name if display_name != "" else move_id


## Check if this move targets enemies
func targets_enemies() -> bool:
	return target_type in ["single_enemy", "all_enemies"]


## Check if this move targets allies
func targets_allies() -> bool:
	return target_type in ["single_ally", "all_allies", "self"]


## Check if this is a damaging move
func is_damaging() -> bool:
	return effect_type == "damage"


## Check if this is a healing move
func is_healing() -> bool:
	return effect_type == "heal"


## Check if this is a shield move
func is_shield() -> bool:
	return effect_type == "shield"


## Check if this is a buff
func is_buff() -> bool:
	return effect_type == "buff"


## Check if this is a debuff
func is_debuff() -> bool:
	return effect_type == "debuff"
