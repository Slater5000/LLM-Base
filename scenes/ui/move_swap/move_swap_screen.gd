extends CanvasLayer
class_name MoveSwapScreen
## Full screen for selecting which 3 moves are active from the creature's learned moves.
## Shows all 9 learnable moves, grayed out if not yet learned.

signal closed

var _creature: CreatureInstance
var _creature_index: int
var _species: CreatureSpecies
var _selected_moves: Array[String] = []
var _move_cards: Dictionary = {}  # move_id -> MoveCard

var _background: ColorRect
var _panel: NinePatchRect
var _title_label: Label
var _grid: GridContainer
var _description_panel: NinePatchRect
var _description_name: Label
var _description_text: Label
var _selection_container: VBoxContainer
var _selection_labels: Array[Label] = []

const PANEL_WIDTH := 340
const PANEL_HEIGHT := 340
const MAX_ACTIVE_MOVES := 3

const ELEMENT_COLORS := {
	"fire": Color(0.85, 0.2, 0.15),
	"water": Color(0.2, 0.4, 0.85),
	"earth": Color(0.2, 0.55, 0.2),
	"air": Color(0.85, 0.75, 0.1)
}


func setup(creature: CreatureInstance, creature_index: int) -> void:
	_creature = creature
	_creature_index = creature_index
	_species = GameState.get_species(creature.species_id)
	_selected_moves = creature.active_moves.duplicate()


func _ready() -> void:
	layer = 111  # Above party screen
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	GameState.open_menu("move_swap_screen", true)

	_create_ui()
	_populate_moves()
	_update_selection_display()
	_show_first_move_description()


func _create_ui() -> void:
	# Background overlay
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.6)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Main panel
	var panel_container := Control.new()
	panel_container.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	panel_container.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	panel_container.clip_contents = true
	center.add_child(panel_container)

	# Panel background
	_panel = NinePatchRect.new()
	_panel.texture = preload("res://assets/sprites/ui/panels/panel_frame_48x40.png")
	_panel.patch_margin_left = 8
	_panel.patch_margin_top = 8
	_panel.patch_margin_right = 8
	_panel.patch_margin_bottom = 8
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.add_child(_panel)

	# Content margin
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Title row - only creature name in element color
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 0)
	vbox.add_child(title_row)

	# "MOVES - " in black with white outline
	var prefix_label := Label.new()
	prefix_label.text = "MOVES - "
	prefix_label.add_theme_font_size_override("font_size", 10)
	prefix_label.add_theme_color_override("font_color", Color.BLACK)
	prefix_label.add_theme_color_override("font_outline_color", Color.WHITE)
	prefix_label.add_theme_constant_override("outline_size", 4)
	title_row.add_child(prefix_label)

	# Creature name in element color with black outline
	var name_label := Label.new()
	name_label.text = _creature.get_display_name()
	name_label.add_theme_font_size_override("font_size", 10)
	var element_color: Color = ELEMENT_COLORS.get(_species.element, Color.BLACK)
	name_label.add_theme_color_override("font_color", element_color)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_label.add_theme_constant_override("outline_size", 4)
	title_row.add_child(name_label)

	# " Lv. X" in black with white outline
	var level_label := Label.new()
	level_label.text = " Lv. %d" % _creature.level
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.add_theme_color_override("font_color", Color.BLACK)
	level_label.add_theme_color_override("font_outline_color", Color.WHITE)
	level_label.add_theme_constant_override("outline_size", 4)
	title_row.add_child(level_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Grid for move cards (3 columns)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(_grid)

	# Description panel
	var desc_container := Control.new()
	desc_container.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(desc_container)

	_description_panel = NinePatchRect.new()
	_description_panel.texture = preload("res://assets/sprites/ui/panels/panel_frame_48x40.png")
	_description_panel.patch_margin_left = 8
	_description_panel.patch_margin_top = 8
	_description_panel.patch_margin_right = 8
	_description_panel.patch_margin_bottom = 8
	_description_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_container.add_child(_description_panel)

	var desc_margin := MarginContainer.new()
	desc_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_margin.add_theme_constant_override("margin_left", 8)
	desc_margin.add_theme_constant_override("margin_top", 8)
	desc_margin.add_theme_constant_override("margin_right", 8)
	desc_margin.add_theme_constant_override("margin_bottom", 4)
	desc_container.add_child(desc_margin)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 2)
	desc_margin.add_child(desc_vbox)

	_description_name = Label.new()
	_description_name.text = ""
	_description_name.add_theme_font_size_override("font_size", 9)
	_description_name.add_theme_color_override("font_color", Color.BLACK)
	desc_vbox.add_child(_description_name)

	_description_text = Label.new()
	_description_text.text = ""
	_description_text.add_theme_font_size_override("font_size", 8)
	_description_text.add_theme_color_override("font_color", Color.BLACK)
	_description_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_description_text.custom_minimum_size = Vector2(0, 30)
	desc_vbox.add_child(_description_text)

	# Selection section - vertical list
	_selection_container = VBoxContainer.new()
	_selection_container.add_theme_constant_override("separation", 2)
	vbox.add_child(_selection_container)

	# Selection header
	var sel_label := Label.new()
	sel_label.text = "Active Moves:"
	sel_label.add_theme_font_size_override("font_size", 9)
	sel_label.add_theme_color_override("font_color", Color.BLACK)
	sel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selection_container.add_child(sel_label)

	# Three slots in vertical list
	for i in MAX_ACTIVE_MOVES:
		var slot_label := Label.new()
		slot_label.text = "[Empty]"
		slot_label.add_theme_font_size_override("font_size", 9)
		slot_label.add_theme_color_override("font_color", Color.BLACK)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_selection_container.add_child(slot_label)
		_selection_labels.append(slot_label)

	# Spacer to push buttons down
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var close_btn := _create_styled_button("CLOSE")
	close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(close_btn)


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 20)
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _populate_moves() -> void:
	# Get all learnable moves for the species
	var learnable := _species.learnable_moves
	var learn_levels := _species.move_learn_levels

	for i in learnable.size():
		var move_id: String = learnable[i]
		var learn_level: int = learn_levels[i] if i < learn_levels.size() else 1
		var move_data: MoveData = GameState.get_move(move_id)
		var is_learned: bool = move_id in _creature.learned_moves

		var card := MoveCard.new()
		card.setup(move_id, move_data, is_learned, learn_level)
		card.pressed.connect(_on_move_card_pressed)
		card.hovered.connect(_on_move_card_hovered)
		card.unhovered.connect(_on_move_card_unhovered)
		_grid.add_child(card)
		_move_cards[move_id] = card

		# Mark as selected if in active moves
		if move_id in _selected_moves:
			card.set_selected(true)

	# Fill remaining slots if less than 9 moves (shouldn't happen but just in case)
	var remaining := 9 - learnable.size()
	for _j in remaining:
		var placeholder := Control.new()
		placeholder.custom_minimum_size = Vector2(MoveCard.CARD_WIDTH, MoveCard.CARD_HEIGHT)
		_grid.add_child(placeholder)


