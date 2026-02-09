extends Area2D
## Temporary pickup — drops from enemies, grants instant/timed effects.
## Pooled with activate/deactivate pattern matching geom.gd.

signal collected(pickup_type: int)

enum PickupType {
	MAGNET_PULSE,
	CHRONOFREEZE,
	HEALING_DROP,
	INSTANT_LEVEL,
	TURBO_T,
	TURBO_U,
	TURBO_R,
	TURBO_B,
	TURBO_O,
	ENEMY_CONVERSION,
	POSITIONAL_CHALLENGE,
	ANGELIC_BOON,
	BERSERKS_RAGE,
	RAPID_FIRE,
}

# Visual config per type: {color, size, rotation_speed}
const TYPE_CONFIG := {
	PickupType.MAGNET_PULSE: {
		"color": Color(0.9, 0.3, 1.0),
		"size": 8.0,
		"rot_speed": 2.5,
		"glow": true,
	},
	PickupType.CHRONOFREEZE: {
		"color": Color(0.5, 0.85, 1.0),
		"size": 9.0,
		"rot_speed": 1.0,
		"glow": true,
	},
	PickupType.HEALING_DROP: {
		"color": Color(1.0, 0.3, 0.3),
		"size": 7.0,
		"rot_speed": 0.0,
		"glow": false,
	},
	PickupType.INSTANT_LEVEL: {
		"color": Color(1.0, 0.9, 0.2),
		"size": 8.0,
		"rot_speed": 0.0,
		"glow": true,
	},
	PickupType.TURBO_T: {
		"color": Color(1.0, 0.2, 0.2),
		"size": 10.0,
		"rot_speed": 0.0,
		"glow": true,
	},
	PickupType.TURBO_U: {
		"color": Color(1.0, 0.6, 0.1),
		"size": 10.0,
		"rot_speed": 0.0,
		"glow": true,
	},
	PickupType.TURBO_R: {
		"color": Color(1.0, 1.0, 0.2),
		"size": 10.0,
		"rot_speed": 0.0,
		"glow": true,
	},
	PickupType.TURBO_B: {
		"color": Color(0.5, 1.0, 0.2),
		"size": 10.0,
		"rot_speed": 0.0,
		"glow": true,
	},
	PickupType.TURBO_O: {
		"color": Color(0.2, 1.0, 1.0),
		"size": 10.0,
		"rot_speed": 0.0,
		"glow": true,
	},
	PickupType.ENEMY_CONVERSION: {
		"color": Color(0.7, 0.2, 1.0),
		"size": 9.0,
		"rot_speed": 1.5,
		"glow": true,
	},
	PickupType.POSITIONAL_CHALLENGE: {
		"color": Color(0.9, 0.9, 1.0),
		"size": 12.0,
		"rot_speed": 0.3,
		"glow": true,
	},
	PickupType.ANGELIC_BOON: {
		"color": Color(1.0, 1.0, 0.85),
		"size": 10.0,
		"rot_speed": 0.8,
		"glow": true,
	},
	PickupType.BERSERKS_RAGE: {
		"color": Color(0.9, 0.15, 0.1),
		"size": 8.0,
		"rot_speed": 4.0,
		"glow": false,
	},
	PickupType.RAPID_FIRE: {
		"color": Color(0.8, 1.0, 0.2),
		"size": 8.0,
		"rot_speed": 0.0,
		"glow": true,
	},
}

var pickup_type := PickupType.MAGNET_PULSE
var is_active := false
var target: Node2D
var fade_timer := 20.0
var magnetic_range := 50.0
var magnetic_speed := 180.0
var is_zone_mode := false

var _bob_timer := 0.0
var _base_y := 0.0

@onready var pickup_polygon: Polygon2D = $PickupPolygon


func _ready() -> void:
	add_to_group("pickups")
	area_entered.connect(_on_area_entered)


func activate(
	pos: Vector2, player: Node2D, type: int,
) -> void:
	position = pos
	_base_y = pos.y
	target = player
	pickup_type = type as PickupType
	is_active = true
	is_zone_mode = false
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	fade_timer = 20.0
	modulate.a = 1.0
	_bob_timer = randf() * TAU
	rotation = 0.0
	_setup_visual()
	_setup_collision()


