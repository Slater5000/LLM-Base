class_name CircleButton extends Control
## A bordered button for the radial menu using Craftpix 9-slice panels.

signal pressed(option_id: String)
signal hovered(option_id: String)

@export var option_id: String = ""
@export var label_text: String = ""
@export var disabled: bool = false

## Visual state
var is_selected: bool = false
var is_hovered: bool = false

## UI nodes
var _background: NinePatchRect
var _label: Label

## Button size - sized for font size 12
const BUTTON_SIZE := Vector2(80, 32)


func _ready() -> void:
	custom_minimum_size = BUTTON_SIZE
	size = BUTTON_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not disabled else Control.CURSOR_ARROW

	_create_ui()
	_update_visual()


func _create_ui() -> void:
	# Background using bordered panel from Main_tiles
	_background = NinePatchRect.new()
	_background.texture = preload("res://assets/sprites/ui/panels/panel_frame_48x40.png")
	_background.patch_margin_left = 6
	_background.patch_margin_top = 6
	_background.patch_margin_right = 6
	_background.patch_margin_bottom = 6
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_background)

	# Label for button text
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color.BLACK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.text = label_text
	add_child(_label)


func _update_visual() -> void:
	if not _background:
		return

	if disabled:
		_background.modulate = Color(0.6, 0.6, 0.6)
		_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	elif is_selected or is_hovered:
		_background.modulate = Color(1.2, 1.2, 1.0)  # Slight highlight
		_label.add_theme_color_override("font_color", Color.BLACK)
	else:
		_background.modulate = Color.WHITE
		_label.add_theme_color_override("font_color", Color.BLACK)


func _gui_input(event: InputEvent) -> void:
	if disabled:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pressed.emit(option_id)
			accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_MOUSE_ENTER:
			if not disabled:
				is_hovered = true
				hovered.emit(option_id)
				_update_visual()
		NOTIFICATION_MOUSE_EXIT:
			is_hovered = false
			_update_visual()


## Set selected state (called by RadialMenu)
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual()


## Set disabled state
func set_disabled(value: bool) -> void:
	disabled = value
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	_update_visual()
