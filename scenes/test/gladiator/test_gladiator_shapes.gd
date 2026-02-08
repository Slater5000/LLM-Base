extends Node2D
## Test scene for Shapes gladiator approach (top-down view)
## Uses pure _draw() method for all rendering

@onready var fighter_a: GladiatorShapes = $FighterA
@onready var fighter_b: GladiatorShapes = $FighterB
@onready var combat_system: RNGCombat = $RNGCombat
@onready var camera: Camera2D = $Camera2D
@onready var ui_layer: CanvasLayer = $UILayer

var hp_bar_a: ColorRect
var hp_bar_b: ColorRect
var combat_log: RichTextLabel
var is_auto_battling: bool = false

const ARENA_RADIUS := 200.0


func _ready() -> void:
	_setup_fighters()
	_setup_ui()
	_setup_camera()
	_connect_signals()

	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")


func _setup_fighters() -> void:
	# Position for top-down arena
	fighter_a.position = Vector2(-100, 0)
	fighter_a.facing_right = true
	fighter_a.base_color = Color(0.2, 0.8, 1.0)  # Light blue
	fighter_a.outline_color = Color.WHITE
	fighter_a.fighter_name = "Blue"

	fighter_b.position = Vector2(100, 0)
	fighter_b.facing_right = false
	fighter_b.base_color = Color(1.0, 0.4, 0.2)  # Orange
	fighter_b.outline_color = Color.WHITE
	fighter_b.fighter_name = "Orange"


func _setup_camera() -> void:
	camera.position = Vector2.ZERO
	camera.zoom = Vector2(2.0, 2.0)


func _setup_ui() -> void:
	var bar_width := 180.0
	var bar_height := 16.0

	# Fighter A health bar
	var hp_bg_a := ColorRect.new()
	hp_bg_a.color = Color(0.15, 0.15, 0.15)
	hp_bg_a.size = Vector2(bar_width, bar_height)
	hp_bg_a.position = Vector2(30, 30)
	ui_layer.add_child(hp_bg_a)

	hp_bar_a = ColorRect.new()
	hp_bar_a.color = Color(0.2, 0.8, 1.0)
	hp_bar_a.size = Vector2(bar_width, bar_height)
	hp_bar_a.position = Vector2(30, 30)
	ui_layer.add_child(hp_bar_a)

	var label_a := Label.new()
	label_a.text = "BLUE"
	label_a.position = Vector2(30, 50)
	label_a.add_theme_font_size_override("font_size", 14)
	label_a.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0))
	ui_layer.add_child(label_a)

	# Fighter B health bar
	var hp_bg_b := ColorRect.new()
	hp_bg_b.color = Color(0.15, 0.15, 0.15)
	hp_bg_b.size = Vector2(bar_width, bar_height)
	hp_bg_b.position = Vector2(1280 - bar_width - 30, 30)
	ui_layer.add_child(hp_bg_b)

	hp_bar_b = ColorRect.new()
	hp_bar_b.color = Color(1.0, 0.4, 0.2)
	hp_bar_b.size = Vector2(bar_width, bar_height)
	hp_bar_b.position = Vector2(1280 - bar_width - 30, 30)
	ui_layer.add_child(hp_bar_b)

	var label_b := Label.new()
	label_b.text = "ORANGE"
	label_b.position = Vector2(1280 - bar_width - 30, 50)
	label_b.add_theme_font_size_override("font_size", 14)
	label_b.add_theme_color_override("font_color", Color(1.0, 0.4, 0.2))
	ui_layer.add_child(label_b)

	# Combat log
	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.scroll_following = true
	combat_log.size = Vector2(350, 120)
	combat_log.position = Vector2(465, 580)
	ui_layer.add_child(combat_log)

	# Instructions
	var instructions := Label.new()
	instructions.text = "TOP-DOWN VIEW | SPACE: Fight | 1-6: Animations | R: Reset"
	instructions.position = Vector2(30, 700)
	instructions.add_theme_color_override("font_color", Color.GRAY)
	ui_layer.add_child(instructions)


func _connect_signals() -> void:
	combat_system.combat_started.connect(_on_combat_started)
	combat_system.combat_ended.connect(_on_combat_ended)
	combat_system.move_executed.connect(_on_move_executed)

	fighter_a.took_damage.connect(func(_d): _update_hp_bars())
	fighter_b.took_damage.connect(func(_d): _update_hp_bars())


func _draw() -> void:
	# Draw arena circle
	draw_arc(Vector2.ZERO, ARENA_RADIUS, 0, TAU, 64, Color(0.25, 0.25, 0.3), 3.0, true)
	draw_arc(Vector2.ZERO, ARENA_RADIUS - 20, 0, TAU, 48, Color(0.2, 0.2, 0.25), 1.5, true)

	# Center cross
	draw_line(Vector2(-15, 0), Vector2(15, 0), Color(0.3, 0.3, 0.35), 2.0)
	draw_line(Vector2(0, -15), Vector2(0, 15), Color(0.3, 0.3, 0.35), 2.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_toggle_auto_battle()

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: fighter_a.play_animation("punch")
			KEY_2: fighter_a.play_animation("kick")
			KEY_3: fighter_a.play_animation("block")
			KEY_4: fighter_a.play_animation("dodge")
			KEY_5: fighter_a.play_animation("uppercut")
			KEY_6: fighter_a.play_animation("sweep")
			KEY_R: _reset_battle()


func _toggle_auto_battle() -> void:
	if is_auto_battling:
		combat_system.stop_combat()
		is_auto_battling = false
		_log("[color=yellow]Paused[/color]")
	else:
		if not fighter_a.is_alive() or not fighter_b.is_alive():
			_reset_battle()
		combat_system.start_combat(fighter_a, fighter_b)
		is_auto_battling = true


func _reset_battle() -> void:
	combat_system.stop_combat()
	is_auto_battling = false

	fighter_a.current_hp = fighter_a.max_hp
	fighter_b.current_hp = fighter_b.max_hp
	fighter_a.modulate = Color.WHITE
	fighter_b.modulate = Color.WHITE
	fighter_a.reset_pose()
	fighter_b.reset_pose()
	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")

	_update_hp_bars()
	combat_log.clear()
	_log("[color=gray]Reset. SPACE to fight.[/color]")


func _update_hp_bars() -> void:
	hp_bar_a.size.x = 180.0 * fighter_a.get_hp_percent()
	hp_bar_b.size.x = 180.0 * fighter_b.get_hp_percent()


func _log(text: String) -> void:
	combat_log.append_text(text + "\n")


func _on_combat_started() -> void:
	_log("[color=green]FIGHT![/color]")


func _on_combat_ended(winner: GladiatorBase) -> void:
	is_auto_battling = false
	_log("[b]%s WINS![/b]" % winner.fighter_name.to_upper())


func _on_move_executed(attacker: GladiatorBase, move: String, outcome: String) -> void:
	_log("%s: %s → %s" % [attacker.fighter_name, move, outcome])
