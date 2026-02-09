extends Control
## Evolve menu test. Tab-based skill tree following settings
## menu pattern: centered panel, tabs, scrollable content.

const PANEL_W := 460
const PANEL_H := 330
const TILE_W := 92.0
const TILE_H := 40.0
const TILE_GAP := 12
const ROW_GAP := 8

const TAB_LABELS := ["PLAYER", "LOGISTICS", "COLONY"]
const TAB_COLS := [
	Color(0.3, 0.65, 0.3, 1.0),
	Color(0.7, 0.6, 0.15, 1.0),
	Color(0.7, 0.25, 0.25, 1.0),
]

var _tab_buttons: Array[Button] = []
var _tab_contents: Array[Control] = []
var _current_tab := 0
var _panel_tex: Texture2D
var _tooltip: PanelContainer
var _tt_name: Label
var _tt_desc: Label
var _rainbow_lbl: Label
var _rainbow_time := 0.0
var _rainbow_labels: Array[Label] = []


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_panel_tex = load(AntColonyUI.PANEL_ROUNDED)
	_create_ui()
	_switch_tab(0)


func _process(delta: float) -> void:
	_rainbow_time += delta * 2.0
	var hue := fmod(_rainbow_time, 1.0)
	var col := Color.from_hsv(hue, 0.9, 1.0)
	_rainbow_lbl.add_theme_color_override(
		"font_color", col,
	)
	for lbl: Label in _rainbow_labels:
		lbl.add_theme_color_override(
			"font_color", col,
		)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)


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


# =============================================================
# UI CONSTRUCTION
# =============================================================


func _create_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel_c := Control.new()
	panel_c.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	panel_c.size = Vector2(PANEL_W, PANEL_H)
	center.add_child(panel_c)

	var panel := NinePatchRect.new()
	panel.texture = load(AntColonyUI.PANEL_ROUNDED)
	panel.patch_margin_left = 14
	panel.patch_margin_top = 14
	panel.patch_margin_right = 14
	panel.patch_margin_bottom = 14
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_c.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel_c.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Banner title
	var banner := _create_banner("EVOLVE", PANEL_W)
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

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_bar)

	for i in TAB_LABELS.size():
		var btn := Button.new()
		btn.text = TAB_LABELS[i]
		btn.custom_minimum_size = Vector2(100, 20)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override(
			"font_color", Color.BLACK,
		)
		btn.pressed.connect(_on_tab_pressed.bind(i))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

	vbox.add_child(HSeparator.new())

	# Content area (holds 3 scroll containers)
	var content := Control.new()
	content.custom_minimum_size = Vector2(0, 160)
	content.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)
	vbox.add_child(content)

	var trees := [
		_player_tiers(),
		_logistics_tiers(),
		_colony_tiers(),
	]
	for i in trees.size():
		_create_tree_tab(content, trees[i], TAB_COLS[i])

	# Tooltip (above everything)
	_create_tooltip()
	$BackButton.move_to_front()


func _create_tree_tab(
	parent: Control, tiers: Array, col: Color,
) -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	scroll.visible = false
	parent.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	vbox.add_theme_constant_override(
		"separation", ROW_GAP,
	)
	scroll.add_child(vbox)

	var first_tier := true
	for tier: Array in tiers:
		if not first_tier:
			var sep := HSeparator.new()
			sep.add_theme_constant_override(
				"separation", 4,
			)
			vbox.add_child(sep)
		first_tier = false
		_add_pick_label(vbox, tier)
		var row := CenterContainer.new()
		row.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)
		vbox.add_child(row)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override(
			"separation", TILE_GAP,
		)
		row.add_child(hbox)

		for skill: Dictionary in tier:
			hbox.add_child(
				_create_tile(skill, col),
			)

	_tab_contents.append(scroll)


func _add_pick_label(
	parent: Control, tier: Array,
) -> void:
	if tier.size() <= 1:
		return
	var pick: String = tier[0].get("pick", "")
	if pick == "":
		return
	var lbl := Label.new()
	lbl.text = pick
	lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lbl.add_theme_font_size_override(
		"font_size", 16,
	)
	lbl.add_theme_color_override(
		"font_color", Color.RED,
	)
	parent.add_child(lbl)


