extends Area2D
## Fast-moving player bullet — cyan elongated bolt with subtle glow.
## Supports piercing, size scaling, and status effect application.

const MAX_RANGE_SQ := 250000.0  # 500px squared
const BULLET_COLOR := Color(0.7, 0.95, 1.0)
const GLOW_COLOR := Color(0.4, 0.7, 1.0, 0.2)
const CORE_COLOR := Color(1.0, 1.0, 1.0, 0.8)
const MID_GLOW_COLOR := Color(0.3, 0.6, 1.0, 0.12)
const OUTER_GLOW_COLOR := Color(0.2, 0.5, 1.0, 0.06)
const BASE_COLLISION_RADIUS := 2.0
const TRAIL_SPACING := 8.0
const TRAIL_DOTS := 6

var velocity := Vector2.ZERO
var speed := 300.0
var direction := Vector2.UP
var is_active := false
# Upgrade-driven stats (set per-activate by shmup_main)
var pierce_remaining := 0
var size_scale := 1.0
var burn_chance := 0.0
var freeze_chance := 0.0
var has_trail := false
var _start_pos := Vector2.ZERO
var _base_polygon := PackedVector2Array([
	Vector2(0, -4.5),
	Vector2(1.5, -1.0),
	Vector2(1.2, 3.0),
	Vector2(0, 3.5),
	Vector2(-1.2, 3.0),
	Vector2(-1.5, -1.0),
])

@onready var bullet_shape: Polygon2D = $BulletShape
@onready var collision_shape: CollisionShape2D = $CollisionShape


func _ready() -> void:
	_setup_visual()
	area_entered.connect(_on_area_entered)


func _setup_visual() -> void:
	bullet_shape.polygon = _base_polygon
	bullet_shape.color = BULLET_COLOR


func activate(
	pos: Vector2,
	dir: Vector2,
	p_pierce: int = 0,
	p_size_scale: float = 1.0,
	p_burn_chance: float = 0.0,
	p_freeze_chance: float = 0.0,
) -> void:
	position = pos
	_start_pos = pos
	direction = dir.normalized()
	velocity = direction * speed
	rotation = direction.angle() + PI / 2.0
	is_active = true
	visible = true

	# Set upgrade stats
	pierce_remaining = p_pierce
	size_scale = p_size_scale
	burn_chance = p_burn_chance
	freeze_chance = p_freeze_chance

	# Scale polygon and collision if needed
	if size_scale != 1.0:
		var scaled := PackedVector2Array()
		for v in _base_polygon:
			scaled.append(v * size_scale)
		bullet_shape.polygon = scaled
		var circ := collision_shape.shape as CircleShape2D
		circ.radius = BASE_COLLISION_RADIUS * size_scale
	else:
		bullet_shape.polygon = _base_polygon
		var circ := collision_shape.shape as CircleShape2D
		circ.radius = BASE_COLLISION_RADIUS

	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	queue_redraw()


func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2(-100, -100)
	# Reset stats
	pierce_remaining = 0
	size_scale = 1.0
	burn_chance = 0.0
	freeze_chance = 0.0
	has_trail = false


func _process(delta: float) -> void:
	if not is_active:
		return

	position += velocity * delta

	# Deactivate when too far from origin
	var dist_sq := position.distance_squared_to(_start_pos)
	if dist_sq > MAX_RANGE_SQ:
		deactivate()


func _draw() -> void:
	if not is_active:
		return
	# Railgun trail: fading dots behind bullet in local space
	if has_trail:
		for i in TRAIL_DOTS:
			var offset := TRAIL_SPACING * (i + 1) * size_scale
			var alpha := 0.3 - i * 0.04
			var r := (2.0 - i * 0.2) * size_scale
			var col := Color(0.7, 0.7, 0.9, alpha)
			draw_circle(Vector2(0, offset), r, col)
	# Outer glow layers (Nova Drift triple-layer technique)
	if size_scale > 1.5:
		var oc := Vector2(0, -0.5) * size_scale
		draw_circle(oc, 7.0 * size_scale, OUTER_GLOW_COLOR)
	if size_scale > 1.0:
		var mc := Vector2(0, -0.5) * size_scale
		draw_circle(mc, 5.5 * size_scale, MID_GLOW_COLOR)
	# Standard glow behind the bullet
	var gc := Vector2(0, -0.5) * size_scale
	draw_circle(gc, 4.0 * size_scale, GLOW_COLOR)
	# White core at tip
	var tc := Vector2(0, -2.5) * size_scale
	draw_circle(tc, 1.2 * size_scale, CORE_COLOR)


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	if area.is_in_group("enemies"):
		# Roll for status effects on the enemy
		if burn_chance > 0.0 and randf() < burn_chance:
			if area.has_method("apply_burn"):
				area.apply_burn()
		if freeze_chance > 0.0 and randf() < freeze_chance:
			if area.has_method("apply_freeze"):
				area.apply_freeze()

		# Piercing: pass through enemies instead of deactivating
		if pierce_remaining > 0:
			pierce_remaining -= 1
		else:
			deactivate()
