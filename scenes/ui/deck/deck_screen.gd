class_name DeckScreen
extends CanvasLayer
## Deck screen - Pokedex-style creature list.
## Left panel shows selected creature preview, right panel has scrollable list.

signal closed

const PREVIEW_PANEL_WIDTH := 200
const LIST_PANEL_WIDTH := 140
const PANEL_HEIGHT := 340
const PANEL_GAP := 8
const PREVIEW_SIZE := 150
const TOTAL_SLOTS := 200
const PANEL_TEXTURE := preload(
	"res://assets/sprites/ui/panels/panel_frame_48x40.png"
)
const ELEMENT_COLORS := {
	"fire": Color(0.85, 0.2, 0.15),
	"water": Color(0.2, 0.4, 0.85),
	"earth": Color(0.2, 0.55, 0.2),
	"air": Color(0.85, 0.75, 0.1),
}
const FONT_PATHS := [
	["PressStart2P", "res://assets/fonts/PressStart2P-Regular.ttf", 8],
	["PixelOp-Bold", "res://assets/fonts/PixelOperator-Bold.ttf", 16],
	["Dogica-Bold", "res://assets/fonts/dogicapixelbold.ttf", 8],
	["BoldPixels", "res://assets/fonts/BoldPixels.ttf", 16],
]

var _background: ColorRect
var _panel: NinePatchRect
var _preview_rect: ColorRect
var _preview_sprite: Label
var _preview_texture: TextureRect
var _preview_name: Label
var _preview_element: Label
var _preview_physical: Label
var _preview_stats: Label
var _preview_description: Label
var _list_container: VBoxContainer
var _scroll_container: ScrollContainer
var _count_label: Label
var _selected_index: int = -1
var _species_by_slot: Dictionary = {}
var _fonts: Array[Array] = []


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	GameState.open_menu("deck_screen", true)

	_load_comparison_fonts()
	_build_species_slots()
	_create_ui()
	_populate_list()
	_select_first_discovered()


func _load_comparison_fonts() -> void:
	for entry in FONT_PATHS:
		if entry[1] == "":
			_fonts.append([entry[0], null, entry[2]])
		else:
			var font := FontFile.new()
			var err := font.load_dynamic_font(entry[1])
			if err == OK:
				font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
				font.hinting = TextServer.HINTING_NONE
				_fonts.append([entry[0], font, entry[2]])


func _build_species_slots() -> void:
	var all_species := GameState.get_all_species()
	var regular: Array[CreatureSpecies] = []
	var legendary: Array[CreatureSpecies] = []

	for species in all_species:
		if species.species_id.begins_with("legendary_"):
			legendary.append(species)
		else:
			regular.append(species)

	var slot := 1
	for species in regular:
		_species_by_slot[slot] = species
		slot += 1

	slot = 197
	for species in legendary:
		_species_by_slot[slot] = species
		slot += 1


func _create_ui() -> void:
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.5)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	var container := Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	_create_preview_panel(container)
	_create_list_panel(container)


