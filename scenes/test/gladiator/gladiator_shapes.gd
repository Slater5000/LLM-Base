class_name GladiatorShapes
extends GladiatorBase
## Stick figure gladiator using pure _draw() method
## All rendering happens in a single draw call - very efficient

const LIMB_WIDTH := 4.0
const JOINT_RADIUS := 4.0
const HEAD_RADIUS := 10.0
const WEAPON_LENGTH := 30.0

@export var glow_intensity: float = 1.5
@export var show_weapon: bool = true
@export var weapon_color: Color = Color.ORANGE_RED
@export var outline_color: Color = Color.WHITE

var current_tween: Tween

# For top-down view, we use different joint positions
func _ready() -> void:
	# Adjust for top-down perspective
	joints = {
		"head": Vector2(0, -40),
		"neck": Vector2(0, -30),
		"torso": Vector2(0, 0),
		"hip": Vector2(0, 20),
		"left_shoulder": Vector2(-12, -25),
		"right_shoulder": Vector2(12, -25),
		"left_elbow": Vector2(-25, -15),
		"right_elbow": Vector2(25, -15),
		"left_hand": Vector2(-35, 0),
		"right_hand": Vector2(35, 0),
		"left_knee": Vector2(-8, 35),
		"right_knee": Vector2(8, 35),
		"left_foot": Vector2(-12, 50),
		"right_foot": Vector2(12, 50),
	}
	super._ready()


func _draw() -> void:
	# Draw in order: legs, torso, arms, head (back to front)

	# Legs
	_draw_limb(joints["hip"], joints["left_knee"], base_color)
	_draw_limb(joints["left_knee"], joints["left_foot"], base_color)
	_draw_limb(joints["hip"], joints["right_knee"], base_color)
	_draw_limb(joints["right_knee"], joints["right_foot"], base_color)

	# Torso
	_draw_limb(joints["neck"], joints["hip"], base_color)

	# Arms
	_draw_limb(joints["left_shoulder"], joints["left_elbow"], base_color)
	_draw_limb(joints["left_elbow"], joints["left_hand"], base_color)
	_draw_limb(joints["right_shoulder"], joints["right_elbow"], base_color)
	_draw_limb(joints["right_elbow"], joints["right_hand"], base_color)

	# Weapon (attached to right hand)
	if show_weapon:
		var hand: Vector2 = joints["right_hand"]
		var weapon_dir := Vector2(1 if facing_right else -1, 0).normalized()
		var weapon_end := hand + weapon_dir * WEAPON_LENGTH
		_draw_limb(hand, weapon_end, weapon_color, LIMB_WIDTH + 1)

	# Joints (circles at key positions)
	for joint_name in ["left_shoulder", "right_shoulder", "left_elbow", "right_elbow",
			"left_hand", "right_hand", "hip", "left_knee", "right_knee",
			"left_foot", "right_foot"]:
		draw_circle(joints[joint_name], JOINT_RADIUS, base_color)

	# Head (larger circle with outline)
	draw_circle(joints["head"], HEAD_RADIUS + 2, outline_color)
	draw_circle(joints["head"], HEAD_RADIUS, base_color)

	# Direction indicator (small triangle showing facing)
	var dir := 1 if facing_right else -1
	var indicator_pos: Vector2 = joints["head"] + Vector2(HEAD_RADIUS * dir, 0)
	var indicator_points := PackedVector2Array([
		indicator_pos,
		indicator_pos + Vector2(-5 * dir, -4),
		indicator_pos + Vector2(-5 * dir, 4),
	])
	draw_colored_polygon(indicator_points, outline_color)


func _draw_limb(from: Vector2, to: Vector2, color: Color, width: float = LIMB_WIDTH) -> void:
	# Draw outline first
	draw_line(from, to, outline_color, width + 2, true)
	# Then the colored limb
	draw_line(from, to, color, width, true)


func _stop_current_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()


