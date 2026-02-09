extends Control
## Main menu test scene. Dark brown bg, title, 3 buttons, version label.


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
