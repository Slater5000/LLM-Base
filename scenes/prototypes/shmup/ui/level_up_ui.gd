extends CanvasLayer
## Level-up card selection UI with reroll, banish, lock, and skip.
## Shows upgrade choices with keyboard navigation.
## Process mode ALWAYS — works while tree is paused.

signal upgrade_chosen(id: String)
signal upgrade_skipped

const CardsDrawScript := preload(
	"res://scenes/prototypes/shmup/ui/level_up_cards_draw.gd"
)

# Card layout
const CARD_W := 130.0
const CARD_H := 170.0
const CARD_GAP := 20.0
const CARD_Y := 48.0  # Shifted up to make room for action bar
const VIEWPORT_W := 640.0
const VIEWPORT_H := 360.0
const ACTION_BAR_Y := 250.0  # Below cards with gap

# Colors
const BG_COLOR := Color(0.0, 0.0, 0.05, 0.6)

# State
var is_showing := false
var choices: Array = []
var selected_index := 1  # Start on middle card
var hovered_action := -1  # 0-3 for action buttons, -1 none

# References (set by shmup_main)
var upgrade_manager: Node
var game_main: Node2D

# Nodes (private)
var _bg: ColorRect
var _title_label: Label
var _summary_label: Label
var _cards_node: Node2D  # Draws all cards via _draw()

# Private state
var _nav_cooldown := 0.0
var _action_cooldown := 0.0
var _slide_progress := 0.0  # 0->1 for entry animation
var _is_animating := false


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
	_title_label.position = Vector2(0, 18)
	_title_label.size = Vector2(VIEWPORT_W, 30)
	_title_label.text = "LEVEL UP!"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 0.5, 1.0),
	)
	add_child(_title_label)

	# Current upgrades summary (bottom)
	_summary_label = Label.new()
	_summary_label.name = "SummaryLabel"
	_summary_label.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_summary_label.position = Vector2(20, 290)
	_summary_label.size = Vector2(VIEWPORT_W - 40, 50)
	_summary_label.text = ""
	_summary_label.add_theme_font_size_override(
		"font_size", 8,
	)
	_summary_label.add_theme_color_override(
		"font_color", Color(0.6, 0.75, 0.85, 0.8),
	)
	_summary_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
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
		_slide_progress = minf(
			_slide_progress + real_delta * 6.0, 1.0,
		)
		_cards_node.queue_redraw()
		if _slide_progress >= 1.0:
			_is_animating = false
		return  # Don't accept input during animation

	# Cooldowns
	_nav_cooldown = maxf(_nav_cooldown - real_delta, 0.0)
	_action_cooldown = maxf(_action_cooldown - real_delta, 0.0)

	_handle_navigation()
	_handle_actions()
	_handle_mouse()

	# Confirm selection (keyboard)
	if _action_cooldown <= 0.0:
		if Input.is_action_just_pressed("shmup_shoot"):
			_confirm_selection()
		elif Input.is_action_just_pressed("shmup_restart"):
			_confirm_selection()


func _handle_navigation() -> void:
	if _nav_cooldown > 0.0:
		return
	var nav := 0
	if Input.is_action_just_pressed("shmup_aim_left"):
		nav = -1
	elif Input.is_action_just_pressed("shmup_move_left"):
		nav = -1
	elif Input.is_action_just_pressed("shmup_aim_right"):
		nav = 1
	elif Input.is_action_just_pressed("shmup_move_right"):
		nav = 1

	if nav != 0:
		selected_index = clampi(
			selected_index + nav, 0, choices.size() - 1,
		)
		_nav_cooldown = 0.2
		_cards_node.queue_redraw()


func _handle_actions() -> void:
	if _action_cooldown > 0.0:
		return
	if Input.is_action_just_pressed("shmup_reroll"):
		_try_reroll()
	elif Input.is_action_just_pressed("shmup_skip"):
		_try_skip()
	elif Input.is_action_just_pressed("shmup_lock"):
		_try_lock()
	elif Input.is_action_just_pressed("shmup_banish"):
		_try_banish()


func show_choices(new_choices: Array) -> void:
	if new_choices.is_empty():
		return

	choices = new_choices
	selected_index = clampi(1, 0, choices.size() - 1)
	is_showing = true
	_slide_progress = 0.0
	_is_animating = true
	_nav_cooldown = 0.3
	_action_cooldown = 0.3

	# Show cursor for mouse interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	_bg.visible = true
	_title_label.visible = true
	_summary_label.visible = true
	_cards_node.visible = true

	# Update summary
	if upgrade_manager:
		_summary_label.text = (
			"YOUR UPGRADES: %s"
			% upgrade_manager.get_upgrade_summary()
		)

	_cards_node.queue_redraw()


func _confirm_selection() -> void:
	if choices.is_empty():
		return
	if selected_index >= choices.size():
		return

	var chosen: Dictionary = choices[selected_index]
	var chosen_id: String = chosen["id"]

	# Clear lock if confirming the locked upgrade
	if upgrade_manager and upgrade_manager.locked_id == chosen_id:
		upgrade_manager.locked_id = ""

	is_showing = false
	_hide_immediate()
	upgrade_chosen.emit(chosen_id)


