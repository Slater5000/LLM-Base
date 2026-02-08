extends Node2D
## Manages visual effects: explosions, score popups, hit-stop, shockwaves.

signal hit_stop_started
signal hit_stop_ended

# Particle throttle — max concurrent GPU particle systems
const MAX_ACTIVE_PARTICLES := 20

var spring_grid: Node2D
var camera: Camera2D
var arena_border: Node2D

# Hit-stop state
var _hit_stop_timer := 0.0
var _pre_hit_stop_timescale := 1.0

# Expanding rings (bomber explosions, etc.)
var _active_rings: Array = []
var _active_particle_count := 0


func setup(grid: Node2D, cam: Camera2D, border: Node2D) -> void:
	spring_grid = grid
	camera = cam
	arena_border = border


func _process(delta: float) -> void:
	if _hit_stop_timer > 0.0:
		_hit_stop_timer -= delta / maxf(Engine.time_scale, 0.001)
		if _hit_stop_timer <= 0.0:
			Engine.time_scale = _pre_hit_stop_timescale
			hit_stop_ended.emit()

	# Update expanding rings
	if _active_rings.size() > 0:
		var i := _active_rings.size() - 1
		while i >= 0:
			var ring: Dictionary = _active_rings[i]
			ring["timer"] += delta
			var t: float = float(ring["timer"]) / float(ring["duration"])
			if t >= 1.0:
				_active_rings.remove_at(i)
			else:
				ring["radius"] = lerpf(3.0, ring["max_radius"], t)
				ring["alpha"] = 1.0 - t * t  # Quadratic fade
			i -= 1
		queue_redraw()


## Spawn a particle explosion at a position with a given color.
func spawn_explosion(
	pos: Vector2, color: Color,
	particle_count: int = 20, force: float = 3.0,
) -> void:
	if _active_particle_count >= MAX_ACTIVE_PARTICLES:
		# Still do grid warp even when skipping particles
		if spring_grid:
			spring_grid.apply_explosive_force(
				pos, force * 0.15, 50.0,
			)
		return
	_active_particle_count += 1
	var particles := GPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = particle_count
	particles.lifetime = 0.6

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3.ZERO
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.color = color

	# Fade out over lifetime
	var color_ramp := Gradient.new()
	color_ramp.set_color(0, color)
	color_ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var color_texture := GradientTexture1D.new()
	color_texture.gradient = color_ramp
	mat.color_ramp = color_texture

	# Scale down over lifetime
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.0))
	var scale_texture := CurveTexture.new()
	scale_texture.curve = scale_curve
	mat.scale_curve = scale_texture

	particles.process_material = mat
	particles.finished.connect(func() -> void:
		_active_particle_count -= 1
		particles.queue_free()
	)
	add_child(particles)

	# Grid warp (subtle — force is scaled down from VFX force)
	if spring_grid:
		spring_grid.apply_explosive_force(pos, force * 0.15, 50.0)

	# Arena border reaction
	if arena_border:
		arena_border.react_to_explosion(pos, clampf(force / 5.0, 0.0, 1.0))


## Spawn polygon fragments that scatter outward.
func spawn_fragments(pos: Vector2, color: Color, count: int = 4, size: float = 3.0) -> void:
	for i in count:
		var frag := Polygon2D.new()
		# Small triangle fragment
		var s := size * randf_range(0.5, 1.5)
		frag.polygon = PackedVector2Array([
			Vector2(-s, -s * 0.5),
			Vector2(s, 0),
			Vector2(-s * 0.3, s * 0.7)
		])
		frag.color = color
		frag.position = pos
		frag.rotation = randf() * TAU
		add_child(frag)

		# Scatter outward with tween
		var angle := randf() * TAU
		var dist := randf_range(30.0, 80.0)
		var target := pos + Vector2.from_angle(angle) * dist
		var duration := randf_range(0.4, 0.8)

		var tween := create_tween().set_parallel(true)
		tween.tween_property(
			frag, "position", target, duration,
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(frag, "rotation", frag.rotation + randf_range(-3.0, 3.0), duration)
		tween.tween_property(frag, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
		tween.chain().tween_callback(frag.queue_free)


## Spawn a floating score popup.
func spawn_score_popup(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos - Vector2(20, 10)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", color)
	label.z_index = 100
	add_child(label)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		label, "position:y", pos.y - 30, 0.8,
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


## Brief time freeze for hit-stop effect.
func apply_hit_stop(duration: float = 0.05) -> void:
	if _hit_stop_timer > 0.0:
		return  # Already in hit-stop
	_pre_hit_stop_timescale = Engine.time_scale
	Engine.time_scale = 0.05
	_hit_stop_timer = duration
	hit_stop_started.emit()


## Screen flash (brief white overlay).
func flash_screen(color: Color = Color(1, 1, 1, 0.3), duration: float = 0.1) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.size = Vector2(640, 360)
	flash.z_index = 50
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Position flash at camera center so it covers the viewport
	if camera:
		flash.position = camera.global_position - Vector2(320, 180)
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)


## Trigger chromatic aberration on the post-process layer.
func trigger_chromatic_aberration(intensity: float = 1.0, duration: float = 0.3) -> void:
	# Find the chromatic aberration ColorRect in the post-process layer
	var ca_rect := get_node_or_null("../PostProcess/ChromaticAberration")
	if ca_rect and ca_rect.material:
		var mat := ca_rect.material as ShaderMaterial
		mat.set_shader_parameter("intensity", intensity)
		var tween := create_tween()
		tween.tween_method(func(v): mat.set_shader_parameter("intensity", v), intensity, 0.0, duration)


## Draw expanding explosion rings.
func _draw() -> void:
	for ring in _active_rings:
		var color: Color = ring["color"]
		color.a = ring["alpha"]
		var r: float = ring["radius"]
		var pos: Vector2 = ring["pos"]
		# Outer ring (bright)
		draw_arc(pos, r, 0, TAU, 32, color, 2.0)
		# Inner glow ring (wider, dimmer)
		var glow_color := color
		glow_color.a *= 0.3
		draw_arc(pos, r * 0.85, 0, TAU, 32, glow_color, 4.0)


## Spawn an expanding ring to show explosion radius.
func spawn_explosion_ring(
	pos: Vector2, max_radius: float,
	color: Color, duration: float = 0.4,
) -> void:
	_active_rings.append({
		"pos": pos,
		"radius": 3.0,
		"max_radius": max_radius,
		"color": color,
		"duration": duration,
		"timer": 0.0,
		"alpha": 1.0,
	})


## Slowmo effect for wave clears etc.
func apply_slowmo(time_scale: float = 0.3, duration: float = 0.5) -> void:
	Engine.time_scale = time_scale
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(Engine, "time_scale", 1.0, duration).set_ease(Tween.EASE_IN)
