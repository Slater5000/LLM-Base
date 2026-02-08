extends Node2D
## Main game controller — ties together all systems.
## Run this scene directly to play the shmup prototype.

# ==========================================================================
# CONSTANTS
# ==========================================================================

# World definition — large scrolling world with camera follow
const WORLD_RECT := Rect2(-1600, -1600, 3200, 3200)
const WORLD_CENTER := Vector2(0, 0)
const VIEWPORT_SIZE := Vector2(640, 360)

# Pool sizes
const PLAYER_BULLET_POOL_SIZE := 200
const ENEMY_BULLET_POOL_SIZE := 80
const GEOM_POOL_SIZE := 200

# Enemy separation
const SEPARATION_RADIUS := 14.0
const SEPARATION_FORCE := 120.0

# Preloaded scripts
const SPRING_GRID_SCRIPT := preload(
	"res://scenes/prototypes/shmup/effects/spring_grid.gd"
)
const SCREEN_SHAKE_SCRIPT := preload(
	"res://scenes/prototypes/shmup/effects/screen_shake.gd"
)
const ARENA_BORDER_SCRIPT := preload(
	"res://scenes/prototypes/shmup/arena/arena_border.gd"
)
const VFX_MANAGER_SCRIPT := preload(
	"res://scenes/prototypes/shmup/effects/vfx_manager.gd"
)
const PLAYER_SHIP_SCRIPT := preload(
	"res://scenes/prototypes/shmup/player/player_ship.gd"
)
const PLAYER_BULLET_SCRIPT := preload(
	"res://scenes/prototypes/shmup/projectiles/player_bullet.gd"
)
const ENEMY_BASE_SCRIPT := preload(
	"res://scenes/prototypes/shmup/enemies/enemy_base.gd"
)
const ENEMY_BULLET_SCRIPT := preload(
	"res://scenes/prototypes/shmup/projectiles/enemy_bullet.gd"
)
const ENEMY_SPAWNER_SCRIPT := preload(
	"res://scenes/prototypes/shmup/enemies/enemy_spawner.gd"
)
const GEOM_SCRIPT := preload(
	"res://scenes/prototypes/shmup/collectibles/geom.gd"
)
const XP_LEVEL_SYSTEM_SCRIPT := preload(
	"res://scenes/prototypes/shmup/systems/xp_level_system.gd"
)
const PERF_TRACKER_SCRIPT := preload(
	"res://scenes/prototypes/shmup/systems/perf_tracker.gd"
)
const UPGRADE_MANAGER_SCRIPT := preload(
	"res://scenes/prototypes/shmup/systems/upgrade_manager.gd"
)
const LEVEL_UP_UI_SCRIPT := preload(
	"res://scenes/prototypes/shmup/ui/level_up_ui.gd"
)
const PASSIVE_WEAPON_MANAGER_SCRIPT := preload(
	"res://scenes/prototypes/shmup/systems/passive_weapon_manager.gd"
)
const LASER_BEAM_SCRIPT := preload(
	"res://scenes/prototypes/shmup/weapons/laser_beam.gd"
)
const CHROMATIC_SHADER := preload(
	"res://scenes/prototypes/shmup/shaders/chromatic_aberration.gdshader"
)
const SpatialGrid := preload(
	"res://scenes/prototypes/shmup/systems/spatial_grid.gd"
)
# Enemy type reference for geom drops
const ENEMY_TYPE_REF = ENEMY_BASE_SCRIPT.EnemyType

# Geom drop table: {type_name: {count: N, large: bool}}
const GEOM_DROPS := {
	"grunt": {"count": 1, "large": false},
	"weaver": {"count": 1, "large": false},
	"spinner": {"count": 2, "large": false},
	"spinner_child": {"count": 1, "large": false},
	"rocket": {"count": 1, "large": false},
	"tank": {"count": 5, "large": true},
	"sniper": {"count": 2, "large": false},
	"charger": {"count": 3, "large": false},
	"orbiter": {"count": 2, "large": false},
	"hive": {"count": 4, "large": true},
	"minelayer": {"count": 1, "large": false},
	"ghost": {"count": 2, "large": false},
	"pulser": {"count": 3, "large": false},
	"leech": {"count": 1, "large": false},
	"bomber": {"count": 2, "large": false},
	"serpent": {"count": 5, "large": true},
	"drone": {"count": 1, "large": false},
}

# ==========================================================================
# VARIABLES
# ==========================================================================

# Camera viewport in world coords — updated each frame
var camera_rect := Rect2(-320, -180, 640, 360)

# Game state
var score := 0
var lives := 20
var bombs := 3
var is_game_over := false
var is_paused := false
var elapsed_time := 0.0

# Node references (created in _ready)
var camera: Camera2D
var spring_grid: Node2D
var arena_border: Node2D
var vfx_manager: Node2D
var player: Area2D
var enemy_spawner: Node
var xp_level_system: Node
var upgrade_manager: Node
var passive_weapon_manager: Node2D
var laser_beam: Node2D
var level_up_ui: CanvasLayer
var perf_tracker: Node2D
var ui_layer: CanvasLayer
var post_process_layer: CanvasLayer
var spatial_grid: RefCounted

# Object pools
var player_bullet_pool: Array[Area2D] = []
var enemy_bullet_pool: Array[Area2D] = []
var geom_pool: Array[Area2D] = []
var enemy_container: Node2D

