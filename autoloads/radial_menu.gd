extends CanvasLayer
class_name RadialMenuClass
## RadialMenu - Circular menu overlay centered on player.
## Opens with F key, doesn't pause the game.
## Uses Craftpix UI sprites for visual buttons.
##
## Usage:
##   RadialMenu.open_menu()
##   RadialMenu.close_menu()
##   await RadialMenu.menu_closed

signal menu_opened
signal menu_closed
signal option_selected(option_id: String)

## Menu state
var _is_open: bool = false
var _selected_index: int = 0
var _open_time: float = 0.0  # Time when menu was opened (for input delay)
var _scanner_was_active: bool = false  # Track if scanner was active when menu opened

## Delay before accepting confirm input (prevents instant-select when same key opens menu)
const CONFIRM_DELAY := 0.15  # 150ms

## Menu options (clockwise from top)
const MENU_OPTIONS := [
	{"id": "party", "label": "PARTY", "disabled": false},
	{"id": "bag", "label": "BAG", "disabled": true},
	{"id": "dex", "label": "DEX", "disabled": false},
	{"id": "save", "label": "SAVE", "disabled": false},
	{"id": "options", "label": "OPT", "disabled": false},
	{"id": "exit", "label": "EXIT", "disabled": false},
]

## Navigation mapping (index -> [up, right, down, left] neighbor indices)
## Arranged as: 0=top, 1=top-right, 2=bottom-right, 3=bottom, 4=bottom-left, 5=top-left
const NAV_MAP := {
	0: {"up": 3, "right": 1, "down": 3, "left": 5},  # Top
	1: {"up": 0, "right": 2, "down": 2, "left": 0},  # Top-right
	2: {"up": 1, "right": 3, "down": 3, "left": 1},  # Bottom-right
	3: {"up": 0, "right": 2, "down": 0, "left": 4},  # Bottom
	4: {"up": 5, "right": 3, "down": 3, "left": 5},  # Bottom-left
	5: {"up": 0, "right": 0, "down": 4, "left": 4},  # Top-left
}

## Button positions relative to center (radius ~80px for 80x32 buttons)
const BUTTON_POSITIONS := [
	Vector2(0, -65),    # Top
	Vector2(80, -32),   # Top-right
	Vector2(80, 32),    # Bottom-right
	Vector2(0, 65),     # Bottom
	Vector2(-80, 32),   # Bottom-left
	Vector2(-80, -32),  # Top-left
]

## UI references
var _overlay: ColorRect
var _menu_container: Control
var _buttons: Array[CircleButton] = []
var _tooltip: Label
var _save_feedback: Label

## Scene references
var _circle_button_scene: PackedScene


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always receive input (for F key toggle)
	_circle_button_scene = preload("res://scenes/ui/radial_menu/circle_button.tscn")
	_create_ui()
	_hide_menu()


func _create_ui() -> void:
	# Darkening overlay
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.25)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# Container that follows player
	_menu_container = Control.new()
	_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_menu_container)

	# Create circle buttons
	for i in MENU_OPTIONS.size():
		var option: Dictionary = MENU_OPTIONS[i]
		var button: CircleButton = _circle_button_scene.instantiate()
		button.option_id = option.id
		button.label_text = option.label
		button.disabled = option.disabled
		button.pressed.connect(_on_button_pressed)
		button.hovered.connect(_on_button_hovered)
		_menu_container.add_child(button)
		_buttons.append(button)

	# Tooltip label at bottom
	_tooltip = Label.new()
	_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tooltip.add_theme_font_size_override("font_size", 16)
	_tooltip.add_theme_color_override("font_color", Color.BLACK)
	_tooltip.add_theme_color_override("font_outline_color", Color.WHITE)
	_tooltip.add_theme_constant_override("outline_size", 5)
	_menu_container.add_child(_tooltip)

	# Save feedback label
	_save_feedback = Label.new()
	_save_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_save_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_save_feedback.add_theme_font_size_override("font_size", 16)
	_save_feedback.add_theme_color_override("font_color", Color.BLACK)
	_save_feedback.add_theme_color_override("font_outline_color", Color.WHITE)
	_save_feedback.add_theme_constant_override("outline_size", 5)
	_save_feedback.text = "SAVED!"
	_save_feedback.hide()
	_menu_container.add_child(_save_feedback)


