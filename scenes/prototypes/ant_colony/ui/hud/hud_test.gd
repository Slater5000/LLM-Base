extends Control
## In-game HUD layout mockup. Shows food, distance, workers,
## and tool indicator at viewport corners.


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
