extends Node2D
## Custom crosshair drawn at mouse world position.
## Cyan neon style matching player ship aesthetic.

const COLOR_CORE := Color(0.2, 0.9, 1.0, 0.85)
const COLOR_GLOW := Color(0.15, 0.6, 0.9, 0.25)

# Crosshair geometry
const GAP := 4.0       # Center gap radius
const LINE_LEN := 8.0  # Line length from gap edge
const LINE_W := 1.2    # Core line width
const GLOW_W := 3.5    # Glow line width
const DOT_R := 1.5     # Center dot radius

var _spin := 0.0


func _process(delta: float) -> void:
	global_position = get_global_mouse_position()
	_spin += delta * 1.5
	queue_redraw()


func _draw() -> void:
	# Outer glow ring
	draw_arc(
		Vector2.ZERO, GAP + 1.0, 0, TAU, 16,
		COLOR_GLOW, GLOW_W,
	)

	# 4 crosshair lines with center gap
	for i in 4:
		var angle := _spin + (TAU / 4.0) * i
		var dir := Vector2.from_angle(angle)
		var start := dir * GAP
		var end := dir * (GAP + LINE_LEN)
		# Glow layer
		draw_line(start, end, COLOR_GLOW, GLOW_W)
		# Core layer
		draw_line(start, end, COLOR_CORE, LINE_W)

	# Center dot
	draw_circle(Vector2.ZERO, DOT_R, COLOR_CORE)
