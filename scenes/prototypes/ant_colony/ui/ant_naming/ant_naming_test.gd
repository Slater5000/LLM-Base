extends Control
## Ant customization screen: naming, color palette, hat giving.
## Worker ants: name + preview + colors + give hat button.
## Queen ant: same + hat collection grid (no give hat).

const SWATCH_SIZE := Vector2(24, 16)
const HAT_SIZE := Vector2(24, 16)

const PALETTE := [
	# Row 1 — pastels
	Color(0.92, 0.90, 1.00), Color(0.58, 0.53, 0.92),
	Color(0.95, 0.93, 0.78), Color(0.90, 0.70, 0.48),
	Color(0.98, 0.65, 0.70), Color(0.60, 0.78, 1.00),
	Color(0.82, 0.98, 0.85), Color(0.60, 0.45, 0.35),
	# Row 2 — mediums
	Color(0.75, 0.70, 0.58), Color(0.45, 0.08, 0.52),
	Color(0.85, 0.75, 0.18), Color(0.90, 0.55, 0.18),
	Color(0.78, 0.18, 0.13), Color(0.13, 0.18, 0.48),
	Color(0.08, 0.53, 0.43), Color(0.38, 0.18, 0.12),
	# Row 3 — darks
	Color(0.05, 0.05, 0.05), Color(0.18, 0.03, 0.22),
	Color(0.58, 0.28, 0.12), Color(0.08, 0.12, 0.32),
	Color(0.13, 0.48, 0.18), Color(0.22, 0.12, 0.08),
	Color(0.42, 0.38, 0.35), Color(0.78, 0.72, 0.65),
]

const HAT_NAMES := [
	"Hard Hat", "Top Hat", "Crown", "Propeller",
	"Wizard", "Party Hat", "Viking", "Flower",
	"Astronaut", "Pirate",
]

const HAT_COLORS := [
	Color(0.90, 0.85, 0.20), Color(0.15, 0.15, 0.15),
	Color(1.00, 0.85, 0.10), Color(0.40, 0.60, 0.90),
	Color(0.55, 0.20, 0.70), Color(0.95, 0.40, 0.60),
	Color(0.55, 0.55, 0.55), Color(0.40, 0.75, 0.35),
	Color(0.90, 0.90, 0.95), Color(0.50, 0.30, 0.15),
]

var _hue := 0.0
var _queen_mode := false
var _colors_unlocked := false
var _ant_color := Color(0.6, 0.3, 0.15)
var _selected_hat := -1

var _name_input: LineEdit
var _ant_preview: Control
var _color_grid: GridContainer
var _lock_label: Label
var _hat_header: Label
var _hat_grid: GridContainer
var _give_hat_btn: Button
var _swatches: Array[Button] = []
var _hat_btns: Array[Button] = []

@onready var _content: VBoxContainer = $Panel/Content


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	$QueenToggle.pressed.connect(_toggle_queen)
	$UnlockToggle.pressed.connect(_toggle_unlock)
	_build_ui()


func _process(delta: float) -> void:
	_hue = fmod(_hue + delta * 0.3, 1.0)
	if _name_input:
		_name_input.add_theme_color_override(
			"font_placeholder_color",
			Color.from_hsv(_hue, 0.7, 0.95),
		)


# -- UI Construction --------------------------------------------------


func _build_ui() -> void:
	_add_name_input()
	_add_preview()
	_add_color_section()
	_add_hat_section()
	_add_give_hat()
	_add_action_row()
	_refresh_layout()


func _add_name_input() -> void:
	_name_input = LineEdit.new()
	_name_input.custom_minimum_size = Vector2(0, 28)
	_name_input.placeholder_text = "GREG"
	_name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_input.add_theme_color_override(
		"font_outline_color", Color.BLACK,
	)
	_name_input.add_theme_font_size_override("font_size", 16)
	_name_input.text_changed.connect(_on_name_changed)
	_content.add_child(_name_input)


func _on_name_changed(new_text: String) -> void:
	if new_text.is_empty():
		_name_input.add_theme_color_override(
			"font_outline_color", Color.BLACK,
		)
	else:
		_name_input.add_theme_color_override(
			"font_outline_color", Color.WHITE,
		)


func _add_preview() -> void:
	var frame := NinePatchRect.new()
	frame.texture = load(AntColonyUI.PANEL_DARK)
	frame.patch_margin_left = 14
	frame.patch_margin_top = 14
	frame.patch_margin_right = 14
	frame.patch_margin_bottom = 14
	frame.custom_minimum_size = Vector2(0, 56)
	_content.add_child(frame)

	_ant_preview = Control.new()
	_ant_preview.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT,
	)
	_ant_preview.draw.connect(_draw_ant)
	frame.add_child(_ant_preview)


