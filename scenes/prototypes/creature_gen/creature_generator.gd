class_name CreatureGenerator
## Factory that produces CreatureGenome instances from seeds.
## Every random decision uses a seeded RNG for determinism.


static func generate(p_seed: int = -1) -> CreatureGenome:
	## Generate a creature with a random body plan.
	if p_seed < 0:
		p_seed = randi()
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	var plan := rng.randi_range(0, 5)
	return _generate_internal(rng, plan, p_seed)


static func generate_from_plan(
	plan: int, p_seed: int = -1,
) -> CreatureGenome:
	## Generate a creature with a specific body plan.
	if p_seed < 0:
		p_seed = randi()
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed
	return _generate_internal(rng, plan, p_seed)


static func is_valid(genome: CreatureGenome) -> bool:
	## Validate a genome for structural correctness.
	if genome.body_plan < 0 or genome.body_plan > 5:
		return false
	if genome.spine_segment_count < 2 or genome.spine_segment_count > 8:
		return false
	var seg := genome.spine_segment_count
	if genome.spine_radii.size() != seg:
		return false
	if genome.spine_spacing.size() != seg - 1:
		return false
	if genome.spine_positions.size() != seg:
		return false
	# Check radii
	for i: int in genome.spine_radii.size():
		if genome.spine_radii[i] <= 0.0:
			return false
	# Check spacing
	for i: int in genome.spine_spacing.size():
		if genome.spine_spacing[i] <= 0.0:
			return false
	# Check adjacent radii ratio
	for i: int in range(1, genome.spine_radii.size()):
		var ratio := genome.spine_radii[i] / genome.spine_radii[i - 1]
		if ratio > 1.5 or ratio < 0.5:
			return false
	# Check limb slots
	for slot: Dictionary in genome.limb_slots:
		if not slot.has("segment_index"):
			return false
		if not slot.has("bone_count"):
			return false
		if not slot.has("bone_lengths"):
			return false
		var si: int = slot["segment_index"]
		if si < 0 or si >= seg:
			return false
		var bc: int = slot["bone_count"]
		if bc < 1 or bc > 4:
			return false
		var bl: PackedFloat32Array = slot["bone_lengths"]
		if bl.size() != bc:
			return false
		for length: float in bl:
			if length <= 0.0:
				return false
	# Check enums
	if genome.head_type < 0 or genome.head_type > 3:
		return false
	if genome.tail_segments < 0 or genome.tail_segments > 8:
		return false
	if genome.tail_taper < 0.3 or genome.tail_taper > 0.95:
		return false
	if genome.size_class < 0 or genome.size_class > 4:
		return false
	return true


# ═══════════════════════════════════════════════════════════
# INTERNAL GENERATION
# ═══════════════════════════════════════════════════════════

static func _generate_internal(
	rng: RandomNumberGenerator, plan: int, p_seed: int,
) -> CreatureGenome:
	var genome := CreatureGenome.new()
	genome.genome_seed = p_seed
	genome.body_plan = plan
	var tmpl := BodyPlanTemplates.get_template(plan)

	# Spine segment count
	genome.spine_segment_count = rng.randi_range(
		tmpl["min_segments"], tmpl["max_segments"],
	)
	var seg := genome.spine_segment_count

	# Size class (template default ±1)
	genome.size_class = clampi(
		int(tmpl["default_size_class"]) + rng.randi_range(-1, 1),
		0, 4,
	)

	# Spine radii from size curve
	genome.spine_radii = _roll_radii(rng, tmpl, seg, genome.size_class)

	# Spine spacing
	var base_sp: float = tmpl["base_spacing"]
	var spacing := PackedFloat32Array()
	for i: int in seg - 1:
		spacing.append(base_sp * rng.randf_range(0.8, 1.2))
	genome.spine_spacing = spacing

	# Spine positions from shape
	genome.spine_positions = _compute_spine_positions(
		tmpl["spine_shape"], seg, spacing, genome.spine_radii,
	)

	# Required limbs
	genome.limb_slots = []
	for limb_def: Dictionary in tmpl["required_limbs"]:
		_place_limb(rng, genome, limb_def)

	# Optional limbs (50% chance each)
	for limb_def: Dictionary in tmpl["optional_limbs"]:
		if rng.randf() < 0.5:
			_place_limb(rng, genome, limb_def)

	# Head
	var valid_heads: Array = tmpl["valid_head_types"]
	genome.head_type = valid_heads[
		rng.randi_range(0, valid_heads.size() - 1)
	]
	genome.head_params = _roll_head_params(rng, genome.head_type)

	# Tail
	if tmpl["has_tail"]:
		var tr: Vector2i = tmpl["tail_range"]
		if rng.randf() < 0.6:
			genome.tail_segments = rng.randi_range(tr.x, tr.y)
			genome.tail_taper = rng.randf_range(0.5, 0.9)
		else:
			genome.tail_segments = 0
	else:
		genome.tail_segments = 0

	# Wings
	if tmpl["has_wings"] and rng.randf() < 0.4:
		genome.has_wings = true
		genome.wing_type = rng.randi_range(0, 2)
	else:
		genome.has_wings = false

	# Palette
	genome.palette_seed = rng.randi()

	return genome


