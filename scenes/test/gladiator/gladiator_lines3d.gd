class_name GladiatorLines3D
extends Node3D
## 3D Wireframe stick figure using ImmediateMesh
## Ultra-minimal Geometry Wars aesthetic - pure glowing lines

signal animation_finished(anim_name: String)
signal hit_landed(damage: int)
signal took_damage(damage: int)

@export var fighter_name: String = "Fighter"
@export var max_hp: int = 100
@export var base_color: Color = Color.CYAN
@export var facing_right: bool = true
@export var line_width: float = 0.03
@export var show_weapon: bool = true
@export var weapon_color: Color = Color.ORANGE_RED

var current_hp: int = 100
var is_blocking: bool = false
var is_animating: bool = false
var current_animation: String = "idle"

var mesh_instance: MeshInstance3D
var current_tween: Tween
var glow_material: StandardMaterial3D
var weapon_material: StandardMaterial3D

# Joint positions (3D)
var joints: Dictionary = {
	"head": Vector3(0, 1.7, 0),
	"neck": Vector3(0, 1.5, 0),
	"left_shoulder": Vector3(-0.2, 1.45, 0),
	"right_shoulder": Vector3(0.2, 1.45, 0),
	"left_elbow": Vector3(-0.35, 1.2, 0),
	"right_elbow": Vector3(0.35, 1.2, 0),
	"left_hand": Vector3(-0.45, 0.95, 0),
	"right_hand": Vector3(0.45, 0.95, 0),
	"torso": Vector3(0, 1.2, 0),
	"hip": Vector3(0, 1.0, 0),
	"left_hip": Vector3(-0.1, 0.95, 0),
	"right_hip": Vector3(0.1, 0.95, 0),
	"left_knee": Vector3(-0.12, 0.55, 0),
	"right_knee": Vector3(0.12, 0.55, 0),
	"left_foot": Vector3(-0.15, 0.1, 0),
	"right_foot": Vector3(0.15, 0.1, 0),
}

var _original_joints: Dictionary = {}


func _ready() -> void:
	current_hp = max_hp
	_original_joints = joints.duplicate(true)

	_create_materials()
	_create_mesh()

	if not facing_right:
		_flip_joints()


func _create_materials() -> void:
	glow_material = StandardMaterial3D.new()
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.albedo_color = base_color
	glow_material.emission_enabled = true
	glow_material.emission = base_color
	glow_material.emission_energy_multiplier = 3.0

	weapon_material = StandardMaterial3D.new()
	weapon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	weapon_material.albedo_color = weapon_color
	weapon_material.emission_enabled = true
	weapon_material.emission = weapon_color
	weapon_material.emission_energy_multiplier = 4.0


func _create_mesh() -> void:
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)


func _flip_joints() -> void:
	for key in joints:
		joints[key].x *= -1
	_original_joints = joints.duplicate(true)


func _process(_delta: float) -> void:
	_rebuild_mesh()


func _rebuild_mesh() -> void:
	var immediate := ImmediateMesh.new()
	mesh_instance.mesh = immediate

	# Draw body lines
	immediate.surface_begin(Mesh.PRIMITIVE_LINES, glow_material)

	# Head circle (approximated with lines)
	_draw_circle_3d(joints["head"], 0.12, 12, immediate)

	# Neck
	_add_line(joints["head"] + Vector3(0, -0.12, 0), joints["neck"], immediate)

	# Torso
	_add_line(joints["neck"], joints["hip"], immediate)

	# Arms
	_add_line(joints["neck"], joints["left_shoulder"], immediate)
	_add_line(joints["left_shoulder"], joints["left_elbow"], immediate)
	_add_line(joints["left_elbow"], joints["left_hand"], immediate)

	_add_line(joints["neck"], joints["right_shoulder"], immediate)
	_add_line(joints["right_shoulder"], joints["right_elbow"], immediate)
	_add_line(joints["right_elbow"], joints["right_hand"], immediate)

	# Legs
	_add_line(joints["hip"], joints["left_hip"], immediate)
	_add_line(joints["left_hip"], joints["left_knee"], immediate)
	_add_line(joints["left_knee"], joints["left_foot"], immediate)

	_add_line(joints["hip"], joints["right_hip"], immediate)
	_add_line(joints["right_hip"], joints["right_knee"], immediate)
	_add_line(joints["right_knee"], joints["right_foot"], immediate)

	immediate.surface_end()

	# Draw weapon
	if show_weapon:
		immediate.surface_begin(Mesh.PRIMITIVE_LINES, weapon_material)
		var hand: Vector3 = joints["right_hand"]
		var weapon_dir := Vector3(1 if facing_right else -1, -0.3, 0).normalized()
		var weapon_end := hand + weapon_dir * 0.5
		_add_line(hand, weapon_end, immediate)

		# Weapon crossguard
		var cross_pos := hand + weapon_dir * 0.08
		var cross_dir := Vector3(0, 1, 0) * 0.08
		_add_line(cross_pos - cross_dir, cross_pos + cross_dir, immediate)

		immediate.surface_end()