func _draw_ant() -> void:
	var cx := _ant_preview.size.x * 0.5
	var cy := _ant_preview.size.y * 0.5
	var sc := 1.3 if _queen_mode else 1.0
	var dark := _ant_color.darkened(0.3)
	# Abdomen
	_ant_preview.draw_circle(
		Vector2(cx + 14.0 * sc, cy), 10.0 * sc, _ant_color,
	)
	# Thorax
	_ant_preview.draw_circle(
		Vector2(cx, cy), 7.0 * sc, _ant_color,
	)
	# Head
	_ant_preview.draw_circle(
		Vector2(cx - 12.0 * sc, cy), 6.0 * sc, _ant_color,
	)
	# Legs (3 pairs)
	for i in range(3):
		var lx := cx - 4.0 * sc + i * 8.0 * sc
		_ant_preview.draw_line(
			Vector2(lx, cy + 5.0 * sc),
			Vector2(lx - 4.0 * sc, cy + 18.0 * sc),
			dark, 1.5,
		)
		_ant_preview.draw_line(
			Vector2(lx, cy + 5.0 * sc),
			Vector2(lx + 4.0 * sc, cy + 18.0 * sc),
			dark, 1.5,
		)
	# Antennae
	var hx := cx - 16.0 * sc
	_ant_preview.draw_line(
		Vector2(hx, cy - 3.0 * sc),
		Vector2(hx - 8.0 * sc, cy - 14.0 * sc),
		dark, 1.5,
	)
	_ant_preview.draw_line(
		Vector2(hx + 2.0 * sc, cy - 3.0 * sc),
		Vector2(hx - 2.0 * sc, cy - 16.0 * sc),
		dark, 1.5,
	)
	# Eye
	_ant_preview.draw_circle(
		Vector2(cx - 14.0 * sc, cy - 2.0 * sc),
		1.5 * sc, Color.WHITE,
	)
	# Queen crown
	if _queen_mode:
		_draw_crown(cx - 12.0 * sc, cy - 8.0 * sc)


func _draw_crown(crown_x: float, crown_y: float) -> void:
	var gold := Color(1.0, 0.85, 0.1)
	for j in range(3):
		var tx := crown_x - 4.0 + j * 4.0
		_ant_preview.draw_line(
			Vector2(tx, crown_y),
			Vector2(tx + 2.0, crown_y - 5.0),
			gold, 1.5,
		)
		_ant_preview.draw_line(
			Vector2(tx + 2.0, crown_y - 5.0),
			Vector2(tx + 4.0, crown_y),
			gold, 1.5,
		)


# -- Color Palette -----------------------------------------------------


func _add_color_section() -> void:
	var header := Label.new()
	header.text = "ANT COLOR"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 16)
	_content.add_child(header)

	_color_grid = GridContainer.new()
	_color_grid.columns = 8
	_color_grid.add_theme_constant_override("h_separation", 2)
	_color_grid.add_theme_constant_override("v_separation", 2)
	_color_grid.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)
	_content.add_child(_color_grid)

	for i in range(PALETTE.size()):
		var btn := _make_swatch(PALETTE[i], i)
		_color_grid.add_child(btn)
		_swatches.append(btn)

	_lock_label = Label.new()
	_lock_label.text = "LOCKED"
	_lock_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_lock_label.add_theme_font_size_override("font_size", 16)
	_lock_label.add_theme_color_override(
		"font_color", Color(0.8, 0.3, 0.3),
	)
	_content.add_child(_lock_label)


