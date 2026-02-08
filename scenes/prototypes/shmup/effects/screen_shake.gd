extends Camera2D
## Screen shake using trauma + noise system.
## Trauma decays over time, applied as camera offset via noise.

@export var max_offset := Vector2(8.0, 6.0)
@export var max_rotation := 0.03
@export var decay_rate := 3.0

var trauma := 0.0
var noise := FastNoiseLite.new()
var noise_y := 0.0


func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.5
	noise.seed = randi()


func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(trauma - decay_rate * delta, 0.0)
		_apply_shake()
	else:
		offset = Vector2.ZERO
		rotation = 0.0


func _apply_shake() -> void:
	var shake_intensity := trauma * trauma  # Quadratic for snappy feel
	noise_y += 1.0

	offset.x = max_offset.x * shake_intensity * noise.get_noise_2d(noise_y, 0.0)
	offset.y = max_offset.y * shake_intensity * noise.get_noise_2d(0.0, noise_y)
	rotation = max_rotation * shake_intensity * noise.get_noise_2d(noise_y, noise_y)


## Add trauma (0-1 range, clamped). Stacks additively.
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
