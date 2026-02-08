class_name GladiatorLine2D
extends GladiatorBase
## Stick figure gladiator using Line2D nodes for limbs
## Procedural animation via tweens

const LIMB_WIDTH := 4.0
const JOINT_RADIUS := 5.0
const HEAD_RADIUS := 12.0
const WEAPON_LENGTH := 35.0
const WEAPON_WIDTH := 3.0

# Lunge distances for attacks (how far to move toward opponent)
const PUNCH_LUNGE := 40.0
const KICK_LUNGE := 50.0
const UPPERCUT_LUNGE := 35.0
const SWEEP_LUNGE := 45.0

@export var glow_intensity: float = 1.5
@export var show_weapon: bool = true
@export var weapon_color: Color = Color.ORANGE_RED

# Store original position for returning after lunges
var _home_position: Vector2

# Line2D nodes for each limb
var line_torso: Line2D
var line_left_arm_upper: Line2D
var line_left_arm_lower: Line2D
var line_right_arm_upper: Line2D
var line_right_arm_lower: Line2D
var line_left_leg_upper: Line2D
var line_left_leg_lower: Line2D
var line_right_leg_upper: Line2D
var line_right_leg_lower: Line2D
var line_weapon: Line2D

var current_tween: Tween


func _ready() -> void:
	super._ready()
	_create_limbs()
	_update_limb_positions()
	# Store starting position so we can return after lunges
	_home_position = position


func _create_limbs() -> void:
	# Create all Line2D nodes for limbs
	line_torso = _create_line(base_color)
	line_left_arm_upper = _create_line(base_color)
	line_left_arm_lower = _create_line(base_color)
	line_right_arm_upper = _create_line(base_color)
	line_right_arm_lower = _create_line(base_color)
	line_left_leg_upper = _create_line(base_color)
	line_left_leg_lower = _create_line(base_color)
	line_right_leg_upper = _create_line(base_color)
	line_right_leg_lower = _create_line(base_color)

	if show_weapon:
		line_weapon = _create_line(weapon_color, WEAPON_WIDTH)


func _create_line(color: Color, width: float = LIMB_WIDTH) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	add_child(line)
	return line


func _update_limb_positions() -> void:
	# Torso (neck to hip)
	line_torso.set_point_position(0, joints["neck"])
	line_torso.set_point_position(1, joints["hip"])

	# Left arm
	line_left_arm_upper.set_point_position(0, joints["left_shoulder"])
	line_left_arm_upper.set_point_position(1, joints["left_elbow"])
	line_left_arm_lower.set_point_position(0, joints["left_elbow"])
	line_left_arm_lower.set_point_position(1, joints["left_hand"])

	# Right arm
	line_right_arm_upper.set_point_position(0, joints["right_shoulder"])
	line_right_arm_upper.set_point_position(1, joints["right_elbow"])
	line_right_arm_lower.set_point_position(0, joints["right_elbow"])
	line_right_arm_lower.set_point_position(1, joints["right_hand"])

	# Left leg
	line_left_leg_upper.set_point_position(0, joints["hip"])
	line_left_leg_upper.set_point_position(1, joints["left_knee"])
	line_left_leg_lower.set_point_position(0, joints["left_knee"])
	line_left_leg_lower.set_point_position(1, joints["left_foot"])

	# Right leg
	line_right_leg_upper.set_point_position(0, joints["hip"])
	line_right_leg_upper.set_point_position(1, joints["right_knee"])
	line_right_leg_lower.set_point_position(0, joints["right_knee"])
	line_right_leg_lower.set_point_position(1, joints["right_foot"])

	# Weapon (attached to right hand)
	if show_weapon and line_weapon:
		var hand: Vector2 = joints["right_hand"]
		var weapon_dir := Vector2(1 if facing_right else -1, -0.3).normalized()
		line_weapon.set_point_position(0, hand)
		line_weapon.set_point_position(1, hand + weapon_dir * WEAPON_LENGTH)

	queue_redraw()


