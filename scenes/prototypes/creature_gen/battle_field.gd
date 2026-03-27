extends Node2D
## HoMM2-style battle screen with Dead Cells-style spider-monkey creatures.
## Left army (warm palette) vs right army (cool palette), 3 stacks each.
## Press Space to regenerate with new random palettes.

const SpiderMonkeyBake := preload(
	"res://scenes/prototypes/creature_gen/spider_monkey_bake.gd"
)

# Battlefield matches viewport: 640x360
const FIELD_W := 640.0
const FIELD_H := 360.0

# Army zones
const LEFT_X := 80.0
const RIGHT_X := 560.0

# 3 vertical stack positions per side
const STACK_Y := [135.0, 210.0, 285.0]

# Backdrop shapes
var _mountains: Array[Dictionary] = []

# Creature + label nodes for cleanup
var _army_nodes: Array[Node] = []


func _ready() -> void:
	_generate_backdrop()
	_spawn_armies()


func _generate_backdrop() -> void:
	_mountains.clear()
	var num_peaks := randi_range(5, 7)
	for i: int in num_peaks:
		_mountains.append({
			"x": randf_range(-40.0, FIELD_W + 40.0),
			"w": randf_range(90.0, 180.0),
			"h": randf_range(35.0, 70.0),
			"shade": randf_range(0.25, 0.40),
		})


func _spawn_armies() -> void:
	for node: Node in _army_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_army_nodes.clear()

	# Left army — 3 stacks, warm palette, facing right
	for i: int in STACK_Y.size():
		var count := randi_range(3, 25)
		var x_pos := LEFT_X + randf_range(-8.0, 8.0)
		_spawn_stack(
			Vector2(x_pos, STACK_Y[i]), 1.0, false,
			_random_warm_palette(), count,
		)

	# Right army — 3 stacks, cool palette, facing left
	for i: int in STACK_Y.size():
		var count := randi_range(3, 25)
		var x_pos := RIGHT_X + randf_range(-8.0, 8.0)
		_spawn_stack(
			Vector2(x_pos, STACK_Y[i]), 1.0, true,
			_random_cool_palette(), count,
		)

	queue_redraw()


func _spawn_stack(
	pos: Vector2, scl: float, flip: bool,
	pal: Dictionary, count: int,
) -> void:
	var creature := Node2D.new()
	creature.set_script(SpiderMonkeyBake)
	creature.position = pos
	creature.creature_scale = scl
	creature.facing_left = flip
	creature.phase_offset = randf() * 10.0
	creature.walk_speed = randf_range(3.5, 5.5)
	creature.fur_color = pal["fur"]
	creature.fur_outline = pal["fur_outline"]
	creature.spider_color = pal["spider"]
	creature.spider_outline = pal["spider_outline"]
	creature.belly_color = pal["belly"]
	creature.eye_color = pal["eye"]
	creature.leg_color = pal["leg"]
	creature.leg_outline = pal["leg_outline"]
	creature.staff_orb = pal["orb"]
	creature.staff_glow = pal["glow"]
	add_child(creature)
	_army_nodes.append(creature)

	# Count label (HoMM2-style number below creature)
	var label := Label.new()
	label.text = str(count)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(pos.x - 10.0, pos.y + 16.0 * scl + 2.0)
	label.size = Vector2(20.0, 12.0)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.85))
	label.add_theme_color_override(
		"font_outline_color", Color(0.15, 0.08, 0.0),
	)
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)
	_army_nodes.append(label)


# ═══════════════════════════════════════════════════════════
# PALETTES
# ═══════════════════════════════════════════════════════════

func _random_warm_palette() -> Dictionary:
	var hue := randf_range(0.02, 0.12)
	var sat := randf_range(0.40, 0.65)
	var val := randf_range(0.30, 0.50)
	var orb_hue := randf_range(0.0, 0.15)
	return {
		"fur": Color.from_hsv(hue, sat, val),
		"fur_outline": Color.from_hsv(hue, sat - 0.10, val + 0.15),
		"spider": Color.from_hsv(hue + 0.02, sat * 0.5, val * 0.6),
		"spider_outline": Color.from_hsv(
			hue + 0.02, sat * 0.4, val * 0.5 + 0.1,
		),
		"belly": Color.from_hsv(hue + 0.04, sat - 0.20, val + 0.20),
		"eye": Color.from_hsv(
			randf_range(0.0, 0.05), 0.85, 0.80,
		),
		"leg": Color.from_hsv(
			randf_range(0.10, 0.14), randf_range(0.55, 0.70),
			randf_range(0.45, 0.60),
		),
		"leg_outline": Color.from_hsv(0.10, 0.40, 0.25),
		"orb": Color.from_hsv(orb_hue, 0.70, 0.85),
		"glow": Color.from_hsv(orb_hue, 0.45, 0.95, 0.6),
	}


