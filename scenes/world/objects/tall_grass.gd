extends Area2D
class_name TallGrass
## A single grass tile that can rustle when walked through
## and shake when a creature is hiding inside.

signal creature_scanned(grass: TallGrass, species: String)

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var player_inside: bool = false
var has_creature: bool = false
var creature_species: String = ""
var is_shaking: bool = false
var is_scanned: bool = false  # Has player completed scanning this grass?

## Visual reveal elements (created dynamically)
var _creature_sprite: Sprite2D = null
var _silhouette_shader: Shader = preload("res://shaders/silhouette.gdshader")
var _scan_reveal_shader: Shader = preload("res://shaders/scan_reveal.gdshader")
var _scan_material: ShaderMaterial = null

func _ready() -> void:
	add_to_group("tall_grass")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if has_creature and is_shaking:
			# Direct contact with creature - start unscanned battle
			var species = engage_creature()
			if species != "":
				var battle_manager := get_node_or_null("/root/BattleManager")
				if battle_manager:
					battle_manager.start_wild_battle(species, false)  # was_scanned = false
		else:
			play_rustle()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func play_rustle() -> void:
	# Quick rustle when player walks through (only if not already shaking)
	if not is_shaking:
		animation_player.play("rustle")

## Called by GrassEncounterZone when a creature spawns here
func spawn_creature(species: String) -> void:
	creature_species = species
	has_creature = true
	_start_shaking()

## Called by GrassEncounterZone when creature leaves (player didn't get there in time)
func creature_leaves() -> void:
	has_creature = false
	creature_species = ""
	is_scanned = false
	_stop_shaking()
	_hide_creature_sprite()

## Called by Scanner when scan starts - shows pixelated creature
func start_scan_visual() -> void:
	if not has_creature or creature_species == "":
		print("[TallGrass] No creature or species")
		return

	# Get species data for the sprite
	var species := GameState.get_species(creature_species)
	if not species:
		print("[TallGrass] Species not found: ", creature_species)
		return

	if not species.sprite_texture:
		print("[TallGrass] Species has no sprite_texture: ", creature_species)
		return

	print("[TallGrass] Starting scan visual for: ", creature_species)

	# Create creature sprite above the grass
	if not _creature_sprite:
		_creature_sprite = Sprite2D.new()
		_creature_sprite.z_index = 100  # Well above everything
		_creature_sprite.z_as_relative = false  # Absolute z-index to bypass y-sort
		add_child(_creature_sprite)

	_creature_sprite.texture = species.sprite_texture
	_creature_sprite.position = Vector2(0, 0)  # Centered on grass
	# Calculate scale to get consistent screen size regardless of texture resolution
	# Target ~40 pixels on screen for the scan silhouette
	var target_size := 40.0
	var tex_size := species.sprite_texture.get_size()
	var max_dim := maxf(tex_size.x, tex_size.y)
	var base_scale := target_size / max_dim
	_creature_sprite.scale = Vector2(base_scale, base_scale)
	_creature_sprite.modulate = Color.WHITE

	# Apply scan reveal shader (starts heavily distorted + pixelated)
	_scan_material = ShaderMaterial.new()
	_scan_material.shader = _scan_reveal_shader
	_scan_material.set_shader_parameter("scan_progress", 0.0)
	_scan_material.set_shader_parameter("show_silhouette", true)
	_scan_material.set_shader_parameter("max_pixel_size", 16.0)  # Visible but chunky
	_scan_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
	_creature_sprite.material = _scan_material

	_creature_sprite.show()
	print("[TallGrass] Creature sprite shown at position: ", global_position, " with texture: ", species.sprite_texture)


## Called by Scanner to update scan progress (0.0 to 1.0)
func update_scan_progress(progress: float) -> void:
	if _scan_material:
		_scan_material.set_shader_parameter("scan_progress", progress)
		# Update time for animated distortion
		_scan_material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)


## Called by Scanner when scan is cancelled
func cancel_scan_visual() -> void:
	_hide_creature_sprite()
	_scan_material = null


## Called by Scanner when scan completes - reveals creature or silhouette
func reveal_creature(was_caught_before: bool) -> void:
	if not has_creature or creature_species == "":
		return

	is_scanned = true
	_stop_shaking()

	# Get species data for the sprite
	var species := GameState.get_species(creature_species)
	if not species:
		return

	# Ensure creature sprite exists
	if not _creature_sprite:
		_creature_sprite = Sprite2D.new()
		_creature_sprite.z_index = 1  # Above grass
		add_child(_creature_sprite)

	_creature_sprite.texture = species.sprite_texture
	_creature_sprite.position = Vector2(0, -16)  # Above grass
	# Calculate scale to get consistent screen size regardless of texture resolution
	# Target ~48 pixels on screen for the revealed creature
	var target_size := 48.0
	var tex_size := species.sprite_texture.get_size()
	var max_dim := maxf(tex_size.x, tex_size.y)
	var base_scale := target_size / max_dim
	_creature_sprite.scale = Vector2(base_scale, base_scale)
	_creature_sprite.modulate = Color.WHITE

	if was_caught_before:
		# Show full creature (no shader)
		_creature_sprite.material = null
	else:
		# Show silhouette using shader
		var silhouette_mat := ShaderMaterial.new()
		silhouette_mat.shader = _silhouette_shader
		_creature_sprite.material = silhouette_mat

	_scan_material = null
	_creature_sprite.show()

	# Animate reveal - scale down slightly then back to target
	var final_scale := base_scale
	var tween := create_tween()
	tween.tween_property(_creature_sprite, "scale", Vector2(final_scale, final_scale), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Called by player walking into grass after scanning - starts battle
func engage_creature() -> String:
	if has_creature:
		var species = creature_species
		has_creature = false
		is_scanned = false
		creature_species = ""
		_hide_creature_sprite()
		animation_player.play("creature_found")
		creature_scanned.emit(self, species)
		return species
	return ""


## Legacy function - now calls engage_creature
func scan_creature() -> String:
	return engage_creature()


func _hide_creature_sprite() -> void:
	if _creature_sprite:
		_creature_sprite.hide()


## Check if this grass was scanned before engaging
func was_scanned() -> bool:
	return is_scanned


## Get the species hiding in this grass (for scanner display)
func get_creature_species() -> String:
	return creature_species

var _shake_loop_running: bool = false

func _start_shaking() -> void:
	is_shaking = true
	if not _shake_loop_running:
		_shake_loop()

func _stop_shaking() -> void:
	is_shaking = false
	_shake_loop_running = false
	# Reset sprite position in case animation was mid-shake
	sprite.position = Vector2.ZERO

func _shake_loop() -> void:
	if not is_shaking or _shake_loop_running:
		return

	_shake_loop_running = true

	while is_shaking and is_inside_tree():
		animation_player.play("creature_shake")
		await animation_player.animation_finished

		if not is_shaking or not is_inside_tree():
			break

		# Small pause between shakes
		await get_tree().create_timer(randf_range(0.3, 0.8)).timeout

	_shake_loop_running = false
