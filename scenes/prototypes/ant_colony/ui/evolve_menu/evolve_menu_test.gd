extends Control
## Evolve menu test. Tab-based skill tree following settings
## menu pattern: centered panel, tabs, scrollable content.

const PANEL_W := 460
const PANEL_H := 300
const CIRCLE_SZ := 68.0
const CIRCLE_GAP := 12
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
var _circle_ring: Texture2D
var _circle_filled: Texture2D
var _tooltip: PanelContainer
var _tt_name: Label
var _tt_desc: Label
var _tt_cost: Label


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_circle_ring = load(AntColonyUI.CIRCLE_RING)
	_circle_filled = load(AntColonyUI.CIRCLE_FILLED)
	_create_ui()
	_switch_tab(0)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)


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
	panel.texture = load(AntColonyUI.PANEL_MASTER)
	panel.patch_margin_left = 8
	panel.patch_margin_top = 8
	panel.patch_margin_right = 8
	panel.patch_margin_bottom = 8
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_c.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel_c.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "EVOLVE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	vbox.add_child(title)

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

	for tier: Array in tiers:
		var row := CenterContainer.new()
		row.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)
		vbox.add_child(row)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override(
			"separation", CIRCLE_GAP,
		)
		row.add_child(hbox)

		for skill: Dictionary in tier:
			hbox.add_child(
				_create_circle(skill, col),
			)

	_tab_contents.append(scroll)


