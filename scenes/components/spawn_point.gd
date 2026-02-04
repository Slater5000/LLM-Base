@tool
extends Marker2D
class_name SpawnPoint
## Marks a location where the player can spawn after a scene transition.
## Add to "spawn_points" group automatically.
##
## Usage: Place in scene, set spawn_id to match transition targets.
## Common IDs: "default", "door_exit", "from_left", "from_right", "from_top", "from_bottom"

## Unique identifier for this spawn point.
## Transitions reference this ID to know where to place the player.
@export var spawn_id: String = "default"

## Direction player should face after spawning (for animation purposes later)
@export_enum("down", "up", "left", "right") var facing_direction: String = "down"

## Editor visualization color
@export var editor_color: Color = Color(0.2, 0.8, 0.2, 0.7)


func _ready() -> void:
	add_to_group("spawn_points")

	# Hide in game, only visible in editor
	if not Engine.is_editor_hint():
		hide()


func get_spawn_id() -> String:
	return spawn_id


func get_facing_direction() -> String:
	return facing_direction


func _draw() -> void:
	if Engine.is_editor_hint():
		# Draw spawn point indicator in editor
		draw_circle(Vector2.ZERO, 8.0, editor_color)
		draw_string(ThemeDB.fallback_font, Vector2(-20, -12), spawn_id, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

		# Draw facing direction arrow
		var arrow_dir := Vector2.DOWN
		match facing_direction:
			"up": arrow_dir = Vector2.UP
			"left": arrow_dir = Vector2.LEFT
			"right": arrow_dir = Vector2.RIGHT
		draw_line(Vector2.ZERO, arrow_dir * 16, Color.WHITE, 2.0)