func _create_preview_panel(parent: Control) -> void:
	var panel_container := Control.new()
	panel_container.custom_minimum_size = Vector2(
		PREVIEW_PANEL_WIDTH, PANEL_HEIGHT
	)
	panel_container.size = Vector2(
		PREVIEW_PANEL_WIDTH, PANEL_HEIGHT
	)
	panel_container.clip_contents = true
	panel_container.set_anchors_preset(Control.PRESET_CENTER)
	panel_container.position = Vector2(
		-PREVIEW_PANEL_WIDTH / 2.0, -PANEL_HEIGHT / 2.0
	)
	parent.add_child(panel_container)

	_panel = NinePatchRect.new()
	_panel.texture = PANEL_TEXTURE
	_panel.patch_margin_left = 8
	_panel.patch_margin_top = 8
	_panel.patch_margin_right = 8
	_panel.patch_margin_bottom = 8
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel_container.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(main_vbox)

	var title_row := HBoxContainer.new()
	main_vbox.add_child(title_row)

	var title := Label.new()
	title.text = "DECK"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.BLACK)
	title_row.add_child(title)

	var spacer_title := Control.new()
	spacer_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer_title)

	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.add_theme_color_override(
		"font_color", Color(0.3, 0.3, 0.3)
	)
	title_row.add_child(_count_label)

	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	var content_vbox := VBoxContainer.new()
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(content_vbox)

	var preview_container := Control.new()
	preview_container.custom_minimum_size = Vector2(
		PREVIEW_SIZE, PREVIEW_SIZE
	)
	preview_container.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)
	content_vbox.add_child(preview_container)

	_preview_rect = ColorRect.new()
	_preview_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_rect.color = Color(0, 0, 0, 0)
	_preview_rect.visible = false
	preview_container.add_child(_preview_rect)

	_preview_sprite = Label.new()
	_preview_sprite.text = "?"
	_preview_sprite.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_preview_sprite.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	_preview_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_sprite.add_theme_font_size_override("font_size", 32)
	_preview_sprite.add_theme_color_override(
		"font_color", Color(0.5, 0.5, 0.5)
	)
	preview_container.add_child(_preview_sprite)

	_preview_texture = TextureRect.new()
	_preview_texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_texture.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	_preview_texture.visible = false
	preview_container.add_child(_preview_texture)

	_preview_name = Label.new()
	_preview_name.text = "???"
	_preview_name.add_theme_font_size_override("font_size", 16)
	_preview_name.add_theme_constant_override("outline_size", 5)
	_preview_name.add_theme_color_override(
		"font_outline_color", Color.BLACK
	)
	content_vbox.add_child(_preview_name)

	_preview_element = Label.new()
	_preview_element.text = "Unknown"
	_preview_element.add_theme_font_size_override("font_size", 16)
	_preview_element.add_theme_color_override(
		"font_color", Color.BLACK
	)
	_preview_element.add_theme_constant_override("outline_size", 3)
	_preview_element.add_theme_color_override(
		"font_outline_color", Color.WHITE
	)
	content_vbox.add_child(_preview_element)

	_preview_physical = Label.new()
	_preview_physical.text = "?.?m  ?.?kg"
	_preview_physical.add_theme_font_size_override("font_size", 16)
	_preview_physical.add_theme_color_override(
		"font_color", Color.BLACK
	)
	content_vbox.add_child(_preview_physical)

	_preview_stats = Label.new()
	_preview_stats.text = "HP:?? ATK:?? DEF:?? SPD:??"
	_preview_stats.add_theme_font_size_override("font_size", 16)
	_preview_stats.add_theme_color_override(
		"font_color", Color.BLACK
	)
	content_vbox.add_child(_preview_stats)

	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 2)
	content_vbox.add_child(sep2)

	_preview_description = Label.new()
	_preview_description.text = (
		"This creature has not been discovered yet."
	)
	_preview_description.add_theme_font_size_override("font_size", 16)
	_preview_description.add_theme_color_override(
		"font_color", Color.BLACK
	)
	_preview_description.autowrap_mode = TextServer.AUTOWRAP_WORD
	_preview_description.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	_preview_description.custom_minimum_size = Vector2(0, 40)
	content_vbox.add_child(_preview_description)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(btn_row)

	var close_btn := _create_styled_button("CLOSE")
	close_btn.pressed.connect(_on_close_pressed)
	btn_row.add_child(close_btn)


func _create_list_panel(parent: Control) -> void:
	var panel_container := Control.new()
	panel_container.custom_minimum_size = Vector2(
		LIST_PANEL_WIDTH, PANEL_HEIGHT
	)
	panel_container.size = Vector2(LIST_PANEL_WIDTH, PANEL_HEIGHT)
	panel_container.set_anchors_preset(Control.PRESET_CENTER)
	panel_container.position = Vector2(
		PREVIEW_PANEL_WIDTH / 2.0 + PANEL_GAP,
		-PANEL_HEIGHT / 2.0,
	)
	parent.add_child(panel_container)

	var list_panel := NinePatchRect.new()
	list_panel.texture = PANEL_TEXTURE
	list_panel.patch_margin_left = 8
	list_panel.patch_margin_top = 8
	list_panel.patch_margin_right = 8
	list_panel.patch_margin_bottom = 8
	list_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.add_child(list_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel_container.add_child(margin)

	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	_scroll_container.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)
	_scroll_container.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	_scroll_container.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_SHOW_NEVER
	)
	margin.add_child(_scroll_container)

	_list_container = VBoxContainer.new()
	_list_container.add_theme_constant_override("separation", 0)
	_list_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	_scroll_container.add_child(_list_container)