func _create_circle(
	skill: Dictionary, col: Color,
) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(
		CIRCLE_SZ, CIRCLE_SZ,
	)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	var ring := TextureRect.new()
	ring.name = "Ring"
	ring.texture = _circle_ring
	ring.stretch_mode = TextureRect.STRETCH_SCALE
	ring.position = Vector2.ZERO
	ring.size = Vector2(CIRCLE_SZ, CIRCLE_SZ)
	ring.modulate = Color(0.5, 0.45, 0.38, 0.7)
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(ring)

	var pad := 8.0
	var lbl := Label.new()
	lbl.text = skill.name
	lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lbl.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	lbl.position = Vector2(pad, pad)
	lbl.size = Vector2(
		CIRCLE_SZ - pad * 2.0,
		CIRCLE_SZ - pad * 2.0,
	)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override(
		"font_color", AntColonyUI.TEXT_CREAM,
	)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(lbl)

	c.mouse_entered.connect(
		_on_circle_entered.bind(c, skill, col, ring),
	)
	c.mouse_exited.connect(
		_on_circle_exited.bind(ring),
	)
	c.gui_input.connect(
		_on_circle_input.bind(skill, ring, col),
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
	style.texture = load(AntColonyUI.PANEL_DARK)
	style.texture_margin_left = 8.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 8.0
	style.texture_margin_bottom = 8.0
	style.content_margin_left = 6.0
	style.content_margin_top = 4.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 4.0
	_tooltip.add_theme_stylebox_override(
		"panel", style,
	)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	_tooltip.add_child(vbox)

	_tt_name = Label.new()
	_tt_name.add_theme_font_size_override("font_size", 10)
	_tt_name.add_theme_color_override(
		"font_color", AntColonyUI.TEXT_CREAM,
	)
	vbox.add_child(_tt_name)

	_tt_desc = Label.new()
	_tt_desc.add_theme_font_size_override("font_size", 8)
	_tt_desc.add_theme_color_override(
		"font_color", Color(0.7, 0.65, 0.55, 0.9),
	)
	_tt_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	_tt_desc.custom_minimum_size = Vector2(120, 0)
	vbox.add_child(_tt_desc)

	_tt_cost = Label.new()
	_tt_cost.add_theme_font_size_override("font_size", 8)
	_tt_cost.add_theme_color_override(
		"font_color", AntColonyUI.ACCENT_ORANGE,
	)
	vbox.add_child(_tt_cost)

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


func _on_circle_entered(
	circle: Control, skill: Dictionary,
	col: Color, ring: TextureRect,
) -> void:
	ring.modulate = col
	var clean: String = skill.name.replace("\n", " ")
	_tt_name.text = clean
	_tt_desc.text = skill.desc
	_tt_cost.text = "Cost: " + skill.cost
	_tooltip.visible = true

	var gp: Vector2 = circle.global_position
	var tx: float = clampf(
		gp.x, 4.0,
		AntColonyUI.VIEWPORT_W - 150.0,
	)
	var ty: float = gp.y - 52.0
	if ty < 4.0:
		ty = gp.y + CIRCLE_SZ + 4.0
	_tooltip.position = Vector2(tx, ty)


func _on_circle_exited(ring: TextureRect) -> void:
	ring.modulate = Color(0.5, 0.45, 0.38, 0.7)
	_tooltip.visible = false


func _on_circle_input(
	event: InputEvent, skill: Dictionary,
	ring: TextureRect, col: Color,
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
			ring.texture = _circle_ring
			ring.modulate = col
		1:
			ring.texture = _circle_filled
			ring.modulate = col
		2:
			ring.texture = _circle_filled
			ring.modulate = AntColonyUI.NODE_LOCKED


# =============================================================
# SKILL DATA (tier layout from reference images)
# =============================================================


func _sk(
	n: String, d: String, c: String,
) -> Dictionary:
	return {
		"name": n, "desc": d,
		"cost": c, "state": 0,
	}


func _player_tiers() -> Array:
	return [
		[_sk(
			"Auto\nMining",
			"Dig blocks by walking into them",
			"50 Food",
		)],
		[_sk(
			"Dig\nStrength",
			"Increase dig damage per hit",
			"Scaling 0/50",
		)],
		[
			_sk("Food\nMagnet",
				"Attract nearby food drops",
				"25 Food ea"),
			_sk("Player\nSpeed",
				"Increase movement speed",
				"25 Food ea"),
			_sk("Carry\nCap",
				"Carry more food at once",
				"25 Food ea"),
		],
		[
			_sk("Dig\nRange",
				"Mine blocks further away",
				"Pick 2 of 3"),
			_sk("Dig\nSpeed",
				"Mine blocks faster",
				"Pick 2 of 3"),
			_sk("Dig\nRadius",
				"Mine a larger area",
				"Pick 2 of 3"),
		],
		[
			_sk("Auto\nWorker",
				"Workers dig without orders",
				"200 Food"),
			_sk("Architect\nAnt",
				"Unlock building mode",
				"300 Food"),
			_sk("Auto\nEvolve",
				"Auto-pick cheapest upgrade",
				"500 Food"),
		],
		[
			_sk("Gun",
				"Shoot blocks from distance",
				"Pick 1 of 4"),
			_sk("Laser",
				"Continuous beam mining",
				"Pick 1 of 4"),
			_sk("Acid",
				"Dissolve blocks over time",
				"Pick 1 of 4"),
			_sk("Explode",
				"Blast large areas",
				"Pick 1 of 4"),
		],
	]


func _logistics_tiers() -> Array:
	return [
		[_sk(
			"Place\nDirt",
			"Place mined dirt blocks",
			"50 Food",
		)],
		[_sk(
			"Transport\nCap",
			"More items per transport trip",
			"Scaling 0/10",
		)],
		[
			_sk("Elevator",
				"Vertical shaft transport",
				"Pick 1 of 4"),
			_sk("Minecart",
				"Rail-based hauling",
				"Pick 1 of 4"),
			_sk("Platform",
				"Moving platforms",
				"Pick 1 of 4"),
			_sk("Zipline",
				"Zipline transport",
				"Pick 1 of 4"),
		],
		[
			_sk("Pheromone\nHwy",
				"Workers follow pheromones",
				"150 Food"),
			_sk("Auto\nConveyor",
				"Auto-route conveyor belts",
				"200 Food"),
		],
		[
			_sk("Tramway",
				"Aerial cable car transport",
				"Pick 1 of 2"),
			_sk("Conveyor\nBelt",
				"Automated belt system",
				"Pick 1 of 2"),
		],
		[
			_sk("Legs",
				"Extra legs for climbing",
				"Pick 1 of 4"),
			_sk("Grapple",
				"Grappling hook movement",
				"Pick 1 of 4"),
			_sk("Jetpack",
				"Fly short distances",
				"Pick 1 of 4"),
			_sk("Jump",
				"Super jump ability",
				"Pick 1 of 4"),
		],
		[
			_sk("Teleport",
				"Instant teleportation",
				"Pick 1 of 2"),
			_sk("Tubes",
				"Pneumatic tube network",
				"Pick 1 of 2"),
		],
	]


func _colony_tiers() -> Array:
	return [
		[_sk(
			"Unlock\nWorkers",
			"Hire your first workers",
			"100 Food",
		)],
		[_sk(
			"Miner\nStrength",
			"Workers dig harder",
			"Scaling 0/50",
		)],
		[
			_sk("Ant\nSpeed",
				"Workers move faster",
				"25 Food ea"),
			_sk("Haul\nCap",
				"Workers carry more food",
				"25 Food ea"),
		],
		[
			_sk("Cannon",
				"Launch food via cannon",
				"Pick 1 of 3"),
			_sk("Singularity",
				"Gravity well collection",
				"Pick 1 of 3"),
			_sk("Relay",
				"Worker relay chain",
				"Pick 1 of 3"),
		],
		[
			_sk("Dig\nRange",
				"Miners reach further",
				"Pick 2 of 3"),
			_sk("Dig\nSpeed",
				"Miners dig faster",
				"Pick 2 of 3"),
			_sk("Dig\nRadius",
				"Miners dig wider",
				"Pick 2 of 3"),
		],
		[
			_sk("Gun",
				"Armed miner ants",
				"Pick 1 of 4"),
			_sk("Laser",
				"Laser mining ants",
				"Pick 1 of 4"),
			_sk("Acid",
				"Acid spraying ants",
				"Pick 1 of 4"),
			_sk("Explode",
				"Demolition ants",
				"Pick 1 of 4"),
		],
	]
