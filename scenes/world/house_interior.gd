extends Node2D
## House Interior - Indoor scene demonstrating door transitions.
## Player enters from outside, can exit back to Route 1.


func _ready() -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.register_world(self)

	print("House Interior loaded - Press E at the door to exit")