func _try_reroll() -> void:
	if not game_main or not upgrade_manager:
		return
	if game_main.bombs <= 0:
		return

	# Can't reroll if only 1 choice and it's locked
	var lock_id: String = upgrade_manager.locked_id
	if choices.size() <= 1 and lock_id != "":
		if choices[0]["id"] == lock_id:
			return

	# Spend a bomb
	game_main.bombs -= 1
	game_main._update_ui()

	# Get fresh choices (locked auto-preserved by upgrade_manager)
	var new_choices: Array = (
		upgrade_manager.get_random_choices(3)
	)
	if new_choices.is_empty():
		return

	choices = new_choices
	selected_index = clampi(1, 0, choices.size() - 1)
	_action_cooldown = 0.3
	_cards_node.queue_redraw()


func _try_skip() -> void:
	if not game_main:
		return

	# Award +1 bomb (capped)
	game_main.bombs = mini(
		game_main.bombs + 1, game_main.BOMB_CAP,
	)
	game_main._update_ui()

	is_showing = false
	_hide_immediate()
	upgrade_skipped.emit()


func _try_lock() -> void:
	if not upgrade_manager or choices.is_empty():
		return
	if selected_index >= choices.size():
		return

	var choice_id: String = choices[selected_index]["id"]

	# Toggle lock
	if upgrade_manager.locked_id == choice_id:
		upgrade_manager.locked_id = ""
	else:
		upgrade_manager.locked_id = choice_id

	_action_cooldown = 0.2
	_cards_node.queue_redraw()


func _try_banish() -> void:
	if not upgrade_manager or choices.is_empty():
		return
	if selected_index >= choices.size():
		return
	if upgrade_manager.banish_charges <= 0:
		return
	if choices.size() <= 1:
		return  # Can't banish last remaining choice

	var choice_id: String = choices[selected_index]["id"]

	# Banish (handles lock auto-break internally)
	upgrade_manager.banish_upgrade(choice_id)

	# Remove from current choices
	choices.remove_at(selected_index)
	selected_index = clampi(
		selected_index, 0, choices.size() - 1,
	)
	_action_cooldown = 0.3
	_cards_node.queue_redraw()


func _hide_immediate() -> void:
	is_showing = false
	_is_animating = false
	_slide_progress = 0.0
	choices = []

	# Hide cursor, return to crosshair mode
	Input.set_mouse_mode(
		Input.MOUSE_MODE_CONFINED_HIDDEN,
	)

	if _bg:
		_bg.visible = false
	if _title_label:
		_title_label.visible = false
	if _summary_label:
		_summary_label.visible = false
	if _cards_node:
		_cards_node.visible = false


## Returns card X position for a given index.
func get_card_x(index: int) -> float:
	var total_w := (
		choices.size() * CARD_W
		+ (choices.size() - 1) * CARD_GAP
	)
	var start_x := (VIEWPORT_W - total_w) / 2.0
	return start_x + index * (CARD_W + CARD_GAP)


## Returns card Y with slide animation offset.
func get_card_y(index: int) -> float:
	var base_y := CARD_Y
	if _is_animating:
		var stagger := index * 0.15
		var denom := 1.0 - stagger * 0.5
		var t := clampf(
			(_slide_progress - stagger) / denom, 0.0, 1.0,
		)
		t = 1.0 - pow(1.0 - t, 3.0)
		base_y = lerpf(VIEWPORT_H + 20.0, CARD_Y, t)
	return base_y


func _handle_mouse() -> void:
	var mpos := get_viewport().get_mouse_position()

	# Hover: update selected card
	var hovered := _get_hovered_card(mpos)
	if hovered >= 0 and hovered != selected_index:
		selected_index = hovered
		_cards_node.queue_redraw()

	# Hover: update action button highlight
	var old_action := hovered_action
	hovered_action = _get_hovered_action(mpos)
	if hovered_action != old_action:
		_cards_node.queue_redraw()

	# Click: confirm card or trigger action bar
	if _action_cooldown > 0.0:
		return
	if not Input.is_action_just_pressed("shmup_click"):
		return
	if _check_action_click(mpos):
		return
	if hovered >= 0:
		selected_index = hovered
		_confirm_selection()


## Returns the card index under mouse, or -1.
func _get_hovered_card(mpos: Vector2) -> int:
	for i in choices.size():
		var cx := get_card_x(i)
		var cy := get_card_y(i)
		var rect := Rect2(cx, cy, CARD_W, CARD_H)
		if rect.has_point(mpos):
			return i
	return -1


## Returns which action button (0-3) is hovered, or -1.
func _get_hovered_action(mpos: Vector2) -> int:
	var y := ACTION_BAR_Y
	var rects := [
		Rect2(50, y - 4, 120, 22),
		Rect2(180, y - 4, 120, 22),
		Rect2(320, y - 4, 120, 22),
		Rect2(470, y - 4, 120, 22),
	]
	for i in rects.size():
		var r: Rect2 = rects[i] as Rect2
		if r.has_point(mpos):
			return i
	return -1


## Checks if mouse clicked an action bar button.
func _check_action_click(mpos: Vector2) -> bool:
	var y := ACTION_BAR_Y
	# Button hit rects (match _draw_action_btn positions)
	var reroll_r := Rect2(50, y - 4, 120, 22)
	var lock_r := Rect2(180, y - 4, 120, 22)
	var banish_r := Rect2(320, y - 4, 120, 22)
	var skip_r := Rect2(470, y - 4, 120, 22)

	if reroll_r.has_point(mpos):
		_try_reroll()
		return true
	if lock_r.has_point(mpos):
		_try_lock()
		return true
	if banish_r.has_point(mpos):
		_try_banish()
		return true
	if skip_r.has_point(mpos):
		_try_skip()
		return true
	return false
