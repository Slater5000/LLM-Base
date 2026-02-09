extends CanvasLayer
class_name DetailsScreen
## Full screen showing detailed creature information.
## XP progress, current stats, caught info, moves learned, active moves, cosmetic form toggle.

signal closed

var _creature: CreatureInstance
var _creature_index: int
var _species: CreatureSpecies
var _available_forms: Array[int] = []
var _current_form_index: int = 0

var _background: ColorRect
var _panel: NinePatchRect
var _sprite_texture: TextureRect
var _sprite_label: Label
var _form_label: Label
var _form_left_btn: Button
var _form_right_btn: Button
var _name_label: Label
var _level_xp_label: Label
var _stats_container: VBoxContainer
var _caught_label: Label
var _date_label: Label
var _moves_learned_label: Label
var _active_moves_container: VBoxContainer

const PANEL_WIDTH := 340
const PANEL_HEIGHT := 320
const SPRITE_SIZE := 130

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
	_available_forms = _get_available_forms()
	_current_form_index = _available_forms.find(creature.cosmetic_form)
	if _current_form_index == -1:
		_current_form_index = 0


func _get_available_forms() -> Array[int]:
	var forms: Array[int] = [0]  # Base form always available
	if _species.evolves_to != "":
		forms.append(1)
		# Check if evolution has its own evolution
		var evo_species := GameState.get_species(_species.evolves_to)
		if evo_species and evo_species.evolves_to != "":
			forms.append(2)
	return forms


func _ready() -> void:
	layer = 111  # Above party screen
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	GameState.open_menu("details_screen", true)

	_create_ui()
	_populate_data()


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
	margin.clip_contents = true
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel_container.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)

	# Header: Name + Level + XP
	_create_header(main_vbox)

	# Separator
	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Main content: Left (sprite + form) | Right (stats)
	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 12)
	main_vbox.add_child(content_hbox)

	_create_left_column(content_hbox)
	_create_right_column(content_hbox)

	# Separator
	var sep2 := HSeparator.new()
	main_vbox.add_child(sep2)

	# Caught info + Moves learned
	_create_info_section(main_vbox)

	# Separator
	var sep3 := HSeparator.new()
	main_vbox.add_child(sep3)

	# Active moves
	_create_moves_section(main_vbox)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer)

	# Close button
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(btn_row)

	var close_btn := _create_styled_button("CLOSE")
	close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(close_btn)


func _create_header(parent: VBoxContainer) -> void:
	# Name row with element
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 8)
	parent.add_child(name_row)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_constant_override("outline_size", 4)
	_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	name_row.add_child(_name_label)

	# Level and XP on same line
	_level_xp_label = Label.new()
	_level_xp_label.add_theme_font_size_override("font_size", 16)
	_level_xp_label.add_theme_color_override("font_color", Color.BLACK)
	_level_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(_level_xp_label)


func _create_left_column(parent: HBoxContainer) -> void:
	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 4)
	parent.add_child(left_vbox)

	# Sprite container
	var sprite_container := Control.new()
	sprite_container.custom_minimum_size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
	left_vbox.add_child(sprite_container)

	_sprite_texture = TextureRect.new()
	_sprite_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite_texture.visible = false
	sprite_container.add_child(_sprite_texture)

	_sprite_label = Label.new()
	_sprite_label.text = "?"
	_sprite_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sprite_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sprite_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_sprite_label.add_theme_font_size_override("font_size", 32)
	_sprite_label.add_theme_color_override("font_color", Color.BLACK)
	sprite_container.add_child(_sprite_label)

	# Form selector (only show if multiple forms available)
	var form_row := HBoxContainer.new()
	form_row.alignment = BoxContainer.ALIGNMENT_CENTER
	form_row.add_theme_constant_override("separation", 4)
	left_vbox.add_child(form_row)

	_form_left_btn = Button.new()
	_form_left_btn.text = "<"
	_form_left_btn.custom_minimum_size = Vector2(20, 16)
	_form_left_btn.add_theme_font_size_override("font_size", 16)
	_form_left_btn.pressed.connect(_on_form_left)
	form_row.add_child(_form_left_btn)

	_form_label = Label.new()
	_form_label.text = "Base"
	_form_label.add_theme_font_size_override("font_size", 16)
	_form_label.add_theme_color_override("font_color", Color.BLACK)
	_form_label.custom_minimum_size = Vector2(50, 0)
	_form_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form_row.add_child(_form_label)

	_form_right_btn = Button.new()
	_form_right_btn.text = ">"
	_form_right_btn.custom_minimum_size = Vector2(20, 16)
	_form_right_btn.add_theme_font_size_override("font_size", 16)
	_form_right_btn.pressed.connect(_on_form_right)
	form_row.add_child(_form_right_btn)


func _create_right_column(parent: HBoxContainer) -> void:
	# Wrapper to center stats vertically with sprite
	var center_wrapper := CenterContainer.new()
	center_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(center_wrapper)

	_stats_container = VBoxContainer.new()
	_stats_container.add_theme_constant_override("separation", 4)
	center_wrapper.add_child(_stats_container)

	# Stats header
	var stats_header := Label.new()
	stats_header.text = "STATS"
	stats_header.add_theme_font_size_override("font_size", 16)
	stats_header.add_theme_color_override("font_color", Color.BLACK)
	_stats_container.add_child(stats_header)