func deactivate() -> void:
	is_active = false
	is_zone_mode = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2(-200, -200)


func enter_zone_mode() -> void:
	is_zone_mode = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_setup_zone_visual()


func _setup_collision() -> void:
	var col: CollisionShape2D
	if has_node("CollisionShape"):
		col = get_node("CollisionShape")
	else:
		col = CollisionShape2D.new()
		col.name = "CollisionShape"
		add_child(col)
	var radius := 6.0
	if col.shape is CircleShape2D:
		col.shape.radius = radius
	else:
		var circle := CircleShape2D.new()
		circle.radius = radius
		col.shape = circle


func _setup_visual() -> void:
	var cfg: Dictionary = TYPE_CONFIG[pickup_type]
	var s: float = cfg["size"]
	var c: Color = cfg["color"]
	pickup_polygon.color = c

	match pickup_type:
		PickupType.MAGNET_PULSE:
			pickup_polygon.polygon = _make_star_burst(s, 8)
		PickupType.CHRONOFREEZE:
			pickup_polygon.polygon = _make_hourglass(s)
		PickupType.HEALING_DROP:
			pickup_polygon.polygon = _make_cross(s)
		PickupType.INSTANT_LEVEL:
			pickup_polygon.polygon = _make_chevron_up(s)
		PickupType.TURBO_T:
			pickup_polygon.polygon = _make_letter_t(s)
		PickupType.TURBO_U:
			pickup_polygon.polygon = _make_letter_u(s)
		PickupType.TURBO_R:
			pickup_polygon.polygon = _make_letter_r(s)
		PickupType.TURBO_B:
			pickup_polygon.polygon = _make_letter_b(s)
		PickupType.TURBO_O:
			pickup_polygon.polygon = _make_letter_o(s)
		PickupType.ENEMY_CONVERSION:
			pickup_polygon.polygon = _make_pentagon(s)
		PickupType.POSITIONAL_CHALLENGE:
			pickup_polygon.polygon = _make_diamond_ring(s)
		PickupType.ANGELIC_BOON:
			pickup_polygon.polygon = _make_six_star(s)
		PickupType.BERSERKS_RAGE:
			pickup_polygon.polygon = _make_jagged_tri(s)
		PickupType.RAPID_FIRE:
			pickup_polygon.polygon = _make_double_chevron(s)


func _setup_zone_visual() -> void:
	var s := 30.0
	pickup_polygon.polygon = PackedVector2Array([
		Vector2(-s, -s), Vector2(s, -s),
		Vector2(s, s), Vector2(-s, s),
	])
	pickup_polygon.color = Color(0.9, 0.9, 1.0, 0.08)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_active:
		return

	if is_zone_mode:
		queue_redraw()
		return

	var cfg: Dictionary = TYPE_CONFIG[pickup_type]
	var rot_spd: float = cfg["rot_speed"]

	_bob_timer += delta
	rotation += rot_spd * delta

	# Bobbing
	position.y = _base_y + sin(_bob_timer * 3.0) * 1.5

	# Magnetic pull (not for positional challenge)
	if pickup_type != PickupType.POSITIONAL_CHALLENGE:
		if target and target.get("is_alive"):
			var dist := position.distance_to(target.position)
			if dist < magnetic_range:
				var pull := (
					(target.position - position).normalized()
				)
				position += pull * magnetic_speed * delta
				_base_y += (
					pull.y * magnetic_speed * delta
				)

	# Fade timer
	fade_timer -= delta
	if fade_timer < 5.0:
		modulate.a = 0.3 + 0.7 * absf(
			sin(fade_timer * 6.0)
		)
	if fade_timer <= 0.0:
		deactivate()


func _draw() -> void:
	if not is_active:
		return

	if is_zone_mode:
		_draw_zone()
		return

	var cfg: Dictionary = TYPE_CONFIG[pickup_type]
	if not cfg["glow"]:
		return

	var c: Color = cfg["color"]
	var s: float = cfg["size"]

	# Glow ring
	var glow_alpha := 0.25 + 0.15 * sin(_bob_timer * 4.0)
	draw_arc(
		Vector2.ZERO, s * 1.4, 0, TAU, 16,
		Color(c.r, c.g, c.b, glow_alpha), 1.5,
	)