func _create_tile(
	skill: Dictionary, col: Color,
) -> Control:
	var has_prog: bool = skill.has("prog")
	var cell_h := TILE_H + 16.0
	if has_prog:
		cell_h = TILE_H + 30.0
	var c := Control.new()
	c.custom_minimum_size = Vector2(
		TILE_W, cell_h,
	)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	var tile := NinePatchRect.new()
	tile.name = "Tile"
	tile.texture = _panel_tex
	tile.patch_margin_left = 14
	tile.patch_margin_top = 14
	tile.patch_margin_right = 14
	tile.patch_margin_bottom = 14
	tile.position = Vector2.ZERO
	tile.size = Vector2(TILE_W, TILE_H)
	tile.modulate = Color(0.5, 0.45, 0.38, 0.7)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(tile)

	var lbl := Label.new()
	lbl.text = skill.name
	lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lbl.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	lbl.position = Vector2(4.0, 2.0)
	lbl.size = Vector2(
		TILE_W - 8.0, TILE_H - 4.0,
	)
	lbl.add_theme_font_size_override(
		"font_size", 16,
	)
	var is_rainbow: bool = skill.get("rainbow", false)
	if is_rainbow:
		lbl.add_theme_color_override(
			"font_outline_color", Color.BLACK,
		)
		lbl.add_theme_constant_override(
			"outline_size", 4,
		)
		_rainbow_labels.append(lbl)
	else:
		lbl.add_theme_color_override(
			"font_color", Color.BLACK,
		)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)

	if has_prog:
		var prog_lbl := Label.new()
		prog_lbl.text = skill.prog
		prog_lbl.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)
		prog_lbl.position = Vector2(
			0.0, TILE_H + 1.0,
		)
		prog_lbl.size = Vector2(TILE_W, 14.0)
		prog_lbl.add_theme_font_size_override(
			"font_size", 16,
		)
		prog_lbl.add_theme_color_override(
			"font_color", Color.BLACK,
		)
		prog_lbl.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)
		c.add_child(prog_lbl)

	var cost_y := TILE_H + 1.0
	if has_prog:
		cost_y = TILE_H + 15.0
	var cost_lbl := Label.new()
	cost_lbl.text = skill.cost
	cost_lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	cost_lbl.position = Vector2(0.0, cost_y)
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

	c.mouse_entered.connect(
		_on_tile_entered.bind(
			c, skill, col, tile,
		),
	)
	c.mouse_exited.connect(
		_on_tile_exited.bind(tile),
	)
	c.gui_input.connect(
		_on_tile_input.bind(skill, tile, col),
	)
	return c


func _create_tooltip() -> void:
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.z_index = 10
	_tooltip.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	var style := StyleBoxTexture.new()
	style.texture = load(AntColonyUI.PANEL_ROUNDED)
	style.texture_margin_left = 14.0
	style.texture_margin_top = 14.0
	style.texture_margin_right = 14.0
	style.texture_margin_bottom = 14.0
	style.content_margin_left = 6.0
	style.content_margin_top = 4.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 4.0
	_tooltip.add_theme_stylebox_override(
		"panel", style,
	)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(vbox)

	_tt_name = Label.new()
	_tt_name.add_theme_font_size_override("font_size", 16)
	_tt_name.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	_tt_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_tt_name)

	_tt_desc = Label.new()
	_tt_desc.add_theme_font_size_override("font_size", 16)
	_tt_desc.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	_tt_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tt_desc.custom_minimum_size = Vector2(160, 0)
	_tt_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_tt_desc)

	add_child(_tooltip)


# =============================================================
# TAB SWITCHING
# =============================================================


func _switch_tab(idx: int) -> void:
	_current_tab = idx
	for i in _tab_buttons.size():
		if i == idx:
			_tab_buttons[i].add_theme_color_override(
				"font_color", TAB_COLS[i],
			)
		else:
			_tab_buttons[i].add_theme_color_override(
				"font_color", Color.BLACK,
			)
	for i in _tab_contents.size():
		_tab_contents[i].visible = (i == idx)
	_tooltip.visible = false


func _on_tab_pressed(idx: int) -> void:
	_switch_tab(idx)


