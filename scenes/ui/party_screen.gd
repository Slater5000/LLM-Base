extends CanvasLayer
class_name PartyScreen
## Party screen showing 6 creature slots.
## Uses Craftpix character panel sprites.

signal closed

var _background: ColorRect
var _panel: NinePatchRect
var _title: Label
var _slots: Array[Control] = []

const PANEL_WIDTH := 280
const PANEL_HEIGHT := 220
const MAX_PARTY_SIZE := 6


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED  # Menu works when game is paused

	# Register with GameState menu system (allow stacking from radial menu)
	GameState.open_menu("party_screen", true)

	_create_ui()
	_refresh_party()


func _create_ui() -> void:
	# Darkening background overlay
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.5)
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
	center.add_child(panel_container)

	# Panel background (9-slice)
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
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Title
	_title = Label.new()
	_title.text = "PARTY"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color.BLACK)
	vbox.add_child(_title)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Grid for 6 slots (2 columns x 3 rows)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	# Create 6 party slots
	for i in MAX_PARTY_SIZE:
		var slot := _create_party_slot(i)
		grid.add_child(slot)
		_slots.append(slot)

	# Spacer to push close button to bottom
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Close button at bottom - styled like radial menu buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var close_btn := _create_styled_button("CLOSE")
	close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(close_btn)


func _create_styled_button(text: String) -> Button:
	## Create a button styled consistently
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 24)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _create_party_slot(index: int) -> Control:
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(120, 36)
	slot.size = Vector2(120, 36)

	# Background using character panel sprite
	var bg := TextureRect.new()
	bg.name = "Background"
	bg.texture = preload("res://assets/sprites/ui/character/char_panel_1.png")
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(bg)

	# Name label (overlaid on the panel)
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = "Empty"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.position = Vector2(32, 4)
	name_label.size = Vector2(80, 14)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color.BLACK)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(name_label)

	# Level label
	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.text = ""
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.position = Vector2(32, 18)
	level_label.size = Vector2(80, 14)
	level_label.add_theme_font_size_override("font_size", 8)
	level_label.add_theme_color_override("font_color", Color.BLACK)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(level_label)

	return slot


func _refresh_party() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if not game_state:
		return

	var party: Array = game_state.get_party()

	for i in MAX_PARTY_SIZE:
		var slot := _slots[i]
		var name_label: Label = slot.get_node("NameLabel")
		var level_label: Label = slot.get_node("LevelLabel")
		var bg: TextureRect = slot.get_node("Background")

		if i < party.size():
			var creature = party[i]
			name_label.text = creature.get_display_name()
			level_label.text = "Lv.%d  HP:%d/%d" % [creature.level, creature.current_hp, creature.max_hp]
			bg.modulate = Color.WHITE
		else:
			name_label.text = "- Empty -"
			level_label.text = ""
			bg.modulate = Color(0.5, 0.5, 0.5, 0.7)


func _on_close_pressed() -> void:
	GameState.close_menu("party_screen")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
