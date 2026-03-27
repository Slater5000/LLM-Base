class_name CreaturePalette
extends Resource
## Per-creature color palette with named slots and ramp generation.
## Colors are organized by material role, not body part.

@export var primary: Color = Color(0.50, 0.35, 0.20)
@export var secondary: Color = Color(0.15, 0.12, 0.08)
@export var belly: Color = Color(0.60, 0.48, 0.35)
@export var limb: Color = Color(0.55, 0.45, 0.12)
@export var eye: Color = Color(0.80, 0.20, 0.10)
@export var eye_pupil: Color = Color(0.08, 0.02, 0.0)
@export var accent: Color = Color(0.30, 0.80, 0.50)
@export var accent_glow: Color = Color(0.40, 0.90, 0.60, 0.6)

# Cached ramps (built on demand)
var _ramps: Dictionary = {}


func get_ramp(slot: String) -> Array:
	## Get a 5-color shading ramp for a named slot.
	## Valid slots: primary, secondary, belly, limb, accent.
	if _ramps.is_empty():
		build_ramps()
	return _ramps.get(slot, _ramps["primary"])


func get_ramp_dimmed(slot: String, factor: float) -> Array:
	## Get a dimmed ramp for far-side depth cue.
	return CreaturePixelUtils.dim_ramp(get_ramp(slot), factor)


func build_ramps() -> void:
	## Generate all ramps from base colors.
	_ramps = {
		"primary": CreaturePixelUtils.make_ramp(primary),
		"secondary": CreaturePixelUtils.make_ramp(secondary),
		"belly": CreaturePixelUtils.make_ramp(belly),
		"limb": CreaturePixelUtils.make_ramp(limb),
		"accent": CreaturePixelUtils.make_ramp(accent),
	}


# ═══════════════════════════════════════════════════════════
# STATIC FACTORIES
# ═══════════════════════════════════════════════════════════

static func create_from_seed(seed_val: int) -> CreaturePalette:
	## Deterministic palette from a seed integer.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var base_hue := rng.randf()
	var sat := rng.randf_range(0.35, 0.65)
	var val := rng.randf_range(0.30, 0.55)
	return _build_from_hsv(base_hue, sat, val, rng)


static func create_random() -> CreaturePalette:
	## Fully random palette.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var base_hue := rng.randf()
	var sat := rng.randf_range(0.35, 0.65)
	var val := rng.randf_range(0.30, 0.55)
	return _build_from_hsv(base_hue, sat, val, rng)


static func create_warm(seed_val: int = -1) -> CreaturePalette:
	## Warm-toned palette (reds, oranges, browns).
	var rng := RandomNumberGenerator.new()
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()
	var base_hue := rng.randf_range(0.02, 0.12)
	var sat := rng.randf_range(0.40, 0.65)
	var val := rng.randf_range(0.30, 0.50)
	return _build_from_hsv(base_hue, sat, val, rng)


static func create_cool(seed_val: int = -1) -> CreaturePalette:
	## Cool-toned palette (blues, purples, teals).
	var rng := RandomNumberGenerator.new()
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()
	var base_hue := rng.randf_range(0.55, 0.80)
	var sat := rng.randf_range(0.30, 0.55)
	var val := rng.randf_range(0.22, 0.40)
	return _build_from_hsv(base_hue, sat, val, rng)


static func _build_from_hsv(
	hue: float, sat: float, val: float,
	rng: RandomNumberGenerator,
) -> CreaturePalette:
	## Internal builder: generates all palette slots from base HSV.
	var pal := CreaturePalette.new()
	pal.primary = Color.from_hsv(hue, sat, val)
	pal.secondary = Color.from_hsv(
		fposmod(hue + 0.02, 1.0), sat * 0.5, val * 0.55,
	)
	pal.belly = Color.from_hsv(
		fposmod(hue + 0.04, 1.0),
		maxf(sat - 0.20, 0.1), minf(val + 0.20, 0.9),
	)
	# Limbs: yellow-amber tones (spider legs)
	pal.limb = Color.from_hsv(
		rng.randf_range(0.10, 0.15),
		rng.randf_range(0.50, 0.70),
		rng.randf_range(0.40, 0.60),
	)
	# Eye: high saturation accent
	var eye_hue := rng.randf_range(0.0, 0.08)
	pal.eye = Color.from_hsv(eye_hue, 0.82, 0.82)
	pal.eye_pupil = Color(0.08, 0.02, 0.0)
	# Accent: complementary or analogous
	var accent_hue := rng.randf()
	pal.accent = Color.from_hsv(accent_hue, 0.65, 0.80)
	pal.accent_glow = Color.from_hsv(accent_hue, 0.40, 0.90, 0.6)
	return pal