func _populate_list() -> void:
	var discovered := GameState.get_discovery_count()
	_count_label.text = "%d / %d" % [discovered, TOTAL_SLOTS]

	for slot in range(1, TOTAL_SLOTS + 1):
		var btn := _create_list_entry(slot)
		_list_container.add_child(btn)


func _create_list_entry(slot: int) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(120, 18)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 0)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	var num_str := "%03d. " % slot
	var species: CreatureSpecies = _species_by_slot.get(
		slot, null
	)

	var num_label := Label.new()
	num_label.text = num_str
	num_label.add_theme_font_size_override("font_size", 16)
	num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(num_label)

	var name_label := Label.new()
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_font_for_slot(name_label, slot)
	container.add_child(name_label)

	if species != null and GameState.is_species_discovered(
		species.species_id
	):
		num_label.add_theme_color_override(
			"font_color", Color.BLACK
		)
		var display := species.get_display_name()
		var font_tag := _get_font_name_for_slot(slot)
		name_label.text = "%s [%s]" % [display, font_tag]
		var element_color: Color = ELEMENT_COLORS.get(
			species.element, Color.BLACK
		)
		name_label.add_theme_color_override(
			"font_color", element_color
		)
		name_label.add_theme_color_override(
			"font_outline_color", Color.BLACK
		)
		name_label.add_theme_constant_override("outline_size", 4)
		container.gui_input.connect(
			_on_list_entry_input.bind(slot, species, true)
		)
	else:
		num_label.add_theme_color_override(
			"font_color", Color(0.5, 0.5, 0.5)
		)
		name_label.text = "???"
		name_label.add_theme_color_override(
			"font_color", Color(0.5, 0.5, 0.5)
		)
		if species:
			container.gui_input.connect(
				_on_list_entry_input.bind(
					slot, species, false
				)
			)
		else:
			container.gui_input.connect(
				_on_empty_slot_input.bind(slot)
			)

	return container


func _get_font_index(slot: int) -> int:
	if _fonts.is_empty():
		return -1
	return (slot - 1) % _fonts.size()


func _apply_font_for_slot(label: Label, slot: int) -> void:
	var idx := _get_font_index(slot)
	if idx < 0:
		return
	if _fonts[idx][1] != null:
		label.add_theme_font_override("font", _fonts[idx][1])
	label.add_theme_font_size_override(
		"font_size", _fonts[idx][2]
	)


func _get_font_name_for_slot(slot: int) -> String:
	var idx := _get_font_index(slot)
	if idx < 0:
		return "default"
	return _fonts[idx][0]


func _on_list_entry_input(
	event: InputEvent,
	slot: int,
	species: CreatureSpecies,
	is_discovered: bool,
) -> void:
	if not event is InputEventMouseButton:
		return
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_species_preview(slot, species, is_discovered)


func _on_empty_slot_input(
	event: InputEvent, slot: int
) -> void:
	if not event is InputEventMouseButton:
		return
	if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_empty_preview(slot)


func _select_first_discovered() -> void:
	for slot in range(1, TOTAL_SLOTS + 1):
		var species: CreatureSpecies = _species_by_slot.get(
			slot, null
		)
		if species and GameState.is_species_discovered(
			species.species_id
		):
			_show_species_preview(slot, species, true)
			return

	for slot in range(1, TOTAL_SLOTS + 1):
		var species: CreatureSpecies = _species_by_slot.get(
			slot, null
		)
		if species:
			_show_species_preview(slot, species, false)
			return

	_show_empty_preview(1)


