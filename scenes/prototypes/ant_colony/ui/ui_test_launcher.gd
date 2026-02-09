extends Control
## Entry point for ant colony UI test scenes. Buttons to navigate each test.


func _ready() -> void:
	var scenes := [
		["Main Menu", AntColonyUI.MAIN_MENU],
		["Mode Select", AntColonyUI.MODE_SELECT],
		["Evolve Menu", AntColonyUI.EVOLVE_MENU],
		["Rainbow Menu", AntColonyUI.RAINBOW_MENU],
		["In-Game HUD", AntColonyUI.HUD],
		["Settings", AntColonyUI.SETTINGS],
		["Pause Menu", AntColonyUI.PAUSE_MENU],
		["Worker Overlay", AntColonyUI.WORKER_OVERLAY],
		["Ant Naming", AntColonyUI.ANT_NAMING],
		["Build Menu", AntColonyUI.BUILD_MENU],
	]

	var vbox := $MarginContainer/VBoxContainer
	for entry: Array in scenes:
		var btn := Button.new()
		btn.text = entry[0]
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_go_to.bind(entry[1]))
		vbox.add_child(btn)


func _go_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