# UI Labels
var score_label: Label
var time_label: Label
var level_label: Label
var lives_label: Label
var bombs_label: Label
var game_over_label: Label
var xp_bar_bg: ColorRect
var xp_bar_fill: ColorRect

# Private state
var _enemy_packed_scene: PackedScene
var _separation_batch_idx := 0
var _railgun_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # So pause/unpause input works
	_setup_input_actions()
	_build_scene_tree()
	_create_object_pools()
	_start_game()

	# Children inherit ALWAYS from us — override to PAUSABLE so they freeze on pause
	# Exceptions: level_up_ui sets its own PROCESS_MODE_ALWAYS
	for child in get_children():
		if child == level_up_ui:
			continue  # Level-up UI manages its own process mode
		child.process_mode = Node.PROCESS_MODE_PAUSABLE


func _setup_input_actions() -> void:
	_add_key_action("shmup_move_up", KEY_W)
	_add_key_action("shmup_move_down", KEY_S)
	_add_key_action("shmup_move_left", KEY_A)
	_add_key_action("shmup_move_right", KEY_D)
	_add_key_action("shmup_aim_up", KEY_UP)
	_add_key_action("shmup_aim_down", KEY_DOWN)
	_add_key_action("shmup_aim_left", KEY_LEFT)
	_add_key_action("shmup_aim_right", KEY_RIGHT)
	_add_key_action("shmup_shoot", KEY_SPACE)
	_add_key_action("shmup_bomb", KEY_E)
	_add_key_action("shmup_restart", KEY_ENTER)
	_add_key_action("shmup_pause", KEY_ESCAPE)

	# Controller mappings
	_add_joy_axis_action("shmup_move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis_action("shmup_move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis_action("shmup_move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis_action("shmup_move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_axis_action("shmup_aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis_action("shmup_aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_axis_action("shmup_aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_joy_axis_action("shmup_aim_down", JOY_AXIS_RIGHT_Y, 1.0)
	_add_joy_button_action("shmup_shoot", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_axis_action("shmup_shoot", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_button_action("shmup_bomb", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button_action("shmup_restart", JOY_BUTTON_START)
	_add_joy_button_action("shmup_pause", JOY_BUTTON_BACK)


func _add_key_action(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action_name, event)


func _add_joy_button_action(action_name: String, button: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action_name, event)


func _add_joy_axis_action(action_name: String, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, 0.2)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action_name, event)


func _build_scene_tree() -> void:
	# --- Background layer (CanvasLayer -1) ---
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	bg_layer.name = "BackgroundLayer"
	add_child(bg_layer)

	# Spring Grid
	spring_grid = Node2D.new()
	spring_grid.set_script(SPRING_GRID_SCRIPT)
	bg_layer.add_child(spring_grid)
	spring_grid.setup(VIEWPORT_SIZE, Vector2.ZERO)

	# --- Game layer (default, layer 0) ---
	# Arena border removed — open scrolling world
	arena_border = null

	# Enemy container
	enemy_container = Node2D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)

	# VFX Manager
	vfx_manager = Node2D.new()
	vfx_manager.name = "VfxManager"
	vfx_manager.set_script(VFX_MANAGER_SCRIPT)
	add_child(vfx_manager)

	# Player
	player = _create_player()
	add_child(player)

	# Enemy Spawner
	enemy_spawner = Node.new()
	enemy_spawner.name = "EnemySpawner"
	enemy_spawner.set_script(ENEMY_SPAWNER_SCRIPT)
	add_child(enemy_spawner)

	# XP / Level System
	xp_level_system = Node.new()
	xp_level_system.name = "XpLevelSystem"
	xp_level_system.set_script(XP_LEVEL_SYSTEM_SCRIPT)
	add_child(xp_level_system)

	# Upgrade Manager
	upgrade_manager = Node.new()
	upgrade_manager.name = "UpgradeManager"
	upgrade_manager.set_script(UPGRADE_MANAGER_SCRIPT)
	add_child(upgrade_manager)

	# Spatial Grid (RefCounted — not added to tree)
	spatial_grid = SpatialGrid.new()

	# Passive Weapon Manager
	passive_weapon_manager = Node2D.new()
	passive_weapon_manager.name = "PassiveWeaponManager"
	passive_weapon_manager.set_script(PASSIVE_WEAPON_MANAGER_SCRIPT)
	add_child(passive_weapon_manager)

	# Laser Beam (inactive by default, activated by upgrade)
	laser_beam = Node2D.new()
	laser_beam.name = "LaserBeam"
	laser_beam.set_script(LASER_BEAM_SCRIPT)
	add_child(laser_beam)

	# Performance Tracker (in its own CanvasLayer so it stays on screen)
	var perf_layer := CanvasLayer.new()
	perf_layer.layer = 4
	perf_layer.name = "PerfLayer"
	add_child(perf_layer)
	perf_tracker = Node2D.new()
	perf_tracker.name = "PerfTracker"
	perf_tracker.set_script(PERF_TRACKER_SCRIPT)
	perf_layer.add_child(perf_tracker)

	# Camera with screen shake — follows player
	camera = Camera2D.new()
	camera.set_script(SCREEN_SHAKE_SCRIPT)
	camera.position = WORLD_CENTER
	camera.name = "Camera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10.0
	add_child(camera)

	# --- Post-processing layer (CanvasLayer 1) ---
	post_process_layer = CanvasLayer.new()
	post_process_layer.layer = 1
	post_process_layer.name = "PostProcess"
	add_child(post_process_layer)

	var ca_rect := ColorRect.new()
	ca_rect.name = "ChromaticAberration"
	ca_rect.size = Vector2(640, 360)
	ca_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ca_mat := ShaderMaterial.new()
	ca_mat.shader = CHROMATIC_SHADER
	ca_mat.set_shader_parameter("intensity", 0.0)
	ca_rect.material = ca_mat
	post_process_layer.add_child(ca_rect)

	# --- UI layer (CanvasLayer 2) ---
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 2
	ui_layer.name = "UILayer"
	add_child(ui_layer)

	_build_ui()

	# --- Level-up UI (CanvasLayer 3, above game UI) ---
	level_up_ui = CanvasLayer.new()
	level_up_ui.name = "LevelUpUI"
	level_up_ui.set_script(LEVEL_UP_UI_SCRIPT)  # Set script before add_child so _ready() fires
	add_child(level_up_ui)

	# --- Setup references ---
	vfx_manager.setup(spring_grid, camera, null)

	# Create enemy scene for spawner
	_enemy_packed_scene = _create_enemy_packed_scene()
	enemy_spawner.setup(WORLD_RECT, player, _enemy_packed_scene, self)

	# Connect signals
	player.fired_bullet.connect(_on_player_fired_bullet)
	player.died.connect(_on_player_died)
	enemy_spawner.enemy_spawned.connect(_on_enemy_spawned)
	xp_level_system.leveled_up.connect(_on_leveled_up)
	xp_level_system.xp_changed.connect(_on_xp_changed)
	level_up_ui.upgrade_chosen.connect(_on_upgrade_chosen)

	# Setup upgrade manager references
	upgrade_manager.player = player
	upgrade_manager.xp_level_system = xp_level_system
	upgrade_manager.game_main = self
	level_up_ui.upgrade_manager = upgrade_manager

	# Setup spring grid camera ref for world→screen coordinate conversion
	spring_grid.camera_ref = camera

	# Setup passive weapon manager
	passive_weapon_manager.setup(
		player, enemy_container, vfx_manager,
		spring_grid, camera, spatial_grid,
	)

	# Setup laser beam (inactive until upgrade)
	laser_beam.setup(player, enemy_container, spring_grid)
	laser_beam.deactivate()

	# Connect upgrade_applied to route passive weapon upgrades
	upgrade_manager.upgrade_applied.connect(_on_upgrade_applied)
	upgrade_manager.evolution_unlocked.connect(
		_on_evolution_unlocked,
	)

	# Setup perf tracker references
	perf_tracker.setup(enemy_container, geom_pool, player_bullet_pool, enemy_bullet_pool)

	# Setup WorldEnvironment for bloom
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CANVAS
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_strength = 1.0
	environment.glow_bloom = 0.3
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_normalized = false
	environment.set("glow_levels/1", true)
	environment.set("glow_levels/2", true)
	environment.set("glow_levels/4", false)
	env.environment = environment
	add_child(env)


func _create_player() -> Area2D:
	var p := Area2D.new()
	p.set_script(PLAYER_SHIP_SCRIPT)
	p.name = "Player"
	p.position = WORLD_CENTER
	p.add_to_group("player")
	p.set_world_bounds(WORLD_RECT)

	var polygon := Polygon2D.new()
	polygon.name = "ShipPolygon"
	p.add_child(polygon)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape"
	p.add_child(col)

	var particles := GPUParticles2D.new()
	particles.name = "EngineParticles"
	particles.position = Vector2(0, 6)
	p.add_child(particles)

	return p


func _create_enemy_packed_scene() -> PackedScene:
	var enemy := Area2D.new()
	enemy.set_script(ENEMY_BASE_SCRIPT)
	enemy.name = "Enemy"

	var polygon := Polygon2D.new()
	polygon.name = "EnemyPolygon"
	enemy.add_child(polygon)
	polygon.owner = enemy

	var col := CollisionShape2D.new()
	col.name = "CollisionShape"
	enemy.add_child(col)
	col.owner = enemy

	var packed := PackedScene.new()
	packed.pack(enemy)
	return packed


func _build_ui() -> void:
	# Score (top-left)
	score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.position = Vector2(45, 4)
	score_label.text = "SCORE: 0"
	score_label.add_theme_font_size_override("font_size", 10)
	score_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.9))
	ui_layer.add_child(score_label)

	# Elapsed time (top-center)
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.position = Vector2(290, 4)
	time_label.text = "0:00"
	time_label.add_theme_font_size_override("font_size", 10)
	time_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.7))
	ui_layer.add_child(time_label)

	# Level (top-right)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.position = Vector2(530, 4)
	level_label.text = "LV 1"
	level_label.add_theme_font_size_override("font_size", 10)
	level_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7, 0.9))
	ui_layer.add_child(level_label)

	# XP bar background (below level label)
	xp_bar_bg = ColorRect.new()
	xp_bar_bg.name = "XpBarBg"
	xp_bar_bg.position = Vector2(525, 18)
	xp_bar_bg.size = Vector2(60, 3)
	xp_bar_bg.color = Color(0.15, 0.15, 0.2, 0.8)
	ui_layer.add_child(xp_bar_bg)

	# XP bar fill
	xp_bar_fill = ColorRect.new()
	xp_bar_fill.name = "XpBarFill"
	xp_bar_fill.position = Vector2(525, 18)
	xp_bar_fill.size = Vector2(0, 3)
	xp_bar_fill.color = Color(0.3, 1.0, 0.5, 0.9)
	ui_layer.add_child(xp_bar_fill)

	# Lives (bottom-left)
	lives_label = Label.new()
	lives_label.name = "LivesLabel"
	lives_label.position = Vector2(220, 338)
	lives_label.text = "LIVES: 3"
	lives_label.add_theme_font_size_override("font_size", 8)
	lives_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 0.8))
	ui_layer.add_child(lives_label)

	# Bombs (bottom-right)
	bombs_label = Label.new()
	bombs_label.name = "BombsLabel"
	bombs_label.position = Vector2(360, 338)
	bombs_label.text = "BOMBS: 3"
	bombs_label.add_theme_font_size_override("font_size", 8)
	bombs_label.add_theme_color_override("font_color", Color(0.2, 0.8, 1.0, 0.8))
	ui_layer.add_child(bombs_label)

	# Game over / pause overlay (center, hidden)
	game_over_label = Label.new()
	game_over_label.name = "GameOverLabel"
	game_over_label.position = Vector2(60, 50)
	game_over_label.size = Vector2(520, 260)
	game_over_label.text = "GAME OVER"
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_label.add_theme_font_size_override("font_size", 14)
	game_over_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	game_over_label.visible = false
	ui_layer.add_child(game_over_label)