func _draw_zone() -> void:
	var s := 30.0
	var pulse := 0.6 + 0.4 * sin(_bob_timer * 2.0) if is_active else 0.3
	var c := Color(0.9, 0.9, 1.0, pulse * 0.5)
	# Outer square border
	var pts := [
		Vector2(-s, -s), Vector2(s, -s),
		Vector2(s, s), Vector2(-s, s),
		Vector2(-s, -s),
	]
	for i in pts.size() - 1:
		draw_line(pts[i], pts[i + 1], c, 2.0)
	# Corner accents
	var accent := Color(1.0, 1.0, 0.85, pulse * 0.8)
	var corner_len := 6.0
	for corner in [
		Vector2(-s, -s), Vector2(s, -s),
		Vector2(s, s), Vector2(-s, s),
	]:
		var dx: float = sign(corner.x) * -1.0
		var dy: float = sign(corner.y) * -1.0
		draw_line(
			corner, corner + Vector2(dx * corner_len, 0),
			accent, 2.0,
		)
		draw_line(
			corner, corner + Vector2(0, dy * corner_len),
			accent, 2.0,
		)


func _on_area_entered(area: Area2D) -> void:
	if not is_active or is_zone_mode:
		return
	if area.is_in_group("player"):
		collected.emit(pickup_type)
		if pickup_type == PickupType.POSITIONAL_CHALLENGE:
			enter_zone_mode()
		else:
			deactivate()


# --- Shape generators ---

func _make_star_burst(s: float, points: int) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in points * 2:
		var angle := (float(i) / (points * 2)) * TAU - PI / 2
		var r := s if i % 2 == 0 else s * 0.4
		verts.append(Vector2(cos(angle) * r, sin(angle) * r))
	return verts


func _make_hourglass(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-s * 0.5, -s), Vector2(s * 0.5, -s),
		Vector2(0, 0),
		Vector2(s * 0.5, s), Vector2(-s * 0.5, s),
		Vector2(0, 0),
	])


func _make_cross(s: float) -> PackedVector2Array:
	var w := s * 0.3
	return PackedVector2Array([
		Vector2(-w, -s), Vector2(w, -s),
		Vector2(w, -w), Vector2(s, -w),
		Vector2(s, w), Vector2(w, w),
		Vector2(w, s), Vector2(-w, s),
		Vector2(-w, w), Vector2(-s, w),
		Vector2(-s, -w), Vector2(-w, -w),
	])


func _make_chevron_up(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -s),
		Vector2(s * 0.7, -s * 0.1),
		Vector2(s * 0.4, s * 0.1),
		Vector2(0, -s * 0.4),
		Vector2(-s * 0.4, s * 0.1),
		Vector2(-s * 0.7, -s * 0.1),
	])


func _make_letter_t(s: float) -> PackedVector2Array:
	var w := s * 0.25
	return PackedVector2Array([
		Vector2(-s * 0.6, -s * 0.7),
		Vector2(s * 0.6, -s * 0.7),
		Vector2(s * 0.6, -s * 0.3),
		Vector2(w, -s * 0.3),
		Vector2(w, s * 0.7),
		Vector2(-w, s * 0.7),
		Vector2(-w, -s * 0.3),
		Vector2(-s * 0.6, -s * 0.3),
	])


func _make_letter_u(s: float) -> PackedVector2Array:
	var w := s * 0.25
	var verts := PackedVector2Array()
	# Left arm
	verts.append(Vector2(-s * 0.5, -s * 0.7))
	verts.append(Vector2(-s * 0.5 + w, -s * 0.7))
	verts.append(Vector2(-s * 0.5 + w, s * 0.3))
	# Bottom curve (approximated)
	var curve_pts := 6
	for i in curve_pts + 1:
		var angle := PI + (float(i) / curve_pts) * PI
		verts.append(Vector2(
			cos(angle) * (s * 0.5 - w),
			s * 0.3 + sin(angle) * -(s * 0.4),
		))
	# Right arm
	verts.append(Vector2(s * 0.5 - w, s * 0.3))
	verts.append(Vector2(s * 0.5 - w, -s * 0.7))
	verts.append(Vector2(s * 0.5, -s * 0.7))
	verts.append(Vector2(s * 0.5, s * 0.5))
	# Outer bottom curve
	for i in range(curve_pts, -1, -1):
		var angle := PI + (float(i) / curve_pts) * PI
		verts.append(Vector2(
			cos(angle) * s * 0.5,
			s * 0.3 + sin(angle) * -(s * 0.5),
		))
	verts.append(Vector2(-s * 0.5, s * 0.5))
	return verts


