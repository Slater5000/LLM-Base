extends Node2D
## Simple procgen tester. Press keys to see each technique.

var current_demo := 0
var seed_value := 1

# Demo names
const DEMOS := ["NOISE", "POISSON", "BSP", "L-SYSTEM", "WFC"]

# Cached results
var _noise: NoiseTerrain
var _poisson_points: Array[Vector2] = []
var _bsp_result: BSPDungeon.DungeonResult
var _lsystem_segments: Array[LSystem.Segment] = []
var _wfc_grid: Array[Array] = []

func _ready() -> void:
	_generate_current()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		current_demo = (current_demo + 1) % DEMOS.size()
		_generate_current()
	elif event.is_action_pressed("ui_left"):
		current_demo = (current_demo - 1 + DEMOS.size()) % DEMOS.size()
		_generate_current()
	elif event.is_action_pressed("ui_accept"):  # Space/Enter
		seed_value += 1
		_generate_current()
	elif event.is_action_pressed("ui_cancel"):  # Escape
		get_tree().quit()

func _generate_current() -> void:
	match current_demo:
		0: _gen_noise()
		1: _gen_poisson()
		2: _gen_bsp()
		3: _gen_lsystem()
		4: _gen_wfc()
	queue_redraw()

func _gen_noise() -> void:
	_noise = NoiseTerrain.new(seed_value)
	_noise.apply_preset(NoiseTerrain.NoisePreset.GRASS_PATCHES)

func _gen_poisson() -> void:
	var sampler := PoissonDisk.new(seed_value)
	_poisson_points = sampler.generate(Rect2(50, 100, 500, 400), 30.0)

func _gen_bsp() -> void:
	var dungeon := BSPDungeon.new(seed_value)
	_bsp_result = dungeon.generate(30, 22)
	dungeon.tag_special_rooms(_bsp_result)

func _gen_lsystem() -> void:
	var lsys := LSystem.new(seed_value)
	lsys.set_river_preset()
	lsys.step_length = 25.0
	_lsystem_segments = lsys.generate_and_interpret(Vector2(300, 80), Vector2.DOWN)

func _gen_wfc() -> void:
	var wfc := WFCSimple.new(seed_value)
	wfc.setup_basic_terrain()
	_wfc_grid = wfc.generate(28, 20)

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 600, 550), Color(0.1, 0.1, 0.12))

	# Title
	var title := "%s (seed: %d)" % [DEMOS[current_demo], seed_value]
	draw_string(ThemeDB.fallback_font, Vector2(20, 30), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)

	# Controls
	draw_string(ThemeDB.fallback_font, Vector2(20, 530), "LEFT/RIGHT = switch | SPACE = new seed | ESC = quit", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GRAY)

	# Draw current demo
	match current_demo:
		0: _draw_noise()
		1: _draw_poisson()
		2: _draw_bsp()
		3: _draw_lsystem()
		4: _draw_wfc()

func _draw_noise() -> void:
	if not _noise:
		return
	var offset := Vector2(50, 100)
	var size := 16
	for x in 32:
		for y in 25:
			var val := _noise.sample(x * 3, y * 3)
			var color: Color
			if val > 0.6:
				color = Color(0.2, 0.7, 0.2)  # Tall grass
			elif val > 0.35:
				color = Color(0.25, 0.5, 0.25)  # Short grass
			else:
				color = Color(0.15, 0.25, 0.15)  # Ground
			draw_rect(Rect2(offset + Vector2(x * size, y * size), Vector2(size, size)), color)

	draw_string(ThemeDB.fallback_font, Vector2(50, 520), "Dark=ground  Medium=short grass  Bright=tall grass", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)

func _draw_poisson() -> void:
	# Border
	draw_rect(Rect2(50, 100, 500, 400), Color(0.2, 0.2, 0.2))

	for point in _poisson_points:
		draw_circle(point, 5, Color(0.3, 0.8, 0.4))
		draw_arc(point, 15, 0, TAU, 12, Color(0.2, 0.4, 0.2, 0.4), 1)

	draw_string(ThemeDB.fallback_font, Vector2(50, 520), "Points evenly spaced - no clumping! (%d points)" % _poisson_points.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)

func _draw_bsp() -> void:
	if not _bsp_result:
		return
	var offset := Vector2(50, 100)
	var size := 16

	# Walls
	draw_rect(Rect2(offset, Vector2(30 * size, 22 * size)), Color(0.25, 0.2, 0.2))

	# Rooms
	for node in _bsp_result.room_nodes:
		var room := node.room
		var rect := Rect2(offset + Vector2(room.position) * size, Vector2(room.size) * size)
		var color: Color
		match node.room_type:
			"entrance": color = Color(0.3, 0.6, 0.3)
			"boss": color = Color(0.7, 0.2, 0.2)
			"treasure": color = Color(0.8, 0.7, 0.2)
			_: color = Color(0.5, 0.45, 0.4)
		draw_rect(rect, color)

	# Corridors
	for corridor in _bsp_result.corridors:
		var rect := Rect2(offset + Vector2(corridor.position) * size, Vector2(corridor.size) * size)
		draw_rect(rect, Color(0.4, 0.35, 0.3))

	draw_string(ThemeDB.fallback_font, Vector2(50, 520), "Green=entrance  Red=boss  Yellow=treasure  (%d rooms)" % _bsp_result.rooms.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)

func _draw_lsystem() -> void:
	var offset := Vector2(0, 20)

	# Background
	draw_rect(Rect2(50, 100, 500, 400), Color(0.15, 0.2, 0.15))

	for segment in _lsystem_segments:
		var start := offset + segment.start
		var end := offset + segment.end
		var alpha := 1.0 - segment.depth * 0.2
		draw_line(start, end, Color(0.3, 0.5, 0.8, alpha), segment.width)

	draw_string(ThemeDB.fallback_font, Vector2(50, 520), "River branches naturally - thicker=main, thinner=tributaries", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)

func _draw_wfc() -> void:
	if _wfc_grid.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(200, 300), "WFC failed - press SPACE to retry", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.RED)
		return

	var offset := Vector2(50, 100)
	var size := 18
	var colors := {
		"grass": Color(0.3, 0.55, 0.3),
		"path": Color(0.55, 0.5, 0.4),
		"dirt": Color(0.5, 0.4, 0.3),
		"sand": Color(0.85, 0.8, 0.55),
		"water": Color(0.25, 0.45, 0.75)
	}

	for x in _wfc_grid.size():
		for y in _wfc_grid[x].size():
			var tile: String = _wfc_grid[x][y]
			var rect := Rect2(offset + Vector2(x * size, y * size), Vector2(size, size))
			draw_rect(rect, colors.get(tile, Color.MAGENTA))

	draw_string(ThemeDB.fallback_font, Vector2(50, 520), "Tiles respect adjacency rules - water only touches sand!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.GRAY)
