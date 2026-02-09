extends CanvasLayer
class_name ScannerClass
## Scanner - Handles creature scanning minigame.
## Press X to enter scanner mode, cursor becomes scanner ring.
## Hover over shaking grass to start shrinking circle minigame.
## Click when the shrinking circle reaches the cursor edge.
## After successful scan, choose to Engage (battle) or Ignore.
## Note: Scanning does NOT reveal creature identity - only captured creatures are known.

signal scanner_opened
signal scanner_closed
signal scan_started(grass: TallGrass)
signal scan_completed(grass: TallGrass)
signal engage_chosen(grass: TallGrass)
signal ignore_chosen(grass: TallGrass)

## Scanner state
var _is_active: bool = false
var _is_scanning: bool = false
var _is_prompting: bool = false  # Showing engage/ignore prompt
var _current_grass: TallGrass = null

## Cursor leash settings
const TILE_SIZE := 24.0
const MAX_LEASH_TILES := 3.0
const MAX_LEASH_DISTANCE := TILE_SIZE * MAX_LEASH_TILES

## Scan meter (0.0 to 1.0)
var _scan_progress: float = 0.0
const SCAN_COMPLETE_THRESHOLD := 1.0

## Shrinking circle settings
const CURSOR_RADIUS := 16.0  # Target radius (actual cursor edge)
const RING_START_RADIUS := 55.0  # Starting radius of shrinking ring
const TIMING_WINDOW := 3.0  # Pixels from target - tighter window
const PROGRESS_PER_HIT := 0.25  # 4 hits to fill
const PROGRESS_PENALTY := 0.12  # Lose progress on miss

## Ring speeds (pixels per second) - varies by difficulty
const RING_SPEED_EASY := 40.0
const RING_SPEED_MEDIUM := 60.0
const RING_SPEED_HARD := 80.0

## Current ring state
var _ring_radius: float = 0.0
var _ring_active: bool = false
var _ring_speed: float = RING_SPEED_MEDIUM
var _ring_cooldown: float = 0.0
const RING_COOLDOWN_TIME := 0.3

## UI elements
var _cursor_sprite: Sprite2D
var _shrinking_ring: Node2D
var _scan_meter_container: Control
var _scan_meter_bg: ColorRect
var _scan_meter_fill: ColorRect
var _feedback_label: Label

## Prompt UI
var _prompt_container: HBoxContainer
var _engage_button: Button
var _ignore_button: Button
var _last_cursor_screen_pos: Vector2 = Vector2.ZERO

## Scanner cursor texture
var _scanner_cursor_texture: Texture2D


func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	_scanner_cursor_texture = preload("res://assets/sprites/ui/scanner_ring.png")
	_create_ui()
	_create_prompt_ui()
	_hide_ui()


func _create_ui() -> void:
	# Shrinking ring (drawn with _draw)
	_shrinking_ring = Node2D.new()
	_shrinking_ring.z_index = 999
	_shrinking_ring.set_script(preload("res://autoloads/scanner_ring_drawer.gd"))
	add_child(_shrinking_ring)

	# Scanner cursor sprite
	_cursor_sprite = Sprite2D.new()
	_cursor_sprite.texture = _scanner_cursor_texture
	_cursor_sprite.z_index = 1000
	add_child(_cursor_sprite)

	# Scan meter container
	_scan_meter_container = Control.new()
	_scan_meter_container.size = Vector2(54, 12)
	_scan_meter_container.z_index = 1000
	add_child(_scan_meter_container)

	# White outline (slightly larger rect behind everything)
	var outline_rect := ColorRect.new()
	outline_rect.color = Color.WHITE
	outline_rect.size = Vector2(54, 12)
	outline_rect.position = Vector2.ZERO
	_scan_meter_container.add_child(outline_rect)

	# Scan meter background (black inner area)
	_scan_meter_bg = ColorRect.new()
	_scan_meter_bg.color = Color.BLACK
	_scan_meter_bg.size = Vector2(50, 8)
	_scan_meter_bg.position = Vector2(2, 2)
	_scan_meter_container.add_child(_scan_meter_bg)

	# Scan meter fill
	_scan_meter_fill = ColorRect.new()
	_scan_meter_fill.color = Color.WHITE
	_scan_meter_fill.size = Vector2(0, 6)
	_scan_meter_fill.position = Vector2(3, 3)
	_scan_meter_container.add_child(_scan_meter_fill)

	# Feedback label
	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 16)
	_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_feedback_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_feedback_label.add_theme_constant_override("outline_size", 2)
	_feedback_label.z_index = 1001
	add_child(_feedback_label)