func _make_letter_r(s: float) -> PackedVector2Array:
	var w := s * 0.25
	return PackedVector2Array([
		Vector2(-s * 0.4, -s * 0.7),
		Vector2(s * 0.2, -s * 0.7),
		Vector2(s * 0.5, -s * 0.4),
		Vector2(s * 0.5, -s * 0.1),
		Vector2(s * 0.2, s * 0.1),
		Vector2(s * 0.5, s * 0.7),
		Vector2(s * 0.5 - w, s * 0.7),
		Vector2(s * 0.1, s * 0.1),
		Vector2(-s * 0.4 + w, s * 0.1),
		Vector2(-s * 0.4 + w, s * 0.7),
		Vector2(-s * 0.4, s * 0.7),
	])


func _make_letter_b(s: float) -> PackedVector2Array:
	var w := s * 0.25
	return PackedVector2Array([
		Vector2(-s * 0.4, -s * 0.7),
		Vector2(s * 0.15, -s * 0.7),
		Vector2(s * 0.45, -s * 0.45),
		Vector2(s * 0.45, -s * 0.15),
		Vector2(s * 0.15, s * 0.05),
		Vector2(s * 0.5, s * 0.25),
		Vector2(s * 0.5, s * 0.5),
		Vector2(s * 0.15, s * 0.7),
		Vector2(-s * 0.4, s * 0.7),
		Vector2(-s * 0.4, s * 0.7 - w),
		Vector2(-s * 0.4 + w, s * 0.7 - w),
		Vector2(-s * 0.4 + w, -s * 0.7 + w),
		Vector2(-s * 0.4, -s * 0.7 + w),
	])


func _make_letter_o(s: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	var pts := 12
	for i in pts:
		var angle := (float(i) / pts) * TAU - PI / 2
		verts.append(Vector2(
			cos(angle) * s * 0.5,
			sin(angle) * s * 0.7,
		))
	return verts


func _make_pentagon(s: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in 5:
		var angle := (float(i) / 5.0) * TAU - PI / 2
		verts.append(Vector2(cos(angle) * s, sin(angle) * s))
	return verts


func _make_diamond_ring(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -s), Vector2(s * 0.7, -s * 0.3),
		Vector2(s, 0), Vector2(s * 0.7, s * 0.3),
		Vector2(0, s), Vector2(-s * 0.7, s * 0.3),
		Vector2(-s, 0), Vector2(-s * 0.7, -s * 0.3),
	])


func _make_six_star(s: float) -> PackedVector2Array:
	var verts := PackedVector2Array()
	for i in 12:
		var angle := (float(i) / 12.0) * TAU - PI / 2
		var r := s if i % 2 == 0 else s * 0.5
		verts.append(Vector2(cos(angle) * r, sin(angle) * r))
	return verts


func _make_jagged_tri(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -s),
		Vector2(s * 0.3, -s * 0.3),
		Vector2(s * 0.8, s * 0.2),
		Vector2(s * 0.3, s * 0.1),
		Vector2(0, s * 0.8),
		Vector2(-s * 0.3, s * 0.1),
		Vector2(-s * 0.8, s * 0.2),
		Vector2(-s * 0.3, -s * 0.3),
	])


func _make_double_chevron(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-s * 0.6, -s * 0.5),
		Vector2(-s * 0.1, 0),
		Vector2(-s * 0.6, s * 0.5),
		Vector2(-s * 0.3, s * 0.5),
		Vector2(s * 0.2, 0),
		Vector2(-s * 0.3, -s * 0.5),
	])