func _add_line(from: Vector3, to: Vector3, mesh: ImmediateMesh) -> void:
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)


func _draw_circle_3d(center: Vector3, radius: float, segments: int, mesh: ImmediateMesh) -> void:
	for i in range(segments):
		var angle0 := (float(i) / segments) * TAU
		var angle1 := (float(i + 1) / segments) * TAU

		var p0 := center + Vector3(cos(angle0), sin(angle0), 0) * radius
		var p1 := center + Vector3(cos(angle1), sin(angle1), 0) * radius

		_add_line(p0, p1, mesh)


func reset_pose() -> void:
	joints = _original_joints.duplicate(true)


func play_animation(anim_name: String) -> void:
	if is_animating and anim_name != "hit":
		return

	is_animating = true
	current_animation = anim_name

	match anim_name:
		"idle": _anim_idle()
		"punch": _anim_punch()
		"kick": _anim_kick()
		"block": _anim_block()
		"dodge": _anim_dodge()
		"uppercut": _anim_uppercut()
		"sweep": _anim_sweep()
		"hit": _anim_hit()
		"victory": _anim_victory()
		"defeat": _anim_defeat()
		_: is_animating = false


func _finish_animation() -> void:
	is_animating = false
	animation_finished.emit(current_animation)
	current_animation = "idle"


func _stop_tween() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()


func _tween_joint(joint: String, target: Vector3, duration: float, parallel: bool = false) -> void:
	var method := func(pos: Vector3): joints[joint] = pos

	if parallel:
		current_tween.parallel().tween_method(method, joints[joint], target, duration)
	else:
		current_tween.tween_method(method, joints[joint], target, duration)


func take_damage(amount: int) -> void:
	if is_blocking:
		amount = int(amount * 0.3)
	current_hp = max(0, current_hp - amount)
	took_damage.emit(amount)
	if current_hp <= 0:
		play_animation("defeat")


func is_alive() -> bool:
	return current_hp > 0


func get_hp_percent() -> float:
	return float(current_hp) / float(max_hp)


## ANIMATIONS

func _anim_idle() -> void:
	_stop_tween()
	current_tween = create_tween()
	current_tween.set_loops()

	current_tween.tween_method(
		func(t: float):
			var sway := sin(t * TAU) * 0.02
			joints["head"] = _original_joints["head"] + Vector3(0, sway, 0)
			joints["left_hand"] = _original_joints["left_hand"] + Vector3(0, sway * 0.5, 0)
			joints["right_hand"] = _original_joints["right_hand"] + Vector3(0, -sway * 0.5, 0),
		0.0, 1.0, 1.8
	)
	is_animating = false


func _anim_punch() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dir := 1.0 if facing_right else -1.0
	var punch_target : Vector3 = _original_joints["right_hand"] + Vector3(0.4 * dir, 0.1, 0)

	# Wind up
	_tween_joint("right_hand", _original_joints["right_hand"] + Vector3(-0.1 * dir, 0, 0), 0.08)
	_tween_joint("right_elbow", _original_joints["right_elbow"] + Vector3(-0.05 * dir, 0, 0), 0.08, true)

	# Strike
	current_tween.tween_callback(func(): hit_landed.emit(10))
	_tween_joint("right_hand", punch_target, 0.06)
	_tween_joint("right_elbow", _original_joints["right_elbow"] + Vector3(0.15 * dir, 0.05, 0), 0.06, true)

	# Retract
	_tween_joint("right_hand", _original_joints["right_hand"], 0.12)
	_tween_joint("right_elbow", _original_joints["right_elbow"], 0.12, true)

	current_tween.tween_callback(_finish_animation)


func _anim_kick() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dir := 1.0 if facing_right else -1.0
	var kick_target : Vector3 = _original_joints["right_foot"] + Vector3(0.35 * dir, 0.3, 0)

	# Lift
	_tween_joint("right_knee", _original_joints["right_knee"] + Vector3(0.1 * dir, 0.2, 0), 0.1)
	_tween_joint("right_foot", _original_joints["right_foot"] + Vector3(0.05 * dir, 0.25, 0), 0.1, true)

	# Kick
	current_tween.tween_callback(func(): hit_landed.emit(15))
	_tween_joint("right_foot", kick_target, 0.08)
	_tween_joint("right_knee", _original_joints["right_knee"] + Vector3(0.2 * dir, 0.15, 0), 0.08, true)

	# Return
	_tween_joint("right_foot", _original_joints["right_foot"], 0.15)
	_tween_joint("right_knee", _original_joints["right_knee"], 0.15, true)

	current_tween.tween_callback(_finish_animation)


