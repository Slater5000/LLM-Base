extends Node2D
## Arcradar-style skill tree. Three prongs from shared trunk.
## Player Ant (left), Logistics (center), Colony (right).
## Scrollable — trunk at bottom, endgame at top.

const NODE_SZ := 30.0
const FORK_SZ := 20.0
const LINE_W := 2.5
const TRUNK_SZ := 22.0
const ROW_STEP := 40.0
const FORK_DROP := 13.0
const SCROLL_SPEED := 24.0
const START_Y := 36.0

const TREE_CX := [160.0, 320.0, 480.0]
const TREE_TITLES := [
	"PLAYER ANT", "LOGISTICS", "COLONY",
]
const LABEL_DIRS := [1, 1, -1]

const FORK_OFFSETS := {
	2: [-28.0, 28.0],
	3: [-42.0, 0.0, 42.0],
	4: [-56.0, -19.0, 19.0, 56.0],
}

const TREE_COLS := [
	Color(0.4, 0.85, 0.4, 1.0),
	Color(0.9, 0.78, 0.2, 1.0),
	Color(0.9, 0.3, 0.3, 1.0),
]
const COL_LABEL := Color(0.75, 0.7, 0.6, 0.9)
const COL_INACTIVE := Color(0.55, 0.5, 0.4, 0.8)
const COL_TRUNK := Color(0.8, 0.7, 0.55, 1.0)
const COL_TT_BG := Color(0.08, 0.06, 0.04, 0.92)
const COL_TT_BORDER := Color(0.5, 0.4, 0.3, 0.8)

const LABEL_SZ := 7
const TITLE_SZ := 9
const TT_NAME_SZ := 8
const TT_DESC_SZ := 6

var circle_ring: Texture2D
var circle_filled: Texture2D
var node_states: Dictionary = {}

var _trees: Array[Array] = []
var _hits: Array[Dictionary] = []
var _trunk_y := 0.0
var _content_h := 0.0
var _scroll_y := 0.0
var _max_scroll := 0.0
var _hovered := ""


func _ready() -> void:
	circle_ring = load(AntColonyUI.CIRCLE_RING)
	circle_filled = load(AntColonyUI.CIRCLE_FILLED)
	_build_data()
	_compute_layout()
	_scroll_y = _max_scroll
	position.y = -_scroll_y


func _process(_delta: float) -> void:
	var mpos := get_local_mouse_position()
	var key := _find_hover(mpos)
	if key != _hovered:
		_hovered = key
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_scroll_y = maxf(
			_scroll_y - SCROLL_SPEED, 0.0,
		)
		position.y = -_scroll_y
		queue_redraw()
	elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll_y = minf(
			_scroll_y + SCROLL_SPEED, _max_scroll,
		)
		position.y = -_scroll_y
		queue_redraw()
	elif mb.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(to_local(mb.position))


# --- Data helpers ---


func _s(n: String, d: String) -> Dictionary:
	return {"name": n, "desc": d, "type": "std"}


func _f(
	n: String, d: String, opts: Array,
) -> Dictionary:
	return {
		"name": n, "desc": d,
		"type": "fork", "opts": opts,
	}


func _o(n: String, d: String) -> Dictionary:
	return {"name": n, "desc": d}


# --- Tree definitions (bottom→top order) ---


func _build_data() -> void:
	_trees = [
		_player_data(),
		_logistics_data(),
		_colony_data(),
	]


func _player_data() -> Array:
	return [
		_s("Auto Mining", "Dig by walking into blocks"),
		_s("Dig Str", "Increase dig damage per hit"),
		_s("Food Magnet", "Attract nearby food drops"),
		_s("Player Speed", "Increase movement speed"),
		_s("Carry Cap", "Carry more food at once"),
		_f("Dig Stats", "Improve digging stats", [
			_o("Range", "Mine further away"),
			_o("Speed", "Mine faster"),
			_o("Radius", "Mine larger area"),
		]),
		_s("Auto Worker", "Workers dig without orders"),
		_s("Architect", "Unlock building mode"),
		_s("Auto Evolve", "Auto-pick cheapest upgrade"),
		_f("Dig Method", "Choose dig method", [
			_o("Gun", "Shoot from distance"),
			_o("Laser", "Continuous beam"),
			_o("Acid", "Dissolve over time"),
			_o("Explode", "Blast large areas"),
		]),
	]


