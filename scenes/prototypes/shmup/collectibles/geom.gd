extends Area2D
## XP Geom — dropped by enemies, grants XP toward level-ups.

signal collected(xp: int)

const GEOM_COLOR := Color(0.5, 1.0, 0.7)
const GEOM_COLOR_LARGE := Color(0.7, 1.0, 0.85)

var xp_value := 1
var is_large := false
var is_active := false
var fade_timer := 15.0
var magnetic_range := 35.0
var magnetic_speed := 200.0
var target: Node2D  # Player

@onready var geom_polygon: Polygon2D = $GeomPolygon


func _ready() -> void:
	add_to_group("geoms")
	area_entered.connect(_on_area_entered)
	_setup_visual()


func _setup_visual() -> void:
	var s := 3.0 if not is_large else 5.0
	geom_polygon.polygon = PackedVector2Array([
		Vector2(0, -s), Vector2(s * 0.6, 0), Vector2(0, s), Vector2(-s * 0.6, 0)
	])
	geom_polygon.color = GEOM_COLOR_LARGE if is_large else GEOM_COLOR


func activate(pos: Vector2, player: Node2D, large: bool = false, value: int = 1) -> void:
	position = pos
	target = player
	is_large = large
	xp_value = 5 if large else value
	is_active = true
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	fade_timer = 15.0
	modulate.a = 1.0
	_setup_visual()

	# Collision shape — update size on each activation (reuse existing)
	var col: CollisionShape2D
	if has_node("CollisionShape"):
		col = get_node("CollisionShape")
	else:
		col = CollisionShape2D.new()
		col.name = "CollisionShape"
		add_child(col)
	var radius := 5.0 if is_large else 3.0
	if col.shape is CircleShape2D:
		col.shape.radius = radius
	else:
		var circle := CircleShape2D.new()
		circle.radius = radius
		col.shape = circle


func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2(-100, -100)


func _process(delta: float) -> void:
	if not is_active:
		return

	# Rotation
	rotation += delta * 3.0

	# Magnetic pull toward player
	if target and target.get("is_alive"):
		var dist := position.distance_to(target.position)
		if dist < magnetic_range:
			var pull := (target.position - position).normalized()
			position += pull * magnetic_speed * delta

	# Fade timer
	fade_timer -= delta
	if fade_timer < 3.0:
		# Blink when about to fade
		modulate.a = 0.3 + 0.7 * absf(sin(fade_timer * 8.0))
	if fade_timer <= 0.0:
		deactivate()


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	if area.is_in_group("player"):
		collected.emit(xp_value)
		deactivate()
