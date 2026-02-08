extends Node2D
## Performance tracking system — FPS, frame drops, per-weapon profiling.
## Always visible: FPS + enemy count. F3: basic overlay. F4: extended profiler.

# --- Tracked metrics ---
var current_fps := 0.0
var min_fps := 999.0
var avg_fps := 0.0
var _fps_samples: Array[float] = []
var _fps_sample_max := 300  # 5s at 60fps

var enemy_count := 0
var enemy_cap := 0
var geom_count := 0
var bullet_count := 0
var node_count := 0
var vfx_count := 0

# --- Frame timing ---
var _frame_start_usec := 0
var _process_time_usec := 0
var _last_frame_time_usec := 0

# --- Drop detection ---
const DROP_THRESHOLD := 50.0  # FPS below this = drop
var _in_drop := false
var _drop_start_time := 0.0
var _drop_start_fps := 0.0
var _drop_start_counts := {}
var _perf_events: Array[Dictionary] = []
var _max_events := 50

# --- Weapon timings ---
var _weapon_timings: Dictionary = {}  # {name: [float, float, ...]}
var _weapon_timing_max := 60  # Keep last 60 samples per weapon

# --- Display state ---
var _show_basic := false   # F3
var _show_extended := false  # F4

# --- UI nodes ---
var _always_label: Label
var _basic_label: Label
var _extended_label: Label
var _fps_graph: Line2D
var _fps_graph_points: PackedVector2Array

# --- References (set by shmup_main) ---
var enemy_container: Node
var geom_pool: Array
var player_bullet_pool: Array
var enemy_bullet_pool: Array
var passive_weapon_manager: Node

# Graph config
const GRAPH_WIDTH := 200.0
const GRAPH_HEIGHT := 40.0
const GRAPH_POS := Vector2(430, 5)  # Top-right area
const GRAPH_SECONDS := 30.0
var _graph_history: Array[float] = []
var _graph_timer := 0.0
const GRAPH_SAMPLE_INTERVAL := 0.1  # Sample every 100ms


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	z_index = 200

	_create_ui()
	_update_visibility()


func _create_ui() -> void:
	# Always-visible: FPS + enemy count (top-left)
	_always_label = Label.new()
	_always_label.position = Vector2(5, 2)
	_always_label.add_theme_font_size_override("font_size", 6)
	_always_label.z_index = 200
	add_child(_always_label)

	# F3 basic overlay (below always label)
	_basic_label = Label.new()
	_basic_label.position = Vector2(5, 22)
	_basic_label.add_theme_font_size_override("font_size", 5)
	_basic_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.9))
	_basic_label.z_index = 200
	add_child(_basic_label)

	# F4 extended overlay (right side)
	_extended_label = Label.new()
	_extended_label.position = Vector2(430, 50)
	_extended_label.add_theme_font_size_override("font_size", 5)
	_extended_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.85))
	_extended_label.z_index = 200
	add_child(_extended_label)

	# FPS graph (Line2D)
	_fps_graph = Line2D.new()
	_fps_graph.width = 1.0
	_fps_graph.default_color = Color(0.3, 1.0, 0.3)
	_fps_graph.z_index = 200
	_fps_graph.position = GRAPH_POS
	add_child(_fps_graph)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_show_basic = not _show_basic
			_update_visibility()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F4:
			_show_extended = not _show_extended
			_update_visibility()
			get_viewport().set_input_as_handled()


func _update_visibility() -> void:
	_basic_label.visible = _show_basic or _show_extended
	_extended_label.visible = _show_extended
	_fps_graph.visible = _show_extended


func _process(delta: float) -> void:
	_frame_start_usec = Time.get_ticks_usec()

	# FPS
	current_fps = Engine.get_frames_per_second()
	_fps_samples.append(current_fps)
	if _fps_samples.size() > _fps_sample_max:
		_fps_samples.remove_at(0)
	if current_fps < min_fps and current_fps > 0:
		min_fps = current_fps

	# Rolling average
	var sum := 0.0
	for s in _fps_samples:
		sum += s
	avg_fps = sum / maxf(_fps_samples.size(), 1.0)

	# Counts
	_update_counts()

	# Drop detection
	_check_drops(delta)

	# Graph
	_update_graph(delta)

	# Update labels
	_update_always_label()
	if _show_basic or _show_extended:
		_update_basic_label()
	if _show_extended:
		_update_extended_label()
		_update_graph_visual()

	_last_frame_time_usec = Time.get_ticks_usec() - _frame_start_usec


