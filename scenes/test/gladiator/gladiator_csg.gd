class_name GladiatorCSG
extends Node3D
## 3D Stick figure gladiator using CSG primitives
## Simple and visual - great for prototyping

signal animation_finished(anim_name: String)
signal hit_landed(damage: int)
signal took_damage(damage: int)

@export var fighter_name: String = "Fighter"
@export var max_hp: int = 100
@export var base_color: Color = Color.CYAN
@export var facing_right: bool = true
@export var show_weapon: bool = true
@export var weapon_color: Color = Color.ORANGE_RED

var current_hp: int = 100
var is_blocking: bool = false
var is_animating: bool = false
var current_animation: String = "idle"

# CSG nodes
var head: CSGSphere3D
var torso: CSGCylinder3D
var left_upper_arm: CSGCylinder3D
var left_lower_arm: CSGCylinder3D
var right_upper_arm: CSGCylinder3D
var right_lower_arm: CSGCylinder3D
var left_upper_leg: CSGCylinder3D
var left_lower_leg: CSGCylinder3D
var right_upper_leg: CSGCylinder3D
var right_lower_leg: CSGCylinder3D
var weapon: CSGBox3D

# Pivot points for limb rotation
var left_shoulder: Node3D
var right_shoulder: Node3D
var left_elbow: Node3D
var right_elbow: Node3D
var left_hip: Node3D
var right_hip: Node3D
var left_knee: Node3D
var right_knee: Node3D

var current_tween: Tween
var glow_material: StandardMaterial3D
var weapon_material: StandardMaterial3D


func _ready() -> void:
	current_hp = max_hp
	_create_materials()
	_build_figure()

	if not facing_right:
		rotation.y = PI


func _create_materials() -> void:
	glow_material = StandardMaterial3D.new()
	glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_material.albedo_color = base_color
	glow_material.emission_enabled = true
	glow_material.emission = base_color
	glow_material.emission_energy_multiplier = 2.0

	weapon_material = StandardMaterial3D.new()
	weapon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	weapon_material.albedo_color = weapon_color
	weapon_material.emission_enabled = true
	weapon_material.emission = weapon_color
	weapon_material.emission_energy_multiplier = 2.5


func _build_figure() -> void:
	# Head
	head = CSGSphere3D.new()
	head.radius = 0.15
	head.position = Vector3(0, 1.7, 0)
	head.material = glow_material
	add_child(head)

	# Torso
	torso = CSGCylinder3D.new()
	torso.radius = 0.08
	torso.height = 0.5
	torso.position = Vector3(0, 1.25, 0)
	torso.material = glow_material
	add_child(torso)

	# Arms
	_create_arm(true)   # Left
	_create_arm(false)  # Right

	# Legs
	_create_leg(true)   # Left
	_create_leg(false)  # Right

	# Weapon
	if show_weapon:
		weapon = CSGBox3D.new()
		weapon.size = Vector3(0.05, 0.6, 0.02)
		weapon.position = Vector3(0, -0.35, 0)
		weapon.material = weapon_material
		right_elbow.get_child(0).add_child(weapon)  # Attach to right forearm


func _create_arm(is_left: bool) -> void:
	var side := -1 if is_left else 1
	var shoulder_pos := Vector3(side * 0.15, 1.45, 0)

	# Shoulder pivot
	var shoulder := Node3D.new()
	shoulder.position = shoulder_pos
	add_child(shoulder)

	# Upper arm
	var upper := CSGCylinder3D.new()
	upper.radius = 0.04
	upper.height = 0.3
	upper.position = Vector3(side * 0.15, -0.05, 0)
	upper.rotation = Vector3(0, 0, side * 0.3)
	upper.material = glow_material
	shoulder.add_child(upper)

	# Elbow pivot
	var elbow := Node3D.new()
	elbow.position = Vector3(side * 0.25, -0.15, 0)
	shoulder.add_child(elbow)

	# Lower arm
	var lower := CSGCylinder3D.new()
	lower.radius = 0.035
	lower.height = 0.28
	lower.position = Vector3(0, -0.15, 0)
	lower.material = glow_material
	elbow.add_child(lower)

	if is_left:
		left_shoulder = shoulder
		left_upper_arm = upper
		left_elbow = elbow
		left_lower_arm = lower
	else:
		right_shoulder = shoulder
		right_upper_arm = upper
		right_elbow = elbow
		right_lower_arm = lower


