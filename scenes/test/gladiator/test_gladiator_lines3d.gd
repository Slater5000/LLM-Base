extends Node3D
## Test scene for 3D wireframe gladiator approach
## Pure Geometry Wars aesthetic - glowing lines only

@onready var fighter_a: GladiatorLines3D = $FighterA
@onready var fighter_b: GladiatorLines3D = $FighterB
@onready var combat_system: RNGCombat = $RNGCombat
@onready var camera: Camera3D = $Camera3D
@onready var ui_layer: CanvasLayer = $UILayer

var hp_bar_a: ColorRect
var hp_bar_b: ColorRect
var combat_log: RichTextLabel
var is_auto_battling: bool = false

# Camera orbit
var camera_angle: float = 0.0
var camera_orbit_speed: float = 0.0  # Set > 0 for orbiting camera


func _ready() -> void:
	_setup_fighters()
	_setup_ui()
	_connect_signals()

	fighter_a.play_animation("idle")
	fighter_b.play_animation("idle")


func _process(delta: float) -> void:
	if camera_orbit_speed > 0:
		camera_angle += delta * camera_orbit_speed
		camera.position = Vector3(sin(camera_angle) * 5, 1.5, cos(camera_angle) * 5)
		camera.look_at(Vector3(0, 1.2, 0))


func _setup_fighters() -> void:
	fighter_a.position = Vector3(-1.2, 0, 0)
	fighter_a.facing_right = true
	fighter_a.base_color = Color(0.0, 1.0, 1.0)  # Cyan
	fighter_a.weapon_color = Color(1.0, 0.5, 0.0)
	fighter_a.fighter_name = "Cyan"

	fighter_b.position = Vector3(1.2, 0, 0)
	fighter_b.facing_right = false
	fighter_b.base_color = Color(1.0, 0.0, 1.0)  # Magenta
	fighter_b.weapon_color = Color(0.5, 1.0, 0.0)
	fighter_b.fighter_name = "Magenta"


func _setup_ui() -> void:
	var bar_width := 200.0
	var bar_height := 18.0

	# Fighter A
	var bg_a := ColorRect.new()
	bg_a.color = Color(0.1, 0.1, 0.1)
	bg_a.size = Vector2(bar_width, bar_height)
	bg_a.position = Vector2(25, 25)
	ui_layer.add_child(bg_a)

	hp_bar_a = ColorRect.new()
	hp_bar_a.color = Color(0.0, 1.0, 1.0)
	hp_bar_a.size = Vector2(bar_width, bar_height)
	hp_bar_a.position = Vector2(25, 25)
	ui_layer.add_child(hp_bar_a)

	var label_a := Label.new()
	label_a.text = "CYAN (3D WIREFRAME)"
	label_a.position = Vector2(25, 48)
	label_a.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	ui_layer.add_child(label_a)

	# Fighter B
	var bg_b := ColorRect.new()
	bg_b.color = Color(0.1, 0.1, 0.1)
	bg_b.size = Vector2(bar_width, bar_height)
	bg_b.position = Vector2(1280 - bar_width - 25, 25)
	ui_layer.add_child(bg_b)

	hp_bar_b = ColorRect.new()
	hp_bar_b.color = Color(1.0, 0.0, 1.0)
	hp_bar_b.size = Vector2(bar_width, bar_height)
	hp_bar_b.position = Vector2(1280 - bar_width - 25, 25)
	ui_layer.add_child(hp_bar_b)

	var label_b := Label.new()
	label_b.text = "MAGENTA (3D WIREFRAME)"
	label_b.position = Vector2(1280 - bar_width - 25, 48)
	label_b.add_theme_color_override("font_color", Color(1.0, 0.0, 1.0))
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
	instructions.text = "3D WIREFRAME | SPACE: Fight | 1-6: Anims | O: Toggle Orbit | R: Reset"
	instructions.position = Vector2(25, 700)
	instructions.add_theme_color_override("font_color", Color.GRAY)
	ui_layer.add_child(instructions)


func _connect_signals() -> void:
	combat_system.combat_started.connect(func(): _log("[color=cyan]FIGHT![/color]"))
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
			KEY_O:
				camera_orbit_speed = 0.5 if camera_orbit_speed == 0 else 0.0
				if camera_orbit_speed == 0:
					camera.position = Vector3(0, 1.5, 5)
					camera.look_at(Vector3(0, 1.2, 0))
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
	var color := "cyan" if attacker == fighter_a else "magenta"
	_log("[color=%s]%s[/color]: %s → %s" % [color, attacker.fighter_name, move, outcome])