func _create_info_section(parent: VBoxContainer) -> void:
	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	parent.add_child(info_vbox)

	_caught_label = Label.new()
	_caught_label.add_theme_font_size_override("font_size", 16)
	_caught_label.add_theme_color_override("font_color", Color.BLACK)
	info_vbox.add_child(_caught_label)

	_date_label = Label.new()
	_date_label.add_theme_font_size_override("font_size", 16)
	_date_label.add_theme_color_override("font_color", Color.BLACK)
	info_vbox.add_child(_date_label)

	_moves_learned_label = Label.new()
	_moves_learned_label.add_theme_font_size_override("font_size", 16)
	_moves_learned_label.add_theme_color_override("font_color", Color.BLACK)
	info_vbox.add_child(_moves_learned_label)


func _create_moves_section(parent: VBoxContainer) -> void:
	var moves_header := Label.new()
	moves_header.text = "ACTIVE MOVES:"
	moves_header.add_theme_font_size_override("font_size", 16)
	moves_header.add_theme_color_override("font_color", Color.BLACK)
	moves_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(moves_header)

	_active_moves_container = VBoxContainer.new()
	_active_moves_container.add_theme_constant_override("separation", 2)
	parent.add_child(_active_moves_container)


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 20)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _populate_data() -> void:
	# Name in element color
	_name_label.text = _creature.get_display_name()
	var element_color: Color = ELEMENT_COLORS.get(_species.element, Color.BLACK)
	_name_label.add_theme_color_override("font_color", element_color)

	# Level and XP
	var xp_to_next := _calculate_xp_to_next_level()
	_level_xp_label.text = "Lv. %d   XP: %d / %d" % [_creature.level, _creature.current_xp, xp_to_next]

	# Sprite
	_update_sprite()

	# Form toggle visibility
	var show_form_toggle := _available_forms.size() > 1
	_form_left_btn.visible = show_form_toggle
	_form_right_btn.visible = show_form_toggle
	_form_label.visible = show_form_toggle
	_update_form_label()

	# Stats - base stats with current in parentheses
	_add_stat_row("HP", _species.base_hp, _creature.max_hp)
	_add_stat_row("ATK", _species.base_attack, _creature.attack)
	_add_stat_row("DEF", _species.base_defense, _creature.defense)
	_add_stat_row("SPD", _species.base_speed, _creature.speed)

	# Caught info
	if _creature.caught_location != "":
		_caught_label.text = "Caught: %s" % _creature.caught_location
	else:
		_caught_label.text = "Caught: Unknown"

	if _creature.caught_timestamp > 0:
		var datetime := Time.get_datetime_dict_from_unix_time(_creature.caught_timestamp)
		_date_label.text = "Date: %s %d, %d" % [_get_month_name(datetime.month), datetime.day, datetime.year]
	else:
		_date_label.text = "Date: Unknown"

	# Battles won
	_moves_learned_label.text = "Battles Won: %d" % _creature.battles_won

	# Active moves - just names, centered
	for move_id in _creature.active_moves:
		var move_data: MoveData = GameState.get_move(move_id)
		var move_label := Label.new()
		if move_data:
			move_label.text = move_data.display_name
		else:
			move_label.text = move_id
		move_label.add_theme_font_size_override("font_size", 16)
		move_label.add_theme_color_override("font_color", Color.BLACK)
		move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_active_moves_container.add_child(move_label)


func _add_stat_row(stat_name: String, base_value: int, current_value: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_stats_container.add_child(row)

	var name_label := Label.new()
	name_label.text = "%s:" % stat_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.BLACK)
	name_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "%d (%d)" % [base_value, current_value]
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(value_label)


func _calculate_xp_to_next_level() -> int:
	# Simple formula: 100 * level
	return 100 * _creature.level


func _get_month_name(month: int) -> String:
	var months := ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return months[month] if month >= 1 and month <= 12 else "???"


func _update_sprite() -> void:
	if _species and _species.sprite_texture:
		_sprite_texture.texture = _species.sprite_texture
		# Apply species sprite_scale
		var sprite_scale: float = _species.sprite_scale if _species.sprite_scale > 0 else 1.0
		_sprite_texture.pivot_offset = _sprite_texture.size / 2.0
		_sprite_texture.scale = Vector2(sprite_scale, sprite_scale)
		_sprite_texture.visible = true
		_sprite_label.visible = false
	else:
		_sprite_texture.visible = false
		_sprite_label.visible = true
		var element_initial := _species.element.substr(0, 1).to_upper() if _species else "?"
		_sprite_label.text = element_initial
		var element_color: Color = ELEMENT_COLORS.get(_species.element, Color.BLACK) if _species else Color.BLACK
		_sprite_label.add_theme_color_override("font_color", element_color)


func _update_form_label() -> void:
	var form := _available_forms[_current_form_index] if _current_form_index < _available_forms.size() else 0
	_form_label.text = _get_form_name(form)


func _get_form_name(form_index: int) -> String:
	if form_index == 0:
		return "Base"
	elif form_index == 1:
		return "Evolved"
	else:
		return "Final"


func _on_form_left() -> void:
	_current_form_index = (_current_form_index - 1 + _available_forms.size()) % _available_forms.size()
	_creature.cosmetic_form = _available_forms[_current_form_index]
	_update_form_label()
	# TODO: Update sprite when evolution sprites exist


func _on_form_right() -> void:
	_current_form_index = (_current_form_index + 1) % _available_forms.size()
	_creature.cosmetic_form = _available_forms[_current_form_index]
	_update_form_label()
	# TODO: Update sprite when evolution sprites exist


func _on_close_pressed() -> void:
	_close()


func _close() -> void:
	GameState.close_menu("details_screen")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("open_menu"):
		get_viewport().set_input_as_handled()
		_close()
