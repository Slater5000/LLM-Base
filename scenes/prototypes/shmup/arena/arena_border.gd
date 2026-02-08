extends Node2D
## Draws the arena boundary with glowing neon lines and rounded corners.

var arena_rect := Rect2(40, 20, 560, 310)
var corner_radius := 8.0
var border_color := Color(0.3, 0.5, 0.8, 0.8)
var border_glow_color := Color(0.2, 0.4, 0.7, 0.3)
var border_width := 1.5
var glow_width := 4.0

# Reactive brightness
var brightness_points: Array[Dictionary] = []  # {pos, intensity, decay_timer}


func _ready() -> void:
	z_index = 1


func setup(rect: Rect2) -> void:
	arena_rect = rect
	queue_redraw()


func _process(delta: float) -> void:
	# Decay brightness points
	var to_remove := []
	for i in brightness_points.size():
		brightness_points[i].intensity -= delta * 3.0
		if brightness_points[i].intensity <= 0.0:
			to_remove.append(i)

	for i in range(to_remove.size() - 1, -1, -1):
		brightness_points.remove_at(to_remove[i])

	if brightness_points.size() > 0:
		queue_redraw()


func _draw() -> void:
	var points := _get_rounded_rect_points()

	# Draw glow layer (wider, dimmer)
	for i in points.size():
		var next_i := (i + 1) % points.size()
		var glow_col := border_glow_color
		# Brighten near reactive points
		for bp in brightness_points:
			var mid := (points[i] + points[next_i]) * 0.5
			var dist := mid.distance_to(bp.pos)
			if dist < 80.0:
				var boost: float = bp.intensity * (1.0 - dist / 80.0)
				glow_col = glow_col.lightened(boost * 0.5)
		draw_line(points[i], points[next_i], glow_col, glow_width, true)

	# Draw main border
	for i in points.size():
		var next_i := (i + 1) % points.size()
		var col := border_color
		for bp in brightness_points:
			var mid := (points[i] + points[next_i]) * 0.5
			var dist := mid.distance_to(bp.pos)
			if dist < 80.0:
				var boost: float = bp.intensity * (1.0 - dist / 80.0)
				col = col.lightened(boost * 0.4)
		draw_line(points[i], points[next_i], col, border_width, true)


func _get_rounded_rect_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var r := corner_radius
	var rect := arena_rect
	var segments_per_corner := 4

	# Top-left corner
	for i in range(segments_per_corner + 1):
		var angle := PI + (PI / 2.0) * (float(i) / segments_per_corner)
		pts.append(Vector2(rect.position.x + r + cos(angle) * r, rect.position.y + r + sin(angle) * r))

	# Top-right corner
	for i in range(segments_per_corner + 1):
		var angle := -PI / 2.0 + (PI / 2.0) * (float(i) / segments_per_corner)
		pts.append(Vector2(rect.end.x - r + cos(angle) * r, rect.position.y + r + sin(angle) * r))

	# Bottom-right corner
	for i in range(segments_per_corner + 1):
		var angle := 0.0 + (PI / 2.0) * (float(i) / segments_per_corner)
		pts.append(Vector2(rect.end.x - r + cos(angle) * r, rect.end.y - r + sin(angle) * r))

	# Bottom-left corner
	for i in range(segments_per_corner + 1):
		var angle := PI / 2.0 + (PI / 2.0) * (float(i) / segments_per_corner)
		pts.append(Vector2(rect.position.x + r + cos(angle) * r, rect.end.y - r + sin(angle) * r))

	return pts


## React to a nearby explosion
func react_to_explosion(world_pos: Vector2, intensity: float) -> void:
	brightness_points.append({
		"pos": world_pos,
		"intensity": clampf(intensity, 0.0, 1.0)
	})
	queue_redraw()