func _draw() -> void:
	# Draw head
	draw_circle(joints["head"], HEAD_RADIUS, base_color)
	# Draw joint circles
	for joint_name in ["neck", "left_shoulder", "right_shoulder", "left_elbow",
			"right_elbow", "left_hand", "right_hand", "hip", "left_knee",
			"right_knee", "left_foot", "right_foot"]:
		draw_circle(joints[joint_name], JOINT_RADIUS, base_color)


func _stop_current_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()


## Stores home position for reset (called by test scene after positioning)
func set_home_position() -> void:
	_home_position = position


## Lunge forward toward opponent during attacks
func _lunge_forward(distance: float, duration: float) -> void:
	var dir := 1 if facing_right else -1
	var target := position + Vector2(distance * dir, 0)
	current_tween.tween_property(self, "position", target, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)


## Return to home position after attack
func _return_home(duration: float) -> void:
	current_tween.tween_property(self, "position", _home_position, duration).set_ease(Tween.EASE_IN_OUT)


func _tween_joint(joint_name: String, target: Vector2, duration: float) -> void:
	current_tween.tween_method(
		func(pos: Vector2):
			joints[joint_name] = pos
			_update_limb_positions(),
		joints[joint_name],
		target,
		duration
	)


func _tween_joint_parallel(joint_name: String, target: Vector2, duration: float) -> void:
	current_tween.parallel().tween_method(
		func(pos: Vector2):
			joints[joint_name] = pos
			_update_limb_positions(),
		joints[joint_name],
		target,
		duration
	)


## ANIMATIONS

func _anim_idle() -> void:
	_stop_current_tween()
	current_tween = create_tween()
	current_tween.set_loops()

	# Subtle breathing motion
	var breath_offset := Vector2(0, 2)
	current_tween.tween_method(
		func(t: float):
			var offset := breath_offset * sin(t * TAU)
			joints["head"] = _original_joints["head"] + offset * 0.5
			joints["neck"] = _original_joints["neck"] + offset * 0.3
			_update_limb_positions(),
		0.0, 1.0, 2.0
	)
	is_animating = false


func _anim_punch() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var punch_hand : Vector2 = _original_joints["right_hand"] + Vector2(50 * dir, -10)
	var punch_elbow : Vector2 = _original_joints["right_elbow"] + Vector2(30 * dir, -5)

	# Wind up (pull back slightly)
	_tween_joint("right_hand", _original_joints["right_hand"] + Vector2(-10 * dir, 5), 0.08)
	_tween_joint_parallel("right_elbow", _original_joints["right_elbow"] + Vector2(-5 * dir, 5), 0.08)

	# Lunge forward and punch
	_lunge_forward(PUNCH_LUNGE, 0.1)
	_tween_joint_parallel("right_hand", punch_hand, 0.1)
	_tween_joint_parallel("right_elbow", punch_elbow, 0.1)

	# Hit connects at peak of lunge
	current_tween.tween_callback(func(): hit_landed.emit(10))

	# Retract arm and return home
	_tween_joint("right_hand", _original_joints["right_hand"], 0.12)
	_tween_joint_parallel("right_elbow", _original_joints["right_elbow"], 0.12)
	_return_home(0.12)

	current_tween.tween_callback(_finish_animation)