func _create_prompt_ui() -> void:
	# Inline prompt - appears below the scanner cursor (replacing the meter)
	_prompt_container = HBoxContainer.new()
	_prompt_container.z_index = 1002
	_prompt_container.add_theme_constant_override("separation", 6)

	# Engage button (green-ish) with black border
	_engage_button = Button.new()
	_engage_button.text = "ENGAGE"
	_engage_button.custom_minimum_size = Vector2(60, 18)
	_engage_button.add_theme_font_size_override("font_size", 16)
	var engage_style := StyleBoxFlat.new()
	engage_style.bg_color = Color(0.25, 0.5, 0.35, 1.0)
	engage_style.border_color = Color.BLACK
	engage_style.set_border_width_all(2)
	engage_style.set_corner_radius_all(2)
	engage_style.content_margin_left = 4
	engage_style.content_margin_right = 4
	engage_style.content_margin_top = 5
	engage_style.content_margin_bottom = 0
	_engage_button.add_theme_stylebox_override("normal", engage_style)
	_engage_button.add_theme_stylebox_override("hover", engage_style)
	_engage_button.add_theme_stylebox_override("pressed", engage_style)
	_engage_button.pressed.connect(_on_engage_pressed)
	_prompt_container.add_child(_engage_button)

	# Ignore button (red-ish) with black border
	_ignore_button = Button.new()
	_ignore_button.text = "IGNORE"
	_ignore_button.custom_minimum_size = Vector2(60, 18)
	_ignore_button.add_theme_font_size_override("font_size", 16)
	var ignore_style := StyleBoxFlat.new()
	ignore_style.bg_color = Color(0.55, 0.3, 0.25, 1.0)
	ignore_style.border_color = Color.BLACK
	ignore_style.set_border_width_all(2)
	ignore_style.set_corner_radius_all(2)
	ignore_style.content_margin_left = 4
	ignore_style.content_margin_right = 4
	ignore_style.content_margin_top = 5
	ignore_style.content_margin_bottom = 0
	_ignore_button.add_theme_stylebox_override("normal", ignore_style)
	_ignore_button.add_theme_stylebox_override("hover", ignore_style)
	_ignore_button.add_theme_stylebox_override("pressed", ignore_style)
	_ignore_button.pressed.connect(_on_ignore_pressed)
	_prompt_container.add_child(_ignore_button)

	add_child(_prompt_container)
	_prompt_container.hide()


func _hide_ui() -> void:
	_cursor_sprite.hide()
	_shrinking_ring.hide()
	_scan_meter_container.hide()
	_feedback_label.hide()
	_prompt_container.hide()


func _show_ui() -> void:
	_cursor_sprite.show()
	if _is_scanning:
		_scan_meter_container.show()
		_shrinking_ring.show()


func _input(event: InputEvent) -> void:
	# Don't process input during prompt
	if _is_prompting:
		return

	# Toggle scanner with X key
	if event.is_action_pressed("scanner_toggle"):
		if _is_active:
			close_scanner()
		else:
			open_scanner()
		get_viewport().set_input_as_handled()
		return

	if not _is_active:
		return

	# Left click during scanning
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _is_scanning and _ring_active:
				_check_ring_click()
				get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _is_active:
		return

	if _is_prompting:
		_update_prompt_position()
		return

	_update_cursor_position()

	if _is_scanning:
		_update_ring(delta)
		_update_scan_meter_ui()
		_check_grass_still_valid()


func _update_ring(delta: float) -> void:
	if _ring_active:
		_ring_radius -= _ring_speed * delta

		_shrinking_ring.set_meta("ring_radius", _ring_radius)
		_shrinking_ring.set_meta("target_radius", CURSOR_RADIUS)
		_shrinking_ring.queue_redraw()

		if _ring_radius <= CURSOR_RADIUS - 8.0:
			_on_ring_missed()
	else:
		_ring_cooldown -= delta
		if _ring_cooldown <= 0:
			_spawn_ring()


func _spawn_ring() -> void:
	_ring_active = true
	_ring_radius = RING_START_RADIUS
	_shrinking_ring.set_meta("ring_radius", _ring_radius)
	_shrinking_ring.set_meta("target_radius", CURSOR_RADIUS)
	_shrinking_ring.queue_redraw()


func _check_ring_click() -> void:
	var distance_from_target := absf(_ring_radius - CURSOR_RADIUS)

	if distance_from_target <= TIMING_WINDOW:
		_scan_progress = minf(_scan_progress + PROGRESS_PER_HIT, SCAN_COMPLETE_THRESHOLD)
	else:
		_scan_progress = maxf(_scan_progress - PROGRESS_PENALTY, 0.0)

	_ring_active = false
	_ring_cooldown = RING_COOLDOWN_TIME

	_shrinking_ring.set_meta("ring_radius", 0.0)
	_shrinking_ring.queue_redraw()

	if _scan_progress >= SCAN_COMPLETE_THRESHOLD:
		_complete_scan()


