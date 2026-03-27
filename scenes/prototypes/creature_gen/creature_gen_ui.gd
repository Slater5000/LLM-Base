extends Button


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	var drawer := get_node_or_null(
		"/root/CreatureGenTest/CreatureDrawer"
	)
	if drawer and drawer.has_method("_randomize_palette"):
		drawer._randomize_palette()
		drawer._generate_walk_frames()
		drawer._generate_attack_frames()