func _create_leg(is_left: bool) -> void:
	var side := -1 if is_left else 1
	var hip_pos := Vector3(side * 0.08, 1.0, 0)

	# Hip pivot
	var hip := Node3D.new()
	hip.position = hip_pos
	add_child(hip)

	# Upper leg
	var upper := CSGCylinder3D.new()
	upper.radius = 0.05
	upper.height = 0.4
	upper.position = Vector3(0, -0.2, 0)
	upper.material = glow_material
	hip.add_child(upper)

	# Knee pivot
	var knee := Node3D.new()
	knee.position = Vector3(0, -0.4, 0)
	hip.add_child(knee)

	# Lower leg
	var lower := CSGCylinder3D.new()
	lower.radius = 0.04
	lower.height = 0.4
	lower.position = Vector3(0, -0.2, 0)
	lower.material = glow_material
	knee.add_child(lower)

	if is_left:
		left_hip = hip
		left_upper_leg = upper
		left_knee = knee
		left_lower_leg = lower
	else:
		right_hip = hip
		right_upper_leg = upper
		right_knee = knee
		right_lower_leg = lower


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


func reset_pose() -> void:
	_stop_tween()
	# Reset all rotations
	left_shoulder.rotation = Vector3.ZERO
	right_shoulder.rotation = Vector3.ZERO
	left_elbow.rotation = Vector3.ZERO
	right_elbow.rotation = Vector3.ZERO
	left_hip.rotation = Vector3.ZERO
	right_hip.rotation = Vector3.ZERO
	left_knee.rotation = Vector3.ZERO
	right_knee.rotation = Vector3.ZERO
	head.position.y = 1.7


## ANIMATIONS

func _anim_idle() -> void:
	_stop_tween()
	current_tween = create_tween()
	current_tween.set_loops()

	# Breathing bob
	current_tween.tween_method(
		func(t: float):
			head.position.y = 1.7 + sin(t * TAU) * 0.02,
		0.0, 1.0, 2.0
	)
	is_animating = false


func _anim_punch() -> void:
	_stop_tween()
	current_tween = create_tween()

	# Wind up
	current_tween.tween_property(right_shoulder, "rotation:x", -0.5, 0.08)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", -0.8, 0.08)

	# Strike
	current_tween.tween_callback(func(): hit_landed.emit(10))
	current_tween.tween_property(right_shoulder, "rotation:x", 0.8, 0.06)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", 0.2, 0.06)

	# Retract
	current_tween.tween_property(right_shoulder, "rotation:x", 0.0, 0.12)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", 0.0, 0.12)

	current_tween.tween_callback(_finish_animation)


