extends Node3D
## Test scene for CSG 3D gladiator approach
## Side-locked orthogonal camera view

@onready var fighter_a: GladiatorCSG = $FighterA
@onready var fighter_b: GladiatorCSG = $FighterB
@onready var combat_system: RNGCombat = $RNGCombat
@onready var camera: Camera3D = $Camera3D
@onready var ui_layer: CanvasLayer = $UILayer

var hp_bar_a: ColorRect
var hp_bar_b: ColorRect
var combat_log: RichTextLabel
var is_auto_battling: bool = false


func _ready() -> void:
	_setup_fighters()
	_setup_ui()
	_connect_signals()

	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")


func _setup_fighters() -> void:
	fighter_a.position = Vector3(-1.5, 0, 0)
	fighter_a.facing_right = true
	fighter_a.base_color = Color(0.3, 1.0, 0.5)  # Green
	fighter_a.fighter_name = "Green"

	fighter_b.position = Vector3(1.5, 0, 0)
	fighter_b.facing_right = false
	fighter_b.base_color = Color(1.0, 0.3, 0.5)  # Pink
	fighter_b.fighter_name = "Pink"


func _setup_ui() -> void:
	var bar_width := 200.0
	var bar_height := 18.0

	# Fighter A
	var bg_a := ColorRect.new()
	bg_a.color = Color(0.15, 0.15, 0.15)
	bg_a.size = Vector2(bar_width, bar_height)
	bg_a.position = Vector2(25, 25)
	ui_layer.add_child(bg_a)

	hp_bar_a = ColorRect.new()
	hp_bar_a.color = Color(0.3, 1.0, 0.5)
	hp_bar_a.size = Vector2(bar_width, bar_height)
	hp_bar_a.position = Vector2(25, 25)
	ui_layer.add_child(hp_bar_a)

	var label_a := Label.new()
	label_a.text = "GREEN (3D CSG)"
	label_a.position = Vector2(25, 48)
	label_a.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	ui_layer.add_child(label_a)

	# Fighter B
	var bg_b := ColorRect.new()
	bg_b.color = Color(0.15, 0.15, 0.15)
	bg_b.size = Vector2(bar_width, bar_height)
	bg_b.position = Vector2(1280 - bar_width - 25, 25)
	ui_layer.add_child(bg_b)

	hp_bar_b = ColorRect.new()
	hp_bar_b.color = Color(1.0, 0.3, 0.5)
	hp_bar_b.size = Vector2(bar_width, bar_height)
	hp_bar_b.position = Vector2(1280 - bar_width - 25, 25)
	ui_layer.add_child(hp_bar_b)

	var label_b := Label.new()
	label_b.text = "PINK (3D CSG)"
	label_b.position = Vector2(1280 - bar_width - 25, 48)
	label_b.add_theme_color_override("font_color", Color(1.0, 0.3, 0.5))
	ui_layer.add_child(label_b)

	# Combat log
	combat_log = RichTextLabel.new()
	combat_log.bbcode_enabled = true
	combat_log.scroll_following = true
	combat_log.size = Vector2(400, 130)
	combat_log.position = Vector2(440, 570)
	ui_layer.add_child(combat_log)

	# Instructions
	var instructions := Label.new()
	instructions.text = "3D CSG VIEW | SPACE: Fight | 1-6: Animations | R: Reset"
	instructions.position = Vector2(25, 700)
	instructions.add_theme_color_override("font_color", Color.GRAY)
	ui_layer.add_child(instructions)


func _connect_signals() -> void:
	combat_system.combat_started.connect(func(): _log("[color=lime]FIGHT![/color]"))
	combat_system.combat_ended.connect(_on_combat_ended)
	combat_system.move_executed.connect(_on_move_executed)

	fighter_a.took_damage.connect(func(_d): _update_hp_bars())
	fighter_b.took_damage.connect(func(_d): _update_hp_bars())


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
	fighter_a.reset_pose()
	fighter_b.reset_pose()
	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")

	_update_hp_bars()
	combat_log.clear()
	_log("[color=gray]Reset. SPACE to fight.[/color]")


func _update_hp_bars() -> void:
	hp_bar_a.size.x = 200.0 * fighter_a.get_hp_percent()
	hp_bar_b.size.x = 200.0 * fighter_b.get_hp_percent()


func _log(text: String) -> void:
	combat_log.append_text(text + "\n")


func _on_combat_ended(winner) -> void:
	is_auto_battling = false
	_log("[b]%s WINS![/b]" % winner.fighter_name.to_upper())


func _on_move_executed(attacker, move: String, outcome: String) -> void:
	_log("%s: %s → %s" % [attacker.fighter_name, move, outcome])
