extends Control
## Ant Colony settings test. Direct copy of creature RPG settings screen
## layout. Only change: Kenney tile_0030 panel instead of Craftpix panel.

const PANEL_WIDTH := 380
const PANEL_HEIGHT := 310
const TAB_NAMES := [
	"AUDIO", "DISP", "GAME",
	"PERF", "ACCESS", "CTRL",
]

var _tab_buttons: Array[Button] = []
var _tab_contents: Array[Control] = []
var _current_tab: int = 0
var _sliders: Dictionary = {}
var _checkboxes: Dictionary = {}
var _option_selectors: Dictionary = {}


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_create_ui()
	_switch_tab(0)


func _create_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel_container := Control.new()
	panel_container.custom_minimum_size = Vector2(
		PANEL_WIDTH, PANEL_HEIGHT
	)
	panel_container.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	center.add_child(panel_container)

	var panel := NinePatchRect.new()
	panel.texture = load(AntColonyUI.PANEL_ROUNDED)
	panel.patch_margin_left = 14
	panel.patch_margin_top = 14
	panel.patch_margin_right = 14
	panel.patch_margin_bottom = 14
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel_container.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	# Banner title
	var banner := _create_banner(
		"SETTINGS", PANEL_WIDTH,
	)
	panel_container.add_child(banner)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 2)
	vbox.add_child(tab_bar)

	for i in TAB_NAMES.size():
		var tab_btn := Button.new()
		tab_btn.text = TAB_NAMES[i]
		tab_btn.custom_minimum_size = Vector2(50, 20)
		tab_btn.add_theme_font_size_override("font_size", 16)
		tab_btn.add_theme_color_override(
			"font_color", Color.BLACK
		)
		tab_btn.pressed.connect(_on_tab_pressed.bind(i))
		tab_bar.add_child(tab_btn)
		_tab_buttons.append(tab_btn)

	vbox.add_child(HSeparator.new())

	# Tab content container
	var content := Control.new()
	content.custom_minimum_size = Vector2(0, 160)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)

	_create_audio_tab(content)
	_create_display_tab(content)
	_create_gameplay_tab(content)
	_create_performance_tab(content)
	_create_accessibility_tab(content)
	_create_controls_tab(content)

	# Bottom buttons
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 8)
	vbox.add_child(btn_row)

	var defaults_btn := _create_styled_button("DEFAULTS")
	defaults_btn.custom_minimum_size = Vector2(56, 24)
	btn_row.add_child(defaults_btn)
	btn_row.add_child(_create_styled_button("SAVE"))
	btn_row.add_child(_create_styled_button("CANCEL"))

	$BackButton.move_to_front()


func _create_styled_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(64, 24)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color.BLACK)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _create_tab_content_base() -> VBoxContainer:
	var c := VBoxContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_theme_constant_override("separation", 8)
	c.visible = false
	return c


# =================================================================
# AUDIO TAB
# =================================================================

func _create_audio_tab(parent: Control) -> void:
	var tab := _create_tab_content_base()
	parent.add_child(tab)
	_tab_contents.append(tab)
	_create_slider_row(tab, "MASTER", "master", 1.0)
	_create_slider_row(tab, "MUSIC", "music", 0.8)
	_create_slider_row(tab, "SFX", "sfx", 1.0)
	_create_slider_row(tab, "AMBIENT", "ambient", 1.0)


