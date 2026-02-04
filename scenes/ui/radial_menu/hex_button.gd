class_name HexButton extends Control
## A hexagonal button for the radial menu.
## Uses custom drawing for the hex shape with pixel-art aesthetic.

signal pressed(option_id: String)
signal hovered(option_id: String)

@export var option_id: String = ""
@export var label_text: String = ""
@export var disabled: bool = false

## Visual state
var is_selected: bool = false
var is_hovered: bool = false

## Size of the hexagon
const HEX_WIDTH: float = 44.0
const HEX_HEIGHT: float = 50.0

## Colors - retro tech gadget aesthetic
const COLOR_NORMAL := Color(0.15, 0.2, 0.25, 0.95)
const COLOR_SELECTED := Color(0.2, 0.4, 0.6, 1.0)
const COLOR_HOVERED := Color(0.25, 0.35, 0.45, 1.0)
const COLOR_DISABLED := Color(0.2, 0.2, 0.2, 0.7)
const COLOR_BORDER := Color(0.4, 0.6, 0.8, 1.0)
const COLOR_BORDER_SELECTED := Color(0.5, 0.8, 1.0, 1.0)
const COLOR_BORDER_DISABLED := Color(0.3, 0.3, 0.3, 0.8)
const COLOR_TEXT := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_TEXT_DISABLED := Color(0.5, 0.5, 0.5, 1.0)


func _ready() -> void:
	custom_minimum_size = Vector2(HEX_WIDTH, HEX_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not disabled else Control.CURSOR_ARROW


func _draw() -> void:
	var center := size / 2.0

	# Determine colors based on state
	var fill_color: Color
	var border_color: Color
	var text_color: Color

	if disabled:
		fill_color = COLOR_DISABLED
		border_color = COLOR_BORDER_DISABLED
		text_color = COLOR_TEXT_DISABLED
	elif is_selected:
		fill_color = COLOR_SELECTED
		border_color = COLOR_BORDER_SELECTED
		text_color = COLOR_TEXT
	elif is_hovered:
		fill_color = COLOR_HOVERED
		border_color = COLOR_BORDER
		text_color = COLOR_TEXT
	else:
		fill_color = COLOR_NORMAL
		border_color = COLOR_BORDER
		text_color = COLOR_TEXT

	# Draw hexagon fill
	var points := _get_hexagon_points(center)
	draw_colored_polygon(points, fill_color)

	# Draw border (as lines for crisp pixel look)
	for i in points.size():
		var start := points[i]
		var end := points[(i + 1) % points.size()]
		draw_line(start, end, border_color, 2.0, false)

	# Draw inner glow when selected
	if is_selected:
		var inner_points := _get_hexagon_points(center, 0.85)
		for i in inner_points.size():
			var start := inner_points[i]
			var end := inner_points[(i + 1) % inner_points.size()]
			draw_line(start, end, Color(1.0, 1.0, 1.0, 0.3), 1.0, false)

	# Draw label text
	if label_text != "":
		var font := ThemeDB.fallback_font
		var font_size := 10
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := center - text_size / 2.0 + Vector2(0, font_size * 0.35)

		# Text outline for readability
		var outline_color := Color(0, 0, 0, 0.8)
		for offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_string(font, text_pos + offset, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)

		draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)


## Get hexagon vertices centered at given point
func _get_hexagon_points(center: Vector2, scale: float = 1.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var w := HEX_WIDTH * 0.5 * scale
	var h := HEX_HEIGHT * 0.5 * scale

	# Pointy-top hexagon
	points.append(center + Vector2(0, -h))           # Top
	points.append(center + Vector2(w, -h * 0.5))     # Top-right
	points.append(center + Vector2(w, h * 0.5))      # Bottom-right
	points.append(center + Vector2(0, h))            # Bottom
	points.append(center + Vector2(-w, h * 0.5))     # Bottom-left
	points.append(center + Vector2(-w, -h * 0.5))    # Top-left

	return points


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit(option_id)
			accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if not disabled:
				is_hovered = true
				hovered.emit(option_id)
				queue_redraw()
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false
			queue_redraw()


## Set selected state (called by RadialMenu)
func set_selected(selected: bool) -> void:
	is_selected = selected
	queue_redraw()


## Set disabled state
func set_disabled(value: bool) -> void:
	disabled = value
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	queue_redraw()


## Check if point is inside hexagon (for click detection)
func is_point_inside(point: Vector2) -> bool:
	var local_point := point - global_position
	var center := size / 2.0
	var points := _get_hexagon_points(center)

	# Simple polygon point test
	var inside := false
	var j := points.size() - 1
	for i in points.size():
		if ((points[i].y > local_point.y) != (points[j].y > local_point.y)) and \
		   (local_point.x < (points[j].x - points[i].x) * (local_point.y - points[i].y) / (points[j].y - points[i].y) + points[i].x):
			inside = not inside
		j = i
	return inside