func _process(_delta: float) -> void:
	if not _is_open:
		return

	_update_menu_position()


func _input(event: InputEvent) -> void:
	# Handle F key toggle (works both paused and unpaused)
	if event.is_action_pressed("open_menu"):
		if _is_open:
			close_menu()
		else:
			# Don't open if scene isn't ready (no player yet)
			if not _get_player():
				return
			# Only open if no dialogue active
			var dialogue_manager := get_node_or_null("/root/DialogueManager")
			if dialogue_manager and dialogue_manager.has_method("is_dialogue_active"):
				if dialogue_manager.is_dialogue_active():
					return
			open_menu()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	# Handle navigation
	if event.is_action_pressed("move_up"):
		_navigate("up")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		_navigate("down")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		_navigate("left")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		_navigate("right")
		get_viewport().set_input_as_handled()

	# Handle confirm (with delay to prevent instant-select when same key opens menu)
	elif event.is_action_pressed("interact") or event.is_action_pressed("menu_confirm"):
		var current_time := Time.get_ticks_msec() / 1000.0
		if current_time - _open_time >= CONFIRM_DELAY:
			_confirm_selection()
		get_viewport().set_input_as_handled()

	# Handle cancel/close
	elif event.is_action_pressed("menu_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()


func _update_menu_position() -> void:
	var player := _get_player()
	if not player:
		return

	var viewport := get_viewport()
	if not viewport:
		return

	# Get player's screen position
	var camera := viewport.get_camera_2d()
	var screen_pos: Vector2
	if camera:
		var viewport_size := viewport.get_visible_rect().size
		screen_pos = player.global_position - camera.global_position + viewport_size / 2.0
	else:
		screen_pos = player.global_position

	# Position buttons around player
	for i in _buttons.size():
		var button := _buttons[i]
		var offset: Vector2 = BUTTON_POSITIONS[i]
		button.position = screen_pos + offset - button.size / 2.0

	# Position tooltip below the ring
	_tooltip.position = screen_pos + Vector2(-60, 85)
	_tooltip.size = Vector2(120, 20)

	# Position save feedback at screen center
	var viewport_size := viewport.get_visible_rect().size
	_save_feedback.position = viewport_size / 2.0 - Vector2(50, 10)
	_save_feedback.size = Vector2(100, 20)


func _get_player() -> CharacterBody2D:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("get_player"):
		return scene_manager.get_player()
	return null


## Open the menu
func open_menu() -> void:
	if _is_open:
		return

	# Check if another menu is already open (except scanner_prompt which we can stack with)
	if GameState.is_menu_open():
		var current := GameState.get_current_menu()
		# Only allow if scanner_prompt is the only open menu
		if current != "scanner_prompt":
			return

	# Track if scanner was active (so we can restore it when menu closes)
	var scanner := get_node_or_null("/root/Scanner")
	_scanner_was_active = scanner and scanner.is_scanner_active() and not scanner._is_prompting

	# Close scanner temporarily while menu is open
	if _scanner_was_active:
		scanner.close_scanner()

	# Register with GameState (allow stacking if scanner_prompt is open)
	var allow_stacking := GameState.is_specific_menu_open("scanner_prompt")
	if not GameState.open_menu("radial_menu", allow_stacking):
		_scanner_was_active = false  # Don't restore if we couldn't open
		return  # Failed to open (another menu blocked it)

	_is_open = true
	_selected_index = 0
	_open_time = Time.get_ticks_msec() / 1000.0  # Record open time for input delay

	# Find first non-disabled option
	for i in MENU_OPTIONS.size():
		if not MENU_OPTIONS[i].disabled:
			_selected_index = i
			break

	_show_menu()
	_update_selection()
	menu_opened.emit()


## Close the menu
## If going_to_subscreen is true, don't restore scanner (it will be restored when subscreen closes)
func close_menu(going_to_subscreen: bool = false) -> void:
	if not _is_open:
		return

	_is_open = false
	_hide_menu()
	GameState.close_menu("radial_menu")

	# Restore scanner if it was active before menu opened (unless going to subscreen)
	if _scanner_was_active and not going_to_subscreen:
		_scanner_was_active = false
		var scanner := get_node_or_null("/root/Scanner")
		if scanner:
			scanner.open_scanner()

	menu_closed.emit()


## Check if menu is open
func is_menu_open() -> bool:
	return _is_open


func _show_menu() -> void:
	_overlay.show()
	_menu_container.show()
	for button in _buttons:
		button.show()
	_tooltip.show()
	_update_menu_position()


func _hide_menu() -> void:
	_overlay.hide()
	_menu_container.hide()
	for button in _buttons:
		button.hide()
	_tooltip.hide()
	_save_feedback.hide()


func _navigate(direction: String) -> void:
	var nav: Dictionary = NAV_MAP.get(_selected_index, {})
	var next_index: int = nav.get(direction, _selected_index)

	# Skip disabled options
	var attempts := 0
	while MENU_OPTIONS[next_index].disabled and attempts < 6:
		nav = NAV_MAP.get(next_index, {})
		next_index = nav.get(direction, next_index)
		attempts += 1

	if not MENU_OPTIONS[next_index].disabled:
		_selected_index = next_index
		_update_selection()


func _update_selection() -> void:
	for i in _buttons.size():
		_buttons[i].set_selected(i == _selected_index)

	# Update tooltip
	var option: Dictionary = MENU_OPTIONS[_selected_index]
	_tooltip.text = _get_tooltip_text(option.id)


func _get_tooltip_text(option_id: String) -> String:
	match option_id:
		"party":
			return "View Party"
		"bag":
			return "Items (Coming Soon)"
		"dex":
			return "View Deck"
		"save":
			return "Save Game"
		"options":
			return "Settings"
		"exit":
			return "Save & Quit"
		_:
			return ""


func _confirm_selection() -> void:
	var option: Dictionary = MENU_OPTIONS[_selected_index]
	if option.disabled:
		return

	option_selected.emit(option.id)
	_handle_option(option.id)


func _on_button_pressed(option_id: String) -> void:
	# Find index of this option
	for i in MENU_OPTIONS.size():
		if MENU_OPTIONS[i].id == option_id:
			if not MENU_OPTIONS[i].disabled:
				_selected_index = i
				_update_selection()
				_confirm_selection()
			break


func _on_button_hovered(option_id: String) -> void:
	# Update selection to hovered button
	for i in MENU_OPTIONS.size():
		if MENU_OPTIONS[i].id == option_id:
			if not MENU_OPTIONS[i].disabled:
				_selected_index = i
				_update_selection()
			break


func _handle_option(option_id: String) -> void:
	match option_id:
		"party":
			_open_party_screen()
		"dex":
			_open_deck_screen()
		"save":
			_save_game()
		"options":
			_open_options_screen()
		"exit":
			_save_and_quit()


func _open_party_screen() -> void:
	close_menu(true)  # Going to subscreen, don't restore scanner yet
	var party_scene: PackedScene = preload("res://scenes/ui/party_screen.tscn")
	var party_screen := party_scene.instantiate()
	party_screen.closed.connect(_on_subscreen_closed)
	get_tree().root.add_child(party_screen)


func _open_deck_screen() -> void:
	close_menu(true)  # Going to subscreen, don't restore scanner yet
	var deck_scene: PackedScene = preload("res://scenes/ui/deck/deck_screen.tscn")
	var deck_screen := deck_scene.instantiate()
	deck_screen.closed.connect(_on_subscreen_closed)
	get_tree().root.add_child(deck_screen)


func _on_subscreen_closed() -> void:
	# Restore scanner if it was active before, otherwise re-open radial menu
	if _scanner_was_active:
		_scanner_was_active = false
		var scanner := get_node_or_null("/root/Scanner")
		if scanner:
			scanner.open_scanner()
	else:
		call_deferred("open_menu")


func _save_game() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("save_game"):
		var success: bool = game_state.save_game()
		if success:
			_show_save_feedback()


func _show_save_feedback() -> void:
	_save_feedback.show()
	_save_feedback.modulate.a = 1.0

	# Fade out after a moment
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_save_feedback, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_save_feedback.hide)


func _open_options_screen() -> void:
	close_menu(true)  # Going to subscreen, don't restore scanner yet
	var settings_scene: PackedScene = preload("res://scenes/ui/settings/settings_screen.tscn")
	var settings_screen := settings_scene.instantiate()
	settings_screen.closed.connect(_on_subscreen_closed)
	get_tree().root.add_child(settings_screen)


func _save_and_quit() -> void:
	var game_state := get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("save_game"):
		game_state.save_game()
	get_tree().quit()
