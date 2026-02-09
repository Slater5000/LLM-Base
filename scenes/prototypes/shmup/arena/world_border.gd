extends Node2D
## Draws visible world boundary — neon glow border with warning zone.
## Placed at world origin; draws using WORLD_RECT coordinates.
## Only redraws when camera moves significantly.

const CORNER_RADIUS := 10.0
const SEGMENTS_PER_CORNER := 4
const BORDER_COLOR := Color(0.85, 0.35, 0.2, 0.75)
const GLOW_COLOR := Color(0.7, 0.25, 0.15, 0.18)
const WARN_COLOR := Color(0.8, 0.3, 0.15, 0.06)
const BORDER_WIDTH := 2.5
const GLOW_WIDTH := 10.0
const WARN_WIDTH := 40.0

var world_rect := Rect2(-1600, -1600, 3200, 3200)

var _last_cam_pos := Vector2.INF
var _rect_points := PackedVector2Array()


func setup(rect: Rect2) -> void:
	world_rect = rect
	_rect_points = _build_rounded_rect(rect, CORNER_RADIUS)
	z_index = 2
	queue_redraw()


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if not cam:
		return
	# Redraw when camera moves more than 20px (keeps border consistent)
	if _last_cam_pos.distance_squared_to(cam.global_position) > 400.0:
		_last_cam_pos = cam.global_position
		queue_redraw()


func _draw() -> void:
	if _rect_points.is_empty():
		return
	var count := _rect_points.size()

	# Warning zone (wide dim strip)
	for i in count:
		var next_i := (i + 1) % count
		draw_line(_rect_points[i], _rect_points[next_i], WARN_COLOR, WARN_WIDTH)

	# Outer glow
	for i in count:
		var next_i := (i + 1) % count
		draw_line(_rect_points[i], _rect_points[next_i], GLOW_COLOR, GLOW_WIDTH)

	# Core border
	for i in count:
		var next_i := (i + 1) % count
		draw_line(_rect_points[i], _rect_points[next_i], BORDER_COLOR, BORDER_WIDTH)


func _build_rounded_rect(rect: Rect2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()

	# Top-left corner
	for i in range(SEGMENTS_PER_CORNER + 1):
		var angle := PI + (PI / 2.0) * (float(i) / SEGMENTS_PER_CORNER)
		pts.append(Vector2(
			rect.position.x + r + cos(angle) * r,
			rect.position.y + r + sin(angle) * r,
		))

	# Top-right corner
	for i in range(SEGMENTS_PER_CORNER + 1):
		var angle := -PI / 2.0 + (PI / 2.0) * (float(i) / SEGMENTS_PER_CORNER)
		pts.append(Vector2(
			rect.end.x - r + cos(angle) * r,
			rect.position.y + r + sin(angle) * r,
		))

	# Bottom-right corner
	for i in range(SEGMENTS_PER_CORNER + 1):
		var angle := 0.0 + (PI / 2.0) * (float(i) / SEGMENTS_PER_CORNER)
		pts.append(Vector2(
			rect.end.x - r + cos(angle) * r,
			rect.end.y - r + sin(angle) * r,
		))

	# Bottom-left corner
	for i in range(SEGMENTS_PER_CORNER + 1):
		var angle := PI / 2.0 + (PI / 2.0) * (float(i) / SEGMENTS_PER_CORNER)
		pts.append(Vector2(
			rect.position.x + r + cos(angle) * r,
			rect.end.y - r + sin(angle) * r,
		))

	return pts
