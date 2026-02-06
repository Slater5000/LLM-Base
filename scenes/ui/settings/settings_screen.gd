extends CanvasLayer
class_name SettingsScreen
## Settings screen with tabs for Audio, Display, Gameplay, Accessibility, and Controls.
## Uses Craftpix UI assets for styling.

signal closed

## Tab definitions
enum Tab { AUDIO, DISPLAY, GAMEPLAY, ACCESS, CONTROLS }

var _background: ColorRect
var _panel: NinePatchRect
var _tab_buttons: Array[Button] = []
var _tab_contents: Array[Control] = []
var _current_tab: Tab = Tab.AUDIO

## Temporary settings (for cancel/revert)
var _original_settings: Dictionary = {}

## UI references for value updates
var _sliders: Dictionary = {}  # name -> HSlider
var _checkboxes: Dictionary = {}  # name -> CheckBox
var _option_selectors: Dictionary = {}  # name -> {label, index, options}
var _rebind_rows: Dictionary = {}  # action -> {label, button, conflict_label}
var _listening_for_key: String = ""  # action name when rebinding
var _controls_scroll_content: VBoxContainer  # Reference for adding reset button

const PANEL_WIDTH := 320
const PANEL_HEIGHT := 280
const TAB_NAMES := ["AUDIO", "DISP", "GAME", "ACCESS", "CTRL"]


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED  # Menu works when game is paused

	# Register with GameState menu system (allow stacking from radial menu)
	GameState.open_menu("settings_screen", true)

	_store_original_settings()
	_create_ui()
	_switch_tab(Tab.AUDIO)


func _store_original_settings() -> void:
	var gs := GameState
	_original_settings = {
		"master_volume": gs.master_volume,
		"music_volume": gs.music_volume,
		"sfx_volume": gs.sfx_volume,
		"dialog_volume": gs.dialog_volume,
		"fullscreen": gs.fullscreen,
		"window_scale": gs.window_scale,
		"screen_shake_enabled": gs.screen_shake_enabled,
		"show_damage_numbers": gs.show_damage_numbers,
		"colorblind_mode": gs.colorblind_mode,
		"key_bindings": gs.key_bindings.duplicate()
	}


func _create_ui() -> void:
	# Darkening background overlay
	_background = ColorRect.new()
	_background.color = Color(0, 0, 0, 0.5)
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_background)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Main panel container
	var panel_container := Control.new()
	panel_container.custom_minimum_size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	panel_container.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	center.add_child(panel_container)

	# Panel background (9-slice)
	_panel = NinePatchRect.new()
	_panel.texture = preload("res://assets/sprites/ui/panels/panel_frame_48x40.png")
	_panel.patch_margin_left = 8
	_panel.patch_margin_top = 8
	_panel.patch_margin_right = 8
	_panel.patch_margin_bottom = 8
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.add_child(_panel)

	# Content margin
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.BLACK)
	vbox.add_child(title)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 2)
	vbox.add_child(tab_bar)

	for i in TAB_NAMES.size():
		var tab_btn := Button.new()
		tab_btn.text = TAB_NAMES[i]
		tab_btn.custom_minimum_size = Vector2(52, 20)
		tab_btn.add_theme_font_size_override("font_size", 8)
		tab_btn.add_theme_color_override("font_color", Color.BLACK)
		tab_btn.pressed.connect(_on_tab_pressed.bind(i))
		tab_bar.add_child(tab_btn)
		_tab_buttons.append(tab_btn)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Tab content container
	var content_container := Control.new()
	content_container.custom_minimum_size = Vector2(0, 160)
	content_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_container)

	# Create each tab's content
	_create_audio_tab(content_container)
	_create_display_tab(content_container)
	_create_gameplay_tab(content_container)
	_create_accessibility_tab(content_container)
	_create_controls_tab(content_container)

	# Bottom button row
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var reset_all_btn := _create_styled_button("DEFAULTS")
	reset_all_btn.custom_minimum_size = Vector2(56, 24)
	reset_all_btn.pressed.connect(_on_reset_all_pressed)
	btn_row.add_child(reset_all_btn)

	var save_btn := _create_styled_button("SAVE")
	save_btn.pressed.connect(_on_save_pressed)
	btn_row.add_child(save_btn)

	var cancel_btn := _create_styled_button("CANCEL")
	cancel_btn.pressed.connect(_on_cancel_pressed)
	btn_row.add_child(cancel_btn)


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 24)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _create_tab_content_base() -> VBoxContainer:
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 8)
	content.visible = false
	return content