func _create_slider_row(
	parent: Control, label_text: String,
	setting_name: String, initial_value: float,
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(60, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value
	slider.custom_minimum_size = Vector2(120, 16)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(
		_on_slider_changed.bind(setting_name)
	)
	row.add_child(slider)
	_sliders[setting_name] = slider

	var value_label := Label.new()
	value_label.name = "ValueLabel"
	value_label.text = "%d%%" % int(initial_value * 100)
	value_label.custom_minimum_size = Vector2(36, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(value_label)


# =================================================================
# DISPLAY TAB
# =================================================================

func _create_display_tab(parent: Control) -> void:
	var tab := _create_tab_content_base()
	parent.add_child(tab)
	_tab_contents.append(tab)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	scroll.custom_minimum_size = Vector2(0, 140)
	scroll.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)
	tab.add_child(scroll)

	var sc := VBoxContainer.new()
	sc.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	sc.add_theme_constant_override("separation", 8)
	scroll.add_child(sc)

	var win_opts := [
		"WINDOWED", "BORDERLESS", "FULLSCREEN",
	]
	_create_option_row(
		sc, "WINDOW", "window_mode", win_opts, 1,
	)
	var res_opts := [
		"1280x720", "1920x1080", "2560x1440",
	]
	_create_option_row(
		sc, "RESOLUTION", "resolution",
		res_opts, 1,
	)
	var fps_opts := [
		"30", "60", "120", "144", "UNLIM",
	]
	_create_option_row(
		sc, "MAX FPS", "max_fps", fps_opts, 1,
	)
	var scale_opts := ["1x", "2x", "3x", "4x"]
	_create_option_row(
		sc, "UI SCALE", "ui_scale", scale_opts, 1,
	)
	_create_slider_row(
		sc, "SHAKE", "screen_shake", 0.8,
	)
	_create_slider_row(
		sc, "PHEROMONE", "pheromone_vis", 0.7,
	)
	var phero_q := ["SIMPLE", "NORMAL", "DETAILED"]
	_create_option_row(
		sc, "TRAIL QUAL", "trail_quality",
		phero_q, 1,
	)
	var ant_det := ["DOTS", "NORMAL", "FULL"]
	_create_option_row(
		sc, "ANT DETAIL", "ant_detail",
		ant_det, 1,
	)
	_create_checkbox_row(
		sc, "ANT NAMES", "show_ant_names", true,
	)


func _create_option_row(
	parent: Control, label_text: String,
	setting_name: String, options: Array,
	initial_index: int,
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var left_btn := Button.new()
	left_btn.text = "<"
	left_btn.custom_minimum_size = Vector2(20, 20)
	left_btn.add_theme_font_size_override("font_size", 16)
	left_btn.pressed.connect(
		_on_option_left.bind(setting_name)
	)
	row.add_child(left_btn)

	var value_label := Label.new()
	if initial_index < options.size():
		value_label.text = options[initial_index]
	else:
		value_label.text = options[0]
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(value_label)

	var right_btn := Button.new()
	right_btn.text = ">"
	right_btn.custom_minimum_size = Vector2(20, 20)
	right_btn.add_theme_font_size_override("font_size", 16)
	right_btn.pressed.connect(
		_on_option_right.bind(setting_name)
	)
	row.add_child(right_btn)

	_option_selectors[setting_name] = {
		"label": value_label,
		"index": initial_index,
		"options": options,
	}


func _create_checkbox_row(
	parent: Control, label_text: String,
	setting_name: String, initial_value: bool,
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var checkbox := CheckBox.new()
	checkbox.button_pressed = initial_value
	checkbox.add_theme_font_size_override("font_size", 16)
	row.add_child(checkbox)
	_checkboxes[setting_name] = checkbox


# =================================================================
# GAMEPLAY TAB
# =================================================================

func _create_gameplay_tab(parent: Control) -> void:
	var tab := _create_tab_content_base()
	parent.add_child(tab)
	_tab_contents.append(tab)
	var speed_opts := ["0.25x", "0.5x", "1x"]
	_create_option_row(
		tab, "SPEED", "game_speed", speed_opts, 2,
	)
	_create_slider_row(
		tab, "ZOOM SPD", "zoom_speed", 0.5,
	)
	_create_checkbox_row(
		tab, "EDGE SCROLL", "edge_scrolling", false,
	)
	_create_checkbox_row(
		tab, "AUTO-SAVE", "auto_save", true,
	)
	var interval := ["1m", "5m", "10m"]
	_create_option_row(
		tab, "SAVE FREQ", "save_interval",
		interval, 1,
	)
	var fmt := ["STANDARD", "SHORT", "SCIENTIFIC"]
	_create_option_row(
		tab, "NUMBERS", "num_format", fmt, 0,
	)
	var sizes := [
		"SMALL", "MEDIUM", "LARGE", "UNLIMITED",
	]
	_create_option_row(
		tab, "COLONY SIZE", "colony_size", sizes, 3,
	)


# =================================================================
# PERFORMANCE TAB
# =================================================================


func _create_performance_tab(
	parent: Control,
) -> void:
	var tab := _create_tab_content_base()
	parent.add_child(tab)
	_tab_contents.append(tab)
	var quality := ["LOW", "MEDIUM", "HIGH"]
	_create_option_row(
		tab, "QUALITY", "quality_preset",
		quality, 1,
	)
	_create_slider_row(
		tab, "MAX ANTS", "max_ants", 0.5,
	)
	_create_checkbox_row(
		tab, "SHOW FPS", "show_fps", false,
	)
	_create_checkbox_row(
		tab, "FPS WARN", "fps_warning", true,
	)


# =================================================================
# ACCESSIBILITY TAB
# =================================================================

func _create_accessibility_tab(parent: Control) -> void:
	var tab := _create_tab_content_base()
	parent.add_child(tab)
	_tab_contents.append(tab)
	var cb_opts := [
		"OFF", "DEUTAN", "PROTAN", "TRITAN",
	]
	_create_option_row(
		tab, "COLORBLIND", "colorblind", cb_opts, 0,
	)
	_create_checkbox_row(
		tab, "HI CONTRAST", "high_contrast", false,
	)
	var font_opts := ["SMALL", "NORMAL", "LARGE"]
	_create_option_row(
		tab, "FONT SIZE", "font_size",
		font_opts, 1,
	)
	_create_checkbox_row(
		tab, "LRG CURSOR", "large_cursor", false,
	)


# =================================================================
# CONTROLS TAB
# =================================================================

func _create_controls_tab(parent: Control) -> void:
	var tab := _create_tab_content_base()
	parent.add_child(tab)
	_tab_contents.append(tab)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED
	)
	scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_AUTO
	)
	scroll.custom_minimum_size = Vector2(0, 120)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab.add_child(scroll)

	var scroll_content := VBoxContainer.new()
	scroll_content.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	scroll_content.add_theme_constant_override("separation", 4)
	scroll.add_child(scroll_content)

	var bindings := [
		["MOVE", "WASD"],
		["DIG", "LCLICK"],
		["PLACE", "RCLICK"],
		["ZOOM", "SCROLL"],
		["EVOLVE", "TAB/E"],
		["BUILD", "B"],
		["PAUSE", "ESC"],
	]
	for pair in bindings:
		_create_key_row(scroll_content, pair[0], pair[1])


func _create_key_row(
	parent: Control, action: String, key: String,
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var label := Label.new()
	label.text = action
	label.custom_minimum_size = Vector2(80, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(label)

	var key_btn := Button.new()
	key_btn.text = key
	key_btn.custom_minimum_size = Vector2(80, 20)
	key_btn.add_theme_font_size_override("font_size", 16)
	key_btn.add_theme_color_override("font_color", Color.BLACK)
	row.add_child(key_btn)


# =================================================================
# TAB SWITCHING
# =================================================================

func _switch_tab(tab_index: int) -> void:
	_current_tab = tab_index
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i]
		if i == int(tab_index):
			btn.add_theme_color_override(
				"font_color", Color(0.2, 0.5, 0.2)
			)
		else:
			btn.add_theme_color_override(
				"font_color", Color.BLACK
			)
	for i in _tab_contents.size():
		_tab_contents[i].visible = (i == tab_index)


func _on_tab_pressed(tab_index: int) -> void:
	_switch_tab(tab_index)


# =================================================================
# VALUE HANDLERS
# =================================================================

func _on_slider_changed(
	value: float, setting_name: String,
) -> void:
	var slider: HSlider = _sliders[setting_name]
	var row := slider.get_parent()
	var value_label: Label = row.get_node("ValueLabel")
	value_label.text = "%d%%" % int(value * 100)


func _on_option_left(setting_name: String) -> void:
	var selector: Dictionary = _option_selectors[setting_name]
	selector.index = maxi(0, selector.index - 1)
	selector.label.text = selector.options[selector.index]


func _on_option_right(setting_name: String) -> void:
	var selector: Dictionary = _option_selectors[setting_name]
	selector.index = mini(
		selector.options.size() - 1, selector.index + 1
	)
	selector.label.text = selector.options[selector.index]


func _create_banner(
	title_text: String, panel_w: float,
) -> Control:
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bx: float = (panel_w - 157.0) / 2.0
	var bl := TextureRect.new()
	bl.texture = load(AntColonyUI.BANNER_LEFT)
	bl.stretch_mode = TextureRect.STRETCH_SCALE
	bl.position = Vector2(bx, -1.0)
	bl.size = Vector2(32, 32)
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bl)
	var mid := TextureRect.new()
	mid.texture = load(AntColonyUI.BANNER_MID)
	mid.stretch_mode = TextureRect.STRETCH_TILE
	mid.position = Vector2(bx + 30.0, -1.0)
	mid.size = Vector2(97, 32)
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(mid)
	var br := TextureRect.new()
	br.texture = load(AntColonyUI.BANNER_RIGHT)
	br.stretch_mode = TextureRect.STRETCH_SCALE
	br.position = Vector2(bx + 125.44, -1.07)
	br.size = Vector2(32, 32)
	br.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(br)
	var lbl := Label.new()
	lbl.text = title_text
	lbl.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	lbl.vertical_alignment = (
		VERTICAL_ALIGNMENT_CENTER
	)
	lbl.position = Vector2(bx, 1.0)
	lbl.size = Vector2(157.0, 32.0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override(
		"font_color", Color.BLACK,
	)
	lbl.add_theme_color_override(
		"font_outline_color", Color.WHITE,
	)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(lbl)
	return holder


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