func _random_cool_palette() -> Dictionary:
	var hue := randf_range(0.55, 0.80)
	var sat := randf_range(0.30, 0.55)
	var val := randf_range(0.22, 0.40)
	var orb_hue := randf_range(0.75, 1.0)
	return {
		"fur": Color.from_hsv(hue, sat, val),
		"fur_outline": Color.from_hsv(hue, sat - 0.10, val + 0.12),
		"spider": Color.from_hsv(hue + 0.05, sat * 0.5, val * 0.5),
		"spider_outline": Color.from_hsv(
			hue + 0.05, sat * 0.4, val * 0.5 + 0.08,
		),
		"belly": Color.from_hsv(hue - 0.05, sat - 0.15, val + 0.15),
		"eye": Color.from_hsv(
			randf_range(0.30, 0.42), 0.80, 0.80,
		),
		"leg": Color.from_hsv(
			randf_range(0.10, 0.15), randf_range(0.50, 0.65),
			randf_range(0.40, 0.55),
		),
		"leg_outline": Color.from_hsv(0.12, 0.35, 0.20),
		"orb": Color.from_hsv(orb_hue, 0.60, 0.75),
		"glow": Color.from_hsv(orb_hue, 0.40, 0.85, 0.5),
	}


# ═══════════════════════════════════════════════════════════
# DRAW — Background, terrain, bottom bar
# ═══════════════════════════════════════════════════════════

func _draw() -> void:
	_draw_sky()
	_draw_mountains()
	_draw_grass_field()
	_draw_field_details()
	_draw_bottom_bar()


func _draw_sky() -> void:
	var sky_h := 85.0
	var steps := 10
	for i: int in steps:
		var t := float(i) / float(steps)
		var c := Color(
			lerpf(0.45, 0.72, t),
			lerpf(0.60, 0.82, t),
			lerpf(0.85, 0.93, t),
		)
		var y0 := t * sky_h
		var y1 := (t + 1.0 / float(steps)) * sky_h
		draw_rect(Rect2(0, y0, FIELD_W, y1 - y0 + 1), c, true)
	# Clouds
	draw_circle(Vector2(120, 25), 16.0, Color(1, 1, 1, 0.35))
	draw_circle(Vector2(140, 22), 12.0, Color(1, 1, 1, 0.30))
	draw_circle(Vector2(105, 30), 10.0, Color(1, 1, 1, 0.25))
	draw_circle(Vector2(440, 30), 14.0, Color(1, 1, 1, 0.28))
	draw_circle(Vector2(458, 26), 11.0, Color(1, 1, 1, 0.22))
	draw_circle(Vector2(300, 18), 10.0, Color(1, 1, 1, 0.18))


func _draw_mountains() -> void:
	var base_y := 85.0
	for m: Dictionary in _mountains:
		var px: float = m["x"]
		var pw: float = m["w"]
		var ph: float = m["h"]
		var shade: float = m["shade"]
		var color := Color(shade * 0.6, shade, shade * 0.5)
		var pts := PackedVector2Array([
			Vector2(px - pw * 0.5, base_y),
			Vector2(px - pw * 0.15, base_y - ph * 0.7),
			Vector2(px, base_y - ph),
			Vector2(px + pw * 0.15, base_y - ph * 0.7),
			Vector2(px + pw * 0.5, base_y),
		])
		draw_colored_polygon(pts, color)
		if ph > 50.0:
			var snow := PackedVector2Array([
				Vector2(px - pw * 0.05, base_y - ph * 0.88),
				Vector2(px, base_y - ph),
				Vector2(px + pw * 0.05, base_y - ph * 0.88),
			])
			draw_colored_polygon(snow, Color(0.9, 0.92, 0.95, 0.6))


func _draw_grass_field() -> void:
	var field_top := 72.0
	var field_bottom := FIELD_H - 35.0
	var field_range := field_bottom - field_top
	var steps := 16
	for i: int in steps:
		var t := float(i) / float(steps)
		var c := Color(
			lerpf(0.30, 0.15, t),
			lerpf(0.50, 0.28, t),
			lerpf(0.18, 0.08, t),
		)
		var y0 := field_top + t * field_range
		var y1 := field_top + (t + 1.0 / float(steps)) * field_range
		draw_rect(Rect2(0, y0, FIELD_W, y1 - y0 + 1), c, true)
	# Dirt patches
	_draw_dirt_patch(280.0, 200.0, 45.0, 22.0)
	_draw_dirt_patch(350.0, 250.0, 35.0, 16.0)
	_draw_dirt_patch(220.0, 270.0, 30.0, 14.0)
	_draw_dirt_patch(400.0, 175.0, 25.0, 12.0)
	# Grass dots
	var grass_seed := 42
	for i: int in 50:
		var gx := fmod(float(grass_seed + i * 137) * 7.31, FIELD_W)
		var gy := fmod(
			float(grass_seed + i * 211) * 3.17, field_range - 20.0,
		) + field_top + 10.0
		var bright := 0.02 if i % 3 == 0 else -0.02
		draw_circle(
			Vector2(gx, gy), 1.5,
			Color(
				0.22 + bright, 0.38 + bright,
				0.12 + bright, 0.4,
			),
		)