# ═══════════════════════════════════════════════════════════
# SPINE GENERATION
# ═══════════════════════════════════════════════════════════

static func _roll_radii(
	rng: RandomNumberGenerator, tmpl: Dictionary,
	seg_count: int, p_size_class: int,
) -> PackedFloat32Array:
	## Generate spine radii by sampling the size curve with variation.
	var curve: Array = tmpl["size_curve"]
	var size_mults: Array[float] = [0.6, 0.8, 1.0, 1.2, 1.6]
	var base_r: float = 1.5 * size_mults[p_size_class]
	var radii := PackedFloat32Array()

	for i: int in seg_count:
		var t := float(i) / maxf(float(seg_count - 1), 1.0)
		# Interpolate curve
		var ci := t * float(curve.size() - 1)
		var lo := int(ci)
		var hi := mini(lo + 1, curve.size() - 1)
		var frac := ci - float(lo)
		var curve_val: float = lerpf(curve[lo], curve[hi], frac)
		var variation := rng.randf_range(0.8, 1.2)
		radii.append(base_r * curve_val * variation)

	# Smooth: clamp adjacent difference to 30%
	for i: int in range(1, radii.size()):
		var ratio := radii[i] / radii[i - 1]
		if ratio > 1.3:
			radii[i] = radii[i - 1] * 1.3
		elif ratio < 0.7:
			radii[i] = radii[i - 1] * 0.7

	return radii


static func _compute_spine_positions(
	shape: String, seg_count: int,
	spacing: PackedFloat32Array, radii: PackedFloat32Array,
) -> PackedVector2Array:
	## Compute rest positions for spine segments based on shape.
	var positions := PackedVector2Array()

	match shape:
		"horizontal":
			var cursor_x := 0.0
			for i: int in seg_count:
				positions.append(Vector2(cursor_x, 0.0))
				if i < seg_count - 1:
					cursor_x += spacing[i] + radii[i] + radii[i + 1]
			_center_x(positions)

		"upright":
			var cursor_y := 0.0
			for i: int in seg_count:
				positions.append(Vector2(0.0, cursor_y))
				if i < seg_count - 1:
					cursor_y -= spacing[i] + radii[i] + radii[i + 1]

		"s_curve":
			var cursor_x := 0.0
			for i: int in seg_count:
				var t := float(i) / maxf(float(seg_count - 1), 1.0)
				var y_off := sin(t * PI * 1.5) * 0.8
				positions.append(Vector2(cursor_x, y_off))
				if i < seg_count - 1:
					cursor_x += spacing[i] + radii[i] + radii[i + 1]
			_center_x(positions)

		"l_shaped":
			var pivot := int(seg_count * 0.6)
			var cursor_x := 0.0
			var cursor_y := 0.0
			for i: int in seg_count:
				positions.append(Vector2(cursor_x, cursor_y))
				if i < seg_count - 1:
					var gap := spacing[i] + radii[i] + radii[i + 1]
					if i < pivot:
						cursor_x += gap
					else:
						cursor_y -= gap
						cursor_x += gap * 0.15
			_center_x(positions)

		"round":
			for i: int in seg_count:
				var angle := float(i) / float(seg_count) * TAU
				var dist := radii[0] * 0.5
				positions.append(Vector2(
					cos(angle) * dist, sin(angle) * dist,
				))

		_:
			for i: int in seg_count:
				positions.append(Vector2(float(i) * 2.0, 0.0))

	return positions


