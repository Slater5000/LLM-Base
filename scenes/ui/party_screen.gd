extends CanvasLayer
class_name PartyScreen
## Pokemon-style party screen with 2x3 grid layout.
## Shows creature sprites, names, levels, and segmented HP bars.

signal closed

var _background: ColorRect
var _panel: NinePatchRect
var _title: Label
var _slots: Array[Control] = []
var _current_submenu: CreatureSubmenu = null
var _swap_mode: bool = false
var _swap_source_index: int = -1

const PANEL_WIDTH := 400
const PANEL_HEIGHT := 320
const MAX_PARTY_SIZE := 6
const SLOT_WIDTH := 188
const SLOT_HEIGHT := 80
const HP_BAR_WIDTH := 70
const HP_BAR_HEIGHT := 6
const HP_BAR_SEGMENTS := 10
const SPRITE_SIZE := 82

## Element colors for backgrounds and indicators
const ELEMENT_COLORS := {
	"fire": Color(0.85, 0.25, 0.15),
	"water": Color(0.2, 0.45, 0.85),
	"earth": Color(0.35, 0.55, 0.25),
	"air": Color(0.85, 0.75, 0.1)
}

## Lighter tints for slot backgrounds
const ELEMENT_TINTS := {
	"fire": Color(0.95, 0.85, 0.8),
	"water": Color(0.8, 0.88, 0.98),
	"earth": Color(0.85, 0.92, 0.82),
	"air": Color(0.98, 0.95, 0.8)
}



func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
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
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Title row
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(title_row)

	_title = Label.new()
	_title.text = "PARTY"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 12)
	_title.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	title_row.add_child(_title)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Grid for 6 slots (2 columns x 3 rows)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
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

	# Close button at bottom
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var close_btn := _create_styled_button("CLOSE")
	close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(close_btn)


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 22)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _create_party_slot(index: int) -> Control:
	var slot := Panel.new()
	slot.name = "Slot%d" % index
	slot.custom_minimum_size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
	slot.size = Vector2(SLOT_WIDTH, SLOT_HEIGHT)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_slot_gui_input.bind(index))

	# Use a StyleBoxFlat for the slot background
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.88, 0.82)  # Default cream color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.45, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot.add_theme_stylebox_override("panel", style)

	# Left side: Sprite area (fills nearly the full slot height)
	var left_section := Control.new()
	left_section.position = Vector2(4, 1)
	left_section.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
	left_section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(left_section)

	# Creature sprite texture
	var sprite_tex := TextureRect.new()
	sprite_tex.name = "SpriteTexture"
	sprite_tex.position = Vector2(0, 0)
	sprite_tex.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
	sprite_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite_tex.visible = false
	left_section.add_child(sprite_tex)

	# Sprite label (placeholder text when no sprite)
	var sprite_label := Label.new()
	sprite_label.name = "SpriteLabel"
	sprite_label.text = "?"
	sprite_label.position = Vector2(0, 0)
	sprite_label.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
	sprite_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sprite_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sprite_label.add_theme_font_size_override("font_size", 22)
	sprite_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	sprite_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_section.add_child(sprite_label)

	# Right side: Name, Level, HP bar
	var right_section := Control.new()
	right_section.position = Vector2(SPRITE_SIZE + 4, 12)
	right_section.size = Vector2(105, 66)
	right_section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(right_section)

	# Name label - with room for outline
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = "- Empty -"
	name_label.position = Vector2(0, 0)
	name_label.size = Vector2(105, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color.BLACK)
	name_label.add_theme_color_override("font_outline_color", Color.WHITE)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_section.add_child(name_label)

	# Level label - centered
	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.text = ""
	level_label.position = Vector2(0, 20)
	level_label.size = Vector2(105, 16)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 8)
	level_label.add_theme_color_override("font_color", Color.BLACK)
	level_label.add_theme_color_override("font_outline_color", Color.WHITE)
	level_label.add_theme_constant_override("outline_size", 3)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_section.add_child(level_label)

	# HP Bar container - centered
	var hp_container := Control.new()
	hp_container.name = "HPContainer"
	hp_container.position = Vector2((105 - (HP_BAR_WIDTH + 14)) / 2, 36)
	hp_container.size = Vector2(HP_BAR_WIDTH + 14, HP_BAR_HEIGHT + 14)
	hp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_section.add_child(hp_container)

	# HP label
	var hp_label := Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP"
	hp_label.position = Vector2(0, 0)
	hp_label.size = Vector2(14, HP_BAR_HEIGHT)
	hp_label.add_theme_font_size_override("font_size", 6)
	hp_label.add_theme_color_override("font_color", Color.BLACK)
	hp_label.add_theme_color_override("font_outline_color", Color.WHITE)
	hp_label.add_theme_constant_override("outline_size", 3)
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_label)

	# HP bar background
	var hp_bg := ColorRect.new()
	hp_bg.name = "HPBarBG"
	hp_bg.position = Vector2(14, 0)
	hp_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	hp_bg.color = Color(0.15, 0.12, 0.1)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_bg)

	# HP bar fill
	var hp_fill := ColorRect.new()
	hp_fill.name = "HPBarFill"
	hp_fill.position = Vector2(15, 1)
	hp_fill.size = Vector2(HP_BAR_WIDTH - 2, HP_BAR_HEIGHT - 2)
	hp_fill.color = Color(0.2, 0.75, 0.25)  # Green
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_fill)

	# HP bar segments (vertical lines)
	for seg in range(1, HP_BAR_SEGMENTS):
		var seg_line := ColorRect.new()
		seg_line.position = Vector2(14 + (HP_BAR_WIDTH / HP_BAR_SEGMENTS) * seg, 0)
		seg_line.size = Vector2(1, HP_BAR_HEIGHT)
		seg_line.color = Color(0.1, 0.08, 0.06, 0.6)
		seg_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp_container.add_child(seg_line)

	# HP numbers - centered under the bar
	var hp_numbers := Label.new()
	hp_numbers.name = "HPNumbers"
	hp_numbers.text = ""
	hp_numbers.position = Vector2(14, HP_BAR_HEIGHT + 2)
	hp_numbers.size = Vector2(HP_BAR_WIDTH, 10)
	hp_numbers.add_theme_font_size_override("font_size", 7)
	hp_numbers.add_theme_color_override("font_color", Color.BLACK)
	hp_numbers.add_theme_color_override("font_outline_color", Color.WHITE)
	hp_numbers.add_theme_constant_override("outline_size", 3)
	hp_numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_numbers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_container.add_child(hp_numbers)

	return slot


