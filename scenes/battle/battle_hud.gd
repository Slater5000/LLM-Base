extends Control
class_name BattleHUD
## Battle HUD - displays move panels for player creatures and action buttons.

signal swap_requested
signal flee_requested
signal move_selected(combatant: Combatant, move_index: int)

## References
@onready var move_panels_container: HBoxContainer = $BottomPanel/HBox/MovePanels
@onready var swap_button: Button = $BottomPanel/HBox/ActionButtons/SwapButton
@onready var flee_button: Button = $BottomPanel/HBox/ActionButtons/FleeButton
@onready var pause_label: Label = $TopBar/PauseLabel

## Move panel scene
const MOVE_PANEL_SCENE := preload("res://scenes/battle/move_panel.tscn")

## Active move panels (one per player combatant)
var _move_panels: Array[MovePanel] = []

## Whether this is a wild encounter (flee enabled)
var _is_wild_encounter: bool = true


func _ready() -> void:
	# Connect button signals
	swap_button.pressed.connect(_on_swap_pressed)
	flee_button.pressed.connect(_on_flee_pressed)

	# Hide pause label initially
	pause_label.hide()

	# Connect to BattleManager signals
	var battle_manager := get_node_or_null("/root/BattleManager")
	if battle_manager:
		battle_manager.battle_paused.connect(_on_battle_paused)
		battle_manager.battle_resumed.connect(_on_battle_resumed)


## Setup the HUD with player combatants
func setup(combatants: Array[Combatant], is_wild: bool) -> void:
	_is_wild_encounter = is_wild

	# Clear existing panels
	for panel in _move_panels:
		panel.queue_free()
	_move_panels.clear()

	# Create a panel for each combatant
	for combatant in combatants:
		var panel: MovePanel = MOVE_PANEL_SCENE.instantiate()
		move_panels_container.add_child(panel)
		panel.setup(combatant)
		panel.move_selected.connect(_on_panel_move_selected)
		_move_panels.append(panel)

		# Connect to combatant signals for HP updates
		combatant.took_damage.connect(_on_combatant_took_damage.bind(panel))
		combatant.healed.connect(_on_combatant_healed.bind(panel))

	# Configure flee button visibility
	flee_button.visible = is_wild


## Update a specific combatant's panel (after swap)
func update_combatant(slot_index: int, combatant: Combatant) -> void:
	if slot_index >= 0 and slot_index < _move_panels.size():
		_move_panels[slot_index].setup(combatant)


## Update all HP displays
func update_all_hp() -> void:
	for panel in _move_panels:
		panel.update_hp()


## Enable/disable move selection for a specific slot
func set_slot_enabled(slot_index: int, enabled: bool) -> void:
	if slot_index >= 0 and slot_index < _move_panels.size():
		_move_panels[slot_index].set_moves_enabled(enabled)


func _on_swap_pressed() -> void:
	swap_requested.emit()


func _on_flee_pressed() -> void:
	flee_requested.emit()


func _on_panel_move_selected(panel: MovePanel, move_index: int) -> void:
	# Find which combatant this panel represents
	var panel_index := _move_panels.find(panel)
	if panel_index >= 0:
		# The panel already set selected_move_index on the combatant
		# Emit signal for BattleScene to handle
		move_selected.emit(panel._combatant, move_index)


func _on_combatant_took_damage(_combatant: Combatant, _amount: int, panel: MovePanel) -> void:
	panel.update_hp()


func _on_combatant_healed(_combatant: Combatant, _amount: int, panel: MovePanel) -> void:
	panel.update_hp()


func _on_battle_paused() -> void:
	pause_label.show()
	# Disable all buttons while paused
	swap_button.disabled = true
	flee_button.disabled = true
	for panel in _move_panels:
		panel.set_moves_enabled(false)


func _on_battle_resumed() -> void:
	pause_label.hide()
	# Re-enable buttons
	swap_button.disabled = false
	flee_button.disabled = false
	for panel in _move_panels:
		panel.set_moves_enabled(true)