func _show_species_preview(
	slot: int,
	species: CreatureSpecies,
	is_discovered: bool,
) -> void:
	_selected_index = slot

	if is_discovered:
		_preview_name.text = species.get_display_name()
		_preview_element.text = species.element.capitalize()
		_preview_physical.text = "%.1fm  %.1fkg" % [
			species.height_m, species.weight_kg,
		]
		_preview_stats.text = "HP:%d ATK:%d DEF:%d SPD:%d" % [
			species.base_hp,
			species.base_attack,
			species.base_defense,
			species.base_speed,
		]
		_preview_description.text = species.description

		var element_color: Color = ELEMENT_COLORS.get(
			species.element, Color.BLACK
		)
		_preview_name.add_theme_color_override(
			"font_color", element_color
		)
		_preview_name.add_theme_color_override(
			"font_outline_color", Color.BLACK
		)
		_preview_element.add_theme_color_override(
			"font_color", element_color
		)
		_preview_element.add_theme_color_override(
			"font_outline_color", Color.BLACK
		)
		_preview_physical.add_theme_color_override(
			"font_color", Color.BLACK
		)
		_preview_stats.add_theme_color_override(
			"font_color", Color.BLACK
		)
		_preview_description.add_theme_color_override(
			"font_color", Color.BLACK
		)

		if species.sprite_texture:
			_preview_texture.texture = species.sprite_texture
			var sscale: float = species.sprite_scale
			if sscale <= 0:
				sscale = 1.0
			_preview_texture.pivot_offset = (
				_preview_texture.size / 2.0
			)
			_preview_texture.scale = Vector2(sscale, sscale)
			_preview_texture.modulate = Color.WHITE
			_preview_texture.visible = true
			_preview_sprite.visible = false
		else:
			_preview_texture.visible = false
			_preview_sprite.visible = true
			_preview_sprite.text = ":)"
			_preview_sprite.add_theme_color_override(
				"font_color", Color(0.4, 0.4, 0.4)
			)
	else:
		_show_undiscovered_preview(species)


func _show_undiscovered_preview(species: CreatureSpecies) -> void:
	_preview_name.text = "???"
	_preview_element.text = "Unknown"
	_preview_physical.text = "?.?m  ?.?kg"
	_preview_element.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_element.add_theme_color_override(
		"font_outline_color", Color.WHITE
	)
	_preview_name.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_physical.add_theme_color_override(
		"font_color", Color.BLACK
	)
	_preview_stats.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_description.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_stats.text = "HP:?? ATK:?? DEF:?? SPD:??"
	_preview_description.text = (
		"This creature has not been discovered yet."
	)

	if species.sprite_texture:
		_preview_texture.texture = species.sprite_texture
		var sscale: float = species.sprite_scale
		if sscale <= 0:
			sscale = 1.0
		_preview_texture.pivot_offset = (
			_preview_texture.size / 2.0
		)
		_preview_texture.scale = Vector2(sscale, sscale)
		_preview_texture.modulate = Color(0.15, 0.15, 0.2)
		_preview_texture.visible = true
		_preview_sprite.visible = false
	else:
		_preview_texture.visible = false
		_preview_sprite.visible = true
		_preview_sprite.text = "?"
		_preview_sprite.add_theme_color_override(
			"font_color", Color(0.4, 0.4, 0.5)
		)


func _show_empty_preview(slot: int) -> void:
	_selected_index = slot
	_preview_name.text = "???"
	_preview_element.text = "Unknown"
	_preview_physical.text = "?.?m  ?.?kg"
	_preview_element.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_name.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_physical.add_theme_color_override(
		"font_color", Color.BLACK
	)
	_preview_stats.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_description.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.4)
	)
	_preview_stats.text = "HP:?? ATK:?? DEF:?? SPD:??"
	_preview_description.text = (
		"This creature has not been discovered yet."
	)
	_preview_texture.visible = false
	_preview_sprite.visible = true
	_preview_sprite.text = "?"
	_preview_sprite.add_theme_color_override(
		"font_color", Color(0.4, 0.4, 0.5)
	)


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 20)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)
	return btn


func _on_close_pressed() -> void:
	GameState.close_menu("deck_screen")
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
	elif event.is_action_pressed("open_menu"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