func _make_swatch(color: Color, idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = SWATCH_SIZE
	btn.add_theme_stylebox_override(
		"normal", _flat_style(color, 1, color.darkened(0.3)),
	)
	btn.add_theme_stylebox_override(
		"hover",
		_flat_style(color.lightened(0.15), 2, Color.WHITE),
	)
	var sel := _flat_style(color.darkened(0.1), 2, Color.WHITE)
	btn.add_theme_stylebox_override("pressed", sel)
	btn.add_theme_stylebox_override("hover_pressed", sel)
	btn.add_theme_stylebox_override(
		"focus", _flat_style(color, 2, Color.WHITE),
	)
	var grey := color.lerp(Color(0.4, 0.4, 0.4), 0.6)
	btn.add_theme_stylebox_override(
		"disabled",
		_flat_style(grey, 1, Color(0.3, 0.3, 0.3, 0.5)),
	)
	btn.disabled = not _colors_unlocked
	btn.pressed.connect(_on_color_picked.bind(idx))
	return btn


func _flat_style(
	bg: Color, border_w: int, border_c: Color,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(2)
	style.set_border_width_all(border_w)
	style.border_color = border_c
	return style


func _on_color_picked(idx: int) -> void:
	_ant_color = PALETTE[idx]
	_ant_preview.queue_redraw()
	_swatches[idx].grab_focus()


# -- Hat Collection (Queen Only) ---------------------------------------


func _add_hat_section() -> void:
	_hat_header = Label.new()
	_hat_header.text = "HAT COLLECTION"
	_hat_header.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_hat_header.add_theme_font_size_override("font_size", 16)
	_content.add_child(_hat_header)

	_hat_grid = GridContainer.new()
	_hat_grid.columns = 5
	_hat_grid.add_theme_constant_override("h_separation", 2)
	_hat_grid.add_theme_constant_override("v_separation", 2)
	_hat_grid.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)
	_content.add_child(_hat_grid)

	for i in range(HAT_NAMES.size()):
		var btn := _make_hat_cell(
			HAT_NAMES[i], HAT_COLORS[i], i,
		)
		_hat_grid.add_child(btn)
		_hat_btns.append(btn)


func _make_hat_cell(
	hat_name: String, color: Color, idx: int,
) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = HAT_SIZE
	btn.tooltip_text = hat_name
	btn.add_theme_stylebox_override(
		"normal", _flat_style(color, 1, color.darkened(0.3)),
	)
	btn.add_theme_stylebox_override(
		"hover",
		_flat_style(color.lightened(0.15), 2, Color.WHITE),
	)
	var sel := _flat_style(color.darkened(0.1), 2, Color.WHITE)
	btn.add_theme_stylebox_override("pressed", sel)
	btn.add_theme_stylebox_override("hover_pressed", sel)
	btn.add_theme_stylebox_override(
		"focus", _flat_style(color, 2, Color.WHITE),
	)
	btn.pressed.connect(_on_hat_picked.bind(idx))
	return btn


func _on_hat_picked(idx: int) -> void:
	_selected_hat = idx
	_hat_btns[idx].grab_focus()


# -- Give Hat Button (Worker Only) ------------------------------------


func _add_give_hat() -> void:
	_give_hat_btn = Button.new()
	_give_hat_btn.text = "GIVE HAT?"
	_give_hat_btn.custom_minimum_size = Vector2(160, 26)
	_give_hat_btn.size_flags_horizontal = (
		Control.SIZE_SHRINK_CENTER
	)
	_give_hat_btn.add_theme_font_size_override(
		"font_size", 16,
	)
	_give_hat_btn.modulate = AntColonyUI.ACCENT_ORANGE
	_give_hat_btn.pressed.connect(_on_give_hat)
	_content.add_child(_give_hat_btn)


func _on_give_hat() -> void:
	_give_hat_btn.text = "HAT GIVEN!"
	_give_hat_btn.disabled = true


# -- Save / Cancel Row ------------------------------------------------


func _add_action_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content.add_child(row)

	var save_btn := Button.new()
	save_btn.text = "SAVE"
	save_btn.custom_minimum_size = Vector2(80, 26)
	save_btn.modulate = AntColonyUI.SAVE_GREEN
	save_btn.add_theme_font_size_override("font_size", 16)
	row.add_child(save_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(80, 26)
	cancel_btn.modulate = AntColonyUI.CANCEL_RED
	cancel_btn.add_theme_font_size_override("font_size", 16)
	row.add_child(cancel_btn)


# -- Test Toggles & Navigation ----------------------------------------


func _toggle_queen() -> void:
	_queen_mode = not _queen_mode
	$QueenToggle.text = "WORKER" if _queen_mode else "QUEEN"
	_ant_preview.queue_redraw()
	_refresh_layout()


func _toggle_unlock() -> void:
	_colors_unlocked = not _colors_unlocked
	$UnlockToggle.text = (
		"LOCK" if _colors_unlocked else "UNLOCK"
	)
	for swatch in _swatches:
		swatch.disabled = not _colors_unlocked
	_lock_label.visible = not _colors_unlocked


func _refresh_layout() -> void:
	_hat_header.visible = _queen_mode
	_hat_grid.visible = _queen_mode
	_give_hat_btn.visible = not _queen_mode
	_lock_label.visible = not _colors_unlocked


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