func _create_object_pools() -> void:
	# Player bullets
	for i in PLAYER_BULLET_POOL_SIZE:
		var bullet := Area2D.new()
		bullet.set_script(PLAYER_BULLET_SCRIPT)
		bullet.name = "PlayerBullet_%d" % i
		bullet.add_to_group("player_bullets")

		var polygon := Polygon2D.new()
		polygon.name = "BulletShape"
		bullet.add_child(polygon)

		var col := CollisionShape2D.new()
		col.name = "CollisionShape"
		var circle := CircleShape2D.new()
		circle.radius = 2.0
		col.shape = circle
		bullet.add_child(col)

		add_child(bullet)
		bullet.deactivate()
		player_bullet_pool.append(bullet)

	# Enemy bullets — z_index 10 so they render above enemies and VFX
	for i in ENEMY_BULLET_POOL_SIZE:
		var bullet := Area2D.new()
		bullet.set_script(ENEMY_BULLET_SCRIPT)
		bullet.name = "EnemyBullet_%d" % i
		bullet.z_index = 10

		var polygon := Polygon2D.new()
		polygon.name = "BulletShape"
		bullet.add_child(polygon)

		var col := CollisionShape2D.new()
		col.name = "CollisionShape"
		var circle := CircleShape2D.new()
		circle.radius = 3.0
		col.shape = circle
		bullet.add_child(col)

		add_child(bullet)
		bullet.deactivate()
		enemy_bullet_pool.append(bullet)

	# Geoms (XP pickups)
	for i in GEOM_POOL_SIZE:
		var geom := Area2D.new()
		geom.set_script(GEOM_SCRIPT)
		geom.name = "Geom_%d" % i

		var polygon := Polygon2D.new()
		polygon.name = "GeomPolygon"
		geom.add_child(polygon)

		add_child(geom)
		geom.deactivate()
		geom.collected.connect(_on_geom_collected)
		geom_pool.append(geom)


