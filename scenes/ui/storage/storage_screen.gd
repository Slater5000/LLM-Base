extends CanvasLayer
class_name StorageScreen
## Pokemon-style storage PC screen.
## Left: Info panel for selected creature. Right: Box grid (6x5 = 30 slots).
## PARTY button opens party overlay for withdrawing/depositing.
## Click to select, click destination to move/swap.

signal closed

var _background: ColorRect
var _panel: NinePatchRect
var _info_panel: Control
var _info_sprite: TextureRect
var _info_name: Label
var _info_level: Label
var _info_element: Label
var _box_label: Label
var _party_btn: Button
var _status_label: Label
var _box_slots: Array[Control] = []

## Party overlay
var _party_overlay: Control
var _party_panel: NinePatchRect
var _party_slots: Array[Control] = []
var _party_visible: bool = false

## Selection state
var _selected_source: Dictionary = {}  # {type: "party"/"box", index: int, box: int}
var _is_selecting: bool = false
var _hovered_creature: CreatureInstance = null

const PANEL_WIDTH := 420
const PANEL_HEIGHT := 260
const INFO_PANEL_WIDTH := 110
const BOX_SLOT_SIZE := 40
const BOX_COLUMNS := 6
const BOX_ROWS := 5
const PARTY_SLOT_SIZE := 44

## Element colors
const ELEMENT_COLORS := {
	"fire": Color(0.85, 0.25, 0.15),
	"water": Color(0.2, 0.45, 0.85),
	"earth": Color(0.35, 0.55, 0.25),
	"air": Color(0.85, 0.75, 0.1)
}

const ELEMENT_TINTS := {
	"fire": Color(0.95, 0.85, 0.8),
	"water": Color(0.8, 0.88, 0.98),
	"earth": Color(0.85, 0.92, 0.82),
	"air": Color(0.98, 0.95, 0.8)
}


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	GameState.open_menu("storage_screen", true)
	_create_ui()
	_create_party_overlay()
	_refresh_all()


func _create_ui() -> void:
	# Darkening background
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
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel_container.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)

	# Title row: Box nav center, PARTY + CLOSE on right
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	main_vbox.add_child(title_row)

	# Box navigation (centered)
	var box_nav := HBoxContainer.new()
	box_nav.add_theme_constant_override("separation", 4)
	box_nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(box_nav)

	# Left spacer for centering
	var nav_spacer1 := Control.new()
	nav_spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_nav.add_child(nav_spacer1)

	var prev_btn := _create_nav_button("<")
	prev_btn.pressed.connect(_on_prev_box)
	box_nav.add_child(prev_btn)

	_box_label = Label.new()
	_box_label.text = "BOX 1"
	_box_label.custom_minimum_size.x = 54
	_box_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box_label.add_theme_font_size_override("font_size", 11)
	_box_label.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	box_nav.add_child(_box_label)

	var next_btn := _create_nav_button(">")
	next_btn.pressed.connect(_on_next_box)
	box_nav.add_child(next_btn)

	# Right spacer for centering
	var nav_spacer2 := Control.new()
	nav_spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_nav.add_child(nav_spacer2)

	# PARTY button
	_party_btn = _create_styled_button("PARTY")
	_party_btn.pressed.connect(_toggle_party)
	title_row.add_child(_party_btn)

	# Close button
	var close_btn := _create_styled_button("CLOSE")
	close_btn.pressed.connect(_on_close_pressed)
	title_row.add_child(close_btn)

	# Main content row: Info panel left, Box grid right
	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 8)
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_row)

	# Left: Info panel
	_create_info_panel(content_row)

	# Vertical separator
	var vsep := VSeparator.new()
	content_row.add_child(vsep)

	# Right: Box grid
	var box_grid := GridContainer.new()
	box_grid.columns = BOX_COLUMNS
	box_grid.add_theme_constant_override("h_separation", 2)
	box_grid.add_theme_constant_override("v_separation", 2)
	content_row.add_child(box_grid)

	for i in (BOX_COLUMNS * BOX_ROWS):
		var slot := _create_box_slot(i)
		box_grid.add_child(slot)
		_box_slots.append(slot)

	# Status/instruction label
	_status_label = Label.new()
	_status_label.text = "Select a creature"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 9)
	_status_label.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
	main_vbox.add_child(_status_label)


