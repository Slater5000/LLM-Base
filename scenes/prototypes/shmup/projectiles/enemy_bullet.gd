extends Area2D
## Enemy bullet — hot pink elongated capsule with white core and triple-layer glow.
## Designed for maximum visibility: unmistakable "dodge this" signal.
## Hot pink is RESERVED exclusively for enemy projectiles — nothing else uses it.

const MAX_RANGE_SQ := 250000.0  # 500px squared

# Hot pink color palette — reserved for enemy bullets only
const CORE_COLOR := Color(1.0, 1.0, 1.0, 0.95)          # White core
const BODY_COLOR := Color(1.0, 0.13, 0.5)                # Hot pink body
const GLOW_TIGHT := Color(1.0, 0.2, 0.55, 0.45)          # Tight glow
const GLOW_MEDIUM := Color(1.0, 0.15, 0.5, 0.2)          # Medium glow
const GLOW_DIFFUSE := Color(1.0, 0.1, 0.45, 0.12)        # Diffuse glow
const EDGE_COLOR := Color(0.4, 0.03, 0.15)               # Dark magenta edge

var velocity := Vector2.ZERO
var speed := 130.0
var direction := Vector2.UP
var is_active := false
var _start_pos := Vector2.ZERO
var _pulse_time := 0.0

@onready var bullet_shape: Polygon2D = $BulletShape


func _ready() -> void:
	add_to_group("enemy_bullets")
	_setup_visual()
	area_entered.connect(_on_area_entered)
	z_index = 10  # Render above enemies and most VFX


func _setup_visual() -> void:
	# Elongated capsule/teardrop — 8px long x 3.5px wide
	# Pointed end leads (negative Y = forward when rotation matches direction)
	bullet_shape.polygon = PackedVector2Array([
		Vector2(0, -5.0),      # Pointed tip (leading edge)
		Vector2(2.0, -2.0),    # Right shoulder
		Vector2(2.0, 2.5),     # Right body
		Vector2(1.2, 4.0),     # Right tail taper
		Vector2(0, 4.5),       # Tail center
		Vector2(-1.2, 4.0),    # Left tail taper
		Vector2(-2.0, 2.5),    # Left body
		Vector2(-2.0, -2.0),   # Left shoulder
	])
	bullet_shape.color = BODY_COLOR


func activate(pos: Vector2, dir: Vector2) -> void:
	position = pos
	_start_pos = pos
	direction = dir.normalized()
	velocity = direction * speed
	rotation = direction.angle() + PI / 2.0  # Orient along velocity
	is_active = true
	visible = true
	_pulse_time = randf() * TAU  # Random phase so bullets don't pulse in sync
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)


func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2(-100, -100)


func _process(delta: float) -> void:
	if not is_active:
		return

	position += velocity * delta

	# Pulse animation (5 Hz) — much more visible than spinning
	_pulse_time += delta * 31.4  # 5 Hz * TAU
	if Engine.get_process_frames() % 2 == 0:
		queue_redraw()

	if position.distance_squared_to(_start_pos) > MAX_RANGE_SQ:
		deactivate()


func _draw() -> void:
	if not is_active:
		return

	var pulse := 0.9 + sin(_pulse_time) * 0.1  # 0.8 to 1.0 scale

	# Layer 1: Diffuse glow (large, faint circle)
	draw_circle(Vector2.ZERO, 10.0 * pulse, GLOW_DIFFUSE)

	# Layer 2: Medium glow (elongated, moderate brightness)
	draw_circle(Vector2(0, -0.5), 6.0 * pulse, GLOW_MEDIUM)

	# Layer 3: Tight glow (follows bullet shape closely)
	draw_circle(Vector2(0, -0.5), 4.0, GLOW_TIGHT)

	# Layer 4: Bright white core (the eye-catcher)
	var core_alpha := 0.85 + sin(_pulse_time) * 0.15  # Pulses 0.7 to 1.0
	var core := CORE_COLOR
	core.a = core_alpha
	draw_circle(Vector2(0, -1.5), 2.0, core)


func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	if area.is_in_group("player"):
		deactivate()


