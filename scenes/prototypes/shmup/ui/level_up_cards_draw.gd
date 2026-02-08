extends Node2D
## Draws upgrade cards for the level-up UI. Procedural icons, borders, glow, stars.

const UpgradeData := preload("res://scenes/prototypes/shmup/systems/upgrade_data.gd")

var ui: Node  # Reference to level_up_ui.gd

const CARD_W := 130.0
const CARD_H := 170.0
const BORDER_RADIUS := 2.0
const ICON_Y := 35.0  # Icon center Y offset within card
const NAME_Y := 72.0
const DESC_Y := 90.0
const STARS_Y := 142.0
const LEVEL_Y := 157.0

# Colors
const CARD_BG := Color(0.05, 0.05, 0.1, 0.85)
const CARD_BG_SEL := Color(0.08, 0.08, 0.15, 0.92)
const BORDER_DIM := Color(0.4, 0.4, 0.5, 0.3)
const STAR_FILLED := Color(1.0, 0.9, 0.3, 0.9)
const STAR_EMPTY := Color(0.3, 0.3, 0.4, 0.5)
const EVO_GOLD := Color(1.0, 0.85, 0.2, 1.0)
const TEXT_DIM := Color(0.7, 0.75, 0.8, 0.7)


func _draw() -> void:
	if not ui or not ui.is_showing or ui.choices.is_empty():
		return

	for i in ui.choices.size():
		_draw_card(i)


func _draw_card(index: int) -> void:
	var choice: Dictionary = ui.choices[index]
	var is_selected: bool = index == ui.selected_index
	var is_evo: bool = choice.get("is_evolution", false)

	var card_x: float = ui.get_card_x(index)
	var card_y: float = ui.get_card_y(index)
	var card_rect := Rect2(card_x, card_y, CARD_W, CARD_H)

	var accent_color: Color = choice.get("color", Color.WHITE)

	# --- Card background ---
	var bg_color: Color = CARD_BG_SEL if is_selected else CARD_BG
	draw_rect(card_rect, bg_color)

	# --- Border ---
	if is_evo:
		# Gold pulsing border for evolutions
		var pulse := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 300.0)
		var evo_color := EVO_GOLD
		evo_color.a = pulse
		_draw_border(card_rect, evo_color, 2.0 if is_selected else 1.5)
	elif is_selected:
		_draw_border(card_rect, accent_color, 2.0)
	else:
		_draw_border(card_rect, BORDER_DIM, 1.0)

	# --- Card alpha for unselected ---
	var alpha_mult := 1.0 if is_selected else 0.7

	# Scale for selected card
	# (We draw at slightly larger effective area via offset — simple approach)

	var cx := card_x + CARD_W / 2.0  # Card center X

	# --- Evolution tag ---
	if is_evo:
		var tag_color := EVO_GOLD
		tag_color.a = 0.9
		var tag_rect := Rect2(card_x + 10, card_y + 4, CARD_W - 20, 12)
		draw_rect(tag_rect, Color(0.2, 0.15, 0.0, 0.6))
		_draw_text_centered("EVOLUTION", cx, card_y + 14, 8, tag_color)

	# --- Icon (procedural shape) ---
	var icon_center := Vector2(cx, card_y + ICON_Y)
	var icon_shape: int = choice.get("icon_shape", UpgradeData.IconShape.DIAMOND)
	_draw_icon(icon_center, icon_shape, accent_color, is_selected)

	# --- Name ---
	var name_color := accent_color
	name_color.a *= alpha_mult
	_draw_text_centered(choice.get("name", ""), cx, card_y + NAME_Y, 10, name_color)

	# --- Description ---
	var desc_color := TEXT_DIM
	desc_color.a *= alpha_mult
	var desc: String = choice.get("description", "")
	_draw_text_wrapped(desc, card_x + 8, card_y + DESC_Y, CARD_W - 16, 8, desc_color)

	# --- Stars (level indicator) ---
	var max_level: int = choice.get("max_level", 1)
	var current_level: int = choice.get("current_level", 0)
	if not is_evo:
		_draw_stars(cx, card_y + STARS_Y, current_level + 1, max_level)
		# Level text
		var lvl_text := "Lv %d/%d" % [current_level + 1, max_level]
		_draw_text_centered(lvl_text, cx, card_y + LEVEL_Y, 8, TEXT_DIM)


func _draw_border(rect: Rect2, color: Color, width: float) -> void:
	var tl := rect.position
	var tr := Vector2(rect.end.x, rect.position.y)
	var br := rect.end
	var bl := Vector2(rect.position.x, rect.end.y)
	draw_line(tl, tr, color, width)
	draw_line(tr, br, color, width)
	draw_line(br, bl, color, width)
	draw_line(bl, tl, color, width)


