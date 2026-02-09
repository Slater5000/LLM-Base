extends Control
## Build menu test. Hexagonal button ring for transport placement.
## Modeled after the creature RPG radial menu (F-key hex layout).
## Press number keys 1-6 to simulate progressive unlocking.

const TRANSPORT := [
	{
		"id": "lift",
		"label": "LIFT",
		"desc": "VERTICAL LIFT — FAST UP/DOWN FOR DEEP MINING",
	},
	{
		"id": "tramway",
		"label": "TRAMWAY",
		"desc": "AERIAL CABLE BETWEEN PYLONS — CROSSES GAPS",
	},
	{
		"id": "minecart",
		"label": "MINECART",
		"desc": "HORIZONTAL RAIL — FAST LEFT/RIGHT HAULING",
	},
	{
		"id": "conveyor",
		"label": "CONVEYOR",
		"desc": "SURFACE BELT — FOLLOWS FLOOR, WALL, CEILING",
	},
	{
		"id": "zipline",
		"label": "ZIP LINE",
		"desc": "DIAGONAL SHORTCUT — FAST DOWN, SLOW UP",
	},
	{
		"id": "teleport",
		"label": "TELEPORT",
		"desc": "INSTANT WARP BETWEEN TWO PADS — 1 PAIR ONLY",
	},
]

const CENTER := Vector2(320.0, 165.0)
const RING_RADIUS := 80.0
const BTN_W := 80.0
const BTN_H := 32.0
var _unlocked_count: int = 6
var _selected: int = -1
var _buttons: Array[Control] = []
var _tooltip: Label
var _count_label: Label
var _overlay: ColorRect
var _place_hint: Label


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_build_ui()


func _build_ui() -> void:
	# Blur overlay (shown when menu has items)
	_overlay = ColorRect.new()
	_overlay.color = Color.WHITE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	var shader := Shader.new()
	shader.code = _make_blur_shader()
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_overlay.material = mat
	add_child(_overlay)

	# World placeholder
	var world_lbl := Label.new()
	world_lbl.text = "[ GAME WORLD HERE ]"
	world_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	world_lbl.set_anchors_preset(Control.PRESET_CENTER)
	world_lbl.position = Vector2(-60, -10)
	world_lbl.size = Vector2(120, 20)
	world_lbl.add_theme_font_size_override("font_size", 16)
	world_lbl.add_theme_color_override(
		"font_color", Color.BLACK
	)
	add_child(world_lbl)

	# Create all 6 button nodes (hidden initially)
	for i in TRANSPORT.size():
		var btn := _create_build_button(i)
		btn.visible = false
		add_child(btn)
		_buttons.append(btn)

	# Tooltip below the ring
	_tooltip = Label.new()
	_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip.position = Vector2(100, CENTER.y + RING_RADIUS + 30)
	_tooltip.size = Vector2(440, 20)
	_tooltip.add_theme_font_size_override("font_size", 16)
	_tooltip.add_theme_color_override(
		"font_color", Color.BLACK
	)
	add_child(_tooltip)

	# Placement hint (shown when item selected)
	_place_hint = Label.new()
	_place_hint.text = "CLICK START, THEN END POSITION. ESC TO CANCEL."
	_place_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place_hint.position = Vector2(
		140, CENTER.y + RING_RADIUS + 48
	)
	_place_hint.size = Vector2(360, 16)
	_place_hint.add_theme_font_size_override("font_size", 16)
	_place_hint.add_theme_color_override(
		"font_color", Color.BLACK
	)
	_place_hint.visible = false
	add_child(_place_hint)

	# Unlock count display
	_count_label = Label.new()
	_count_label.text = "UNLOCKED: 6 / 6"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.position = Vector2(230, 320)
	_count_label.size = Vector2(180, 16)
	_count_label.add_theme_font_size_override("font_size", 16)
	_count_label.add_theme_color_override(
		"font_color", Color.BLACK
	)
	add_child(_count_label)

	# Instructions
	var inst := Label.new()
	inst.text = "PRESS 1-6 TO UNLOCK TRANSPORT TYPES"
	inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inst.position = Vector2(160, 340)
	inst.size = Vector2(320, 16)
	inst.add_theme_font_size_override("font_size", 16)
	inst.add_theme_color_override(
		"font_color", Color.BLACK
	)
	add_child(inst)

	# Banner title
	var banner := _create_banner("BUILD", 640.0)
	banner.position = Vector2(0, 29)
	add_child(banner)

	$BackButton.move_to_front()
	_update_layout()


# =========================================================================
# BUTTON CREATION
# =========================================================================

func _create_build_button(index: int) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(BTN_W, BTN_H)
	container.size = Vector2(BTN_W, BTN_H)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	# Panel background using Kenney brown tile
	var bg := NinePatchRect.new()
	bg.name = "BG"
	bg.texture = load(AntColonyUI.PANEL_ROUNDED)
	bg.patch_margin_left = 14
	bg.patch_margin_top = 14
	bg.patch_margin_right = 14
	bg.patch_margin_bottom = 14
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# Label
	var lbl := Label.new()
	lbl.text = TRANSPORT[index].label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(lbl)

	# Connect input
	container.gui_input.connect(_on_btn_input.bind(index))
	container.mouse_entered.connect(_on_btn_enter.bind(index))
	container.mouse_exited.connect(_on_btn_exit.bind(index))

	return container