static func _center_x(positions: PackedVector2Array) -> void:
	## Center positions horizontally around x=0.
	if positions.is_empty():
		return
	var min_x := positions[0].x
	var max_x := positions[0].x
	for pos: Vector2 in positions:
		min_x = minf(min_x, pos.x)
		max_x = maxf(max_x, pos.x)
	var offset := (min_x + max_x) * 0.5
	for i: int in positions.size():
		positions[i].x -= offset


# ═══════════════════════════════════════════════════════════
# LIMB PLACEMENT
# ═══════════════════════════════════════════════════════════

static func _place_limb(
	rng: RandomNumberGenerator,
	genome: CreatureGenome,
	limb_def: Dictionary,
) -> void:
	## Place one limb group from a template definition.
	var seg_range: Vector2i = limb_def["segment_range"]
	var seg_min := clampi(seg_range.x, 0, genome.spine_segment_count - 1)
	var seg_max := clampi(seg_range.y, 0, genome.spine_segment_count - 1)
	var limb_count: int = limb_def["count"]

	for _i: int in limb_count:
		var seg_idx := rng.randi_range(seg_min, seg_max)
		var bc_range: Vector2i = limb_def["bone_count_range"]
		var bone_count := rng.randi_range(bc_range.x, bc_range.y)
		var bl_range: Vector2 = limb_def["bone_length_range"]
		var bone_lengths := PackedFloat32Array()
		for _b: int in bone_count:
			bone_lengths.append(rng.randf_range(bl_range.x, bl_range.y))
		var aa_range: Vector2 = limb_def["attach_angle_range"]

		genome.limb_slots.append({
			"segment_index": seg_idx,
			"type": limb_def["type"],
			"bone_count": bone_count,
			"bone_lengths": bone_lengths,
			"mirror": limb_def["mirror"],
			"attach_angle": rng.randf_range(aa_range.x, aa_range.y),
			"thickness": limb_def["thickness"],
			"foot_type": int(limb_def["foot_type"]),
		})


# ═══════════════════════════════════════════════════════════
# HEAD PARAMETERS
# ═══════════════════════════════════════════════════════════

static func _roll_head_params(
	rng: RandomNumberGenerator, p_head_type: int,
) -> Dictionary:
	## Roll head-specific parameters based on type.
	match p_head_type:
		CreatureGenome.HeadType.ROUND:
			return {
				"eye_count": rng.randi_range(1, 2),
				"eye_size": rng.randf_range(0.3, 0.6),
				"ear_size": rng.randf_range(0.0, 0.4),
				"mouth_width": rng.randf_range(0.3, 0.7),
			}
		CreatureGenome.HeadType.SPIDER:
			return {
				"eye_count": rng.randi_range(2, 6),
				"eye_size": rng.randf_range(0.25, 0.5),
				"mandible_length": rng.randf_range(0.5, 1.5),
				"mandible_count": rng.randi_range(1, 2),
				"has_fur_tufts": rng.randf() < 0.4,
			}
		CreatureGenome.HeadType.BEAK:
			return {
				"eye_count": rng.randi_range(1, 2),
				"eye_size": rng.randf_range(0.3, 0.5),
				"beak_length": rng.randf_range(0.8, 2.0),
				"beak_width": rng.randf_range(0.3, 0.6),
				"crest_height": rng.randf_range(0.0, 1.0),
			}
		CreatureGenome.HeadType.FLAT:
			return {
				"eye_count": rng.randi_range(1, 4),
				"eye_size": rng.randf_range(0.2, 0.4),
				"width_ratio": rng.randf_range(1.2, 2.0),
				"has_horns": rng.randf() < 0.3,
				"horn_count": rng.randi_range(1, 3),
			}
		_:
			return {"eye_count": 2, "eye_size": 0.4}
