extends Node2D
## Test scene for Line2D gladiator approach
## Two fighters auto-battle with RNG combat chains

@onready var fighter_a: GladiatorLine2D = $FighterA
@onready var fighter_b: GladiatorLine2D = $FighterB
@onready var combat_system: RNGCombat = $RNGCombat
@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UILayer

var hp_bar_a: ColorRect
var hp_bar_b: ColorRect
var combat_log: RichTextLabel
var is_auto_battling: bool = false

const ARENA_WIDTH := 800.0
const FIGHTER_SPACING := 140.0  # Close enough to actually make contact!
const SHAKE_INTENSITY := 8.0
const SHAKE_DURATION := 0.15

var shake_tween: Tween


func _ready() -> void:
	_setup_fighters()
	_setup_ui()
	_setup_camera()
	_connect_signals()

	# Start idle animations
	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")


func _setup_fighters() -> void:
	# Position fighters facing each other - close enough to make contact!
	fighter_a.position = Vector2(-FIGHTER_SPACING / 2, 50)
	fighter_a.facing_right = true
	fighter_a.base_color = Color.CYAN
	fighter_a.fighter_name = "Cyan"
	fighter_a.set_home_position()

	fighter_b.position = Vector2(FIGHTER_SPACING / 2, 50)
	fighter_b.facing_right = false
	fighter_b.base_color = Color.MAGENTA
	fighter_b.fighter_name = "Magenta"
	fighter_b.set_home_position()


func _setup_camera() -> void:
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(1.8, 1.8)  # Zoom in more to see the action


func _shake_camera(intensity: float = SHAKE_INTENSITY) -> void:
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()

	shake_tween = create_tween()
	var original_offset := camera.offset

	# Quick violent shakes
	for i in range(4):
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(camera, "offset", offset, SHAKE_DURATION / 5.0)

	# Return to center
	shake_tween.tween_property(camera, "offset", original_offset, SHAKE_DURATION / 4.0)


func _setup_ui() -> void:
	# Health bars
	var bar_width := 200.0
	var bar_height := 20.0

	# Fighter A health bar (left side)
	var hp_bg_a := ColorRect.new()
	hp_bg_a.color = Color(0.2, 0.2, 0.2)
	hp_bg_a.size = Vector2(bar_width, bar_height)
	hp_bg_a.position = Vector2(20, 20)
	ui_layer.add_child(hp_bg_a)

	hp_bar_a = ColorRect.new()
	hp_bar_a.color = Color.CYAN
	hp_bar_a.size = Vector2(bar_width, bar_height)
	hp_bar_a.position = Vector2(20, 20)
	ui_layer.add_child(hp_bar_a)

	var label_a := Label.new()
	label_a.text = "CYAN"
	label_a.position = Vector2(20, 45)
	label_a.add_theme_color_override("font_color", Color.CYAN)
	ui_layer.add_child(label_a)

	# Fighter B health bar (right side)
	var hp_bg_b := ColorRect.new()
	hp_bg_b.color = Color(0.2, 0.2, 0.2)
	hp_bg_b.size = Vector2(bar_width, bar_height)
	hp_bg_b.position = Vector2(1280 - bar_width - 20, 20)
	ui_layer.add_child(hp_bg_b)

	hp_bar_b = ColorRect.new()
	hp_bar_b.color = Color.MAGENTA
	hp_bar_b.size = Vector2(bar_width, bar_height)
	hp_bar_b.position = Vector2(1280 - bar_width - 20, 20)
	hp_bar_b.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ui_layer.add_child(hp_bar_b)

	var label_b := Label.new()
	label_b.text = "MAGENTA"
	label_b.position = Vector2(1280 - bar_width - 20, 45)
	label_b.add_theme_color_override("font_color", Color.MAGENTA)
	ui_layer.add_child(label_b)

	# Combat log
	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.scroll_following = true
	combat_log.size = Vector2(400, 150)
	combat_log.position = Vector2(440, 550)
	combat_log.add_theme_color_override("default_color", Color.WHITE)
	ui_layer.add_child(combat_log)

	# Instructions
	var instructions := Label.new()
	instructions.text = "SPACE: Start/Stop Auto-Battle | 1-6: Manual Animations | R: Reset"
	instructions.position = Vector2(20, 700)
	instructions.add_theme_color_override("font_color", Color.GRAY)
	ui_layer.add_child(instructions)


