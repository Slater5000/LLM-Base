extends Node2D
## Battle showcase — spider-monkeys at all size tiers.
## Uses the same bake-to-atlas pipeline as Ant Farm worker_manager.
## Left army faces right, right army faces left.

const SpiderMonkeyBake := preload(
	"res://scenes/prototypes/creature_gen/spider_monkey_bake.gd"
)

# Scale multipliers applied to the baked sprite
const TIERS := {
	"Small": 0.5,
	"Medium": 0.9,
	"Large": 1.4,
	"Titan": 2.0,
}

const LEFT_COUNTS := {
	"Small": 10,
	"Medium": 5,
	"Large": 2,
	"Titan": 1,
}

const RIGHT_COUNTS := {
	"Small": 8,
	"Medium": 4,
	"Large": 2,
	"Titan": 1,
}


func _ready() -> void:
	_spawn_armies()


func _spawn_armies() -> void:
	for child in get_children():
		child.queue_free()

	# Fixed layout: left army x=30-320, right army x=380-670
	# Row Y positions chosen to fill the 580px field evenly
	var rows := [
		{"tier": "Small", "y": 90, "left_x": 30, "right_x": 380},
		{"tier": "Medium", "y": 200, "left_x": 30, "right_x": 380},
		{"tier": "Large", "y": 340, "left_x": 50, "right_x": 400},
		{"tier": "Titan", "y": 480, "left_x": 80, "right_x": 430},
	]

	for row: Dictionary in rows:
		var tier_name: String = row["tier"]
		var scl: float = TIERS[tier_name]
		var base_y: float = row["y"]
		var unit_w := 64.0 * scl + 8.0

		# Left army
		var left_count: int = LEFT_COUNTS[tier_name]
		for i in range(left_count):
			var px: float = row["left_x"] + float(i) * unit_w
			if px > 310.0:
				break
			_spawn_creature(
				Vector2(px, base_y), scl, false,
				_random_warm_palette(), randf() * 10.0,
			)

		# Right army
		var right_count: int = RIGHT_COUNTS[tier_name]
		for i in range(right_count):
			var px: float = row["right_x"] + float(i) * unit_w
			if px > 660.0:
				break
			_spawn_creature(
				Vector2(px, base_y), scl, true,
				_random_cool_palette(), randf() * 10.0,
			)


func _spawn_creature(
	pos: Vector2, scl: float, flip: bool,
	pal: Dictionary, phase: float,
) -> void:
	var creature := Node2D.new()
	creature.set_script(SpiderMonkeyBake)
	creature.position = pos
	creature.creature_scale = scl
	creature.facing_left = flip
	creature.phase_offset = phase
	creature.walk_speed = randf_range(4.0, 6.0)
	# Apply palette
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


func _random_warm_palette() -> Dictionary:
	var hue := randf_range(0.03, 0.12)
	var sat := randf_range(0.4, 0.6)
	var val := randf_range(0.3, 0.5)
	var orb_hue := randf()
	return {
		"fur": Color.from_hsv(hue, sat, val),
		"fur_outline": Color.from_hsv(hue, sat - 0.1, val + 0.15),
		"spider": Color.from_hsv(hue + 0.02, sat * 0.5, val * 0.6),
		"spider_outline": Color.from_hsv(hue + 0.02, sat * 0.4, val * 0.5 + 0.1),
		"belly": Color.from_hsv(hue + 0.04, sat - 0.2, val + 0.2),
		"eye": Color.from_hsv(randf_range(0.1, 0.18), 0.8, 0.85),
		"leg": Color.from_hsv(hue + 0.02, sat * 0.5, val * 0.4),
		"leg_outline": Color.from_hsv(hue + 0.02, sat * 0.4, val * 0.4 + 0.1),
		"orb": Color.from_hsv(orb_hue, 0.7, 0.8),
		"glow": Color.from_hsv(orb_hue, 0.5, 0.9, 0.6),
	}


func _random_cool_palette() -> Dictionary:
	var hue := randf_range(0.55, 0.80)
	var sat := randf_range(0.3, 0.5)
	var val := randf_range(0.25, 0.40)
	var orb_hue := randf()
	return {
		"fur": Color.from_hsv(hue, sat, val),
		"fur_outline": Color.from_hsv(hue, sat - 0.1, val + 0.12),
		"spider": Color.from_hsv(hue + 0.05, sat * 0.5, val * 0.5),
		"spider_outline": Color.from_hsv(hue + 0.05, sat * 0.4, val * 0.5 + 0.08),
		"belly": Color.from_hsv(hue - 0.05, sat - 0.15, val + 0.15),
		"eye": Color.from_hsv(randf_range(0.0, 0.1), 0.8, 0.8),
		"leg": Color.from_hsv(hue + 0.03, sat * 0.4, val * 0.35),
		"leg_outline": Color.from_hsv(hue + 0.03, sat * 0.3, val * 0.35 + 0.08),
		"orb": Color.from_hsv(orb_hue, 0.6, 0.7),
		"glow": Color.from_hsv(orb_hue, 0.4, 0.8, 0.5),
	}


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_spawn_armies()


func _draw() -> void:
	# Field
	draw_rect(Rect2(0, 0, 700, 580), Color(0.18, 0.30, 0.12), true)
	draw_rect(Rect2(280, 80, 140, 420), Color(0.22, 0.35, 0.15), true)

	# 16px grid
	for gx in range(0, 701, 16):
		draw_line(
			Vector2(gx, 0), Vector2(gx, 580),
			Color(1, 1, 1, 0.03), 0.5,
		)
	for gy in range(0, 581, 16):
		draw_line(
			Vector2(0, gy), Vector2(700, gy),
			Color(1, 1, 1, 0.03), 0.5,
		)

	# Player ref
	_draw_ref_character(Vector2(330, 300))
	_draw_ref_character(Vector2(370, 330))

	# Army labels (in field coords)
	draw_string(
		ThemeDB.fallback_font, Vector2(120, 70),
		"YOUR ARMY  ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(0.8, 1.0, 0.8, 0.7),
	)
	draw_string(
		ThemeDB.fallback_font, Vector2(480, 70),
		"<-  ENEMY ARMY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
		Color(1.0, 0.7, 0.7, 0.7),
	)

	# Player ref label
	draw_string(
		ThemeDB.fallback_font, Vector2(305, 285),
		"Player (16x32)",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
		Color(1, 1, 1, 0.4),
	)


func _draw_ref_character(pos: Vector2) -> void:
	var r := Rect2(pos.x - 4, pos.y - 32, 10, 32)
	draw_rect(r, Color(0.4, 0.5, 0.7, 0.6), true)
	draw_circle(
		Vector2(pos.x + 1, pos.y - 26), 5.0,
		Color(0.5, 0.6, 0.8, 0.7),
	)
	draw_rect(r, Color(0.6, 0.7, 0.9, 0.4), false, 0.5)