func _on_ring_missed() -> void:
	_scan_progress = maxf(_scan_progress - PROGRESS_PENALTY, 0.0)

	_ring_active = false
	_ring_cooldown = RING_COOLDOWN_TIME

	_shrinking_ring.set_meta("ring_radius", 0.0)
	_shrinking_ring.queue_redraw()


func _update_cursor_position() -> void:
	var player := _get_player()
	if not player:
		return

	var viewport := get_viewport()
	if not viewport:
		return

	var canvas_transform := viewport.get_canvas_transform()
	var mouse_screen_pos := viewport.get_mouse_position()
	var mouse_world_pos := canvas_transform.affine_inverse() * mouse_screen_pos

	var player_pos := player.global_position
	var to_mouse := mouse_world_pos - player_pos
	var distance := to_mouse.length()

	var leashed_world_pos: Vector2
	if distance > MAX_LEASH_DISTANCE:
		leashed_world_pos = player_pos + to_mouse.normalized() * MAX_LEASH_DISTANCE
	else:
		leashed_world_pos = mouse_world_pos

	var leashed_screen_pos := canvas_transform * leashed_world_pos

	_cursor_sprite.position = leashed_screen_pos
	_shrinking_ring.position = leashed_screen_pos
	_scan_meter_container.position = leashed_screen_pos + Vector2(-27, 30)
	_feedback_label.position = leashed_screen_pos + Vector2(-30, -45)
	_feedback_label.size = Vector2(60, 20)

	# Store for prompt positioning
	_last_cursor_screen_pos = leashed_screen_pos

	if not _is_scanning:
		_check_grass_hover(leashed_world_pos)


func _update_prompt_position() -> void:
	# Position prompt below the grass/silhouette
	if _current_grass and is_instance_valid(_current_grass):
		var viewport := get_viewport()
		if viewport:
			var canvas_transform := viewport.get_canvas_transform()
			var grass_screen_pos := canvas_transform * _current_grass.global_position
			_prompt_container.position = grass_screen_pos + Vector2(-66, 15)
			return
	# Fallback to last cursor position
	_prompt_container.position = _last_cursor_screen_pos + Vector2(-66, 30)


func _check_grass_hover(world_pos: Vector2) -> void:
	var grass := _get_grass_at_position(world_pos)
	if not grass:
		return

	# Debug: show why scanning isn't starting
	if grass.has_creature and not grass.is_shaking:
		print("[Scanner] Grass has creature but not shaking - restarting shake")
		grass._start_shaking()

	if grass.has_creature and grass.is_shaking and not grass.is_scanned:
		_start_scanning(grass)


func _get_grass_at_position(world_pos: Vector2) -> TallGrass:
	var space_state := _get_world_2d_space()
	if not space_state:
		return null

	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false

	var results := space_state.intersect_point(query, 10)

	for result in results:
		var collider = result.get("collider")
		if collider is TallGrass and is_instance_valid(collider):
			return collider

	return null


func _get_world_2d_space() -> PhysicsDirectSpaceState2D:
	var current_scene: Node = get_tree().current_scene
	if current_scene:
		var world_2d: World2D = current_scene.get_world_2d()
		if world_2d:
			return world_2d.direct_space_state
	return null


func _start_scanning(grass: TallGrass) -> void:
	_is_scanning = true
	_current_grass = grass
	_scan_progress = 0.0
	_ring_active = false
	_ring_cooldown = 0.1

	_scan_meter_container.show()
	_shrinking_ring.show()
	_update_scan_meter_ui()

	grass.start_scan_visual()
	scan_started.emit(grass)


func _stop_scanning() -> void:
	_is_scanning = false
	_ring_active = false

	_shrinking_ring.set_meta("ring_radius", 0.0)
	_shrinking_ring.queue_redraw()

	if _current_grass:
		_current_grass.cancel_scan_visual()

	_scan_progress = 0.0
	_scan_meter_container.hide()
	_shrinking_ring.hide()
	_feedback_label.hide()