func _anim_block() -> void:
	_stop_tween()
	current_tween = create_tween()
	is_blocking = true

	var dir := 1.0 if facing_right else -1.0
	var block_pos := Vector3(0.1 * dir, 1.4, 0)

	_tween_joint("left_hand", block_pos + Vector3(-0.05 * dir, 0, 0), 0.1)
	_tween_joint("right_hand", block_pos + Vector3(0.05 * dir, -0.05, 0), 0.1, true)
	_tween_joint("left_elbow", _original_joints["left_elbow"] + Vector3(0.1 * dir, 0.1, 0), 0.1, true)
	_tween_joint("right_elbow", _original_joints["right_elbow"] + Vector3(-0.05 * dir, 0.1, 0), 0.1, true)

	current_tween.tween_interval(0.3)

	_tween_joint("left_hand", _original_joints["left_hand"], 0.12)
	_tween_joint("right_hand", _original_joints["right_hand"], 0.12, true)
	_tween_joint("left_elbow", _original_joints["left_elbow"], 0.12, true)
	_tween_joint("right_elbow", _original_joints["right_elbow"], 0.12, true)

	current_tween.tween_callback(func():
		is_blocking = false
		_finish_animation()
	)


func _anim_dodge() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dir := 1.0 if facing_right else -1.0
	var dodge := Vector3(-0.4 * dir, 0, 0)

	current_tween.tween_property(self, "position", position + dodge, 0.12)
	current_tween.tween_property(self, "position", position, 0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_uppercut() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dir := 1.0 if facing_right else -1.0

	# Crouch
	_tween_joint("head", _original_joints["head"] + Vector3(0, -0.15, 0), 0.08)
	_tween_joint("hip", _original_joints["hip"] + Vector3(0, -0.1, 0), 0.08, true)

	# Rising strike
	current_tween.tween_callback(func(): hit_landed.emit(25))
	var uppercut : Vector3 = _original_joints["right_hand"] + Vector3(0.15 * dir, 0.5, 0)
	_tween_joint("right_hand", uppercut, 0.07)
	_tween_joint("right_elbow", _original_joints["right_elbow"] + Vector3(0.1 * dir, 0.25, 0), 0.07, true)
	_tween_joint("head", _original_joints["head"] + Vector3(0, 0.05, 0), 0.07, true)
	_tween_joint("hip", _original_joints["hip"], 0.07, true)

	# Recover
	_tween_joint("right_hand", _original_joints["right_hand"], 0.18)
	_tween_joint("right_elbow", _original_joints["right_elbow"], 0.18, true)
	_tween_joint("head", _original_joints["head"], 0.18, true)

	current_tween.tween_callback(_finish_animation)


func _anim_sweep() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dir := 1.0 if facing_right else -1.0

	# Crouch
	_tween_joint("head", _original_joints["head"] + Vector3(0, -0.3, 0), 0.1)
	_tween_joint("hip", _original_joints["hip"] + Vector3(0, -0.2, 0), 0.1, true)

	# Sweep
	current_tween.tween_callback(func(): hit_landed.emit(12))
	var sweep : Vector3 = _original_joints["right_foot"] + Vector3(0.4 * dir, 0.05, 0)
	_tween_joint("right_foot", sweep, 0.1)
	_tween_joint("right_knee", _original_joints["right_knee"] + Vector3(0.25 * dir, 0, 0), 0.1, true)

	# Recover
	_tween_joint("right_foot", _original_joints["right_foot"], 0.18)
	_tween_joint("right_knee", _original_joints["right_knee"], 0.18, true)
	_tween_joint("head", _original_joints["head"], 0.18, true)
	_tween_joint("hip", _original_joints["hip"], 0.18, true)

	current_tween.tween_callback(_finish_animation)


func _anim_hit() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dir := 1.0 if facing_right else -1.0
	var knockback := Vector3(-0.15 * dir, 0, 0)

	current_tween.tween_property(self, "position", position + knockback, 0.06)

	# Flash
	current_tween.tween_callback(func():
		glow_material.emission = Color.RED
		glow_material.albedo_color = Color.RED
	)
	current_tween.tween_interval(0.05)
	current_tween.tween_callback(func():
		glow_material.emission = base_color
		glow_material.albedo_color = base_color
	)

	current_tween.tween_property(self, "position", position, 0.1)

	current_tween.tween_callback(_finish_animation)


func _anim_victory() -> void:
	_stop_tween()
	current_tween = create_tween()

	_tween_joint("left_hand", _original_joints["left_hand"] + Vector3(-0.15, 0.5, 0), 0.25)
	_tween_joint("right_hand", _original_joints["right_hand"] + Vector3(0.15, 0.5, 0), 0.25, true)

	current_tween.set_loops(3)
	current_tween.tween_method(
		func(t: float):
			joints["head"] = _original_joints["head"] + Vector3(0, 0.05 + sin(t * TAU) * 0.03, 0),
		0.0, 1.0, 0.3
	)


func _anim_defeat() -> void:
	_stop_tween()
	current_tween = create_tween()

	_tween_joint("head", _original_joints["head"] + Vector3(0, -0.5, 0.1), 0.4)
	_tween_joint("hip", _original_joints["hip"] + Vector3(0, -0.3, 0), 0.4, true)
	_tween_joint("left_hand", _original_joints["left_hand"] + Vector3(-0.1, -0.3, 0), 0.4, true)
	_tween_joint("right_hand", _original_joints["right_hand"] + Vector3(0.1, -0.3, 0), 0.4, true)

	current_tween.tween_callback(func():
		glow_material.emission_energy_multiplier = 1.0
	)
