extends CanvasLayer
## Level-up card selection UI. Shows 3 upgrade choices with controller/keyboard navigation.
## Process mode ALWAYS — works while tree is paused.

signal upgrade_chosen(id: String)

const UpgradeData := preload("res://scenes/prototypes/shmup/systems/upgrade_data.gd")
const CardsDrawScript := preload("res://scenes/prototypes/shmup/ui/level_up_cards_draw.gd")

# Card layout
const CARD_W := 130.0
const CARD_H := 170.0
const CARD_GAP := 20.0
const CARD_Y := 85.0  # Top of cards (centered vertically in 360px viewport)
const VIEWPORT_W := 640.0
const VIEWPORT_H := 360.0

# Colors
const BG_COLOR := Color(0.0, 0.0, 0.05, 0.6)
const CARD_BG := Color(0.05, 0.05, 0.1, 0.85)
const CARD_BG_SELECTED := Color(0.08, 0.08, 0.15, 0.92)
const BORDER_DIM := Color(0.4, 0.4, 0.5, 0.3)
const STAR_FILLED := Color(1.0, 0.9, 0.3, 0.9)
const STAR_EMPTY := Color(0.3, 0.3, 0.4, 0.5)
const EVO_GOLD := Color(1.0, 0.85, 0.2, 1.0)

# State
var is_showing := false
var choices: Array = []
var selected_index := 1  # Start on middle card
var _nav_cooldown := 0.0
var _slide_progress := 0.0  # 0→1 for entry animation
var _is_animating := false

# Nodes
var _bg: ColorRect
var _title_label: Label
var _summary_label: Label
var _card_container: Control  # Parent for card drawing
var _cards_node: Node2D  # Draws all cards via _draw()

# Reference to upgrade manager (for summary text)
var upgrade_manager: Node


func _ready() -> void:
	layer = 3  # Above game UI
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Dim background overlay
	_bg = ColorRect.new()
	_bg.name = "DimOverlay"
	_bg.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	_bg.color = BG_COLOR
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# "LEVEL UP!" title
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.position = Vector2(0, 30)
	_title_label.size = Vector2(VIEWPORT_W, 30)
	_title_label.text = "LEVEL UP!"
	_title_label.add_theme_font_size_override("font_size", 18)
	_title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
	add_child(_title_label)

	# Current upgrades summary (bottom)
	_summary_label = Label.new()
	_summary_label.name = "SummaryLabel"
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_label.position = Vector2(0, 275)
	_summary_label.size = Vector2(VIEWPORT_W, 40)
	_summary_label.text = ""
	_summary_label.add_theme_font_size_override("font_size", 8)
	_summary_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.7))
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary_label)

	# Card drawing node
	_cards_node = Node2D.new()
	_cards_node.name = "CardsNode"
	add_child(_cards_node)
	_cards_node.set_script(CardsDrawScript)
	_cards_node.ui = self

	_hide_immediate()


func _process(delta: float) -> void:
	if not is_showing:
		return

	# Use unscaled delta so hit-stop doesn't slow the UI
	var real_delta := delta / maxf(Engine.time_scale, 0.001)

	# Entry animation
	if _is_animating:
		_slide_progress = minf(_slide_progress + real_delta * 6.0, 1.0)  # ~0.17s
		_cards_node.queue_redraw()
		if _slide_progress >= 1.0:
			_is_animating = false
		return  # Don't accept input during animation

	# Navigation cooldown
	_nav_cooldown = maxf(_nav_cooldown - real_delta, 0.0)

	if _nav_cooldown <= 0.0:
		var nav := 0
		if Input.is_action_just_pressed("shmup_aim_left") or Input.is_action_just_pressed("shmup_move_left"):
			nav = -1
		elif Input.is_action_just_pressed("shmup_aim_right") or Input.is_action_just_pressed("shmup_move_right"):
			nav = 1

		if nav != 0:
			selected_index = clampi(selected_index + nav, 0, choices.size() - 1)
			_nav_cooldown = 0.2
			_cards_node.queue_redraw()

	# Confirm selection
	if Input.is_action_just_pressed("shmup_shoot") or Input.is_action_just_pressed("shmup_restart"):
		_confirm_selection()


func show_choices(new_choices: Array) -> void:
	if new_choices.is_empty():
		return

	choices = new_choices
	selected_index = clampi(1, 0, choices.size() - 1)  # Middle card
	is_showing = true
	_slide_progress = 0.0
	_is_animating = true
	_nav_cooldown = 0.3  # Brief delay before accepting input

	_bg.visible = true
	_title_label.visible = true
	_summary_label.visible = true
	_cards_node.visible = true

	# Update summary
	if upgrade_manager:
		_summary_label.text = "YOUR UPGRADES: %s" % upgrade_manager.get_upgrade_summary()

	_cards_node.queue_redraw()


func _confirm_selection() -> void:
	if choices.is_empty() or selected_index >= choices.size():
		return

	var chosen: Dictionary = choices[selected_index]
	is_showing = false
	_hide_immediate()
	upgrade_chosen.emit(chosen["id"])


func _hide_immediate() -> void:
	is_showing = false
	_is_animating = false
	_slide_progress = 0.0
	choices = []
	if _bg:
		_bg.visible = false
	if _title_label:
		_title_label.visible = false
	if _summary_label:
		_summary_label.visible = false
	if _cards_node:
		_cards_node.visible = false


## Returns card X position for a given index (0, 1, 2).
func get_card_x(index: int) -> float:
	var total_w := choices.size() * CARD_W + (choices.size() - 1) * CARD_GAP
	var start_x := (VIEWPORT_W - total_w) / 2.0
	return start_x + index * (CARD_W + CARD_GAP)


## Returns card Y with slide animation offset.
func get_card_y(index: int) -> float:
	var base_y := CARD_Y
	if _is_animating:
		# Slide up from below, staggered per card
		var stagger := index * 0.15
		var t := clampf((_slide_progress - stagger) / (1.0 - stagger * 0.5), 0.0, 1.0)
		# Ease out cubic
		t = 1.0 - pow(1.0 - t, 3.0)
		base_y = lerpf(VIEWPORT_H + 20.0, CARD_Y, t)
	return base_y
