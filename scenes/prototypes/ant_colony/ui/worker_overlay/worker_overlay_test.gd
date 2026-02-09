extends Control
## Worker overlay test: bottom-right panel with worker counts.


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
