extends Control
class_name MoveCard
## Individual move card for the move swap screen.
## Shows move name, power, type, and learn level if not learned.

signal pressed(move_id: String)
signal hovered(move_id: String)
signal unhovered()

var _move_id: String
var _move_data: MoveData
var _is_learned: bool
var _is_selected: bool
var _learn_level: int

var _panel: Panel
var _name_label: Label
var _locked_overlay: ColorRect
var _locked_label: Label
var _selected_indicator: ColorRect

const CARD_WIDTH := 100
const CARD_HEIGHT := 50

const ELEMENT_COLORS := {
	"fire": Color(0.85, 0.2, 0.15),
	"water": Color(0.2, 0.4, 0.85),
	"earth": Color(0.2, 0.55, 0.2),
	"air": Color(0.85, 0.75, 0.1)
}


func setup(move_id: String, move_data: MoveData, is_learned: bool, learn_level: int) -> void:
	_move_id = move_id
	_move_data = move_data
	_is_learned = is_learned
	_learn_level = learn_level
	_is_selected = false


func _ready() -> void:
	custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	clip_contents = true  # Prevent text overflow
	mouse_filter = Control.MOUSE_FILTER_STOP  # Always stop for hover detection
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if _is_learned:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		gui_input.connect(_on_gui_input)

	_build_ui()


func _build_ui() -> void:
	# Panel background
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.93, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = ELEMENT_COLORS.get(_move_data.element, Color.GRAY) if _move_data else Color.GRAY
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# Center container for name
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Move name - centered, stacked vertically for multi-word names
	_name_label = Label.new()
	var name_text: String = _move_data.display_name if _move_data else "???"
	# Stack words vertically by replacing spaces with newlines
	_name_label.text = name_text.replace(" ", "\n")
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", Color.BLACK)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center.add_child(_name_label)

	# Selected indicator (green border overlay)
	_selected_indicator = ColorRect.new()
	_selected_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	_selected_indicator.color = Color(0.2, 0.8, 0.3, 0.3)
	_selected_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selected_indicator.visible = false
	add_child(_selected_indicator)

	# Locked overlay for unlearned moves - completely black
	if not _is_learned:
		_locked_overlay = ColorRect.new()
		_locked_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_locked_overlay.color = Color(0.15, 0.15, 0.15, 1.0)  # Solid dark
		_locked_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_locked_overlay)

		_locked_label = Label.new()
		_locked_label.text = "Lv. %d" % _learn_level
		_locked_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_locked_label.add_theme_font_size_override("font_size", 16)
		_locked_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))  # Light gray on dark bg
		_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(_locked_label)


func set_selected(selected: bool) -> void:
	_is_selected = selected
	if _selected_indicator:
		_selected_indicator.visible = selected


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit(_move_id)


func _on_mouse_entered() -> void:
	hovered.emit(_move_id)


func _on_mouse_exited() -> void:
	unhovered.emit()