func _create_info_panel(parent: Control) -> void:
	_info_panel = Panel.new()
	_info_panel.custom_minimum_size = Vector2(INFO_PANEL_WIDTH, 0)
	_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.85, 0.8)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.45, 0.4)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_info_panel.add_theme_stylebox_override("panel", style)
	parent.add_child(_info_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	_info_panel.add_child(vbox)

	# Sprite container (centered, larger)
	var sprite_container := CenterContainer.new()
	sprite_container.custom_minimum_size.y = 70
	vbox.add_child(sprite_container)

	_info_sprite = TextureRect.new()
	_info_sprite.custom_minimum_size = Vector2(64, 64)
	_info_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_info_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite_container.add_child(_info_sprite)

	# Name label
	_info_name = Label.new()
	_info_name.text = ""
	_info_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_name.add_theme_font_size_override("font_size", 10)
	_info_name.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	_info_name.clip_text = true
	_info_name.custom_minimum_size.x = INFO_PANEL_WIDTH - 8
	vbox.add_child(_info_name)

	# Level label
	_info_level = Label.new()
	_info_level.text = ""
	_info_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_level.add_theme_font_size_override("font_size", 9)
	_info_level.add_theme_color_override("font_color", Color(0.35, 0.3, 0.25))
	vbox.add_child(_info_level)

	# Element label
	_info_element = Label.new()
	_info_element.text = ""
	_info_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_element.add_theme_font_size_override("font_size", 9)
	vbox.add_child(_info_element)


func _create_party_overlay() -> void:
	# Party overlay (hidden by default)
	_party_overlay = Control.new()
	_party_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_party_overlay.visible = false
	_party_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_party_overlay)

	# Darken background slightly more
	var overlay_bg := ColorRect.new()
	overlay_bg.color = Color(0, 0, 0, 0.3)
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_party_overlay.add_child(overlay_bg)

	# Party panel (positioned to the right)
	var party_container := Control.new()
	party_container.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	party_container.offset_left = -160
	party_container.offset_top = -120
	party_container.offset_right = -10
	party_container.offset_bottom = 120
	_party_overlay.add_child(party_container)

	_party_panel = NinePatchRect.new()
	_party_panel.texture = preload("res://assets/sprites/ui/panels/panel_frame_48x40.png")
	_party_panel.patch_margin_left = 8
	_party_panel.patch_margin_top = 8
	_party_panel.patch_margin_right = 8
	_party_panel.patch_margin_bottom = 8
	_party_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	party_container.add_child(_party_panel)

	# Party content
	var party_margin := MarginContainer.new()
	party_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	party_margin.add_theme_constant_override("margin_left", 8)
	party_margin.add_theme_constant_override("margin_top", 6)
	party_margin.add_theme_constant_override("margin_right", 8)
	party_margin.add_theme_constant_override("margin_bottom", 6)
	party_container.add_child(party_margin)

	var party_vbox := VBoxContainer.new()
	party_vbox.add_theme_constant_override("separation", 4)
	party_margin.add_child(party_vbox)

	# Party header
	var party_header := HBoxContainer.new()
	party_vbox.add_child(party_header)

	var party_title := Label.new()
	party_title.text = "PARTY"
	party_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	party_title.add_theme_font_size_override("font_size", 10)
	party_title.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	party_header.add_child(party_title)

	var party_close := Button.new()
	party_close.text = "X"
	party_close.custom_minimum_size = Vector2(20, 18)
	party_close.add_theme_font_size_override("font_size", 9)
	party_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	party_close.pressed.connect(_toggle_party)
	party_header.add_child(party_close)

	# Party grid (2 columns x 3 rows)
	var party_grid := GridContainer.new()
	party_grid.columns = 2
	party_grid.add_theme_constant_override("h_separation", 4)
	party_grid.add_theme_constant_override("v_separation", 4)
	party_vbox.add_child(party_grid)

	for i in 6:
		var slot := _create_party_slot(i)
		party_grid.add_child(slot)
		_party_slots.append(slot)


func _create_nav_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(22, 18)
	btn.add_theme_font_size_override("font_size", 11)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(50, 18)
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _create_party_slot(index: int) -> Control:
	var slot := Panel.new()
	slot.name = "PartySlot%d" % index
	slot.custom_minimum_size = Vector2(64, PARTY_SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_party_slot_input.bind(index))
	slot.mouse_entered.connect(_on_party_slot_hover.bind(index))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.88, 0.82)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.45, 0.4)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	slot.add_theme_stylebox_override("panel", style)

	# HBox for sprite + info
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 2)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(hbox)

	# Sprite
	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.custom_minimum_size = Vector2(36, 36)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(sprite)

	# Level label only (name shown in info panel)
	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.text = ""
	level_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	level_label.add_theme_font_size_override("font_size", 9)
	level_label.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2))
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(level_label)

	return slot


