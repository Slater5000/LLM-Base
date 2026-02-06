extends Node2D
## Draws the shrinking ring for the scanner minigame.

const HIT_WINDOW := 3.0  # Must match scanner.gd TIMING_WINDOW

func _draw() -> void:
	var ring_radius: float = get_meta("ring_radius", 0.0)
	var target_radius: float = get_meta("target_radius", 20.0)

	if ring_radius <= 0:
		return

	# Calculate color based on how close to target
	var distance_from_target := absf(ring_radius - target_radius)
	var color: Color

	if distance_from_target <= HIT_WINDOW:
		# In the hit zone - bright green
		color = Color(0.2, 1.0, 0.2, 1.0)
	else:
		# Red - gets slightly brighter as it approaches
		var brightness := clampf(0.6 + (1.0 - distance_from_target / 40.0) * 0.4, 0.6, 1.0)
		color = Color(brightness, 0.15, 0.1, 0.9)

	# Draw the shrinking ring
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, color, 3.0, true)
