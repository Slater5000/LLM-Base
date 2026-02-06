extends Control
class_name CreatureSubmenu
## Small popup menu that appears when clicking a creature in the party screen.
## Shows MOVES and DETAILS options.

signal moves_selected(creature_index: int)
signal details_selected(creature_index: int)
signal swap_selected(creature_index: int)
signal closed

var _creature_index: int = -1
var _slot_global_pos: Vector2
var _slot_size: Vector2
var _panel: NinePatchRect
var _panel_container: Control
var _panel_position: Vector2

const SUBMENU_WIDTH := 81
const SUBMENU_HEIGHT := 65  # 3 buttons with proper padding


func setup(creature_index: int, slot_global_pos: Vector2, slot_size: Vector2) -> void:
	_creature_index = creature_index
	_slot_global_pos = slot_global_pos
	_slot_size = slot_size


func _ready() -> void:
	# Don't block mouse - let clicks pass through to slots below
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Calculate panel position now that we're in the tree
	_calculate_panel_position()
	_create_ui()


func _calculate_panel_position() -> void:
	# Position to the right of the slot
	var target_x := _slot_global_pos.x + _slot_size.x + 4
	var target_y := _slot_global_pos.y

	_panel_position = Vector2(target_x, target_y)


func _create_ui() -> void:
	# Panel container at the calculated position
	_panel_container = Control.new()
	_panel_container.position = _panel_position
	_panel_container.size = Vector2(SUBMENU_WIDTH, SUBMENU_HEIGHT)
	_panel_container.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel_container)

	# Panel background
	_panel = NinePatchRect.new()
	_panel.texture = preload("res://assets/sprites/ui/panels/panel_frame_48x40.png")
	_panel.patch_margin_left = 8
	_panel.patch_margin_top = 8
	_panel.patch_margin_right = 8
	_panel.patch_margin_bottom = 8
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_container.add_child(_panel)

	# Content margin
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	_panel_container.add_child(margin)

	# VBox for buttons
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	# MOVES button
	var moves_btn := _create_menu_button("MOVES")
	moves_btn.pressed.connect(_on_moves_pressed)
	vbox.add_child(moves_btn)

	# DETAILS button
	var details_btn := _create_menu_button("DETAILS")
	details_btn.pressed.connect(_on_details_pressed)
	vbox.add_child(details_btn)

	# SWAP button
	var swap_btn := _create_menu_button("SWAP")
	swap_btn.pressed.connect(_on_swap_pressed)
	vbox.add_child(swap_btn)


func _create_menu_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(54, 14)
	btn.add_theme_font_size_override("font_size", 8)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _on_moves_pressed() -> void:
	moves_selected.emit(_creature_index)
	queue_free()


func _on_details_pressed() -> void:
	details_selected.emit(_creature_index)
	queue_free()


func _on_swap_pressed() -> void:
	swap_selected.emit(_creature_index)
	queue_free()


func _on_close_pressed() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Close if clicking outside the panel
		var panel_rect := Rect2(_panel_container.global_position, _panel_container.size)
		if not panel_rect.has_point(event.global_position):
			_on_close_pressed()