func _draw_dirt_patch(
	cx: float, cy: float, rx: float, ry: float,
) -> void:
	var pts := PackedVector2Array()
	var segs := 14
	for i: int in segs:
		var angle := float(i) / float(segs) * TAU
		pts.append(Vector2(cx + cos(angle) * rx, cy + sin(angle) * ry))
	draw_colored_polygon(pts, Color(0.30, 0.22, 0.12, 0.5))
	var inner := PackedVector2Array()
	for i: int in segs:
		var angle := float(i) / float(segs) * TAU
		inner.append(Vector2(
			cx + cos(angle) * rx * 0.55,
			cy + sin(angle) * ry * 0.55,
		))
	draw_colored_polygon(inner, Color(0.28, 0.20, 0.10, 0.35))


func _draw_field_details() -> void:
	# Rocks
	_draw_rock(300.0, 210.0, 12.0, 8.0)
	_draw_rock(340.0, 160.0, 8.0, 5.0)
	_draw_rock(280.0, 285.0, 10.0, 7.0)
	# Flower clusters
	for i: int in 4:
		_draw_flower_cluster(
			490.0 + float(i) * 18.0,
			260.0 + float(i % 3) * 20.0,
		)


func _draw_rock(cx: float, cy: float, rx: float, ry: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 8:
		var angle := float(i) / 8.0 * TAU
		var jitter := 1.0 + sin(float(i) * 2.7) * 0.15
		pts.append(Vector2(
			cx + cos(angle) * rx * jitter,
			cy + sin(angle) * ry * jitter,
		))
	draw_colored_polygon(pts, Color(0.45, 0.43, 0.40))
	draw_circle(
		Vector2(cx - rx * 0.2, cy - ry * 0.3),
		minf(rx, ry) * 0.4, Color(0.55, 0.53, 0.50, 0.5),
	)


func _draw_flower_cluster(cx: float, cy: float) -> void:
	for j: int in 3:
		var fx := cx + float(j) * 3.0 - 3.0
		var fy := cy + sin(float(j)) * 2.0
		draw_circle(
			Vector2(fx, fy), 1.5,
			Color(0.8, 0.3 + float(j) * 0.15, 0.4, 0.7),
		)
		draw_line(
			Vector2(fx, fy + 1.5), Vector2(fx, fy + 4.5),
			Color(0.2, 0.45, 0.15, 0.6), 1.0,
		)


func _draw_bottom_bar() -> void:
	var bar_y := FIELD_H - 35.0
	draw_rect(Rect2(0, bar_y, FIELD_W, 35.0), Color(0.55, 0.45, 0.30), true)
	draw_rect(
		Rect2(3, bar_y + 3, FIELD_W - 6.0, 29.0),
		Color(0.65, 0.55, 0.38), true,
	)
	draw_line(
		Vector2(0, bar_y), Vector2(FIELD_W, bar_y),
		Color(0.75, 0.60, 0.30), 2.0,
	)
	draw_line(
		Vector2(0, bar_y + 2), Vector2(FIELD_W, bar_y + 2),
		Color(0.40, 0.30, 0.15), 1.0,
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(FIELD_W * 0.5 - 110.0, bar_y + 22.0),
		"Spider-monkeys prepare for battle!",
		HORIZONTAL_ALIGNMENT_CENTER, 220, 11,
		Color(0.15, 0.10, 0.05),
	)
	# AUTO button
	draw_rect(Rect2(6, bar_y + 6, 36, 20), Color(0.50, 0.40, 0.25), true)
	draw_rect(
		Rect2(6, bar_y + 6, 36, 20),
		Color(0.70, 0.55, 0.30), false, 1.0,
	)
	draw_string(
		ThemeDB.fallback_font, Vector2(11, bar_y + 21),
		"AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Color(0.95, 0.90, 0.75),
	)
	# SKIP button
	draw_rect(
		Rect2(FIELD_W - 42, bar_y + 6, 36, 20),
		Color(0.50, 0.40, 0.25), true,
	)
	draw_rect(
		Rect2(FIELD_W - 42, bar_y + 6, 36, 20),
		Color(0.70, 0.55, 0.30), false, 1.0,
	)
	draw_string(
		ThemeDB.fallback_font,
		Vector2(FIELD_W - 37, bar_y + 21),
		"SKIP", HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Color(0.95, 0.90, 0.75),
	)


# ═══════════════════════════════════════════════════════════
# INPUT
# ═══════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_generate_backdrop()
		_spawn_armies()