# =============================================================
# INTERACTION
# =============================================================


func _on_tile_entered(
	tile_c: Control, skill: Dictionary,
	col: Color, tile: NinePatchRect,
) -> void:
	tile.modulate = col
	var clean: String = skill.name.replace("\n", " ")
	_tt_name.text = clean
	_tt_desc.text = skill.desc
	_tooltip.visible = true

	var gp: Vector2 = tile_c.global_position
	var tx: float = gp.x + TILE_W + 4.0
	var ty: float = gp.y
	# Flip to left side if it would go off-screen
	if tx + 170.0 > AntColonyUI.VIEWPORT_W:
		tx = gp.x - 170.0 - 4.0
	tx = clampf(tx, 4.0, AntColonyUI.VIEWPORT_W - 170.0)
	ty = clampf(
		ty, 4.0,
		AntColonyUI.VIEWPORT_H - 80.0,
	)
	_tooltip.position = Vector2(tx, ty)


func _on_tile_exited(
	tile: NinePatchRect,
) -> void:
	tile.modulate = Color(0.5, 0.45, 0.38, 0.7)
	_tooltip.visible = false


func _on_tile_input(
	event: InputEvent, skill: Dictionary,
	tile: NinePatchRect, col: Color,
) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	var state: int = skill.get("state", 0)
	state = (state + 1) % 3
	skill["state"] = state
	match state:
		0:
			tile.modulate = col
		1:
			tile.modulate = col
		2:
			tile.modulate = AntColonyUI.NODE_LOCKED


# =============================================================
# SKILL DATA (tier layout from reference images)
# =============================================================


func _sk(
	n: String, d: String, c: String,
	p: String = "", pk: String = "",
	rb: bool = false,
) -> Dictionary:
	var data := {
		"name": n, "desc": d,
		"cost": c, "state": 0,
	}
	if p != "":
		data["prog"] = p
	if pk != "":
		data["pick"] = pk
	if rb:
		data["rainbow"] = true
	return data


func _player_tiers() -> Array:
	return [
		[_sk(
			"AUTO\nMINING",
			"DIG BLOCKS BY WALKING INTO THEM",
			"50",
		)],
		[_sk(
			"DIG\nSTRENGTH",
			"INCREASE DIG DAMAGE PER HIT",
			"25", "0/50",
		)],
		[
			_sk("FOOD\nMAGNET",
				"ATTRACT NEARBY FOOD DROPS",
				"25"),
			_sk("PLAYER\nSPEED",
				"INCREASE MOVEMENT SPEED",
				"25"),
			_sk("CARRY\nCAP",
				"CARRY MORE FOOD AT ONCE",
				"25"),
		],
		[
			_sk("DIG\nRANGE",
				"MINE BLOCKS FURTHER AWAY",
				"100", "",
				"PICK 2 OF 3"),
			_sk("DIG\nSPEED",
				"MINE BLOCKS FASTER",
				"100", "",
				"PICK 2 OF 3"),
			_sk("DIG\nRADIUS",
				"MINE A LARGER AREA",
				"100", "",
				"PICK 2 OF 3"),
		],
		[
			_sk("AUTO\nWORKER",
				"WORKERS DIG WITHOUT ORDERS",
				"200"),
			_sk("ARCHITECT\nANT",
				"UNLOCK BUILDING MODE",
				"300"),
			_sk("AUTO\nEVOLVE",
				"AUTO-PICK CHEAPEST UPGRADE",
				"500"),
		],
		[
			_sk("GUN",
				"SHOOT BLOCKS FROM DISTANCE",
				"400", "",
				"PICK 1 OF 4"),
			_sk("LASER",
				"CONTINUOUS BEAM MINING",
				"400", "",
				"PICK 1 OF 4"),
			_sk("ACID",
				"DISSOLVE BLOCKS OVER TIME",
				"400", "",
				"PICK 1 OF 4"),
			_sk("EXPLODE",
				"BLAST LARGE AREAS",
				"400", "",
				"PICK 1 OF 4"),
		],
		[_sk(
			"OVER THE\nRAINBOW",
			"UNLOCK THE RAINBOW FOOD CHEAT MENU",
			"1,000,000,000", "", "", true,
		)],
	]


