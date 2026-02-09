extends Control
## Rainbow menu test. Endgame grid of toggleable
## rainbow-colored upgrades across three categories.
## Click tiles to toggle on/off. Hover for descriptions.

const PANEL_W := 510.0
const PANEL_H := 310.0
const TILE_W := 76.0
const TILE_H := 40.0
const TILE_GAP := 4
const BANNER_W := 220.0

var _tooltip: PanelContainer
var _tt_name: Label
var _tt_desc: Label
var _toggled: Array[bool] = []
var _tiles: Array[Control] = []
var _idx := 0
var _rainbow_lbl: Label
var _rainbow_time := 0.0


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_create_ui()


func _process(delta: float) -> void:
	_rainbow_time += delta * 2.0
	var hue := fmod(_rainbow_time, 1.0)
	_rainbow_lbl.add_theme_color_override(
		"font_color",
		Color.from_hsv(hue, 0.9, 1.0),
	)


func _go_back() -> void:
	get_tree().change_scene_to_file(
		AntColonyUI.LAUNCHER,
	)


# =========================================================
# UI CONSTRUCTION
# =========================================================


func _create_ui() -> void:
	var cats := _get_categories()
	var total := 0
	for cat: Dictionary in cats:
		total += cat.items.size()
	_toggled.resize(total)
	_toggled.fill(false)

	# Panel container centered on screen
	var panel_c := Control.new()
	panel_c.position = Vector2(
		(AntColonyUI.VIEWPORT_W - PANEL_W) / 2.0,
		(AntColonyUI.VIEWPORT_H - PANEL_H) / 2.0,
	)
	panel_c.size = Vector2(PANEL_W, PANEL_H)
	add_child(panel_c)

	# Panel background
	var panel := NinePatchRect.new()
	panel.texture = load(AntColonyUI.PANEL_ROUNDED)
	panel.patch_margin_left = 14
	panel.patch_margin_top = 14
	panel.patch_margin_right = 14
	panel.patch_margin_bottom = 14
	panel.set_anchors_preset(
		Control.PRESET_FULL_RECT,
	)
	panel_c.add_child(panel)

	# Content margins
	var margin := MarginContainer.new()
	margin.set_anchors_preset(
		Control.PRESET_FULL_RECT,
	)
	margin.add_theme_constant_override(
		"margin_left", 10,
	)
	margin.add_theme_constant_override(
		"margin_top", 36,
	)
	margin.add_theme_constant_override(
		"margin_right", 10,
	)
	margin.add_theme_constant_override(
		"margin_bottom", 6,
	)
	panel_c.add_child(margin)

	# Scrollable content
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	vbox.add_theme_constant_override(
		"separation", 6,
	)
	scroll.add_child(vbox)

	_idx = 0
	for i in cats.size():
		_add_category(vbox, cats[i])

	# Banner
	var banner := _create_banner(
		"OVER THE RAINBOW", PANEL_W,
	)
	panel_c.add_child(banner)

	# Rainbow count (top-right)
	_rainbow_lbl = Label.new()
	_rainbow_lbl.text = "0"
	_rainbow_lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
	)
	_rainbow_lbl.position = Vector2(
		PANEL_W - 40.0, 4.0,
	)
	_rainbow_lbl.size = Vector2(32.0, 20.0)
	_rainbow_lbl.add_theme_font_size_override(
		"font_size", 16,
	)
	_rainbow_lbl.add_theme_color_override(
		"font_outline_color", Color.BLACK,
	)
	_rainbow_lbl.add_theme_constant_override(
		"outline_size", 4,
	)
	panel_c.add_child(_rainbow_lbl)

	# Tooltip + ordering
	_create_tooltip()
	$BackButton.move_to_front()


# =========================================================
# CATEGORY ROWS
# =========================================================