func _create_box_slot(index: int) -> Control:
	var slot := Panel.new()
	slot.name = "BoxSlot%d" % index
	slot.custom_minimum_size = Vector2(BOX_SLOT_SIZE, BOX_SLOT_SIZE)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slot.gui_input.connect(_on_box_slot_input.bind(index))
	slot.mouse_entered.connect(_on_box_slot_hover.bind(index))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.85, 0.82, 0.78)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.48, 0.45)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	slot.add_theme_stylebox_override("panel", style)

	# Sprite centered
	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.offset_left = 2
	sprite.offset_top = 2
	sprite.offset_right = -2
	sprite.offset_bottom = -2
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(sprite)

	return slot


func _refresh_all() -> void:
	_refresh_box_slots()
	_refresh_party_slots()
	_update_box_label()
	_update_info_panel(null)


func _refresh_party_slots() -> void:
	for i in 6:
		var slot: Panel = _party_slots[i]
		var creature = GameState.get_party_slot(i)
		_update_party_slot_visual(slot, creature, i)


func _refresh_box_slots() -> void:
	var box := GameState.get_current_box()
	for i in (BOX_COLUMNS * BOX_ROWS):
		var slot: Panel = _box_slots[i]
		var creature = box[i] if i < box.size() else null
		_update_box_slot_visual(slot, creature, i)


func _update_party_slot_visual(slot: Panel, creature: CreatureInstance, index: int) -> void:
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
	var sprite: TextureRect = slot.find_child("Sprite", true, false)
	var level_label: Label = slot.find_child("LevelLabel", true, false)

	# Check if this slot is selected
	var is_selected: bool = _is_selecting and _selected_source.get("type", "") == "party" and _selected_source.get("index", -1) == index

	if creature != null:
		var species = GameState.get_species(creature.species_id)
		var element: String = species.element if species else "earth"

		style.bg_color = ELEMENT_TINTS.get(element, Color(0.9, 0.88, 0.82))
		style.border_color = ELEMENT_COLORS.get(element, Color(0.5, 0.45, 0.4)).darkened(0.2)

		if species and species.sprite_texture:
			sprite.texture = species.sprite_texture
		else:
			sprite.texture = null

		level_label.text = "L%d" % creature.level
		level_label.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color.BLACK).darkened(0.1))
	else:
		style.bg_color = Color(0.8, 0.78, 0.75, 0.5)
		style.border_color = Color(0.5, 0.48, 0.45, 0.4)
		sprite.texture = null
		level_label.text = ""

	# Selection highlight
	if is_selected:
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 0.85, 0.0)
	else:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

	slot.add_theme_stylebox_override("panel", style)


func _update_box_slot_visual(slot: Panel, creature: CreatureInstance, index: int) -> void:
	var style: StyleBoxFlat = slot.get_theme_stylebox("panel").duplicate()
	var sprite: TextureRect = slot.get_node("Sprite")

	# Check if this slot is selected
	var is_selected: bool = _is_selecting and _selected_source.get("type", "") == "box" and _selected_source.get("index", -1) == index and _selected_source.get("box", -1) == GameState.current_storage_box

	if creature != null:
		var species = GameState.get_species(creature.species_id)
		var element: String = species.element if species else "earth"

		style.bg_color = ELEMENT_TINTS.get(element, Color(0.9, 0.88, 0.82))
		style.border_color = ELEMENT_COLORS.get(element, Color(0.5, 0.45, 0.4)).darkened(0.2)

		if species and species.sprite_texture:
			sprite.texture = species.sprite_texture
		else:
			sprite.texture = null
	else:
		style.bg_color = Color(0.8, 0.78, 0.75, 0.5)
		style.border_color = Color(0.5, 0.48, 0.45, 0.4)
		sprite.texture = null

	# Selection highlight
	if is_selected:
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 0.85, 0.0)
	else:
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1

	slot.add_theme_stylebox_override("panel", style)


func _update_info_panel(creature: CreatureInstance) -> void:
	if creature == null:
		_info_sprite.texture = null
		_info_name.text = "No selection"
		_info_level.text = ""
		_info_element.text = ""
		return

	var species = GameState.get_species(creature.species_id)
	if species == null:
		_info_sprite.texture = null
		_info_name.text = "Unknown"
		_info_level.text = ""
		_info_element.text = ""
		return

	if species.sprite_texture:
		_info_sprite.texture = species.sprite_texture

	_info_name.text = creature.get_display_name()
	_info_level.text = "Level %d" % creature.level

	var element: String = species.element
	_info_element.text = element.capitalize()
	_info_element.add_theme_color_override("font_color", ELEMENT_COLORS.get(element, Color.BLACK))


