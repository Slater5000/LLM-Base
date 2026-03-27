extends Node2D
## Ant creature using _draw() — matches production worker_manager bake.
## Side-view profile facing right. Elbowed antenna, mandibles, 3 legs.

@export var body_color := Color(0.05, 0.05, 0.05)
@export var outline_color := Color(1.0, 1.0, 1.0, 0.6)
@export var outline_width := 1.0
@export var walk_speed := 6.0
@export var phase_offset := 0.0
@export var facing_left := false

var _anim_time := 0.0


func _ready() -> void:
	_anim_time = phase_offset


func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()


func _draw() -> void:
	if facing_left:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))

	var t := _anim_time * walk_speed
	var p := _anim_positions(t)
	var ow := outline_width

	# Separator rings (prevent blobbing when overlapping)
	var sep := Color(0.0, 0.0, 0.0, 0.4)
	draw_circle(p["abd"].round(), 2.8, sep)
	draw_circle(p["thor"].round(), 2.2, sep)
	draw_circle(p["hd"].round(), 1.9, sep)

	# Outline layer — bodies
	draw_circle(p["abd"].round(), 2.3, outline_color)
	draw_circle(p["thor"].round(), 1.8, outline_color)
	draw_circle(p["hd"].round(), 1.5, outline_color)
	# Outline layer — limbs (thick)
	_draw_limbs(p, outline_color, ow + 0.8)

	# Fill layer — bodies
	draw_circle(p["abd"].round(), 2.0, body_color)
	draw_circle(p["thor"].round(), 1.5, body_color)
	draw_circle(p["hd"].round(), 1.2, body_color)
	# Fill layer — limbs (thin)
	_draw_limbs(p, body_color, ow)

	if facing_left:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 1))


func _anim_positions(t: float) -> Dictionary:
	## Matches worker_manager._anim_positions exactly.
	var bob := sin(t * 2.0) * 0.5
	var leg_sw := sin(t) * 1.2
	var leg_sw_b := sin(t + PI) * 1.2
	var lift_a := maxf(sin(t), 0.0) * 0.8
	var lift_b := maxf(sin(t + PI), 0.0) * 0.8
	var sway := sin(t * 0.583) * 0.8

	return {
		"abd": Vector2(-2.5, -0.5 + bob),
		"thor": Vector2(0.5, -0.8 + bob),
		"hd": Vector2(2.8, -1.0 + bob),
		"fl": Vector2(2.5 + leg_sw, 2.5 - lift_a),
		"ml": Vector2(-0.2 + leg_sw_b, 2.8 - lift_b),
		"rl": Vector2(-2.2 + leg_sw, 2.5 - lift_a),
		"lb1": Vector2(1.8, bob),
		"lb2": Vector2(0.3, bob),
		"lb3": Vector2(-1.5, 0.5 + bob),
		"ant_base": Vector2(3.5, -1.8 + bob),
		"ant_elbow": Vector2(4.5, -2.8 + bob),
		"ant_tip": Vector2(
			5.5 + sway, -3.2 - absf(sway) * 0.3
		),
		"ant_tip2": Vector2(
			6.5 + sway * 0.7, -2.5 + bob
		),
		"mand_base": Vector2(3.8, -0.6 + bob),
		"mand_top": Vector2(4.6, -1.0 + bob),
		"mand_bot": Vector2(4.6, -0.1 + bob),
	}


func _draw_limbs(p: Dictionary, color: Color, w: float) -> void:
	# 3 legs
	draw_line(p["lb1"].round(), p["fl"].round(), color, w)
	draw_line(p["lb2"].round(), p["ml"].round(), color, w)
	draw_line(p["lb3"].round(), p["rl"].round(), color, w)
	# Elbowed antenna: base → elbow → tip → tip2
	draw_line(
		p["ant_base"].round(), p["ant_elbow"].round(), color, w
	)
	draw_line(
		p["ant_elbow"].round(), p["ant_tip"].round(), color, w
	)
	draw_line(
		p["ant_tip"].round(), p["ant_tip2"].round(), color, w
	)
	# Mandibles: base → upper jaw, base → lower jaw
	draw_line(
		p["mand_base"].round(), p["mand_top"].round(), color, w
	)
	draw_line(
		p["mand_base"].round(), p["mand_bot"].round(), color, w
	)