func _refresh_party() -> void:
	for i in MAX_PARTY_SIZE:
		var slot: Panel = _slots[i]
		var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()

		# Get child nodes
		var left_section := slot.get_child(0)
		var right_section := slot.get_child(1)

		var sprite_tex: TextureRect = left_section.get_node("SpriteTexture")
		var sprite_label: Label = left_section.get_node("SpriteLabel")

		var name_label: Label = right_section.get_node("NameLabel")
		var level_label: Label = right_section.get_node("LevelLabel")
		var hp_container: Control = right_section.get_node("HPContainer")
		var hp_fill: ColorRect = hp_container.get_node("HPBarFill")
		var hp_numbers: Label = hp_container.get_node("HPNumbers")

		var creature = GameState.get_party_slot(i)
		if creature != null:
			var species = GameState.get_species(creature.species_id)
			var element: String = species.element if species else "earth"

			# Set slot background tint based on element
			style.bg_color = ELEMENT_TINTS.get(element, Color(0.9, 0.88, 0.82))
			style.border_color = ELEMENT_COLORS.get(element, Color(0.5, 0.45, 0.4)).darkened(0.2)
			slot.add_theme_stylebox_override("panel", style)

			# Show creature sprite if available, otherwise show element letter
			if species and species.sprite_texture:
				sprite_tex.texture = species.sprite_texture
				# Apply species sprite_scale (for non-standard size assets)
				var scale: float = species.sprite_scale if species.sprite_scale > 0 else 1.0
				var scaled_size: float = SPRITE_SIZE * scale
				var offset: float = (SPRITE_SIZE - scaled_size) / 2.0
				sprite_tex.position = Vector2(offset + 5, offset + 2)
				sprite_tex.size = Vector2(scaled_size, scaled_size)
				sprite_tex.visible = true
				sprite_label.visible = false
			else:
				sprite_tex.visible = false
				sprite_label.visible = true
				sprite_label.text = element.substr(0, 1).to_upper()
				sprite_label.add_theme_color_override("font_color", Color.WHITE)

			# Set name in element color with black outline
			name_label.text = creature.get_display_name()
			var name_color: Color = ELEMENT_COLORS.get(element, Color.BLACK)
			name_label.add_theme_color_override("font_color", name_color)
			name_label.add_theme_color_override("font_outline_color", Color.BLACK)
			level_label.text = "Lv. %d" % creature.level
			level_label.visible = true

			# Set HP bar
			var hp_percent: float = float(creature.current_hp) / float(creature.max_hp) if creature.max_hp > 0 else 0.0
			hp_fill.size.x = (HP_BAR_WIDTH - 2) * hp_percent

			# Color HP bar based on percentage
			if hp_percent > 0.5:
				hp_fill.color = Color(0.2, 0.75, 0.25)  # Green
			elif hp_percent > 0.25:
				hp_fill.color = Color(0.9, 0.7, 0.1)   # Yellow
			else:
				hp_fill.color = Color(0.85, 0.2, 0.15)  # Red

			hp_numbers.text = "%d / %d" % [creature.current_hp, creature.max_hp]
			hp_container.visible = true
		else:
			# Empty slot
			style.bg_color = Color(0.75, 0.72, 0.68, 0.6)
			style.border_color = Color(0.5, 0.48, 0.45, 0.5)
			slot.add_theme_stylebox_override("panel", style)

			sprite_tex.visible = false
			sprite_label.visible = true
			sprite_label.text = "-"
			sprite_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))

			name_label.text = "- Empty -"
			name_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
			level_label.visible = false
			hp_container.visible = false