func _logistics_tiers() -> Array:
	return [
		[_sk(
			"PLACE\nDIRT",
			"PLACE MINED DIRT BLOCKS",
			"50",
		)],
		[_sk(
			"TRANSPORT\nCAP",
			"MORE ITEMS PER TRANSPORT TRIP",
			"20", "0/10",
		)],
		[
			_sk("LIFT",
				"VERTICAL SHAFT TRANSPORT",
				"150", "",
				"PICK 1 OF 4"),
			_sk("MINECART",
				"RAIL-BASED HAULING",
				"150", "",
				"PICK 1 OF 4"),
			_sk("PLATFORM",
				"MOVING PLATFORMS",
				"150", "",
				"PICK 1 OF 4"),
			_sk("ZIPLINE",
				"ZIPLINE TRANSPORT",
				"150", "",
				"PICK 1 OF 4"),
		],
		[
			_sk("PHEROMONE\nHWY",
				"WORKERS FOLLOW PHEROMONES",
				"150"),
			_sk("AUTO\nCONVEYOR",
				"AUTO-ROUTE CONVEYOR BELTS",
				"200"),
		],
		[
			_sk("TRAMWAY",
				"AERIAL CABLE CAR TRANSPORT",
				"250", "",
				"PICK 1 OF 2"),
			_sk("CONVEYOR\nBELT",
				"AUTOMATED BELT SYSTEM",
				"250", "",
				"PICK 1 OF 2"),
		],
		[
			_sk("LEGS",
				"EXTRA LEGS FOR CLIMBING",
				"300", "",
				"PICK 1 OF 4"),
			_sk("GRAPPLE",
				"GRAPPLING HOOK MOVEMENT",
				"300", "",
				"PICK 1 OF 4"),
			_sk("JETPACK",
				"FLY SHORT DISTANCES",
				"300", "",
				"PICK 1 OF 4"),
			_sk("JUMP",
				"SUPER JUMP ABILITY",
				"300", "",
				"PICK 1 OF 4"),
		],
		[
			_sk("TELEPORT",
				"INSTANT TELEPORTATION",
				"500", "",
				"PICK 1 OF 2"),
			_sk("TUBES",
				"PNEUMATIC TUBE NETWORK",
				"500", "",
				"PICK 1 OF 2"),
		],
	]


func _colony_tiers() -> Array:
	return [
		[_sk(
			"UNLOCK\nWORKERS",
			"HIRE YOUR FIRST WORKERS",
			"100",
		)],
		[_sk(
			"MINER\nSTRENGTH",
			"WORKERS DIG HARDER",
			"25", "0/50",
		)],
		[
			_sk("ANT\nSPEED",
				"WORKERS MOVE FASTER",
				"25"),
			_sk("HAUL\nCAP",
				"WORKERS CARRY MORE FOOD",
				"25"),
		],
		[
			_sk("CANNON",
				"LAUNCH FOOD VIA CANNON",
				"200", "",
				"PICK 1 OF 3"),
			_sk("SINGULARITY",
				"GRAVITY WELL COLLECTION",
				"200", "",
				"PICK 1 OF 3"),
			_sk("RELAY",
				"WORKER RELAY CHAIN",
				"200", "",
				"PICK 1 OF 3"),
		],
		[
			_sk("DIG\nRANGE",
				"MINERS REACH FURTHER",
				"150", "",
				"PICK 2 OF 3"),
			_sk("DIG\nSPEED",
				"MINERS DIG FASTER",
				"150", "",
				"PICK 2 OF 3"),
			_sk("DIG\nRADIUS",
				"MINERS DIG WIDER",
				"150", "",
				"PICK 2 OF 3"),
		],
		[
			_sk("GUN",
				"ARMED MINER ANTS",
				"400", "",
				"PICK 1 OF 4"),
			_sk("LASER",
				"LASER MINING ANTS",
				"400", "",
				"PICK 1 OF 4"),
			_sk("ACID",
				"ACID SPRAYING ANTS",
				"400", "",
				"PICK 1 OF 4"),
			_sk("EXPLODE",
				"DEMOLITION ANTS",
				"400", "",
				"PICK 1 OF 4"),
		],
	]