func _add_category(
	parent: VBoxContainer, cat: Dictionary,
) -> void:
	var header := Label.new()
	header.text = cat.title
	header.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	header.add_theme_font_size_override(
		"font_size", 16,
	)
	header.add_theme_color_override(
		"font_color", AntColonyUI.ACCENT_ORANGE,
	)
	header.add_theme_color_override(
		"font_outline_color", Color.BLACK,
	)
	header.add_theme_constant_override(
		"outline_size", 3,
	)
	parent.add_child(header)

	var center := CenterContainer.new()
	center.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	parent.add_child(center)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override(
		"separation", TILE_GAP,
	)
	center.add_child(hbox)

	var items: Array = cat.items
	for i in items.size():
		var tile := _create_tile(items[i])
		hbox.add_child(tile)
		_tiles.append(tile)
		_idx += 1


# =========================================================
# TILE CREATION
# =========================================================


func _create_tile(item: Dictionary) -> Control:
	var cell_h := TILE_H + 16.0
	var c := Control.new()
	c.custom_minimum_size = Vector2(
		TILE_W, cell_h,
	)
	c.size = Vector2(TILE_W, cell_h)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	var tile := NinePatchRect.new()
	tile.name = "Tile"
	tile.texture = load(AntColonyUI.PANEL_ROUNDED)
	tile.patch_margin_left = 14
	tile.patch_margin_top = 14
	tile.patch_margin_right = 14
	tile.patch_margin_bottom = 14
	tile.position = Vector2.ZERO
	tile.size = Vector2(TILE_W, TILE_H)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(tile)

	var hue: float = float(_idx) / 16.0
	var rainbow := Color.from_hsv(
		hue, 0.7, 0.95,
	)

	var lbl := Label.new()
	lbl.text = item.name
	lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lbl.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	lbl.position = Vector2.ZERO
	lbl.size = Vector2(TILE_W, TILE_H)
	lbl.add_theme_font_size_override(
		"font_size", 16,
	)
	lbl.add_theme_color_override(
		"font_color", rainbow,
	)
	lbl.add_theme_color_override(
		"font_outline_color", Color.BLACK,
	)
	lbl.add_theme_constant_override(
		"outline_size", 3,
	)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = item.cost
	cost_lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	cost_lbl.position = Vector2(
		0.0, TILE_H + 1.0,
	)
	cost_lbl.size = Vector2(TILE_W, 14.0)
	cost_lbl.add_theme_font_size_override(
		"font_size", 16,
	)
	cost_lbl.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	cost_lbl.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	c.add_child(cost_lbl)

	var idx := _idx
	c.gui_input.connect(
		_on_tile_click.bind(idx, tile),
	)
	c.mouse_entered.connect(
		_on_tile_enter.bind(c, item, tile),
	)
	c.mouse_exited.connect(
		_on_tile_exit.bind(idx, tile),
	)

	return c


# =========================================================
# INTERACTION
# =========================================================


func _on_tile_click(
	event: InputEvent, idx: int,
	tile: NinePatchRect,
) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if not event.pressed:
		return
	_toggled[idx] = not _toggled[idx]
	if _toggled[idx]:
		tile.modulate = AntColonyUI.NODE_PURCHASED
	else:
		tile.modulate = Color.WHITE


func _on_tile_enter(
	tile_c: Control, item: Dictionary,
	tile: NinePatchRect,
) -> void:
	tile.modulate = AntColonyUI.NODE_HOVERED
	var clean: String = (
		item.name.replace("\n", " ")
	)
	_tt_name.text = clean
	_tt_desc.text = item.desc
	_tooltip.visible = true

	var gp: Vector2 = tile_c.global_position
	var tx: float = gp.x + TILE_W + 4.0
	var ty: float = gp.y
	if tx + 170.0 > AntColonyUI.VIEWPORT_W:
		tx = gp.x - 170.0 - 4.0
	_tooltip.position = Vector2(tx, ty)


func _on_tile_exit(
	idx: int, tile: NinePatchRect,
) -> void:
	if _toggled[idx]:
		tile.modulate = AntColonyUI.NODE_PURCHASED
	else:
		tile.modulate = Color.WHITE
	_tooltip.visible = false


# =========================================================
# TOOLTIP
# =========================================================