func _update_counts() -> void:
	if enemy_container:
		enemy_count = enemy_container.get_child_count()
	node_count = get_tree().get_node_count() if get_tree() else 0

	# Count active geoms
	var active_geoms := 0
	for g in geom_pool:
		if g and is_instance_valid(g) and g.visible:
			active_geoms += 1
	geom_count = active_geoms

	# Count active bullets
	var active_bullets := 0
	for b in player_bullet_pool:
		if b and is_instance_valid(b) and b.get("is_active"):
			active_bullets += 1
	var active_enemy_bullets := 0
	for b in enemy_bullet_pool:
		if b and is_instance_valid(b) and b.get("is_active"):
			active_enemy_bullets += 1
	bullet_count = active_bullets + active_enemy_bullets


func _check_drops(delta: float) -> void:
	var elapsed := _get_elapsed_time()

	if current_fps < DROP_THRESHOLD and not _in_drop:
		# Drop started
		_in_drop = true
		_drop_start_time = elapsed
		_drop_start_fps = current_fps
		_drop_start_counts = {
			"enemies": enemy_count,
			"geoms": geom_count,
			"bullets": bullet_count,
			"nodes": node_count,
		}
	elif current_fps >= DROP_THRESHOLD and _in_drop:
		# Drop ended — log event
		_in_drop = false
		var duration := elapsed - _drop_start_time
		if duration > 0.05:  # Ignore micro-drops
			var evt := {
				"timestamp": _drop_start_time,
				"fps": _drop_start_fps,
				"duration": duration,
				"enemy_count": _drop_start_counts.get("enemies", 0),
				"geom_count": _drop_start_counts.get("geoms", 0),
				"bullet_count": _drop_start_counts.get("bullets", 0),
				"node_count": _drop_start_counts.get("nodes", 0),
				"cause": _diagnose_cause(),
			}
			_perf_events.append(evt)
			if _perf_events.size() > _max_events:
				_perf_events.remove_at(0)
			_log_event(evt)


func _diagnose_cause() -> String:
	var counts := _drop_start_counts
	var en: int = counts.get("enemies", 0)

	# Check weapon timings
	var expensive_weapon := ""
	var max_weapon_time := 0.0
	for wname in _weapon_timings:
		var samples: Array = _weapon_timings[wname]
		if samples.size() > 0:
			var avg_time: float = samples[-1]
			if avg_time > max_weapon_time:
				max_weapon_time = avg_time
				expensive_weapon = wname

	if en > 300:
		return "High enemy count (%d)" % en
	if max_weapon_time > 0.002:
		return "Expensive weapon: %s (%.1fms)" % [expensive_weapon, max_weapon_time * 1000.0]
	if counts.get("nodes", 0) > 3000:
		return "Node count high (%d)" % counts.get("nodes", 0)
	if counts.get("bullets", 0) > 150:
		return "Bullet count high (%d)" % counts.get("bullets", 0)
	return "General load"


func _log_event(evt: Dictionary) -> void:
	var mins := int(evt.timestamp) / 60
	var secs := int(evt.timestamp) % 60
	print("[PERF %d:%02d] FPS DROP: %.0ffps for %.1fs | %d enemies, %d nodes | Cause: %s" % [
		mins, secs, evt.fps, evt.duration, evt.enemy_count, evt.node_count, evt.cause
	])


func _update_graph(delta: float) -> void:
	_graph_timer += delta
	if _graph_timer >= GRAPH_SAMPLE_INTERVAL:
		_graph_timer -= GRAPH_SAMPLE_INTERVAL
		_graph_history.append(current_fps)
		var max_samples := int(GRAPH_SECONDS / GRAPH_SAMPLE_INTERVAL)
		if _graph_history.size() > max_samples:
			_graph_history.remove_at(0)


func _update_graph_visual() -> void:
	if _graph_history.size() < 2:
		return

	var pts := PackedVector2Array()
	var count := _graph_history.size()
	for i in count:
		var x := (float(i) / maxf(count - 1, 1.0)) * GRAPH_WIDTH
		var fps_val: float = _graph_history[i]
		var y := GRAPH_HEIGHT - clampf(fps_val / 60.0, 0.0, 1.0) * GRAPH_HEIGHT
		pts.append(Vector2(x, y))

	_fps_graph.points = pts

	# Color based on recent FPS
	if current_fps >= 55:
		_fps_graph.default_color = Color(0.3, 1.0, 0.3)
	elif current_fps >= 40:
		_fps_graph.default_color = Color(1.0, 1.0, 0.3)
	else:
		_fps_graph.default_color = Color(1.0, 0.3, 0.3)