func _start_game() -> void:
	score = 0
	lives = 20
	bombs = 3
	elapsed_time = 0.0
	is_game_over = false
	is_paused = false
	game_over_label.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	xp_level_system.reset()
	upgrade_manager.reset()
	passive_weapon_manager.reset()
	laser_beam.deactivate()
	level_up_ui._hide_immediate()
	perf_tracker.reset()
	perf_tracker.set_enemy_cap(enemy_spawner.get_max_enemies())

	# Reset player stats to defaults (upgrades may have modified them)
	player.fire_rate = 5.0
	player.max_speed = 150.0
	player.spread_count = 1
	player.bullet_size_scale = 1.0
	player.pierce_count = 0
	player.burn_chance = 0.0
	player.freeze_chance = 0.0
	player.has_laser = false

	_update_ui()
	_update_xp_bar()

	player.respawn(WORLD_CENTER)
	enemy_spawner.start()


func _process(delta: float) -> void:
	if is_game_over:
		if Input.is_action_just_pressed("shmup_restart"):
			_restart_game()
		return

	# Pause toggle (don't allow while level-up UI is showing)
	if Input.is_action_just_pressed("shmup_pause") and not level_up_ui.is_showing:
		_toggle_pause()
		return

	if is_paused:
		return

	# Camera follows player
	if player and player.is_alive:
		camera.global_position = player.global_position
	camera_rect = get_camera_rect()

	# Update spatial grid for weapon queries
	spatial_grid.clear()
	for node in enemy_container.get_children():
		if node.get("is_active"):
			spatial_grid.insert(node, node.position)

	# Track elapsed time
	elapsed_time += delta
	_update_time_display()

	# Update perf tracker with current enemy cap
	perf_tracker.set_enemy_cap(enemy_spawner.get_max_enemies())

	# Enemy separation — prevent stacking
	_apply_enemy_separation(delta)

	# Bomb input
	if Input.is_action_just_pressed("shmup_bomb") and bombs > 0 and player.is_alive:
		_use_bomb()