func _on_close_pressed() -> void:
	GameState.close_menu("party_screen")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		if _swap_mode:
			_cancel_swap_mode()
		else:
			_on_close_pressed()
	elif event.is_action_pressed("open_menu"):
		get_viewport().set_input_as_handled()
		if _swap_mode:
			_cancel_swap_mode()
		else:
			_on_close_pressed()


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _swap_mode:
				_perform_swap(slot_index)
			else:
				# Only show submenu if slot has a creature
				var creature = GameState.get_party_slot(slot_index)
				if creature != null:
					_show_submenu(slot_index)


func _show_submenu(slot_index: int) -> void:
	# Close any existing submenu
	_close_submenu()

	var slot: Control = _slots[slot_index]
	_current_submenu = CreatureSubmenu.new()
	_current_submenu.setup(slot_index, slot.global_position, slot.size)
	_current_submenu.moves_selected.connect(_on_submenu_moves)
	_current_submenu.details_selected.connect(_on_submenu_details)
	_current_submenu.swap_selected.connect(_on_submenu_swap)
	_current_submenu.closed.connect(_on_submenu_closed)
	add_child(_current_submenu)


func _close_submenu() -> void:
	if _current_submenu and is_instance_valid(_current_submenu):
		_current_submenu.queue_free()
		_current_submenu = null


func _on_submenu_moves(creature_index: int) -> void:
	_current_submenu = null
	var creature = GameState.get_party_slot(creature_index)
	if creature == null:
		return
	var move_screen := MoveSwapScreen.new()
	move_screen.setup(creature, creature_index)
	move_screen.closed.connect(_on_subscreen_closed)
	get_tree().root.add_child(move_screen)


func _on_submenu_details(creature_index: int) -> void:
	_current_submenu = null
	var creature = GameState.get_party_slot(creature_index)
	if creature == null:
		return
	var details_screen := DetailsScreen.new()
	details_screen.setup(creature, creature_index)
	details_screen.closed.connect(_on_subscreen_closed)
	get_tree().root.add_child(details_screen)


func _on_submenu_closed() -> void:
	_current_submenu = null


func _on_subscreen_closed() -> void:
	_refresh_party()  # Refresh in case moves/form changed


func _on_submenu_swap(creature_index: int) -> void:
	_current_submenu = null
	_swap_mode = true
	_swap_source_index = creature_index
	_title.text = "SWAP - Select slot"
	_update_swap_highlight()


func _cancel_swap_mode() -> void:
	_swap_mode = false
	_swap_source_index = -1
	_title.text = "PARTY"
	_refresh_party()


func _perform_swap(target_index: int) -> void:
	if not _swap_mode or _swap_source_index == -1:
		return

	# Don't swap with self
	if target_index == _swap_source_index:
		_cancel_swap_mode()
		return

	# Simply swap the two slots - works for both creature-to-creature and creature-to-empty
	GameState.swap_party_positions(_swap_source_index, target_index)

	# Exit swap mode and refresh
	_cancel_swap_mode()


func _update_swap_highlight() -> void:
	for i in MAX_PARTY_SIZE:
		var slot: Panel = _slots[i]
		var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()

		if i == _swap_source_index:
			# Highlight the source slot with a golden border
			style.border_width_left = 3
			style.border_width_top = 3
			style.border_width_right = 3
			style.border_width_bottom = 3
			style.border_color = Color(1.0, 0.85, 0.0)  # Gold
		else:
			var creature = GameState.get_party_slot(i)
			if creature != null:
				# Filled slot - element-colored border
				var species = GameState.get_species(creature.species_id)
				var element: String = species.element if species else "earth"
				style.border_width_left = 1
				style.border_width_top = 1
				style.border_width_right = 1
				style.border_width_bottom = 1
				style.border_color = ELEMENT_COLORS.get(element, Color(0.5, 0.45, 0.4)).darkened(0.2)
			else:
				# Empty slot
				style.border_width_left = 1
				style.border_width_top = 1
				style.border_width_right = 1
				style.border_width_bottom = 1
				style.border_color = Color(0.5, 0.48, 0.45, 0.5)

		slot.add_theme_stylebox_override("panel", style)