func _check_grass_still_valid() -> void:
	if not _current_grass or not is_instance_valid(_current_grass):
		_stop_scanning()
		return

	if not _current_grass.has_creature or not _current_grass.is_shaking:
		_stop_scanning()
		return

	var player := _get_player()
	if not player:
		return

	var viewport := get_viewport()
	if not viewport:
		return

	var canvas_transform := viewport.get_canvas_transform()
	var mouse_screen_pos := viewport.get_mouse_position()
	var mouse_world_pos := canvas_transform.affine_inverse() * mouse_screen_pos

	var player_pos := player.global_position
	var to_mouse := mouse_world_pos - player_pos
	var distance := to_mouse.length()

	var leashed_world_pos: Vector2
	if distance > MAX_LEASH_DISTANCE:
		leashed_world_pos = player_pos + to_mouse.normalized() * MAX_LEASH_DISTANCE
	else:
		leashed_world_pos = mouse_world_pos

	var dist_to_grass := leashed_world_pos.distance_to(_current_grass.global_position)
	if dist_to_grass > TILE_SIZE * 1.5:
		_stop_scanning()


func _complete_scan() -> void:
	# Stop the minigame
	_is_scanning = false
	_ring_active = false
	_shrinking_ring.set_meta("ring_radius", 0.0)
	_shrinking_ring.queue_redraw()
	_scan_meter_container.hide()
	_shrinking_ring.hide()

	# Mark grass as scanned (for flee bonus)
	if _current_grass and is_instance_valid(_current_grass):
		_current_grass.is_scanned = true

	# Pause game and show prompt
	await get_tree().create_timer(0.3).timeout

	# Safety check: make sure scanner is still active after the await
	if not _is_active or not _current_grass or not is_instance_valid(_current_grass):
		return

	_show_prompt()


func _show_prompt() -> void:
	_is_prompting = true
	# Register with GameState menu system (allows stacking with other menus)
	GameState.open_menu("scanner_prompt", true)

	# Show mouse cursor for button interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_cursor_sprite.hide()

	_prompt_container.show()
	_update_prompt_position()

	scan_completed.emit(_current_grass)


func _on_engage_pressed() -> void:
	_hide_prompt()

	var grass := _current_grass
	var species := grass.creature_species if grass else ""
	var was_scanned := true  # Always true via scanner path
	_current_grass = null

	# Consume the creature from the grass (clears has_creature, is_scanned, etc.)
	# This also notifies the GrassEncounterZone to remove it from active_creatures
	if grass and is_instance_valid(grass):
		grass.engage_creature()

	close_scanner()

	# Start battle via BattleManager
	if species != "":
		var battle_manager := get_node_or_null("/root/BattleManager")
		if battle_manager:
			battle_manager.start_wild_battle(species, was_scanned)

	if grass and is_instance_valid(grass):
		engage_chosen.emit(grass)


func _on_ignore_pressed() -> void:
	_hide_prompt()

	var grass := _current_grass
	_current_grass = null

	# Hide the creature sprite and allow rescanning
	if grass and is_instance_valid(grass):
		grass.cancel_scan_visual()
		grass.is_scanned = false  # Allow rescanning

	# Keep scanner active - just reset scanning state
	_is_scanning = false
	_ring_active = false
	_scan_progress = 0.0

	# Hide the scanner cursor and show it again for continued scanning
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_cursor_sprite.show()

	if grass and is_instance_valid(grass):
		ignore_chosen.emit(grass)


func _hide_prompt() -> void:
	_is_prompting = false
	# Unregister from GameState menu system
	GameState.close_menu("scanner_prompt")
	_prompt_container.hide()


func _show_feedback(text: String, color: Color) -> void:
	_feedback_label.text = text
	_feedback_label.add_theme_color_override("font_color", color)
	_feedback_label.modulate.a = 1.0
	_feedback_label.show()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)  # Work during pause
	tween.tween_interval(0.3)
	tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.2)


func _update_scan_meter_ui() -> void:
	var fill_width := (_scan_progress / SCAN_COMPLETE_THRESHOLD) * 48.0
	_scan_meter_fill.size.x = fill_width

	if _current_grass:
		_current_grass.update_scan_progress(_scan_progress / SCAN_COMPLETE_THRESHOLD)


func _get_player() -> CharacterBody2D:
	var scene_manager := get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("get_player"):
		return scene_manager.get_player()
	return null


func open_scanner() -> void:
	if _is_active or _is_prompting:
		return

	if GameState.is_menu_open():
		return

	if not _get_player():
		return

	_is_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_show_ui()
	scanner_opened.emit()


func close_scanner() -> void:
	# Always clean up all state - don't early return
	# This prevents state from getting stuck if something desyncs
	if _is_scanning:
		_stop_scanning()

	# Always try to close scanner_prompt menu (even if _is_prompting is false, in case of desync)
	GameState.close_menu("scanner_prompt")

	# Reset ALL scanner state
	_is_active = false
	_is_prompting = false
	_is_scanning = false
	_ring_active = false
	_current_grass = null

	# Restore mouse cursor and hide UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hide_ui()
	scanner_closed.emit()


func is_scanner_active() -> bool:
	return _is_active


func is_scanning() -> bool:
	return _is_scanning
