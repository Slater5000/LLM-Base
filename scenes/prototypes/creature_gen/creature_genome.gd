class_name CreatureGenome
extends Resource
## The DNA of a procedurally generated creature.
## Encodes everything needed to render and animate the creature.
## Deterministic: same genome_seed → same creature every time.

# ═══════════════════════════════════════════════════════════
# ENUMS
# ═══════════════════════════════════════════════════════════

enum BodyPlan {
	QUADRUPED = 0,
	BIPED = 1,
	SERPENTINE = 2,
	CENTAUR = 3,
	INSECTOID = 4,
	BLOB = 5,
}

enum HeadType {
	ROUND = 0,
	SPIDER = 1,
	BEAK = 2,
	FLAT = 3,
}

enum FootType {
	POINT = 0,
	PAD = 1,
	CLAW = 2,
	HOOF = 3,
}

enum WingType {
	MEMBRANE = 0,
	INSECT = 1,
	FEATHERED = 2,
}

enum SizeClass {
	TINY = 0,
	SMALL = 1,
	MEDIUM = 2,
	LARGE = 3,
	TITAN = 4,
}

# ═══════════════════════════════════════════════════════════
# SIZE LOOKUP TABLES
# ═══════════════════════════════════════════════════════════

const SIZE_PX: Array[int] = [32, 48, 64, 80, 112]
const PPU_TABLE: Array[float] = [2.0, 2.5, 3.0, 3.5, 4.5]

# ═══════════════════════════════════════════════════════════
# GENOME DATA
# ═══════════════════════════════════════════════════════════

@export var genome_seed: int = 0
@export var body_plan: int = 0

# Spine
@export var spine_segment_count: int = 3
@export var spine_radii: PackedFloat32Array = PackedFloat32Array()
@export var spine_spacing: PackedFloat32Array = PackedFloat32Array()
@export var spine_positions: PackedVector2Array = PackedVector2Array()

# Limbs — each: {segment_index, type, bone_count, bone_lengths,
#   mirror, attach_angle, thickness, foot_type}
@export var limb_slots: Array[Dictionary] = []

# Head
@export var head_type: int = 0
@export var head_params: Dictionary = {}

# Tail
@export var tail_segments: int = 0
@export var tail_taper: float = 0.7

# Wings
@export var has_wings: bool = false
@export var wing_type: int = 0

# Appearance
@export var palette_seed: int = 0
@export var size_class: int = SizeClass.MEDIUM

# ═══════════════════════════════════════════════════════════
# ACCESSORS
# ═══════════════════════════════════════════════════════════

func get_tex_size() -> Vector2i:
	var px := SIZE_PX[clampi(size_class, 0, SIZE_PX.size() - 1)]
	return Vector2i(px, px)


func get_ppu() -> float:
	return PPU_TABLE[clampi(size_class, 0, PPU_TABLE.size() - 1)]


# ═══════════════════════════════════════════════════════════
# SERIALIZATION
# ═══════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	## Serialize to a JSON-friendly dictionary.
	var positions_arr: Array = []
	for pos: Vector2 in spine_positions:
		positions_arr.append([pos.x, pos.y])

	var limbs_arr: Array = []
	for slot: Dictionary in limb_slots:
		var slot_copy := slot.duplicate()
		# Convert PackedFloat32Array to plain Array for JSON
		if slot_copy.has("bone_lengths"):
			var lengths: Array = []
			for length: float in slot_copy["bone_lengths"]:
				lengths.append(length)
			slot_copy["bone_lengths"] = lengths
		limbs_arr.append(slot_copy)

	return {
		"genome_seed": genome_seed,
		"body_plan": body_plan,
		"spine_segment_count": spine_segment_count,
		"spine_radii": Array(spine_radii),
		"spine_spacing": Array(spine_spacing),
		"spine_positions": positions_arr,
		"limb_slots": limbs_arr,
		"head_type": head_type,
		"head_params": head_params.duplicate(),
		"tail_segments": tail_segments,
		"tail_taper": tail_taper,
		"has_wings": has_wings,
		"wing_type": wing_type,
		"palette_seed": palette_seed,
		"size_class": size_class,
	}


static func from_dict(d: Dictionary) -> CreatureGenome:
	## Deserialize from a dictionary.
	var g := CreatureGenome.new()
	g.genome_seed = d.get("genome_seed", 0)
	g.body_plan = d.get("body_plan", 0)
	g.spine_segment_count = d.get("spine_segment_count", 3)

	var radii_arr: Array = d.get("spine_radii", [])
	g.spine_radii = PackedFloat32Array(radii_arr)

	var spacing_arr: Array = d.get("spine_spacing", [])
	g.spine_spacing = PackedFloat32Array(spacing_arr)

	var pos_arr: Array = d.get("spine_positions", [])
	g.spine_positions = PackedVector2Array()
	for p: Array in pos_arr:
		g.spine_positions.append(Vector2(p[0], p[1]))

	var limbs_arr: Array = d.get("limb_slots", [])
	g.limb_slots = []
	for slot: Dictionary in limbs_arr:
		var slot_copy := slot.duplicate()
		if slot_copy.has("bone_lengths"):
			slot_copy["bone_lengths"] = PackedFloat32Array(
				slot_copy["bone_lengths"]
			)
		g.limb_slots.append(slot_copy)

	g.head_type = d.get("head_type", 0)
	g.head_params = d.get("head_params", {}).duplicate()
	g.tail_segments = d.get("tail_segments", 0)
	g.tail_taper = d.get("tail_taper", 0.7)
	g.has_wings = d.get("has_wings", false)
	g.wing_type = d.get("wing_type", 0)
	g.palette_seed = d.get("palette_seed", 0)
	g.size_class = d.get("size_class", SizeClass.MEDIUM)
	return g