# =========================================================================
# LAYOUT
# =========================================================================

func _update_layout() -> void:
	# Hide all buttons
	for btn in _buttons:
		btn.visible = false

	_overlay.visible = _unlocked_count > 0

	if _unlocked_count == 0:
		_tooltip.text = "NO TRANSPORT UNLOCKED YET"
		_place_hint.visible = false
		return

	# Position unlocked buttons in a ring
	for i in _unlocked_count:
		var btn := _buttons[i]
		btn.visible = true
		var pos := _get_ring_pos(i, _unlocked_count)
		btn.position = pos - Vector2(BTN_W, BTN_H) / 2.0

	# Reset selection if out of range
	if _selected >= _unlocked_count:
		_deselect()

	_count_label.text = "UNLOCKED: %d / 6" % _unlocked_count


func _get_ring_pos(index: int, total: int) -> Vector2:
	if total == 1:
		return CENTER
	# Fixed hex positions matching creature RPG radial menu layout
	var angle := -PI / 2.0 + (TAU * float(index) / float(total))
	return CENTER + Vector2(
		cos(angle), sin(angle)
	) * RING_RADIUS


# =========================================================================
# INTERACTION
# =========================================================================

func _on_btn_input(event: InputEvent, index: int) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select(index)


func _on_btn_enter(index: int) -> void:
	if index >= _unlocked_count:
		return
	_buttons[index].get_node("BG").modulate = AntColonyUI.BTN_HOVER
	_tooltip.text = TRANSPORT[index].desc


func _on_btn_exit(index: int) -> void:
	if index >= _unlocked_count:
		return
	if index == _selected:
		_buttons[index].get_node("BG").modulate = (
			AntColonyUI.FOOD_ORANGE
		)
	else:
		_buttons[index].get_node("BG").modulate = Color.WHITE
	# Restore tooltip to selected item
	if _selected >= 0:
		_tooltip.text = TRANSPORT[_selected].desc
	else:
		_tooltip.text = ""


func _select(index: int) -> void:
	_deselect()
	_selected = index
	_buttons[index].get_node("BG").modulate = (
		AntColonyUI.FOOD_ORANGE
	)
	_tooltip.text = TRANSPORT[index].desc
	_place_hint.visible = true


func _deselect() -> void:
	if _selected >= 0 and _selected < _buttons.size():
		_buttons[_selected].get_node("BG").modulate = Color.WHITE
	_selected = -1
	_tooltip.text = ""
	_place_hint.visible = false


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	var key: int = event.keycode
	# Number keys 1-6 set unlock count
	if key >= KEY_1 and key <= KEY_6:
		var num: int = key - KEY_1 + 1
		if num <= _unlocked_count:
			_unlocked_count = num - 1
		else:
			_unlocked_count = num
		_update_layout()
	elif key == KEY_ESCAPE and _selected >= 0:
		_deselect()


func _make_blur_shader() -> String:
	var lines := PackedStringArray([
		"shader_type canvas_item;",
		"uniform sampler2D screen_tex"
		+ " : hint_screen_texture,"
		+ " filter_linear_mipmap;",
		"uniform float blur_lod"
		+ " : hint_range(0.0, 5.0) = 2.5;",
		"void fragment() {",
		"  COLOR = textureLod("
		+ "screen_tex, SCREEN_UV, blur_lod);",
		"  COLOR.a = 1.0;",
		"}",
	])
	return "\n".join(lines)


func _create_banner(
	title_text: String, panel_w: float,
) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bx: float = (panel_w - 157.0) / 2.0
	var bl := TextureRect.new()
	bl.texture = load(AntColonyUI.BANNER_LEFT)
	bl.stretch_mode = TextureRect.STRETCH_SCALE
	bl.position = Vector2(bx, -1.0)
	bl.size = Vector2(32, 32)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bl)
	var mid := TextureRect.new()
	mid.texture = load(AntColonyUI.BANNER_MID)
	mid.stretch_mode = TextureRect.STRETCH_TILE
	mid.position = Vector2(bx + 30.0, -1.0)
	mid.size = Vector2(97, 32)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(mid)
	var br := TextureRect.new()
	br.texture = load(AntColonyUI.BANNER_RIGHT)
	br.stretch_mode = TextureRect.STRETCH_SCALE
	br.position = Vector2(bx + 125.44, -1.07)
	br.size = Vector2(32, 32)
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(br)
	var lbl := Label.new()
	lbl.text = title_text
	lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lbl.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	lbl.position = Vector2(bx, 1.0)
	lbl.size = Vector2(157.0, 32.0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	lbl.add_theme_color_override(
		"font_outline_color", Color.WHITE,
	)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(lbl)
	return holder


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
