extends Node2D
## Pallet Town - Starting town with player's house and Pokemon Lab.
## The player's journey begins here. Exit east to Route 1.


func _ready() -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.register_world(self)

	print("Pallet Town - Your adventure begins here!")