func _anim_kick() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var kick_foot : Vector2 = _original_joints["right_foot"] + Vector2(55 * dir, -25)
	var kick_knee : Vector2 = _original_joints["right_knee"] + Vector2(30 * dir, -10)

	# Chamber the kick (lift leg)
	_tween_joint("right_knee", kick_knee + Vector2(-10 * dir, -20), 0.1)
	_tween_joint_parallel("right_foot", _original_joints["right_foot"] + Vector2(0, -35), 0.1)

	# Lunge and extend kick
	_lunge_forward(KICK_LUNGE, 0.12)
	_tween_joint_parallel("right_foot", kick_foot, 0.12)
	_tween_joint_parallel("right_knee", kick_knee, 0.12)

	# Hit connects
	current_tween.tween_callback(func(): hit_landed.emit(15))

	# Retract and return
	_tween_joint("right_foot", _original_joints["right_foot"], 0.15)
	_tween_joint_parallel("right_knee", _original_joints["right_knee"], 0.15)
	_return_home(0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_block() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	# Bring arms up in front
	var block_left_hand := Vector2(-5 * dir, -50)
	var block_right_hand := Vector2(10 * dir, -45)
	var block_left_elbow := Vector2(-15 * dir, -35)
	var block_right_elbow := Vector2(5 * dir, -30)

	_tween_joint("left_hand", block_left_hand, 0.1)
	_tween_joint_parallel("right_hand", block_right_hand, 0.1)
	_tween_joint_parallel("left_elbow", block_left_elbow, 0.1)
	_tween_joint_parallel("right_elbow", block_right_elbow, 0.1)

	# Hold block
	current_tween.tween_interval(0.3)

	# Return to idle
	_tween_joint("left_hand", _original_joints["left_hand"], 0.15)
	_tween_joint_parallel("right_hand", _original_joints["right_hand"], 0.15)
	_tween_joint_parallel("left_elbow", _original_joints["left_elbow"], 0.15)
	_tween_joint_parallel("right_elbow", _original_joints["right_elbow"], 0.15)

	current_tween.tween_callback(func():
		is_blocking = false
		_finish_animation()
	)


func _anim_dodge() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var dodge_offset := Vector2(-45 * dir, 0)

	# Quick sidestep back with lean
	current_tween.tween_property(self, "position", _home_position + dodge_offset, 0.12).set_ease(Tween.EASE_OUT)
	_tween_joint_parallel("head", _original_joints["head"] + Vector2(-12 * dir, 8), 0.12)
	_tween_joint_parallel("neck", _original_joints["neck"] + Vector2(-10 * dir, 5), 0.12)

	# Hold briefly
	current_tween.tween_interval(0.08)

	# Return to home position
	_return_home(0.18)
	_tween_joint_parallel("head", _original_joints["head"], 0.18)
	_tween_joint_parallel("neck", _original_joints["neck"], 0.18)

	current_tween.tween_callback(_finish_animation)


func _anim_uppercut() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1

	# Crouch down (wind up)
	_tween_joint("head", _original_joints["head"] + Vector2(0, 18), 0.1)
	_tween_joint_parallel("neck", _original_joints["neck"] + Vector2(0, 12), 0.1)
	_tween_joint_parallel("hip", _original_joints["hip"] + Vector2(0, 12), 0.1)
	_tween_joint_parallel("right_hand", _original_joints["right_hand"] + Vector2(-5 * dir, 25), 0.1)

	# Explosive lunge + uppercut
	var uppercut_hand : Vector2 = _original_joints["right_hand"] + Vector2(30 * dir, -75)
	var uppercut_elbow : Vector2 = _original_joints["right_elbow"] + Vector2(18 * dir, -45)

	_lunge_forward(UPPERCUT_LUNGE, 0.1)
	_tween_joint_parallel("right_hand", uppercut_hand, 0.1)
	_tween_joint_parallel("right_elbow", uppercut_elbow, 0.1)
	_tween_joint_parallel("head", _original_joints["head"] + Vector2(0, -12), 0.1)
	_tween_joint_parallel("neck", _original_joints["neck"] + Vector2(0, -6), 0.1)
	_tween_joint_parallel("hip", _original_joints["hip"], 0.1)

	# Hit connects at peak
	current_tween.tween_callback(func(): hit_landed.emit(25))

	# Recovery
	_tween_joint("right_hand", _original_joints["right_hand"], 0.18)
	_tween_joint_parallel("right_elbow", _original_joints["right_elbow"], 0.18)
	_tween_joint_parallel("head", _original_joints["head"], 0.18)
	_tween_joint_parallel("neck", _original_joints["neck"], 0.18)
	_return_home(0.18)

	current_tween.tween_callback(_finish_animation)


func _anim_sweep() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1

	# Crouch low
	_tween_joint("head", _original_joints["head"] + Vector2(0, 30), 0.1)
	_tween_joint_parallel("neck", _original_joints["neck"] + Vector2(0, 25), 0.1)
	_tween_joint_parallel("hip", _original_joints["hip"] + Vector2(0, 25), 0.1)

	# Lunge and sweep
	var sweep_foot : Vector2 = _original_joints["right_foot"] + Vector2(65 * dir, 10)
	var sweep_knee : Vector2 = _original_joints["right_knee"] + Vector2(35 * dir, 18)

	_lunge_forward(SWEEP_LUNGE, 0.12)
	_tween_joint_parallel("right_foot", sweep_foot, 0.12)
	_tween_joint_parallel("right_knee", sweep_knee, 0.12)

	# Hit connects
	current_tween.tween_callback(func(): hit_landed.emit(12))

	# Recovery
	_tween_joint("right_foot", _original_joints["right_foot"], 0.18)
	_tween_joint_parallel("right_knee", _original_joints["right_knee"], 0.18)
	_tween_joint_parallel("head", _original_joints["head"], 0.18)
	_tween_joint_parallel("neck", _original_joints["neck"], 0.18)
	_tween_joint_parallel("hip", _original_joints["hip"], 0.18)
	_return_home(0.18)

	current_tween.tween_callback(_finish_animation)


func _anim_hit() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	var dir := 1 if facing_right else -1
	var knockback := Vector2(-25 * dir, 0)

	# Violent recoil from impact
	current_tween.tween_property(self, "position", _home_position + knockback, 0.06).set_ease(Tween.EASE_OUT)
	_tween_joint_parallel("head", _original_joints["head"] + Vector2(-18 * dir, 12), 0.06)
	_tween_joint_parallel("neck", _original_joints["neck"] + Vector2(-12 * dir, 8), 0.06)

	# Flash white then red
	current_tween.tween_callback(func(): modulate = Color.WHITE * 2.0)
	current_tween.tween_interval(0.03)
	current_tween.tween_callback(func(): modulate = Color(1.5, 0.4, 0.4))
	current_tween.tween_interval(0.05)
	current_tween.tween_callback(func(): modulate = Color.WHITE)

	# Stagger back to home
	_return_home(0.2)
	_tween_joint_parallel("head", _original_joints["head"], 0.2)
	_tween_joint_parallel("neck", _original_joints["neck"], 0.2)

	current_tween.tween_callback(_finish_animation)


func _anim_victory() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	# Raise both arms
	var victory_left : Vector2 = _original_joints["left_hand"] + Vector2(-20, -50)
	var victory_right : Vector2 = _original_joints["right_hand"] + Vector2(20, -50)

	_tween_joint("left_hand", victory_left, 0.3)
	_tween_joint_parallel("right_hand", victory_right, 0.3)
	_tween_joint_parallel("left_elbow", _original_joints["left_elbow"] + Vector2(-10, -30), 0.3)
	_tween_joint_parallel("right_elbow", _original_joints["right_elbow"] + Vector2(10, -30), 0.3)

	# Pump fists
	current_tween.set_loops(3)
	_tween_joint("left_hand", victory_left + Vector2(0, 10), 0.2)
	_tween_joint_parallel("right_hand", victory_right + Vector2(0, 10), 0.2)
	_tween_joint("left_hand", victory_left, 0.2)
	_tween_joint_parallel("right_hand", victory_right, 0.2)


func _anim_defeat() -> void:
	_stop_current_tween()
	current_tween = create_tween()

	# Collapse
	_tween_joint("head", _original_joints["head"] + Vector2(0, 80), 0.4)
	_tween_joint_parallel("neck", _original_joints["neck"] + Vector2(0, 60), 0.4)
	_tween_joint_parallel("hip", _original_joints["hip"] + Vector2(0, 40), 0.4)
	_tween_joint_parallel("left_hand", _original_joints["left_hand"] + Vector2(-20, 50), 0.4)
	_tween_joint_parallel("right_hand", _original_joints["right_hand"] + Vector2(20, 50), 0.4)
	_tween_joint_parallel("left_knee", _original_joints["left_knee"] + Vector2(-10, 20), 0.4)
	_tween_joint_parallel("right_knee", _original_joints["right_knee"] + Vector2(10, 20), 0.4)

	# Fade out
	current_tween.tween_property(self, "modulate:a", 0.5, 0.3)
