extends Node2D
## Route 1 - Wild area between Town 1 and further regions.
## Features tall grass patches and varied terrain.


func _ready() -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.register_world(self)

	print("Route 1 loaded - Go west to return to Town 1")