## Returns the camera viewport in world coordinates.
func get_camera_rect() -> Rect2:
	if camera:
		return Rect2(camera.global_position - VIEWPORT_SIZE / 2.0, VIEWPORT_SIZE)
	return Rect2(WORLD_CENTER - VIEWPORT_SIZE / 2.0, VIEWPORT_SIZE)


## --- Enemy Separation ---

func _apply_enemy_separation(delta: float) -> void:
	var enemies := enemy_container.get_children()
	var count := enemies.size()
	if count < 2:
		return

	# Build spatial grid for O(n) neighbor lookups
	# Cell size = 2x separation radius so we only check adjacent cells
	var cell_size := SEPARATION_RADIUS * 2.0
	var grid: Dictionary = {}

	for node in enemies:
		var e: Node2D = node as Node2D
		if not e.get("is_active"):
			continue
		var cx := int(e.position.x / cell_size)
		var cy := int(e.position.y / cell_size)
		var key := cx * 10000 + cy
		if not grid.has(key):
			grid[key] = []
		grid[key].append(e)

	# Check each enemy against neighbors in same + adjacent cells
	var sep_radius_sq := SEPARATION_RADIUS * SEPARATION_RADIUS
	for node in enemies:
		var enemy: Node2D = node as Node2D
		if not enemy.get("is_active"):
			continue
		var cx := int(enemy.position.x / cell_size)
		var cy := int(enemy.position.y / cell_size)
		var push := Vector2.ZERO

		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var key := (cx + dx) * 10000 + (cy + dy)
				if not grid.has(key):
					continue
				for other_node in grid[key]:
					var other: Node2D = other_node as Node2D
					if other == enemy or not other.get("is_active"):
						continue
					var diff: Vector2 = enemy.position - other.position
					var dist_sq := diff.length_squared()
					if dist_sq < sep_radius_sq and dist_sq > 0.01:
						var dist := sqrt(dist_sq)
						var overlap := SEPARATION_RADIUS - dist
						push += diff.normalized() * overlap
					elif dist_sq <= 0.01:
						# Exactly overlapping — push in random direction
						push += Vector2.from_angle(randf() * TAU) * SEPARATION_RADIUS

		if push.length_squared() > 0.01:
			enemy.position += push.normalized() * SEPARATION_FORCE * delta


## --- Pause ---

func _toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused

	if is_paused:
		game_over_label.visible = true
		var mins := int(elapsed_time) / 60
		var secs := int(elapsed_time) % 60
		var upgrades_text: String = upgrade_manager.get_upgrade_summary()
		game_over_label.text = "PAUSED\n\nSCORE: %s\nTIME: %d:%02d\nLEVEL: %d\n\n%s\n\nPress ESC" % [
			_format_score(score), mins, secs, xp_level_system.level, upgrades_text]
		game_over_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 1.0))
	else:
		game_over_label.visible = false
		game_over_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))


# --- Signal handlers ---

func _on_player_fired_bullet(pos: Vector2, direction: Vector2) -> void:
	var bullet := _get_pooled_player_bullet()
	if bullet:
		bullet.activate(
			pos, direction,
			player.pierce_count,
			player.bullet_size_scale,
			player.burn_chance,
			player.freeze_chance
		)
		# Railgun: slow massive bullet with trail VFX
		if _railgun_active:
			bullet.speed = 150.0
			bullet.velocity = direction.normalized() * 150.0
			bullet.has_trail = true
		if spring_grid:
			var grid_force: float = 0.04 * float(player.bullet_size_scale)
			spring_grid.apply_directed_force(pos, direction, grid_force, 12.0)


func _on_player_died(pos: Vector2) -> void:
	lives -= 1

	# Death VFX
	vfx_manager.spawn_explosion(pos, Color(0.2, 0.9, 1.0), 40, 6.0)
	vfx_manager.spawn_fragments(pos, Color(0.2, 0.9, 1.0), 6, 4.0)
	vfx_manager.apply_hit_stop(0.15)
	vfx_manager.flash_screen(Color(1, 1, 1, 0.4), 0.15)
	vfx_manager.trigger_chromatic_aberration(2.0, 0.5)
	camera.add_trauma(0.8)

	_update_ui()

	if lives <= 0:
		_game_over()
	else:
		get_tree().create_timer(1.5).timeout.connect(func():
			if not is_game_over:
				player.respawn(player.position)
		)


func _on_enemy_spawned(enemy: Area2D) -> void:
	enemy_container.add_child(enemy)
	enemy.killed.connect(_on_enemy_killed)
	enemy.fired_bullet.connect(_on_enemy_fired_bullet)

	# Connect new enemy signals
	if enemy.has_signal("spawned_drone"):
		enemy.spawned_drone.connect(_on_drone_spawned)
	if enemy.has_signal("bomber_exploded"):
		enemy.bomber_exploded.connect(_on_bomber_exploded)
	if enemy.has_signal("mine_placed"):
		enemy.mine_placed.connect(_on_mine_placed)