func _on_move_card_pressed(move_id: String) -> void:
	if move_id in _selected_moves:
		# Don't allow deselecting last move
		if _selected_moves.size() <= 1:
			return
		# Deselect
		_selected_moves.erase(move_id)
		_move_cards[move_id].set_selected(false)
	else:
		# Select (if room)
		if _selected_moves.size() < MAX_ACTIVE_MOVES:
			_selected_moves.append(move_id)
			_move_cards[move_id].set_selected(true)

	_update_selection_display()
	_auto_save()


func _update_selection_display() -> void:
	for i in MAX_ACTIVE_MOVES:
		if i < _selected_moves.size():
			var move_id: String = _selected_moves[i]
			var move_data: MoveData = GameState.get_move(move_id)
			_selection_labels[i].text = move_data.display_name if move_data else move_id
		else:
			_selection_labels[i].text = "[Empty]"


func _on_move_card_hovered(move_id: String) -> void:
	var is_learned: bool = move_id in _creature.learned_moves
	if not is_learned:
		_description_name.text = "???"
		_description_text.text = "Learn this move to see its details."
		return

	var move_data: MoveData = GameState.get_move(move_id)
	if move_data:
		_description_name.text = "%s - %s" % [move_data.display_name, _get_move_stat_text(move_data)]
		_description_text.text = move_data.description
	else:
		_description_name.text = move_id
		_description_text.text = "No description available."


func _get_move_stat_text(move_data: MoveData) -> String:
	# For buffs/debuffs, show duration instead of power
	if move_data.effect_type in ["buff", "debuff"]:
		if move_data.duration_turns == 1:
			return "1 turn"
		else:
			return "%d turns" % move_data.duration_turns
	else:
		return "Power: %d" % move_data.power


func _on_move_card_unhovered() -> void:
	# Keep showing last hovered move's description - don't reset
	pass


func _show_first_move_description() -> void:
	# Show description of first selected move on open
	if _selected_moves.size() > 0:
		var move_id: String = _selected_moves[0]
		var move_data: MoveData = GameState.get_move(move_id)
		if move_data:
			_description_name.text = "%s - %s" % [move_data.display_name, _get_move_stat_text(move_data)]
			_description_text.text = move_data.description


func _auto_save() -> void:
	# Auto-save moves whenever selection changes
	if _selected_moves.size() > 0:
		_creature.set_active_moves(_selected_moves)
		GameState.party_changed.emit()


func _on_close_pressed() -> void:
	_close()


func _close() -> void:
	GameState.close_menu("move_swap_screen")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("open_menu"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