# =============================================================================
# AUDIO TAB
# =============================================================================

func _create_audio_tab(parent: Control) -> void:
	var content := _create_tab_content_base()
	parent.add_child(content)
	_tab_contents.append(content)

	_create_slider_row(content, "Master", "master_volume", GameState.master_volume)
	_create_slider_row(content, "Music", "music_volume", GameState.music_volume)
	_create_slider_row(content, "SFX", "sfx_volume", GameState.sfx_volume)
	_create_slider_row(content, "Dialog", "dialog_volume", GameState.dialog_volume)


func _create_slider_row(parent: Control, label_text: String, setting_name: String, initial_value: float) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60, 0)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(120, 16)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_slider_changed.bind(setting_name))
	row.add_child(slider)
	_sliders[setting_name] = slider

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "%d%%" % int(initial_value * 100)
	value_label.custom_minimum_size = Vector2(36, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(value_label)


# =============================================================================
# DISPLAY TAB
# =============================================================================

func _create_display_tab(parent: Control) -> void:
	var content := _create_tab_content_base()
	parent.add_child(content)
	_tab_contents.append(content)

	# Window Scale option
	var scale_options := ["2x", "3x", "4x"]
	var scale_index := GameState.window_scale - 2  # Convert 2,3,4 to 0,1,2
	_create_option_row(content, "Window", "window_scale", scale_options, scale_index)

	# Fullscreen checkbox
	_create_checkbox_row(content, "Fullscreen", "fullscreen", GameState.fullscreen)


func _create_option_row(parent: Control, label_text: String, setting_name: String, options: Array, initial_index: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var left_btn := Button.new()
	left_btn.text = "<"
	left_btn.custom_minimum_size = Vector2(20, 20)
	left_btn.add_theme_font_size_override("font_size", 10)
	left_btn.pressed.connect(_on_option_left.bind(setting_name))
	row.add_child(left_btn)

	var value_label := Label.new()
	value_label.text = options[initial_index] if initial_index < options.size() else options[0]
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(value_label)

	var right_btn := Button.new()
	right_btn.text = ">"
	right_btn.custom_minimum_size = Vector2(20, 20)
	right_btn.add_theme_font_size_override("font_size", 10)
	right_btn.pressed.connect(_on_option_right.bind(setting_name))
	row.add_child(right_btn)

	_option_selectors[setting_name] = {
		"label": value_label,
		"index": initial_index,
		"options": options
	}


func _create_checkbox_row(parent: Control, label_text: String, setting_name: String, initial_value: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var checkbox := CheckBox.new()
	checkbox.button_pressed = initial_value
	checkbox.add_theme_font_size_override("font_size", 10)
	checkbox.toggled.connect(_on_checkbox_toggled.bind(setting_name))
	row.add_child(checkbox)
	_checkboxes[setting_name] = checkbox


# =============================================================================
# GAMEPLAY TAB
# =============================================================================

func _create_gameplay_tab(parent: Control) -> void:
	var content := _create_tab_content_base()
	parent.add_child(content)
	_tab_contents.append(content)

	_create_checkbox_row(content, "Screen Shake", "screen_shake_enabled", GameState.screen_shake_enabled)
	_create_checkbox_row(content, "Damage Nums", "show_damage_numbers", GameState.show_damage_numbers)


# =============================================================================
# ACCESSIBILITY TAB
# =============================================================================

func _create_accessibility_tab(parent: Control) -> void:
	var content := _create_tab_content_base()
	parent.add_child(content)
	_tab_contents.append(content)

	var cb_options := ["Off", "Friendly"]
	_create_option_row(content, "Colorblind", "colorblind_mode", cb_options, GameState.colorblind_mode)


# =============================================================================
# CONTROLS TAB
# =============================================================================

func _create_controls_tab(parent: Control) -> void:
	var content := _create_tab_content_base()
	parent.add_child(content)
	_tab_contents.append(content)

	# Scrollable container for key bindings
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_content.add_theme_constant_override("separation", 4)
	scroll.add_child(scroll_content)
	_controls_scroll_content = scroll_content

	var actions := [
		["move_up", "Up"],
		["move_down", "Down"],
		["move_left", "Left"],
		["move_right", "Right"],
		["interact", "Interact"],
		["open_menu", "Menu"],
		["pause_combat", "Pause"]
	]

	for action_data in actions:
		_create_rebind_row(scroll_content, action_data[0], action_data[1])

	# Reset keys button
	var reset_btn := _create_styled_button("RESET KEYS")
	reset_btn.pressed.connect(_on_reset_bindings)
	content.add_child(reset_btn)

	# Check initial conflict warnings
	call_deferred("_update_all_conflict_warnings")


func _create_rebind_row(parent: Control, action: String, display_name: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = display_name
	label.custom_minimum_size = Vector2(80, 0)  # Wider to fit "Interact"
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var key_btn := Button.new()
	key_btn.text = _get_input_name(GameState.get_binding_for_action(action))
	key_btn.custom_minimum_size = Vector2(80, 20)
	key_btn.add_theme_font_size_override("font_size", 9)
	key_btn.add_theme_color_override("font_color", Color.BLACK)
	key_btn.pressed.connect(_on_rebind_pressed.bind(action))
	row.add_child(key_btn)

	# Conflict warning label (hidden by default)
	var conflict_label := Label.new()
	conflict_label.text = "CONFLICT"
	conflict_label.add_theme_font_size_override("font_size", 8)
	conflict_label.add_theme_color_override("font_color", Color.RED)
	conflict_label.add_theme_color_override("font_outline_color", Color.BLACK)
	conflict_label.add_theme_constant_override("outline_size", 3)
	conflict_label.visible = false
	row.add_child(conflict_label)

	_rebind_rows[action] = {"label": label, "button": key_btn, "conflict_label": conflict_label}


## Convert a binding dictionary to a display name
func _get_input_name(binding: Dictionary) -> String:
	var input_type: String = binding.get("type", "")
	if input_type == "key":
		var keycode: int = binding.get("keycode", 0)
		if keycode == 0:
			return "None"
		return OS.get_keycode_string(keycode)
	elif input_type == "mouse":
		var button: int = binding.get("button", 0)
		match button:
			MOUSE_BUTTON_LEFT: return "Mouse L"
			MOUSE_BUTTON_RIGHT: return "Mouse R"
			MOUSE_BUTTON_MIDDLE: return "Mouse M"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Dn"
			MOUSE_BUTTON_XBUTTON1: return "Mouse 4"
			MOUSE_BUTTON_XBUTTON2: return "Mouse 5"
			_: return "Mouse %d" % button
	return "None"


## Legacy helper for backwards compat
func _get_key_name(keycode: int) -> String:
	return _get_input_name({"type": "key", "keycode": keycode})


# =============================================================================
# TAB SWITCHING
# =============================================================================

func _switch_tab(tab: Tab) -> void:
	_current_tab = tab

	# Update tab button styles
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i]
		if i == int(tab):
			btn.add_theme_color_override("font_color", Color(0.2, 0.5, 0.2))
		else:
			btn.add_theme_color_override("font_color", Color.BLACK)

	# Show/hide tab contents
	for i in _tab_contents.size():
		_tab_contents[i].visible = (i == int(tab))


func _on_tab_pressed(tab_index: int) -> void:
	_switch_tab(tab_index as Tab)


# =============================================================================
# VALUE CHANGE HANDLERS
# =============================================================================

func _on_slider_changed(value: float, setting_name: String) -> void:
	# Update percentage label
	var slider: HSlider = _sliders[setting_name]
	var row := slider.get_parent()
	var value_label: Label = row.get_node("ValueLabel")
	value_label.text = "%d%%" % int(value * 100)

	# Apply immediately for preview
	match setting_name:
		"master_volume": GameState.set_master_volume(value)
		"music_volume": GameState.set_music_volume(value)
		"sfx_volume": GameState.set_sfx_volume(value)
		"dialog_volume": GameState.set_dialog_volume(value)


func _on_checkbox_toggled(pressed: bool, setting_name: String) -> void:
	match setting_name:
		"fullscreen": GameState.set_fullscreen(pressed)
		"screen_shake_enabled": GameState.set_screen_shake_enabled(pressed)
		"show_damage_numbers": GameState.set_show_damage_numbers(pressed)


func _on_option_left(setting_name: String) -> void:
	var selector: Dictionary = _option_selectors[setting_name]
	selector.index = maxi(0, selector.index - 1)
	_update_option_selector(setting_name)


func _on_option_right(setting_name: String) -> void:
	var selector: Dictionary = _option_selectors[setting_name]
	selector.index = mini(selector.options.size() - 1, selector.index + 1)
	_update_option_selector(setting_name)


func _update_option_selector(setting_name: String) -> void:
	var selector: Dictionary = _option_selectors[setting_name]
	selector.label.text = selector.options[selector.index]

	match setting_name:
		"window_scale":
			GameState.set_window_scale(selector.index + 2)  # Convert 0,1,2 to 2,3,4
		"colorblind_mode":
			GameState.set_colorblind_mode(selector.index)


# =============================================================================
# KEY REBINDING
# =============================================================================

func _on_rebind_pressed(action: String) -> void:
	_listening_for_key = action
	var btn: Button = _rebind_rows[action].button
	btn.text = "Press key..."


func _input(event: InputEvent) -> void:
	# Handle key/mouse rebinding
	if _listening_for_key != "":
		if event is InputEventKey and event.pressed:
			var key_event := event as InputEventKey
			_apply_rebind(_listening_for_key, {"type": "key", "keycode": key_event.physical_keycode})
			_listening_for_key = ""
			get_viewport().set_input_as_handled()
			return
		elif event is InputEventMouseButton and event.pressed:
			var mouse_event := event as InputEventMouseButton
			# Only allow side buttons (4 and 5), not left/right/middle/wheel
			if mouse_event.button_index in [MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
				_apply_rebind(_listening_for_key, {"type": "mouse", "button": mouse_event.button_index})
				_listening_for_key = ""
				get_viewport().set_input_as_handled()
				return

	# Handle ESC to close (but not while rebinding)
	if _listening_for_key == "" and event.is_action_pressed("menu_cancel"):
		get_viewport().set_input_as_handled()
		_on_cancel_pressed()


## Apply a rebind with a binding dictionary (supports both key and mouse)
func _apply_rebind(action: String, binding: Dictionary) -> void:
	# Create the appropriate input event
	var new_event: InputEvent
	if binding.get("type") == "key":
		var key_event := InputEventKey.new()
		key_event.physical_keycode = binding.get("keycode", 0)
		new_event = key_event
	elif binding.get("type") == "mouse":
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = binding.get("button", 0)
		new_event = mouse_event
	else:
		return  # Invalid binding

	GameState.set_key_binding(action, new_event)

	# Update button text
	var btn: Button = _rebind_rows[action].button
	btn.text = _get_input_name(binding)

	# Update conflict warnings for all actions
	_update_all_conflict_warnings()


## Check for conflicts and show/hide warning labels
func _update_all_conflict_warnings() -> void:
	var rebindable := ["move_up", "move_down", "move_left", "move_right",
		"interact", "open_menu", "pause_combat"]

	# Build a map of binding -> list of actions using it
	var binding_to_actions: Dictionary = {}
	for action in rebindable:
		var binding := GameState.get_binding_for_action(action)
		var binding_key := _binding_to_string(binding)
		if binding_key not in binding_to_actions:
			binding_to_actions[binding_key] = []
		binding_to_actions[binding_key].append(action)

	# Show/hide conflict labels
	for action in rebindable:
		if action not in _rebind_rows:
			continue
		var binding := GameState.get_binding_for_action(action)
		var binding_key := _binding_to_string(binding)
		var actions_with_binding: Array = binding_to_actions.get(binding_key, [])
		var has_conflict := actions_with_binding.size() > 1
		var conflict_label: Label = _rebind_rows[action].conflict_label
		conflict_label.visible = has_conflict


## Convert a binding to a unique string for comparison
func _binding_to_string(binding: Dictionary) -> String:
	var bind_type: String = binding.get("type", "")
	if bind_type == "key":
		return "key:%d" % binding.get("keycode", 0)
	elif bind_type == "mouse":
		return "mouse:%d" % binding.get("button", 0)
	return "none"


func _on_reset_bindings() -> void:
	GameState.reset_key_bindings()
	# Update all button texts
	for action in _rebind_rows:
		var btn: Button = _rebind_rows[action].button
		var default_binding := {"type": "key", "keycode": GameState.get_default_key_for_action(action)}
		btn.text = _get_input_name(default_binding)
	_update_all_conflict_warnings()


func _on_reset_all_pressed() -> void:
	GameState.reset_all_settings()
	_refresh_all_ui()


## Refresh all UI elements to match current GameState values
func _refresh_all_ui() -> void:
	# Audio sliders
	if "master_volume" in _sliders:
		_sliders["master_volume"].value = GameState.master_volume
	if "music_volume" in _sliders:
		_sliders["music_volume"].value = GameState.music_volume
	if "sfx_volume" in _sliders:
		_sliders["sfx_volume"].value = GameState.sfx_volume
	if "dialog_volume" in _sliders:
		_sliders["dialog_volume"].value = GameState.dialog_volume

	# Checkboxes
	if "fullscreen" in _checkboxes:
		_checkboxes["fullscreen"].button_pressed = GameState.fullscreen
	if "screen_shake_enabled" in _checkboxes:
		_checkboxes["screen_shake_enabled"].button_pressed = GameState.screen_shake_enabled
	if "show_damage_numbers" in _checkboxes:
		_checkboxes["show_damage_numbers"].button_pressed = GameState.show_damage_numbers

	# Option selectors
	if "window_scale" in _option_selectors:
		var selector: Dictionary = _option_selectors["window_scale"]
		selector.index = GameState.window_scale - 2
		selector.label.text = selector.options[selector.index]
	if "colorblind_mode" in _option_selectors:
		var selector: Dictionary = _option_selectors["colorblind_mode"]
		selector.index = GameState.colorblind_mode
		selector.label.text = selector.options[selector.index]

	# Key bindings
	for action in _rebind_rows:
		var btn: Button = _rebind_rows[action].button
		var default_binding := {"type": "key", "keycode": GameState.get_default_key_for_action(action)}
		btn.text = _get_input_name(default_binding)
	_update_all_conflict_warnings()


# =============================================================================
# SAVE / CANCEL
# =============================================================================

func _on_save_pressed() -> void:
	GameState.save_game()
	GameState.close_menu("settings_screen")
	closed.emit()
	queue_free()


func _on_cancel_pressed() -> void:
	_restore_original_settings()
	GameState.close_menu("settings_screen")
	closed.emit()
	queue_free()


func _restore_original_settings() -> void:
	var gs := GameState
	gs.master_volume = _original_settings.master_volume
	gs.music_volume = _original_settings.music_volume
	gs.sfx_volume = _original_settings.sfx_volume
	gs.dialog_volume = _original_settings.dialog_volume
	gs.fullscreen = _original_settings.fullscreen
	gs.window_scale = _original_settings.window_scale
	gs.screen_shake_enabled = _original_settings.screen_shake_enabled
	gs.show_damage_numbers = _original_settings.show_damage_numbers
	gs.colorblind_mode = _original_settings.colorblind_mode
	gs.key_bindings = _original_settings.key_bindings
	gs._apply_settings()
	gs._apply_key_bindings()