func _on_enemy_killed(pos: Vector2, enemy_type: String, points: int) -> void:
	score += points

	# VFX based on enemy type
	var color := Color.WHITE
	var particle_count := 20
	var force := 3.0
	var trauma := 0.2
	var fragment_count := 4

	# Use TYPE_COLORS from enemy_base for consistent colors
	var type_colors := {
		"grunt": Color(0.3, 0.4, 1.0),
		"weaver": Color(0.2, 1.0, 0.4),
		"spinner": Color(0.75, 0.3, 1.0),
		"spinner_child": Color(0.75, 0.3, 1.0),
		"rocket": Color(1.0, 0.5, 0.1),
		"tank": Color(1.0, 0.15, 0.15),
		"sniper": Color(0.3, 0.9, 1.0),
		"charger": Color(0.8, 0.1, 0.1),
		"orbiter": Color(1.0, 0.85, 0.2),
		"hive": Color(0.6, 0.2, 0.9),
		"minelayer": Color(0.5, 1.0, 0.2),
		"ghost": Color(0.8, 0.85, 1.0),
		"pulser": Color(0.55, 0.2, 1.0),
		"leech": Color(0.7, 0.1, 0.2),
		"bomber": Color(1.0, 0.7, 0.1),
		"serpent": Color(0.4, 0.3, 0.9),
		"drone": Color(0.5, 0.15, 0.7),
	}

	if type_colors.has(enemy_type):
		color = type_colors[enemy_type]

	# Scale VFX by enemy importance
	match enemy_type:
		"grunt", "weaver", "leech", "drone":
			particle_count = 12; force = 2.0; trauma = 0.1; fragment_count = 2
		"spinner", "spinner_child", "rocket", "minelayer", "ghost", "sniper":
			particle_count = 18; force = 2.5; trauma = 0.15; fragment_count = 3
		"charger", "orbiter", "pulser", "bomber":
			particle_count = 25; force = 3.5; trauma = 0.25; fragment_count = 4
		"tank", "hive", "serpent":
			particle_count = 40; force = 6.0; trauma = 0.5; fragment_count = 8

	# Handle spinner splitting
	if enemy_type == "spinner" and not is_game_over:
		_spawn_split_spinners(pos)

	vfx_manager.spawn_explosion(pos, color, particle_count, force)
	vfx_manager.spawn_fragments(pos, color, fragment_count)
	vfx_manager.apply_hit_stop(0.03)
	camera.add_trauma(trauma)
	vfx_manager.spawn_score_popup(pos, str(points), color)

	# Drop geoms (XP)
	_spawn_geoms(pos, enemy_type)

	# Soul Harvest — chance to chain-explode on kill
	passive_weapon_manager.on_enemy_killed(pos)

	_update_ui()


func _on_enemy_fired_bullet(pos: Vector2, direction: Vector2) -> void:
	var bullet := _get_pooled_enemy_bullet()
	if bullet:
		bullet.activate(pos, direction)


func _on_geom_collected(xp: int) -> void:
	xp_level_system.add_xp(xp)


func _on_leveled_up(level: int) -> void:
	level_label.text = "LV %d" % level
	# Flash the level label
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.5, 1.0))
	tween.tween_callback(func():
		level_label.add_theme_font_size_override("font_size", 10)
		level_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7, 0.9))
	).set_delay(0.3)

	print("[LEVEL UP] Level %d reached at %.1fs" % [level, elapsed_time])

	# Show upgrade selection UI (only if not already showing — queue handles multiples)
	if not level_up_ui.is_showing:
		_show_level_up_ui()


func _show_level_up_ui() -> void:
	var choices: Array = upgrade_manager.get_random_choices(3)
	if choices.is_empty():
		# All upgrades maxed — consume the level and skip
		xp_level_system.consume_pending_level()
		return

	# Pause game and show choices
	is_paused = true
	get_tree().paused = true
	level_up_ui.show_choices(choices)


func _on_upgrade_chosen(id: String) -> void:
	# Apply the chosen upgrade
	upgrade_manager.apply_upgrade(id)
	xp_level_system.consume_pending_level()

	# Check for queued level-ups
	if xp_level_system.has_pending_levels():
		# Brief delay then show next choices (create_timer process_always=true by default)
		get_tree().create_timer(0.1).timeout.connect(_show_level_up_ui, CONNECT_ONE_SHOT)
	else:
		# Unpause
		is_paused = false
		get_tree().paused = false


func _on_xp_changed(_current_xp: int, _xp_to_next: int) -> void:
	_update_xp_bar()


func _on_upgrade_applied(id: String, new_level: int) -> void:
	# Route passive weapon upgrades to passive_weapon_manager
	var passive_weapons := [
		"fireball", "chain_lightning", "death_spiral", "ice_nova", "poison_cloud",
		"runetracer", "meteor_shower", "thunder_strike", "holy_water", "homing_missiles",
		"gravity_well", "shockwave", "drone_swarm", "soul_harvest", "thorn_aura",
	]
	if id in passive_weapons:
		passive_weapon_manager.set_weapon_level(id, new_level)

	# Laser beam activation
	if id == "laser":
		player.has_laser = true
		laser_beam.activate()


func _on_evolution_unlocked(id: String) -> void:
	passive_weapon_manager.set_evolution(id)
	match id:
		"bullet_storm":
			player.has_bullet_storm = true
			player.spread_count = 8
			player.fire_rate *= 1.5
		"railgun":
			player.has_railgun = true
			player.spread_count = 1
			player.pierce_count = 9999
			player.bullet_size_scale = 4.0
			player.fire_rate = 1.5
			_railgun_active = true
	print(
		"[EVOLUTION] %s unlocked" % id,
	)