func _logistics_data() -> Array:
	return [
		_s("Place Dirt", "Place mined dirt blocks"),
		_s("Transport Cap", "More items per trip"),
		_f("Tier 1", "First transport", [
			_o("Elevator", "Vertical shaft"),
			_o("Minecart", "Rail hauling"),
			_o("Platform", "Moving platforms"),
			_o("Zip", "Zipline transport"),
		]),
		_s("Pheromone Hwy", "Workers follow pheromones"),
		_s("Auto Conveyor", "Auto-route conveyors"),
		_f("Tier 2", "Advanced transport", [
			_o("Tramway", "Aerial cable car"),
			_o("Conveyor", "Automated belts"),
		]),
		_f("Traversal", "Choose traversal", [
			_o("Legs", "Climb walls"),
			_o("Grapple", "Grappling hook"),
			_o("Jetpack", "Short flight"),
			_o("Jump", "Super jump"),
		]),
		_f("Endgame", "Ultimate transport", [
			_o("Teleport", "Instant teleport"),
			_o("Tubes", "Pneumatic tubes"),
		]),
	]


func _colony_data() -> Array:
	return [
		_s("Unlock Workers", "Hire first workers"),
		_s("Miner Str", "Workers dig harder"),
		_s("Ant Speed", "Workers move faster"),
		_s("Haul Cap", "Workers carry more"),
		_f("Haul Eff", "Choose haul method", [
			_o("Cannon", "Launch via cannon"),
			_o("Singularity", "Gravity collection"),
			_o("Relay", "Worker relay chain"),
		]),
		_f("Miner Stats", "Improve miner stats", [
			_o("Range", "Miners reach further"),
			_o("Speed", "Miners dig faster"),
			_o("Radius", "Miners dig wider"),
		]),
		_f("Miner Dig", "Miner dig method", [
			_o("Gun", "Armed miners"),
			_o("Laser", "Laser miners"),
			_o("Acid", "Acid spray miners"),
			_o("Explode", "Demolition miners"),
		]),
	]


# --- Layout ---


func _compute_layout() -> void:
	_hits.clear()
	var max_n := 0
	for tree: Array in _trees:
		max_n = maxi(max_n, tree.size())

	var bottom_y: float = (
		START_Y + (max_n - 1) * ROW_STEP
	)
	_trunk_y = bottom_y + 30.0
	_content_h = _trunk_y + 24.0
	_max_scroll = maxf(
		0.0, _content_h - AntColonyUI.VIEWPORT_H,
	)

	for ti in _trees.size():
		var tree: Array = _trees[ti]
		var cx: float = TREE_CX[ti]
		for ei in tree.size():
			var entry: Dictionary = tree[ei]
			var ey: float = bottom_y - ei * ROW_STEP
			entry["pos"] = Vector2(cx, ey)

			if entry.type == "std":
				_hits.append({
					"key": entry.name,
					"pos": entry.pos,
					"r": NODE_SZ / 2.0 + 3.0,
					"name": entry.name,
					"desc": entry.desc,
				})

			if entry.type == "fork":
				_layout_fork(entry, cx, ey)


func _layout_fork(
	entry: Dictionary, cx: float, ey: float,
) -> void:
	var opts: Array = entry.get("opts", [])
	var offs: Array = FORK_OFFSETS[opts.size()]
	var op_arr: Array[Vector2] = []
	for oi in opts.size():
		var opos := Vector2(
			cx + offs[oi], ey + FORK_DROP,
		)
		op_arr.append(opos)
		var okey: String = (
			entry.name + "_" + str(oi)
		)
		var opt: Dictionary = opts[oi]
		_hits.append({
			"key": okey,
			"pos": opos,
			"r": FORK_SZ / 2.0 + 3.0,
			"name": opt.name,
			"desc": opt.desc,
		})
	entry["opos"] = op_arr


# --- Drawing ---


func _draw() -> void:
	if _trees.is_empty():
		return

	var tp := Vector2(320.0, _trunk_y)
	var tsz := Vector2(TRUNK_SZ, TRUNK_SZ)
	draw_texture_rect(
		circle_filled,
		Rect2(tp - tsz / 2.0, tsz),
		false, COL_TRUNK,
	)

	for ti in _trees.size():
		var tree: Array = _trees[ti]
		if tree.size() > 0:
			_draw_line(
				tp, tree[0].pos, TREE_COLS[ti],
			)

	for ti in _trees.size():
		_draw_tree(ti)

	if not _hovered.is_empty():
		_draw_tooltip()


func _draw_tree(ti: int) -> void:
	var tree: Array = _trees[ti]
	var col: Color = TREE_COLS[ti]
	var ldir: int = LABEL_DIRS[ti]
	var n: int = tree.size()

	for i in range(n - 1):
		_draw_line(tree[i].pos, tree[i + 1].pos, col)

	for entry: Dictionary in tree:
		if entry.type == "std":
			_draw_node(entry, col, ldir)
		else:
			_draw_fork(entry, col)

	var top_y: float = tree[n - 1].pos.y - 18.0
	_draw_centered(
		TREE_TITLES[ti],
		Vector2(TREE_CX[ti], top_y),
		col, TITLE_SZ,
	)