func _anim_kick() -> void:
	_stop_tween()
	current_tween = create_tween()

	# Lift leg
	current_tween.tween_property(right_hip, "rotation:x", -1.2, 0.1)
	current_tween.parallel().tween_property(right_knee, "rotation:x", 0.8, 0.1)

	# Extend kick
	current_tween.tween_callback(func(): hit_landed.emit(15))
	current_tween.tween_property(right_knee, "rotation:x", 0.0, 0.08)

	# Return
	current_tween.tween_property(right_hip, "rotation:x", 0.0, 0.15)
	current_tween.parallel().tween_property(right_knee, "rotation:x", 0.0, 0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_block() -> void:
	_stop_tween()
	current_tween = create_tween()
	is_blocking = true

	# Arms up
	current_tween.tween_property(left_shoulder, "rotation:x", -1.2, 0.1)
	current_tween.parallel().tween_property(right_shoulder, "rotation:x", -1.2, 0.1)
	current_tween.parallel().tween_property(left_elbow, "rotation:x", -1.5, 0.1)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", -1.5, 0.1)

	# Hold
	current_tween.tween_interval(0.3)

	# Lower
	current_tween.tween_property(left_shoulder, "rotation:x", 0.0, 0.12)
	current_tween.parallel().tween_property(right_shoulder, "rotation:x", 0.0, 0.12)
	current_tween.parallel().tween_property(left_elbow, "rotation:x", 0.0, 0.12)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", 0.0, 0.12)

	current_tween.tween_callback(func():
		is_blocking = false
		_finish_animation()
	)


func _anim_dodge() -> void:
	_stop_tween()
	current_tween = create_tween()

	var dodge_dir := Vector3(-0.5 if facing_right else 0.5, 0, 0)
	current_tween.tween_property(self, "position", position + dodge_dir, 0.12)
	current_tween.tween_property(self, "position", position, 0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_uppercut() -> void:
	_stop_tween()
	current_tween = create_tween()

	# Crouch
	current_tween.tween_property(head, "position:y", 1.5, 0.08)
	current_tween.parallel().tween_property(right_shoulder, "rotation:x", 0.5, 0.08)

	# Rising strike
	current_tween.tween_callback(func(): hit_landed.emit(25))
	current_tween.tween_property(head, "position:y", 1.8, 0.06)
	current_tween.parallel().tween_property(right_shoulder, "rotation:x", -1.5, 0.06)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", -0.5, 0.06)

	# Recover
	current_tween.tween_property(head, "position:y", 1.7, 0.15)
	current_tween.parallel().tween_property(right_shoulder, "rotation:x", 0.0, 0.15)
	current_tween.parallel().tween_property(right_elbow, "rotation:x", 0.0, 0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_sweep() -> void:
	_stop_tween()
	current_tween = create_tween()

	# Crouch
	current_tween.tween_property(head, "position:y", 1.4, 0.1)

	# Sweep
	current_tween.tween_callback(func(): hit_landed.emit(12))
	current_tween.tween_property(right_hip, "rotation:z", 1.2, 0.1)
	current_tween.parallel().tween_property(right_knee, "rotation:x", 0.3, 0.1)

	# Recover
	current_tween.tween_property(right_hip, "rotation:z", 0.0, 0.15)
	current_tween.parallel().tween_property(right_knee, "rotation:x", 0.0, 0.15)
	current_tween.parallel().tween_property(head, "position:y", 1.7, 0.15)

	current_tween.tween_callback(_finish_animation)


func _anim_hit() -> void:
	_stop_tween()
	current_tween = create_tween()

	var knockback := Vector3(-0.2 if facing_right else 0.2, 0, 0)
	current_tween.tween_property(self, "position", position + knockback, 0.06)

	# Flash red
	var flash_mat := glow_material.duplicate()
	flash_mat.emission = Color.RED
	flash_mat.albedo_color = Color.RED

	current_tween.tween_callback(func():
		head.material = flash_mat
		torso.material = flash_mat
	)
	current_tween.tween_interval(0.05)
	current_tween.tween_callback(func():
		head.material = glow_material
		torso.material = glow_material
	)

	current_tween.tween_property(self, "position", position, 0.1)

	current_tween.tween_callback(_finish_animation)


func _anim_victory() -> void:
	_stop_tween()
	current_tween = create_tween()

	# Arms up
	current_tween.tween_property(left_shoulder, "rotation:z", 1.0, 0.25)
	current_tween.parallel().tween_property(right_shoulder, "rotation:z", -1.0, 0.25)

	# Pump
	current_tween.set_loops(3)
	current_tween.tween_property(head, "position:y", 1.75, 0.15)
	current_tween.tween_property(head, "position:y", 1.7, 0.15)


func _anim_defeat() -> void:
	_stop_tween()
	current_tween = create_tween()

	# Collapse
	current_tween.tween_property(head, "position:y", 1.2, 0.4)
	current_tween.parallel().tween_property(left_hip, "rotation:x", 1.0, 0.4)
	current_tween.parallel().tween_property(right_hip, "rotation:x", 1.0, 0.4)
	current_tween.parallel().tween_property(left_shoulder, "rotation:z", 0.5, 0.4)
	current_tween.parallel().tween_property(right_shoulder, "rotation:z", -0.5, 0.4)

	# Fade
	current_tween.tween_callback(func():
		glow_material.emission_energy_multiplier = 0.5
	)
