extends Node2D
## Cursed Lands - A corrupted region filled with organic horrors.
## Features unique cursed creatures and haunting atmosphere.


func _ready() -> void:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.register_world(self)

	print("Cursed Lands loaded - A corrupted realm awaits...")