func _draw_icon(center: Vector2, shape: int, color: Color, is_selected: bool) -> void:
	var size := 14.0 if is_selected else 12.0

	# Triple-layer glow (Nova Drift technique)
	var glow_color := color
	glow_color.a = 0.15
	_draw_shape_at(center, shape, size * 2.2, glow_color)

	var mid_color := color
	mid_color.a = 0.4
	_draw_shape_at(center, shape, size * 1.5, mid_color)

	_draw_shape_at(center, shape, size, color)


func _draw_shape_at(center: Vector2, shape: int, size: float, color: Color) -> void:
	match shape:
		UpgradeData.IconShape.DIAMOND:
			var pts := PackedVector2Array([
				center + Vector2(0, -size),
				center + Vector2(size * 0.6, 0),
				center + Vector2(0, size),
				center + Vector2(-size * 0.6, 0),
			])
			draw_colored_polygon(pts, color)

		UpgradeData.IconShape.CIRCLE:
			var pts := PackedVector2Array()
			for i in 12:
				var angle := i * TAU / 12.0 - PI / 2.0
				pts.append(center + Vector2(cos(angle), sin(angle)) * size * 0.6)
			draw_colored_polygon(pts, color)

		UpgradeData.IconShape.ARROW_UP:
			var pts := PackedVector2Array([
				center + Vector2(0, -size),           # Top point
				center + Vector2(size * 0.5, -size * 0.2),  # Right wing
				center + Vector2(size * 0.2, -size * 0.2),  # Right notch
				center + Vector2(size * 0.2, size * 0.6),   # Right base
				center + Vector2(-size * 0.2, size * 0.6),  # Left base
				center + Vector2(-size * 0.2, -size * 0.2), # Left notch
				center + Vector2(-size * 0.5, -size * 0.2), # Left wing
			])
			draw_colored_polygon(pts, color)

		UpgradeData.IconShape.FLAME:
			# Wavy flame shape
			var pts := PackedVector2Array([
				center + Vector2(0, -size),              # Top
				center + Vector2(size * 0.35, -size * 0.5),
				center + Vector2(size * 0.5, 0),
				center + Vector2(size * 0.3, size * 0.4),
				center + Vector2(0, size * 0.7),         # Bottom
				center + Vector2(-size * 0.3, size * 0.4),
				center + Vector2(-size * 0.5, 0),
				center + Vector2(-size * 0.35, -size * 0.5),
			])
			draw_colored_polygon(pts, color)

		UpgradeData.IconShape.STAR:
			var pts := PackedVector2Array()
			for i in 10:
				var angle := i * TAU / 10.0 - PI / 2.0
				var r := size * 0.7 if i % 2 == 0 else size * 0.35
				pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			draw_colored_polygon(pts, color)


func _draw_stars(cx: float, y: float, filled: int, total: int) -> void:
	var star_spacing := 13.0
	var start_x := cx - (total - 1) * star_spacing / 2.0

	for i in total:
		var sx := start_x + i * star_spacing
		var color := STAR_FILLED if i < filled else STAR_EMPTY
		# Star shape
		var pts := PackedVector2Array()
		for j in 10:
			var angle := j * TAU / 10.0 - PI / 2.0
			var r := 5.0 if j % 2 == 0 else 2.5
			pts.append(Vector2(sx + cos(angle) * r, y + sin(angle) * r))
		draw_colored_polygon(pts, color)


func _draw_text_centered(text: String, cx: float, y: float, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if not font:
		return
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var x := cx - text_size.x / 2.0
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_text_wrapped(text: String, x: float, y: float, max_width: float, font_size: int, color: Color) -> void:
	var font := ThemeDB.fallback_font
	if not font:
		return

	# Simple word-wrap
	var words := text.split(" ")
	var lines: Array[String] = []
	var current_line := ""

	for word in words:
		var test_line := (current_line + " " + word).strip_edges()
		var test_width := font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if test_width > max_width and current_line != "":
			lines.append(current_line)
			current_line = word
		else:
			current_line = test_line

	if current_line != "":
		lines.append(current_line)

	var line_height := font_size + 2.0
	var center_x := x + max_width / 2.0
	for i in lines.size():
		var line_text: String = lines[i]
		var line_w := font.get_string_size(line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var lx := center_x - line_w / 2.0
		draw_string(font, Vector2(lx, y + i * line_height), line_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