func _animate_joint(joint_name: String, target: Vector2, duration: float, parallel: bool = false) -> void:
	var method := func(pos: Vector2):
		joints[joint_name] = pos
		queue_redraw()

	if parallel:
		current_tween.parallel().tween_method(method, joints[joint_name], target, duration)
	else:
		current_tween.tween_method(method, joints[joint_name], target, duration)


## ANIMATIONS (Top-down perspective)

func _anim_idle() -> void:
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_loops()

	# Subtle sway
	current_tween.tween_method(
		func(t: float):
			var sway := sin(t * TAU) * 2
			joints["head"] = _original_joints["head"] + Vector2(sway, 0)
			joints["left_hand"] = _original_joints["left_hand"] + Vector2(0, sway)
			joints["right_hand"] = _original_joints["right_hand"] + Vector2(0, -sway)
			queue_redraw(),
		0.0, 1.0, 1.5
	)
	is_animating = false


func _anim_punch() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var punch_hand : Vector2 = _original_joints["right_hand"] + Vector2(40 * dir, 0)
	var punch_elbow : Vector2 = _original_joints["right_elbow"] + Vector2(20 * dir, 0)

	# Wind up
	_animate_joint("right_hand", _original_joints["right_hand"] + Vector2(-10 * dir, 0), 0.08)
	_animate_joint("right_elbow", _original_joints["right_elbow"] + Vector2(-5 * dir, 0), 0.08, true)

	# Strike
	current_tween.tween_callback(func(): hit_landed.emit(10))
	_animate_joint("right_hand", punch_hand, 0.06)
	_animate_joint("right_elbow", punch_elbow, 0.06, true)

	# Retract
	_animate_joint("right_hand", _original_joints["right_hand"], 0.12)
	_animate_joint("right_elbow", _original_joints["right_elbow"], 0.12, true)

	current_tween.tween_callback(_finish_animation)


func _anim_kick() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var kick_foot : Vector2 = _original_joints["right_foot"] + Vector2(35 * dir, 0)
	var kick_knee : Vector2 = _original_joints["right_knee"] + Vector2(20 * dir, 0)

	# Lift
	_animate_joint("right_knee", kick_knee + Vector2(0, -10), 0.1)
	_animate_joint("right_foot", _original_joints["right_foot"] + Vector2(10 * dir, -15), 0.1, true)

	# Kick
	current_tween.tween_callback(func(): hit_landed.emit(15))
	_animate_joint("right_foot", kick_foot, 0.08)
	_animate_joint("right_knee", kick_knee, 0.08, true)

	# Return
	_animate_joint("right_foot", _original_joints["right_foot"], 0.15)
	_animate_joint("right_knee", _original_joints["right_knee"], 0.15, true)

	current_tween.tween_callback(_finish_animation)


func _anim_block() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	# Cross arms in front
	var block_left := Vector2(5 * dir, -10)
	var block_right := Vector2(10 * dir, -5)

	_animate_joint("left_hand", block_left, 0.08)
	_animate_joint("right_hand", block_right, 0.08, true)
	_animate_joint("left_elbow", _original_joints["left_elbow"] + Vector2(10 * dir, 0), 0.08, true)
	_animate_joint("right_elbow", _original_joints["right_elbow"] + Vector2(-5 * dir, 0), 0.08, true)

	# Hold
	current_tween.tween_interval(0.25)

	# Release
	_animate_joint("left_hand", _original_joints["left_hand"], 0.12)
	_animate_joint("right_hand", _original_joints["right_hand"], 0.12, true)
	_animate_joint("left_elbow", _original_joints["left_elbow"], 0.12, true)
	_animate_joint("right_elbow", _original_joints["right_elbow"], 0.12, true)

	current_tween.tween_callback(func():
		is_blocking = false
		_finish_animation()
	)