func _connect_signals() -> void:
	combat_system.combat_started.connect(_on_combat_started)
	combat_system.combat_ended.connect(_on_combat_ended)
	combat_system.move_executed.connect(_on_move_executed)

	# Shake camera and update bars when damage is dealt
	fighter_a.took_damage.connect(func(dmg):
		_update_hp_bars()
		_shake_camera(clampf(dmg * 0.5, 4.0, 12.0))
	)
	fighter_b.took_damage.connect(func(dmg):
		_update_hp_bars()
		_shake_camera(clampf(dmg * 0.5, 4.0, 12.0))
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # Space
		_toggle_auto_battle()

	# Manual animation triggers (for testing)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				fighter_a.play_animation("punch")
			KEY_2:
				fighter_a.play_animation("kick")
			KEY_3:
				fighter_a.play_animation("block")
			KEY_4:
				fighter_a.play_animation("dodge")
			KEY_5:
				fighter_a.play_animation("uppercut")
			KEY_6:
				fighter_a.play_animation("sweep")
			KEY_R:
				_reset_battle()


func _toggle_auto_battle() -> void:
	if is_auto_battling:
		combat_system.stop_combat()
		is_auto_battling = false
		_log("[color=yellow]Combat paused[/color]")
	else:
		if not fighter_a.is_alive() or not fighter_b.is_alive():
			_reset_battle()
		combat_system.start_combat(fighter_a, fighter_b)
		is_auto_battling = true


func _reset_battle() -> void:
	combat_system.stop_combat()
	is_auto_battling = false

	# Reset HP
	fighter_a.current_hp = fighter_a.max_hp
	fighter_b.current_hp = fighter_b.max_hp
	fighter_a.modulate = Color.WHITE
	fighter_b.modulate = Color.WHITE

	# Reset positions to home (in case mid-lunge)
	fighter_a.position = Vector2(-FIGHTER_SPACING / 2, 50)
	fighter_b.position = Vector2(FIGHTER_SPACING / 2, 50)
	fighter_a.set_home_position()
	fighter_b.set_home_position()

	# Reset pose and start idle
	fighter_a.reset_pose()
	fighter_b.reset_pose()
	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")

	# Reset camera
	camera.offset = Vector2.ZERO

	_update_hp_bars()
	combat_log.clear()
	_log("[color=gray]Battle reset. Press SPACE to start.[/color]")


func _update_hp_bars() -> void:
	var a_percent := fighter_a.get_hp_percent()
	var b_percent := fighter_b.get_hp_percent()

	hp_bar_a.size.x = 200.0 * a_percent
	hp_bar_b.size.x = 200.0 * b_percent

	# Color based on health
	hp_bar_a.color = _get_hp_color(a_percent, Color.CYAN)
	hp_bar_b.color = _get_hp_color(b_percent, Color.MAGENTA)


func _get_hp_color(percent: float, base: Color) -> Color:
	if percent > 0.5:
		return base
	elif percent > 0.25:
		return base.lerp(Color.YELLOW, 0.5)
	else:
		return base.lerp(Color.RED, 0.7)


func _log(text: String) -> void:
	combat_log.append_text(text + "\n")


func _on_combat_started() -> void:
	_log("[color=green]FIGHT![/color]")


func _on_combat_ended(winner: GladiatorBase) -> void:
	is_auto_battling = false
	var color := "cyan" if winner == fighter_a else "magenta"
	_log("[color=%s]%s WINS![/color]" % [color, winner.fighter_name.to_upper()])


func _on_move_executed(attacker: GladiatorBase, move: String, outcome: String) -> void:
	var color := "cyan" if attacker == fighter_a else "magenta"
	var name := attacker.fighter_name
	_log("[color=%s]%s[/color] used [b]%s[/b] → %s" % [color, name, move.to_upper(), outcome])
