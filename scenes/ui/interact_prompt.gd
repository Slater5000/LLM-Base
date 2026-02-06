extends Control
class_name InteractPrompt
## Styled interact prompt with outlined text.
## Shows "[E] Talk" or similar above interactable objects.

@export var prompt_text: String = "(E)":
	set(value):
		prompt_text = value
		if _label:
			_label.text = value

var _label: Label


func _ready() -> void:
	# Fixed width container so we can center properly
	custom_minimum_size = Vector2(80, 30)
	size = Vector2(80, 30)
	_create_ui()


func _create_ui() -> void:
	# Label with black text and white outline - centered in container
	_label = Label.new()
	_label.text = prompt_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_color", Color.BLACK)
	_label.add_theme_color_override("font_outline_color", Color.WHITE)
	_label.add_theme_constant_override("outline_size", 7)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
