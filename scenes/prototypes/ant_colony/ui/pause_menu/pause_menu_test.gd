extends Control
## Pause menu test: dark overlay with centered panel and buttons.


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
