class_name NoiseTerrain
extends RefCounted
## Noise-based terrain generation using Godot's built-in FastNoiseLite.
##
## Use this for natural-looking grass patches, biome blending, forest density,
## encounter zones, and any terrain feature that should feel organic.
##
## Example usage:
##   var noise_gen = NoiseTerrain.new()
##   noise_gen.configure_grass_patches(0.05, 0.3, 0.6)
##   var value = noise_gen.sample(world_x, world_y)
##   if value > 0.6: place_tall_grass()
##   elif value > 0.3: place_short_grass()

# ============================================================================
# CONFIGURATION
# ============================================================================

## The underlying noise generator
var noise: FastNoiseLite

## Current seed (stored for debugging/display)
var current_seed: int = 0

## Presets for common use cases
enum NoisePreset {
	GRASS_PATCHES,      # Medium-sized organic patches
	BIOME_BLEND,        # Large smooth transitions
	FOREST_DENSITY,     # Varied tree density
	ENCOUNTER_ZONES,    # Hot spots for creatures
	DETAIL_SCATTER,     # Small decorations
	CUSTOM              # User-defined
}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _init(seed_value: int = 0) -> void:
	noise = FastNoiseLite.new()
	if seed_value == 0:
		randomize()
		seed_value = randi()
	set_seed(seed_value)

	# Default to grass patches preset
	apply_preset(NoisePreset.GRASS_PATCHES)


func set_seed(seed_value: int) -> void:
	current_seed = seed_value
	noise.seed = seed_value


## Apply a preset configuration
func apply_preset(preset: NoisePreset) -> void:
	match preset:
		NoisePreset.GRASS_PATCHES:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.frequency = 0.05
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
			noise.fractal_octaves = 3
			noise.fractal_lacunarity = 2.0
			noise.fractal_gain = 0.5

		NoisePreset.BIOME_BLEND:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.frequency = 0.015  # Very large features
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
			noise.fractal_octaves = 2
			noise.fractal_lacunarity = 2.0
			noise.fractal_gain = 0.5

		NoisePreset.FOREST_DENSITY:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.frequency = 0.03
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
			noise.fractal_octaves = 4
			noise.fractal_lacunarity = 2.0
			noise.fractal_gain = 0.4

		NoisePreset.ENCOUNTER_ZONES:
			noise.noise_type = FastNoiseLite.TYPE_CELLULAR
			noise.frequency = 0.04
			noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
			noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE

		NoisePreset.DETAIL_SCATTER:
			noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
			noise.frequency = 0.1  # Small features
			noise.fractal_type = FastNoiseLite.FRACTAL_FBM
			noise.fractal_octaves = 2
			noise.fractal_lacunarity = 2.0
			noise.fractal_gain = 0.5


## Custom configuration for fine-tuning
func configure(
	frequency: float = 0.05,
	octaves: int = 3,
	lacunarity: float = 2.0,
	gain: float = 0.5,
	noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
) -> void:
	noise.noise_type = noise_type
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	noise.fractal_lacunarity = lacunarity
	noise.fractal_gain = gain


## Configure specifically for grass patch distribution
func configure_grass_patches(frequency: float = 0.05, _low_threshold: float = 0.3, _high_threshold: float = 0.6) -> void:
	apply_preset(NoisePreset.GRASS_PATCHES)
	noise.frequency = frequency


# ============================================================================
# SAMPLING
# ============================================================================

## Get raw noise value at position (-1.0 to 1.0)
func sample_raw(x: float, y: float) -> float:
	return noise.get_noise_2d(x, y)


## Get normalized noise value (0.0 to 1.0)
func sample(x: float, y: float) -> float:
	return (noise.get_noise_2d(x, y) + 1.0) / 2.0


## Get noise value with domain warping for more organic shapes
func sample_warped(x: float, y: float, warp_strength: float = 20.0) -> float:
	# Use offset coordinates to get different values for x and y warp
	var warp_x := noise.get_noise_2d(x + 1000, y + 1000) * warp_strength
	var warp_y := noise.get_noise_2d(x + 2000, y + 2000) * warp_strength
	return sample(x + warp_x, y + warp_y)


## Check if position passes a threshold
func passes_threshold(x: float, y: float, threshold: float) -> bool:
	return sample(x, y) > threshold


## Get which tier a position falls into (for multi-level terrain)
## Returns index into thresholds array, or -1 if below all thresholds
func get_tier(x: float, y: float, thresholds: Array[float]) -> int:
	var value := sample(x, y)
	for i in range(thresholds.size() - 1, -1, -1):
		if value >= thresholds[i]:
			return i
	return -1


# ============================================================================
# BULK OPERATIONS
# ============================================================================

## Generate a 2D array of noise values
func generate_grid(width: int, height: int, scale: float = 1.0) -> Array[Array]:
	var grid: Array[Array] = []
	for x in range(width):
		var column: Array[float] = []
		for y in range(height):
			column.append(sample(x * scale, y * scale))
		grid.append(column)
	return grid


## Generate positions that pass a threshold
func generate_positions_above_threshold(
	bounds: Rect2,
	threshold: float,
	step: float = 1.0
) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var x := bounds.position.x
	while x < bounds.end.x:
		var y := bounds.position.y
		while y < bounds.end.y:
			if sample(x, y) > threshold:
				positions.append(Vector2(x, y))
			y += step
		x += step
	return positions


## Generate a density map (useful for debugging/visualization)
func generate_density_image(width: int, height: int, scale: float = 1.0) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_L8)
	for x in range(width):
		for y in range(height):
			var value := sample(x * scale, y * scale)
			var brightness := int(value * 255)
			image.set_pixel(x, y, Color8(brightness, brightness, brightness))
	return image


# ============================================================================
# GRASS PATCH HELPERS
# ============================================================================

## Result type for grass sampling
enum GrassType {
	NONE,
	SHORT,  # Low encounter rate
	TALL    # High encounter rate
}

## Sample grass type at position
func sample_grass(x: float, y: float, short_threshold: float = 0.3, tall_threshold: float = 0.6) -> GrassType:
	var value := sample(x, y)
	if value >= tall_threshold:
		return GrassType.TALL
	elif value >= short_threshold:
		return GrassType.SHORT
	return GrassType.NONE


## Check if position should have an encounter (with rarity modifier)
func should_have_encounter(x: float, y: float, base_rate: float = 0.1) -> bool:
	var grass := sample_grass(x, y)
	match grass:
		GrassType.TALL:
			return randf() < base_rate * 2.0
		GrassType.SHORT:
			return randf() < base_rate
		_:
			return false


# ============================================================================
# BIOME BLENDING
# ============================================================================

## Get blend factor between two biomes (0.0 = biome A, 1.0 = biome B)
func get_biome_blend(x: float, y: float) -> float:
	return sample(x, y)


## Get the dominant biome at position from a list
func get_dominant_biome(x: float, y: float, biome_count: int) -> int:
	var value := sample(x, y)
	return int(value * biome_count) % biome_count


# ============================================================================
# COMBINING MULTIPLE NOISE LAYERS
# ============================================================================

## Create a secondary noise generator with offset seed
func create_secondary(seed_offset: int = 100) -> NoiseTerrain:
	var secondary := NoiseTerrain.new(current_seed + seed_offset)
	return secondary


## Combine two noise values (multiply for intersection, max for union)
static func combine_multiply(a: float, b: float) -> float:
	return a * b


static func combine_max(a: float, b: float) -> float:
	return maxf(a, b)


static func combine_min(a: float, b: float) -> float:
	return minf(a, b)


static func combine_average(a: float, b: float) -> float:
	return (a + b) / 2.0