func _update_box_label() -> void:
	_box_label.text = "BOX %d" % (GameState.current_storage_box + 1)


func _toggle_party() -> void:
	_show_party(not _party_visible)


func _show_party(show: bool) -> void:
	_party_visible = show
	_party_overlay.visible = _party_visible
	_party_btn.text = "BACK" if _party_visible else "PARTY"
	if _party_visible:
		_refresh_party_slots()


func _on_party_slot_hover(index: int) -> void:
	var creature = GameState.get_party_slot(index)
	_update_info_panel(creature)


func _on_box_slot_hover(index: int) -> void:
	var box := GameState.get_current_box()
	var creature = box[index] if index < box.size() else null
	_update_info_panel(creature)


func _on_party_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_slot_click("party", index)


func _on_box_slot_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_slot_click("box", index)


func _handle_slot_click(slot_type: String, index: int) -> void:
	if not _is_selecting:
		# First click: select source
		var creature: CreatureInstance = null
		if slot_type == "party":
			creature = GameState.get_party_slot(index)
		else:
			creature = GameState.get_storage_creature(GameState.current_storage_box, index)

		if creature != null:
			_is_selecting = true
			_selected_source = {
				"type": slot_type,
				"index": index,
				"box": GameState.current_storage_box
			}
			_status_label.text = "Select destination"
			_refresh_all()
			_update_info_panel(creature)

			# Auto-open party when selecting from box (to withdraw)
			if slot_type == "box" and not _party_visible:
				_show_party(true)
	else:
		# Second click: perform move/swap
		var success := _perform_move(slot_type, index)
		var src_type: String = _selected_source.get("type", "")
		var was_cross_transfer: bool = src_type != slot_type
		_cancel_selection()
		if success:
			GameState.save_game()
			# Auto-close party after successful cross-transfer
			if was_cross_transfer and _party_visible:
				_show_party(false)


func _perform_move(dest_type: String, dest_index: int) -> bool:
	var src_type: String = _selected_source.get("type", "")
	var src_index: int = _selected_source.get("index", -1)
	var src_box: int = _selected_source.get("box", 0)

	# Same slot clicked - cancel
	if src_type == dest_type and src_index == dest_index:
		if dest_type == "box" and src_box == GameState.current_storage_box:
			return false
		elif dest_type == "party":
			return false

	# Party to Party: swap positions
	if src_type == "party" and dest_type == "party":
		GameState.swap_party_positions(src_index, dest_index)
		return true

	# Party to Box: deposit
	if src_type == "party" and dest_type == "box":
		var dest_creature = GameState.get_storage_creature(GameState.current_storage_box, dest_index)
		if dest_creature == null:
			return GameState.deposit_to_storage(src_index, GameState.current_storage_box, dest_index)
		else:
			return GameState.swap_party_storage(src_index, GameState.current_storage_box, dest_index)

	# Box to Party: withdraw
	if src_type == "box" and dest_type == "party":
		var dest_creature = GameState.get_party_slot(dest_index)
		if dest_creature == null:
			return GameState.withdraw_from_storage(src_box, src_index, dest_index)
		else:
			return GameState.swap_party_storage(dest_index, src_box, src_index)

	# Box to Box: move within storage
	if src_type == "box" and dest_type == "box":
		return GameState.move_storage_to_storage(src_box, src_index, GameState.current_storage_box, dest_index)

	return false


func _cancel_selection() -> void:
	_is_selecting = false
	_selected_source = {}
	_status_label.text = "Select a creature"
	_refresh_all()


func _on_prev_box() -> void:
	var new_box := GameState.current_storage_box - 1
	if new_box < 0:
		new_box = GameState.STORAGE_BOX_COUNT - 1
	GameState.set_current_storage_box(new_box)
	_cancel_selection()


func _on_next_box() -> void:
	var new_box := GameState.current_storage_box + 1
	if new_box >= GameState.STORAGE_BOX_COUNT:
		new_box = 0
	GameState.set_current_storage_box(new_box)
	_cancel_selection()


func _on_close_pressed() -> void:
	GameState.close_menu("storage_screen")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel") or event.is_action_pressed("open_menu"):
		get_viewport().set_input_as_handled()
		if _party_visible:
			_toggle_party()
		elif _is_selecting:
			_cancel_selection()
		else:
			_on_close_pressed()