## --- New enemy signal handlers ---

func _on_drone_spawned(pos: Vector2) -> void:
	# Hive spawns a mini drone enemy
	var enemy := _enemy_packed_scene.instantiate() as Area2D
	var hp_scale := 1.0 + elapsed_time / 300.0
	var spd_scale := minf(1.0 + elapsed_time / 3000.0, 1.3)
	enemy.configure(ENEMY_TYPE_REF.GRUNT, player, WORLD_RECT, 0.5, hp_scale * 0.3, spd_scale)
	enemy.hp = 1
	enemy.max_hp = 1
	enemy.speed = 90.0
	enemy.points = 25
	enemy.geom_count = 1
	enemy.type_name = "drone"
	enemy.position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
	enemy.killed.connect(_on_enemy_killed)
	enemy.fired_bullet.connect(_on_enemy_fired_bullet)
	enemy.killed.connect(enemy_spawner._on_enemy_killed)
	enemy_container.add_child(enemy)
	enemy_spawner.enemies_alive += 1


func _on_bomber_exploded(pos: Vector2, radius: float, damage: int) -> void:
	# Chain explosion — damage nearby enemies
	for enemy in enemy_container.get_children():
		if not is_instance_valid(enemy) or not enemy.is_active:
			continue
		if enemy.position.distance_to(pos) < radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)

	# Explosion VFX — expanding orange ring shows blast radius
	vfx_manager.spawn_explosion(pos, Color(1.0, 0.7, 0.1), 30, 5.0)
	vfx_manager.spawn_explosion_ring(pos, radius, Color(1.0, 0.5, 0.1))
	camera.add_trauma(0.3)
	if spring_grid:
		spring_grid.apply_explosive_force(pos, 1.5, 40.0)


func _on_mine_placed(pos: Vector2) -> void:
	# Create a mine node at position (simple timed hazard)
	var mine := Area2D.new()
	mine.name = "Mine"
	mine.position = pos
	mine.add_to_group("mines")

	# Outer glow layer
	var glow := Polygon2D.new()
	glow.name = "MineGlow"
	glow.polygon = PackedVector2Array([
		Vector2(0, -10), Vector2(4, -4),
		Vector2(10, 0), Vector2(4, 4),
		Vector2(0, 10), Vector2(-4, 4),
		Vector2(-10, 0), Vector2(-4, -4),
	])
	glow.color = Color(1.0, 0.2, 0.1, 0.1)
	mine.add_child(glow)
	# Mid layer
	var mid := Polygon2D.new()
	mid.name = "MineMid"
	mid.polygon = PackedVector2Array([
		Vector2(0, -7), Vector2(3, -3),
		Vector2(7, 0), Vector2(3, 3),
		Vector2(0, 7), Vector2(-3, 3),
		Vector2(-7, 0), Vector2(-3, -3),
	])
	mid.color = Color(1.0, 0.3, 0.1, 0.35)
	mine.add_child(mid)
	# Core spiky shape
	var polygon := Polygon2D.new()
	polygon.name = "MinePolygon"
	polygon.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(2, -2),
		Vector2(5, 0), Vector2(2, 2),
		Vector2(0, 5), Vector2(-2, 2),
		Vector2(-5, 0), Vector2(-2, -2),
	])
	polygon.color = Color(1.0, 0.5, 0.2, 0.9)
	mine.add_child(polygon)
	# Hot center dot
	var center := Polygon2D.new()
	center.name = "MineCenter"
	center.polygon = PackedVector2Array([
		Vector2(0, -2), Vector2(2, 0),
		Vector2(0, 2), Vector2(-2, 0),
	])
	center.color = Color(1.0, 0.9, 0.6, 0.95)
	mine.add_child(center)

	var col := CollisionShape2D.new()
	col.name = "CollisionShape"
	var circle := CircleShape2D.new()
	circle.radius = 6.0
	col.shape = circle
	mine.add_child(col)

	mine.monitoring = true
	mine.monitorable = true

	add_child(mine)

	# Auto-expire after 8 seconds
	get_tree().create_timer(8.0).timeout.connect(func():
		if is_instance_valid(mine):
			vfx_manager.spawn_explosion(mine.position, Color(1.0, 0.4, 0.15, 0.6), 8, 2.0)
			mine.queue_free()
	)


# --- Game flow ---

func _use_bomb() -> void:
	bombs -= 1
	_update_ui()

	var pos := player.position

	# VFX
	vfx_manager.apply_hit_stop(0.12)
	vfx_manager.spawn_explosion(pos, Color(1, 1, 1), 60, 8.0)
	vfx_manager.flash_screen(Color(1, 1, 1, 0.5), 0.15)
	vfx_manager.trigger_chromatic_aberration(1.5, 0.3)
	camera.add_trauma(0.6)

	# Damage all enemies
	for enemy in enemy_container.get_children():
		if enemy.has_method("take_damage") and enemy.is_active:
			enemy.take_damage(4)

	# Destroy all enemy bullets
	for bullet in enemy_bullet_pool:
		if bullet.is_active:
			bullet.deactivate()

	# Clear mines
	for mine in get_tree().get_nodes_in_group("mines"):
		if is_instance_valid(mine):
			mine.queue_free()

	# Invincibility
	player.is_invincible = true
	player.invincible_timer = 1.0


