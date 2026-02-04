extends Node2D
## Main entry point - loads the starting world scene or continues from save.


func _ready() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var scene_manager := get_node_or_null("/root/SceneManager")

	# Check for existing save file
	if game_state and game_state.has_save():
		if scene_manager and scene_manager.load_from_save():
			return  # Scene will be loaded via SceneManager

	# No save or load failed - start fresh
	var starting_scene := preload("res://scenes/world/town_1.tscn").instantiate()
	add_child(starting_scene)

	# Register with SceneManager
	if scene_manager:
		scene_manager.register_world(starting_scene)
