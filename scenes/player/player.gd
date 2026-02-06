extends CharacterBody2D
class_name Player
## Player character with smooth 8-directional movement.
## Registers with SceneManager for scene transitions.
## Uses CharacterBody2D for collision handling.

## Movement speed in pixels per second.
@export var move_speed: float = 160.0

## Animation speed (frames per second)
@export var animation_fps: float = 8.0

## Reference to the sprite for animation direction.
@onready var sprite: Sprite2D = $Sprite2D

## Current facing direction (for animations and spawn facing)
var facing_direction: String = "down"

## Animation timer
var animation_time: float = 0.0
var current_frame: int = 0
var is_moving: bool = false

## Frame offsets for each direction (row * 4)
const FRAME_DOWN: int = 0
const FRAME_LEFT: int = 4
const FRAME_RIGHT: int = 8
const FRAME_UP: int = 12


func _ready() -> void:
	# Add to player group for detection by AreaTransition
	add_to_group("player")

	# Register with SceneManager
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.register_player(self)

	# Set initial frame
	_set_direction_frame()


func _physics_process(delta: float) -> void:
	# Don't move during dialogue or menu
	if _is_input_blocked():
		velocity = Vector2.ZERO
		is_moving = false
		_set_direction_frame()  # Show idle frame
		return

	var input_direction := _get_input_direction()
	velocity = input_direction * move_speed

	move_and_slide()

	# Update movement state
	is_moving = input_direction != Vector2.ZERO

	_update_facing_direction(input_direction)
	_update_animation(delta)


## Note: F key (open_menu) is handled by RadialMenu autoload directly


func _get_input_direction() -> Vector2:
	var direction := Vector2.ZERO

	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	# Normalize to prevent faster diagonal movement
	if direction.length() > 1.0:
		direction = direction.normalized()

	return direction


func _update_facing_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	# Determine primary direction (favor horizontal for diagonals)
	if abs(direction.x) > abs(direction.y):
		facing_direction = "right" if direction.x > 0 else "left"
	else:
		facing_direction = "down" if direction.y > 0 else "up"


func _update_animation(delta: float) -> void:
	if is_moving:
		# Advance animation timer
		animation_time += delta
		var frame_duration := 1.0 / animation_fps

		if animation_time >= frame_duration:
			animation_time -= frame_duration
			# Cycle through 4 walk frames (0, 1, 2, 3)
			current_frame = (current_frame + 1) % 4

		# Set the sprite frame based on direction and animation frame
		sprite.frame = _get_direction_offset() + current_frame
	else:
		# Reset to idle frame (frame 0 of current direction)
		animation_time = 0.0
		current_frame = 0
		_set_direction_frame()


func _get_direction_offset() -> int:
	match facing_direction:
		"down":
			return FRAME_DOWN
		"left":
			return FRAME_LEFT
		"right":
			return FRAME_RIGHT
		"up":
			return FRAME_UP
	return FRAME_DOWN


func _set_direction_frame() -> void:
	sprite.frame = _get_direction_offset()


## Set the player's facing direction (used after transitions)
func set_facing_direction(dir: String) -> void:
	facing_direction = dir
	_set_direction_frame()


## Get current facing direction
func get_facing_direction() -> String:
	return facing_direction


## Check if any modal UI is blocking input (dialogue, menu, etc.)
func _is_input_blocked() -> bool:
	if _is_dialogue_active():
		return true
	if _is_menu_open():
		return true
	return false


## Check if dialogue is currently active
func _is_dialogue_active() -> bool:
	var dialogue_manager := get_node_or_null("/root/DialogueManager")
	if dialogue_manager and dialogue_manager.has_method("is_dialogue_active"):
		return dialogue_manager.is_dialogue_active()
	return false


## Check if radial menu is currently open
func _is_menu_open() -> bool:
	var radial_menu := get_node_or_null("/root/RadialMenu")
	if radial_menu and radial_menu.has_method("is_menu_open"):
		return radial_menu.is_menu_open()
	return false
