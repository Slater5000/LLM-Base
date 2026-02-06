extends PanelContainer
class_name MovePanel
## Displays a single creature's moves for selection in battle.

signal move_selected(panel: MovePanel, move_index: int)

## The combatant this panel represents
var _combatant: Combatant = null

## Visual references
@onready var creature_name_label: Label = $VBox/CreatureName
@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var moves_container: VBoxContainer = $VBox/MovesContainer

## Move button references
var _move_buttons: Array[Button] = []

## Element colors for move buttons
const ELEMENT_COLORS := {
	"fire": Color(0.85, 0.2, 0.15),
	"water": Color(0.2, 0.4, 0.85),
	"earth": Color(0.2, 0.55, 0.2),
	"air": Color(0.85, 0.75, 0.1)
}


func _ready() -> void:
	# Create 3 move buttons
	for i in range(3):
		var btn := Button.new()
		btn.name = "Move" + str(i)
		btn.custom_minimum_size = Vector2(120, 28)
		btn.pressed.connect(_on_move_pressed.bind(i))
		moves_container.add_child(btn)
		_move_buttons.append(btn)


## Setup the panel with a combatant
func setup(combatant: Combatant) -> void:
	_combatant = combatant

	if not combatant or not combatant.creature:
		_clear_display()
		return

	var creature := combatant.creature
	var species := GameState.get_species(creature.species_id)

	# Set creature name
	var display_name := creature.nickname if creature.nickname != "" else ""
	if display_name == "" and species:
		display_name = species.display_name
	creature_name_label.text = display_name + " Lv" + str(creature.level)

	# Set HP bar
	hp_bar.max_value = creature.max_hp
	hp_bar.value = creature.current_hp

	# Setup move buttons
	for i in range(3):
		if i < creature.active_moves.size():
			var move_id := creature.active_moves[i]
			var move_data := GameState.get_move(move_id)
			if move_data:
				_move_buttons[i].text = move_data.display_name
				_move_buttons[i].disabled = false
				_move_buttons[i].visible = true

				# Color based on element
				var element := move_data.element if move_data.element != "" else "fire"
				if ELEMENT_COLORS.has(element):
					_move_buttons[i].modulate = ELEMENT_COLORS[element]
				else:
					_move_buttons[i].modulate = Color.WHITE
			else:
				_move_buttons[i].text = move_id
				_move_buttons[i].disabled = true
				_move_buttons[i].visible = true
		else:
			_move_buttons[i].visible = false


func _clear_display() -> void:
	creature_name_label.text = "Empty"
	hp_bar.value = 0
	for btn in _move_buttons:
		btn.visible = false


## Update HP display (called when creature takes damage/heals)
func update_hp() -> void:
	if _combatant and _combatant.creature:
		hp_bar.value = _combatant.creature.current_hp


## Highlight the currently selected move
func set_selected_move(index: int) -> void:
	for i in range(_move_buttons.size()):
		if i == index:
			_move_buttons[i].add_theme_color_override("font_color", Color.YELLOW)
		else:
			_move_buttons[i].remove_theme_color_override("font_color")


## Enable/disable all move buttons (e.g., during swap freeze)
func set_moves_enabled(enabled: bool) -> void:
	for btn in _move_buttons:
		btn.disabled = not enabled


func _on_move_pressed(move_index: int) -> void:
	if _combatant:
		_combatant.selected_move_index = move_index
		set_selected_move(move_index)
		move_selected.emit(self, move_index)