func _draw_node(
	entry: Dictionary, col: Color, ldir: int,
) -> void:
	var pos: Vector2 = entry.pos
	var key: String = entry.name
	var state: int = node_states.get(key, 0)

	var tex: Texture2D = circle_ring
	var tint := COL_INACTIVE
	if state == 1:
		tex = circle_filled
		tint = col
	elif state == 2:
		tex = circle_filled
		tint = AntColonyUI.NODE_LOCKED
	if _hovered == key:
		tint = tint.lightened(0.25)

	var sz := Vector2(NODE_SZ, NODE_SZ)
	draw_texture_rect(
		tex, Rect2(pos - sz / 2.0, sz),
		false, tint,
	)

	var font := ThemeDB.fallback_font
	var tw: float = font.get_string_size(
		key, HORIZONTAL_ALIGNMENT_LEFT,
		-1, LABEL_SZ,
	).x
	var lx: float
	if ldir > 0:
		lx = pos.x + NODE_SZ / 2.0 + 4.0
	else:
		lx = pos.x - NODE_SZ / 2.0 - 4.0 - tw
	draw_string(
		font, Vector2(lx, pos.y + 3.0),
		key, HORIZONTAL_ALIGNMENT_LEFT,
		-1, LABEL_SZ, COL_LABEL,
	)


func _draw_fork(
	entry: Dictionary, col: Color,
) -> void:
	var opos_arr: Array = entry.get("opos", [])
	var opts: Array = entry.get("opts", [])
	var bpos: Vector2 = entry.pos

	for p: Vector2 in opos_arr:
		_draw_line(bpos, p, col)

	for i in opts.size():
		var okey: String = (
			entry.name + "_" + str(i)
		)
		var state: int = node_states.get(okey, 0)
		var tex: Texture2D = circle_ring
		var tint := COL_INACTIVE
		if state == 1:
			tex = circle_filled
			tint = col
		elif state == 2:
			tex = circle_filled
			tint = AntColonyUI.NODE_LOCKED
		if _hovered == okey:
			tint = tint.lightened(0.25)

		var osz := Vector2(FORK_SZ, FORK_SZ)
		var op: Vector2 = opos_arr[i]
		draw_texture_rect(
			tex, Rect2(op - osz / 2.0, osz),
			false, tint,
		)


func _draw_tooltip() -> void:
	var info: Dictionary = {}
	for nd: Dictionary in _hits:
		if nd.key == _hovered:
			info = nd
			break
	if info.is_empty():
		return

	var font := ThemeDB.fallback_font
	var nw: float = font.get_string_size(
		info.name, HORIZONTAL_ALIGNMENT_LEFT,
		-1, TT_NAME_SZ,
	).x
	var dw: float = font.get_string_size(
		info.desc, HORIZONTAL_ALIGNMENT_LEFT,
		-1, TT_DESC_SZ,
	).x
	var bw: float = maxf(nw, dw) + 12.0
	var bh := 28.0

	var mpos := get_local_mouse_position()
	var bx: float = clampf(
		mpos.x - bw / 2.0, 4.0,
		AntColonyUI.VIEWPORT_W - bw - 4.0,
	)
	var vis_top: float = _scroll_y
	var by: float = clampf(
		mpos.y - bh - 8.0,
		vis_top + 4.0,
		vis_top + AntColonyUI.VIEWPORT_H - bh - 4.0,
	)

	draw_rect(Rect2(bx, by, bw, bh), COL_TT_BG)
	draw_rect(
		Rect2(bx, by, bw, bh),
		COL_TT_BORDER, false, 1.0,
	)
	draw_string(
		font, Vector2(bx + 6.0, by + 12.0),
		info.name, HORIZONTAL_ALIGNMENT_LEFT,
		-1, TT_NAME_SZ, Color.WHITE,
	)
	draw_string(
		font, Vector2(bx + 6.0, by + 23.0),
		info.desc, HORIZONTAL_ALIGNMENT_LEFT,
		-1, TT_DESC_SZ, COL_LABEL,
	)


# --- Interaction ---


func _handle_click(lpos: Vector2) -> void:
	for nd: Dictionary in _hits:
		if lpos.distance_to(nd.pos) <= nd.r:
			_cycle_state(nd.key)
			queue_redraw()
			return


func _find_hover(local_pos: Vector2) -> String:
	for nd: Dictionary in _hits:
		if local_pos.distance_to(nd.pos) <= nd.r:
			return nd.key
	return ""


func _cycle_state(key: String) -> void:
	var cur: int = node_states.get(key, 0)
	node_states[key] = (cur + 1) % 3


func _draw_line(
	a: Vector2, b: Vector2, col: Color,
) -> void:
	draw_line(
		a, b, col * Color(1, 1, 1, 0.6), LINE_W,
	)


func _draw_centered(
	text: String, pos: Vector2,
	col: Color, sz: int,
) -> void:
	var font := ThemeDB.fallback_font
	var tw: float = font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz,
	).x
	draw_string(
		font,
		Vector2(pos.x - tw / 2.0, pos.y),
		text, HORIZONTAL_ALIGNMENT_LEFT,
		-1, sz, col,
	)