func _create_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override(
		"separation", 2,
	)
	_tooltip.add_child(vbox)

	_tt_name = Label.new()
	_tt_name.add_theme_font_size_override(
		"font_size", 16,
	)
	_tt_name.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	_tt_name.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	vbox.add_child(_tt_name)

	_tt_desc = Label.new()
	_tt_desc.add_theme_font_size_override(
		"font_size", 16,
	)
	_tt_desc.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	_tt_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tt_desc.custom_minimum_size = Vector2(160, 0)
	_tt_desc.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	vbox.add_child(_tt_desc)

	add_child(_tooltip)


# =========================================================
# BANNER
# =========================================================


func _create_banner(
	title_text: String, panel_w: float,
) -> Control:
	var holder := Control.new()
	holder.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	var bx: float = (
		(panel_w - BANNER_W) / 2.0
	)

	var bl := TextureRect.new()
	bl.texture = load(AntColonyUI.BANNER_LEFT)
	bl.stretch_mode = TextureRect.STRETCH_SCALE
	bl.position = Vector2(bx, -1.0)
	bl.size = Vector2(32, 32)
	bl.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	holder.add_child(bl)

	var mid_w: float = BANNER_W - 62.0
	var mid := TextureRect.new()
	mid.texture = load(AntColonyUI.BANNER_MID)
	mid.stretch_mode = TextureRect.STRETCH_TILE
	mid.position = Vector2(bx + 30.0, -1.0)
	mid.size = Vector2(mid_w, 32)
	mid.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	holder.add_child(mid)

	var br := TextureRect.new()
	br.texture = load(AntColonyUI.BANNER_RIGHT)
	br.stretch_mode = TextureRect.STRETCH_SCALE
	br.position = Vector2(
		bx + BANNER_W - 32.0, -1.07,
	)
	br.size = Vector2(32, 32)
	br.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
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
	lbl.size = Vector2(BANNER_W, 32.0)
	lbl.add_theme_font_size_override(
		"font_size", 16,
	)
	lbl.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	lbl.add_theme_color_override(
		"font_outline_color", Color.WHITE,
	)
	lbl.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)
	holder.add_child(lbl)

	return holder


# =========================================================
# ITEM DATA
# =========================================================


func _it(
	n: String, d: String, c: String,
) -> Dictionary:
	return {"name": n, "desc": d, "cost": c}


func _get_categories() -> Array:
	return [
		{
			"title": "LOGISTICS",
			"items": [
				_it("HIVE\nMIND",
					"ALL ANTS MINE AND HAUL FREELY",
					"30"),
				_it("SPEED\nLIGHT",
					"ALL TRANSPORT RUNS 5X FASTER",
					"25"),
				_it("GLOBAL\nCONV",
					"COLONY-WIDE CONVEYOR NETWORK",
					"20"),
			],
		},
		{
			"title": "POWER FANTASY",
			"items": [
				_it("QUANTUM",
					"QUANTUM TUNNEL THROUGH BLOCKS",
					"30"),
				_it("AUTO\nATTACK",
					"AUTO-DIG WHEREVER FACING",
					"25"),
				_it("AUTO-\nPILOT",
					"QUEEN AUTO-MOVES FORWARD",
					"20"),
				_it("GIANT\nQUEEN",
					"QUEEN BECOMES 5X BIGGER",
					"25"),
				_it("VOID\nSTORAGE",
					"FOOD STORED INSTANTLY ON PICKUP",
					"20"),
			],
		},
		{
			"title": "COSMETIC",
			"items": [
				_it("BIG\nHEAD",
					"COMICALLY OVERSIZED ANT HEADS",
					"10"),
				_it("BIG\nANT",
					"ALL ANTS GROW 2X LARGER",
					"10"),
				_it("RAINBOW\nTRAIL",
					"QUEEN LEAVES A RAINBOW TRAIL (PICK 1)",
					"15"),
				_it("FIRE\nTRAIL",
					"QUEEN LEAVES A FIRE TRAIL (PICK 1)",
					"15"),
				_it("BOOGIE\nBOMB",
					"TOGGLE: ALL ANTS STOP AND DANCE",
					"10"),
				_it("ANT\nCOLORS",
					"UNLOCK ANT COLOR CUSTOMIZATION",
					"10"),
			],
		},
	]