func _anim_dodge() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var dodge_offset := Vector2(-30 * dir, 0)

	# Quick step back
	current_tween.tween_property(self, "position", position + dodge_offset, 0.12)
	current_tween.set_ease(Tween.EASE_OUT)

	# Return
	current_tween.tween_property(self, "position", position, 0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_uppercut() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1

	# Crouch
	_animate_joint("head", _original_joints["head"] + Vector2(0, 10), 0.08)
	_animate_joint("torso", _original_joints["torso"] + Vector2(0, 5), 0.08, true)

	# Rising strike
	current_tween.tween_callback(func(): hit_landed.emit(25))
	var uppercut_hand : Vector2 = _original_joints["right_hand"] + Vector2(20 * dir, -35)
	_animate_joint("right_hand", uppercut_hand, 0.07)
	_animate_joint("right_elbow", _original_joints["right_elbow"] + Vector2(10 * dir, -20), 0.07, true)
	_animate_joint("head", _original_joints["head"] + Vector2(0, -5), 0.07, true)
	_animate_joint("torso", _original_joints["torso"], 0.07, true)

	# Recovery
	_animate_joint("right_hand", _original_joints["right_hand"], 0.18)
	_animate_joint("right_elbow", _original_joints["right_elbow"], 0.18, true)
	_animate_joint("head", _original_joints["head"], 0.18, true)

	current_tween.tween_callback(_finish_animation)


func _anim_sweep() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1

	# Low stance
	_animate_joint("head", _original_joints["head"] + Vector2(0, 15), 0.1)
	_animate_joint("hip", _original_joints["hip"] + Vector2(0, 10), 0.1, true)

	# Sweep leg
	current_tween.tween_callback(func(): hit_landed.emit(12))
	var sweep_foot : Vector2 = _original_joints["right_foot"] + Vector2(40 * dir, 0)
	_animate_joint("right_foot", sweep_foot, 0.08)
	_animate_joint("right_knee", _original_joints["right_knee"] + Vector2(25 * dir, 0), 0.08, true)

	# Recover
	_animate_joint("right_foot", _original_joints["right_foot"], 0.18)
	_animate_joint("right_knee", _original_joints["right_knee"], 0.18, true)
	_animate_joint("head", _original_joints["head"], 0.18, true)
	_animate_joint("hip", _original_joints["hip"], 0.18, true)

	current_tween.tween_callback(_finish_animation)


func _anim_hit() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var knockback := Vector2(-15 * dir, 0)

	# Recoil
	current_tween.tween_property(self, "position", position + knockback, 0.06)
	_animate_joint("head", _original_joints["head"] + Vector2(-10 * dir, 0), 0.06, true)

	# Flash
	current_tween.tween_callback(func(): modulate = Color.RED)
	current_tween.tween_interval(0.04)
	current_tween.tween_callback(func(): modulate = Color.WHITE)

	# Return
	current_tween.tween_property(self, "position", position, 0.12)
	_animate_joint("head", _original_joints["head"], 0.12, true)

	current_tween.tween_callback(_finish_animation)


func _anim_victory() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	# Arms up
	_animate_joint("left_hand", _original_joints["left_hand"] + Vector2(-15, -30), 0.25)
	_animate_joint("right_hand", _original_joints["right_hand"] + Vector2(15, -30), 0.25, true)

	# Celebrate
	current_tween.set_loops(3)
	current_tween.tween_method(
		func(t: float):
			var bounce := sin(t * TAU) * 5
			joints["head"] = _original_joints["head"] + Vector2(0, -10 + bounce)
			queue_redraw(),
		0.0, 1.0, 0.3
	)


func _anim_defeat() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	# Collapse
	_animate_joint("head", _original_joints["head"] + Vector2(0, 40), 0.35)
	_animate_joint("left_hand", _original_joints["left_hand"] + Vector2(-10, 30), 0.35, true)
	_animate_joint("right_hand", _original_joints["right_hand"] + Vector2(10, 30), 0.35, true)
	_animate_joint("left_foot", _original_joints["left_foot"] + Vector2(-5, 10), 0.35, true)
	_animate_joint("right_foot", _original_joints["right_foot"] + Vector2(5, 10), 0.35, true)

	current_tween.tween_property(self, "modulate:a", 0.5, 0.25)
