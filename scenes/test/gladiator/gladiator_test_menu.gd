extends Control
## Main menu for selecting gladiator visual test scenes
## Allows easy comparison between all approaches

const SCENES := {
	"2D Line2D (Side View)": "res://scenes/test/gladiator/test_gladiator_line2d.tscn",
	"2D Shapes (Top-Down)": "res://scenes/test/gladiator/test_gladiator_shapes.tscn",
	"3D CSG (Side View)": "res://scenes/test/gladiator/test_gladiator_csg.tscn",
	"3D Wireframe (Neon Lines)": "res://scenes/test/gladiator/test_gladiator_lines3d.tscn",
}

var buttons: Array[Button] = []
var selected_index: int = 0


func _ready() -> void:
	_setup_ui()
	_select_button(0)


func _setup_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Container
	var container := VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(-200, -200)
	container.custom_minimum_size = Vector2(400, 400)
	add_child(container)

	# Title
	var title := Label.new()
	title.text = "GLADIATOR VISUAL TESTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Compare different rendering approaches"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color.GRAY)
	container.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	container.add_child(spacer)

	# Scene buttons
	var idx := 0
	for scene_name in SCENES:
		var btn := Button.new()
		btn.text = scene_name
		btn.custom_minimum_size = Vector2(350, 50)
		btn.add_theme_font_size_override("font_size", 18)

		var scene_path: String = SCENES[scene_name]
		btn.pressed.connect(func(): _load_scene(scene_path))
		btn.focus_entered.connect(func(): _on_button_focused(idx))

		container.add_child(btn)
		buttons.append(btn)
		idx += 1

	# Spacer
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	container.add_child(spacer2)

	# Instructions
	var instructions := Label.new()
	instructions.text = "Arrow Keys: Navigate | Enter: Select | ESC: Return to menu"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	container.add_child(instructions)

	# Description panel
	var desc_panel := Panel.new()
	desc_panel.custom_minimum_size = Vector2(350, 80)
	container.add_child(desc_panel)

	var desc_label := Label.new()
	desc_label.name = "Description"
	desc_label.text = _get_description(0)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	desc_panel.add_child(desc_label)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_select_button((selected_index + 1) % buttons.size())
	elif event.is_action_pressed("ui_up"):
		_select_button((selected_index - 1 + buttons.size()) % buttons.size())
	elif event.is_action_pressed("ui_accept"):
		buttons[selected_index].pressed.emit()


func _select_button(idx: int) -> void:
	selected_index = idx
	buttons[idx].grab_focus()


func _on_button_focused(idx: int) -> void:
	selected_index = idx
	var desc := get_node_or_null("VBoxContainer/Panel/Description") as Label
	if desc:
		desc.text = _get_description(idx)


func _get_description(idx: int) -> String:
	match idx:
		0:
			return "Line2D nodes for limbs, procedural tween animation.\nSide-view camera (Street Fighter style).\nGood for: Classic 2D fighting game look."
		1:
			return "Pure _draw() method, circles and lines.\nTop-down arena camera.\nGood for: Minimal overhead, full control."
		2:
			return "CSG primitives (spheres, cylinders).\n3D with orthogonal side camera.\nGood for: Quick 3D prototyping."
		3:
			return "ImmediateMesh wireframe lines only.\nPure Geometry Wars neon aesthetic.\nGood for: Maximum visual style, minimal art."
		_:
			return ""


func _load_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
