class_name GladiatorBase
extends Node2D
## Base class for all gladiator visual implementations
## Defines the animation interface that all approaches must implement

signal animation_finished(anim_name: String)
signal hit_landed(damage: int)
signal took_damage(damage: int)

# Fighter properties
@export var fighter_name: String = "Fighter"
@export var max_hp: int = 100
@export var base_color: Color = Color.CYAN
@export var facing_right: bool = true

var current_hp: int = 100
var is_blocking: bool = false
var is_animating: bool = false
var current_animation: String = "idle"

# Joint positions (override in subclasses)
var joints: Dictionary = {
	"head": Vector2(0, -60),
	"neck": Vector2(0, -45),
	"torso": Vector2(0, -20),
	"hip": Vector2(0, 10),
	"left_shoulder": Vector2(-15, -40),
	"right_shoulder": Vector2(15, -40),
	"left_elbow": Vector2(-30, -25),
	"right_elbow": Vector2(30, -25),
	"left_hand": Vector2(-40, -10),
	"right_hand": Vector2(40, -10),
	"left_knee": Vector2(-10, 35),
	"right_knee": Vector2(10, 35),
	"left_foot": Vector2(-15, 60),
	"right_foot": Vector2(15, 60),
}

# Store original positions for resetting
var _original_joints: Dictionary = {}


func _ready() -> void:
	current_hp = max_hp
	_original_joints = joints.duplicate(true)
	if not facing_right:
		_flip_horizontal()


func _flip_horizontal() -> void:
	for key in joints:
		joints[key].x *= -1
	_original_joints = joints.duplicate(true)


## Reset all joints to idle position
func reset_pose() -> void:
	joints = _original_joints.duplicate(true)
	queue_redraw()


## Animation interface - override these in subclasses
func play_animation(anim_name: String) -> void:
	if is_animating:
		return

	is_animating = true
	current_animation = anim_name

	match anim_name:
		"idle":
			_anim_idle()
		"punch":
			_anim_punch()
		"kick":
			_anim_kick()
		"block":
			_anim_block()
		"dodge":
			_anim_dodge()
		"uppercut":
			_anim_uppercut()
		"sweep":
			_anim_sweep()
		"hit":
			_anim_hit()
		"victory":
			_anim_victory()
		"defeat":
			_anim_defeat()
		_:
			is_animating = false


func _finish_animation() -> void:
	is_animating = false
	animation_finished.emit(current_animation)
	current_animation = "idle"


## Override these animation methods in subclasses
func _anim_idle() -> void:
	is_animating = false

func _anim_punch() -> void:
	_finish_animation()

func _anim_kick() -> void:
	_finish_animation()

func _anim_block() -> void:
	is_blocking = true
	_finish_animation()

func _anim_dodge() -> void:
	_finish_animation()

func _anim_uppercut() -> void:
	_finish_animation()

func _anim_sweep() -> void:
	_finish_animation()

func _anim_hit() -> void:
	_finish_animation()

func _anim_victory() -> void:
	_finish_animation()

func _anim_defeat() -> void:
	_finish_animation()


## Combat methods
func take_damage(amount: int) -> void:
	if is_blocking:
		amount = int(amount * 0.3)  # Block reduces damage by 70%

	current_hp = max(0, current_hp - amount)
	took_damage.emit(amount)

	if current_hp <= 0:
		play_animation("defeat")


func deal_damage() -> int:
	# Base damage, override for specific moves
	return 10


func end_block() -> void:
	is_blocking = false


func is_alive() -> bool:
	return current_hp > 0


func get_hp_percent() -> float:
	return float(current_hp) / float(max_hp)