func _update_always_label() -> void:
	var fps_color := "00ff00" if current_fps >= 55 else ("ffff00" if current_fps >= 40 else "ff4444")
	_always_label.text = "FPS: %.0f  ENM: %d/%d" % [current_fps, enemy_count, enemy_cap]
	_always_label.add_theme_color_override("font_color",
		Color.GREEN if current_fps >= 55 else (Color.YELLOW if current_fps >= 40 else Color.RED))


func _update_basic_label() -> void:
	var active_p := 0
	for b in player_bullet_pool:
		if b and is_instance_valid(b) and b.get("is_active"):
			active_p += 1
	var active_e := bullet_count - active_p

	var budget_pct := 0.0
	if _last_frame_time_usec > 0:
		budget_pct = (_last_frame_time_usec / 16667.0) * 100.0

	var bar := ""
	var filled := clampi(int(budget_pct / 10.0), 0, 10)
	for i in 10:
		bar += "■" if i < filled else "░"

	_basic_label.text = "FPS: %.0f (min: %.0f | avg: %.0f)\nENEMIES: %d / %d (cap)\nGEOMS: %d\nBULLETS: %dP + %dE = %d\nNODES: %d\nBUDGET: %.0f%% [%s]" % [
		current_fps, min_fps, avg_fps,
		enemy_count, enemy_cap,
		geom_count,
		active_p, active_e, bullet_count,
		node_count,
		budget_pct, bar,
	]


func _update_extended_label() -> void:
	var lines := PackedStringArray()
	lines.append("── FRAME TIMING ──")
	var frame_ms := _last_frame_time_usec / 1000.0
	lines.append("Frame: %.1fms" % frame_ms)
	lines.append("")

	# Recent perf events
	lines.append("── PERF EVENTS ──")
	var recent := _perf_events.slice(maxi(_perf_events.size() - 5, 0))
	if recent.size() == 0:
		lines.append("(none)")
	for evt in recent:
		var mins := int(evt.timestamp) / 60
		var secs := int(evt.timestamp) % 60
		lines.append("[%d:%02d] %.0ffps %.1fs — %s" % [
			mins, secs, evt.fps, evt.duration, evt.cause
		])
	lines.append("")

	# Weapon load
	if _weapon_timings.size() > 0:
		lines.append("── WEAPON LOAD ──")
		# Sort by average time (descending)
		var weapon_avgs: Array[Dictionary] = []
		for wname in _weapon_timings:
			var samples: Array = _weapon_timings[wname]
			if samples.size() > 0:
				var total := 0.0
				for s in samples:
					total += s
				var avg_val: float = total / samples.size()
				weapon_avgs.append({"name": wname, "avg": avg_val})
		weapon_avgs.sort_custom(func(a, b): return a.avg > b.avg)
		for wa in weapon_avgs:
			lines.append("%s: %.2fms" % [wa.name, wa.avg * 1000.0])

	_extended_label.text = "\n".join(lines)


# --- Public API ---

## Record a weapon fire timing. Call before and after weapon fire.
func begin_weapon_timing(weapon_name: String) -> int:
	return Time.get_ticks_usec()


func end_weapon_timing(weapon_name: String, start_usec: int) -> void:
	var elapsed := (Time.get_ticks_usec() - start_usec) / 1000000.0
	if not _weapon_timings.has(weapon_name):
		_weapon_timings[weapon_name] = []
	var arr: Array = _weapon_timings[weapon_name]
	arr.append(elapsed)
	if arr.size() > _weapon_timing_max:
		arr.remove_at(0)


func set_enemy_cap(cap: int) -> void:
	enemy_cap = cap


func setup(p_enemy_container: Node, p_geom_pool: Array, p_player_bullet_pool: Array, p_enemy_bullet_pool: Array) -> void:
	enemy_container = p_enemy_container
	geom_pool = p_geom_pool
	player_bullet_pool = p_player_bullet_pool
	enemy_bullet_pool = p_enemy_bullet_pool


func reset() -> void:
	min_fps = 999.0
	_fps_samples.clear()
	_perf_events.clear()
	_weapon_timings.clear()
	_graph_history.clear()


func _get_elapsed_time() -> float:
	# Try to get from parent (shmup_main)
	var parent := get_parent()
	if parent and parent.has_method("get_elapsed_time"):
		return parent.get_elapsed_time()
	return Time.get_ticks_msec() / 1000.0