func _game_over() -> void:
	is_game_over = true
	enemy_spawner.is_running = false

	# Chain-explode all enemies
	var enemies := enemy_container.get_children()
	var delay := 0.0
	for enemy in enemies:
		if enemy.has_method("die") and enemy.is_active:
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(enemy) and enemy.is_active:
					enemy.die()
			)
			delay += 0.05

	# Slowmo
	vfx_manager.apply_slowmo(0.2, 1.5)

	# Show game over UI after cascade
	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60
	get_tree().create_timer(0.5).timeout.connect(func():
		game_over_label.visible = true
		game_over_label.add_theme_font_size_override("font_size", 14)
		game_over_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		var go_upgrades: String = upgrade_manager.get_upgrade_summary()
		game_over_label.text = "GAME OVER\n\nSCORE: %s\nTIME: %d:%02d\nLEVEL: %d\n\n%s\n\nPress ENTER" % [
			_format_score(score), mins, secs, xp_level_system.level, go_upgrades]
	, CONNECT_ONE_SHOT)


func _restart_game() -> void:
	# Clean up enemies
	for child in enemy_container.get_children():
		child.queue_free()

	# Clean up mines
	for mine in get_tree().get_nodes_in_group("mines"):
		if is_instance_valid(mine):
			mine.queue_free()

	# Reset pools
	for bullet in player_bullet_pool:
		bullet.deactivate()
	for bullet in enemy_bullet_pool:
		bullet.deactivate()
	for geom in geom_pool:
		geom.deactivate()

	Engine.time_scale = 1.0
	get_tree().paused = false
	enemy_spawner.reset()
	_start_game()


func _spawn_split_spinners(pos: Vector2) -> void:
	# Deferred to avoid "Can't change state while flushing queries" error
	call_deferred("_spawn_split_spinners_deferred", pos)


func _spawn_split_spinners_deferred(pos: Vector2) -> void:
	for i in 2:
		var angle := randf() * TAU
		var offset := Vector2.from_angle(angle) * 10.0
		var enemy := _enemy_packed_scene.instantiate() as Area2D
		enemy.configure(ENEMY_TYPE_REF.SPINNER, player, WORLD_RECT, 0.6)
		enemy.hp = 1
		enemy.max_hp = 1
		enemy.is_split_child = true
		enemy.can_shoot = false
		enemy.speed = 80.0
		enemy.type_name = "spinner_child"
		enemy.position = pos + offset
		enemy.killed.connect(_on_enemy_killed)
		enemy.fired_bullet.connect(_on_enemy_fired_bullet)
		enemy.killed.connect(enemy_spawner._on_enemy_killed)
		enemy_container.add_child(enemy)
		enemy_spawner.enemies_alive += 1


func _spawn_geoms(pos: Vector2, enemy_type: String) -> void:
	var drop: Dictionary = GEOM_DROPS.get(enemy_type, {"count": 1, "large": false})
	var count: int = drop["count"]
	var spawn_large: bool = drop["large"]

	for i in count:
		var geom := _get_pooled_geom()
		if geom:
			var offset := Vector2.from_angle(randf() * TAU) * randf_range(5, 15)
			var is_large := spawn_large and i == 0
			var value := 5 if is_large else 1
			geom.call_deferred("activate", pos + offset, player, is_large, value)


# --- Object pool helpers ---

func _get_pooled_player_bullet() -> Area2D:
	for bullet in player_bullet_pool:
		if not bullet.is_active:
			return bullet
	return null


func _get_pooled_enemy_bullet() -> Area2D:
	for bullet in enemy_bullet_pool:
		if not bullet.is_active:
			return bullet
	return null


func _get_pooled_geom() -> Area2D:
	for geom in geom_pool:
		if not geom.is_active:
			return geom
	return null


# --- UI ---

func _update_ui() -> void:
	score_label.text = "SCORE: %s" % _format_score(score)
	level_label.text = "LV %d" % xp_level_system.level
	lives_label.text = "LIVES: %d" % lives
	bombs_label.text = "BOMBS: %d" % bombs


func _update_time_display() -> void:
	var mins := int(elapsed_time) / 60
	var secs := int(elapsed_time) % 60
	time_label.text = "%d:%02d" % [mins, secs]

	# Color shift at 10 min (INSANO MODE indicator)
	if elapsed_time >= 600.0:
		var pulse := absf(sin(elapsed_time * 2.0))
		time_label.add_theme_color_override("font_color",
			Color(1.0, 0.3, 0.3, 0.7).lerp(Color(1.0, 0.8, 0.2, 1.0), pulse))
	elif elapsed_time >= 480.0:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3, 0.8))


func _update_xp_bar() -> void:
	var progress: float = xp_level_system.get_progress()
	xp_bar_fill.size.x = 60.0 * progress

	# Color shift based on progress
	xp_bar_fill.color = Color(0.3, 1.0, 0.5, 0.9).lerp(Color(1.0, 1.0, 0.5, 1.0), progress)


func _format_score(s: int) -> String:
	var text := str(s)
	var result := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = text[i] + result
		count += 1
	return result


func get_elapsed_time() -> float:
	return elapsed_time
