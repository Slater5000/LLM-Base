class_name BodyPlanTemplates
## Static constraint data for each body plan type.
## Templates define valid ranges for spine, limbs, and features.


static func get_template(plan_type: int) -> Dictionary:
	## Return the constraint template for a body plan type.
	match plan_type:
		CreatureGenome.BodyPlan.QUADRUPED:
			return _quadruped()
		CreatureGenome.BodyPlan.BIPED:
			return _biped()
		CreatureGenome.BodyPlan.SERPENTINE:
			return _serpentine()
		CreatureGenome.BodyPlan.CENTAUR:
			return _centaur()
		CreatureGenome.BodyPlan.INSECTOID:
			return _insectoid()
		CreatureGenome.BodyPlan.BLOB:
			return _blob()
		_:
			return _quadruped()


static func _quadruped() -> Dictionary:
	return {
		"min_segments": 4,
		"max_segments": 6,
		"base_spacing": 1.8,
		"size_curve": [0.5, 0.7, 1.0, 0.9, 0.7, 0.5],
		"spine_shape": "horizontal",
		"required_limbs": [
			{
				"segment_range": Vector2i(1, 2),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.2, 2.0),
				"attach_angle_range": Vector2(-0.3, 0.3),
				"foot_type": CreatureGenome.FootType.PAD,
				"thickness": 1.0,
			},
			{
				"segment_range": Vector2i(3, 5),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.2, 2.0),
				"attach_angle_range": Vector2(-0.3, 0.3),
				"foot_type": CreatureGenome.FootType.PAD,
				"thickness": 1.0,
			},
		],
		"optional_limbs": [
			{
				"segment_range": Vector2i(0, 0),
				"type": "antenna",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 3),
				"bone_length_range": Vector2(0.5, 1.0),
				"attach_angle_range": Vector2(-1.2, -0.5),
				"foot_type": CreatureGenome.FootType.POINT,
				"thickness": 0.5,
			},
		],
		"has_tail": true,
		"tail_range": Vector2i(2, 5),
		"has_wings": false,
		"valid_head_types": [
			CreatureGenome.HeadType.ROUND,
			CreatureGenome.HeadType.FLAT,
		],
		"default_size_class": CreatureGenome.SizeClass.MEDIUM,
	}


static func _biped() -> Dictionary:
	return {
		"min_segments": 3,
		"max_segments": 4,
		"base_spacing": 2.0,
		"size_curve": [0.6, 1.0, 0.8, 0.6],
		"spine_shape": "upright",
		"required_limbs": [
			{
				"segment_range": Vector2i(0, 0),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 3),
				"bone_length_range": Vector2(1.5, 2.5),
				"attach_angle_range": Vector2(-0.2, 0.2),
				"foot_type": CreatureGenome.FootType.PAD,
				"thickness": 1.2,
			},
			{
				"segment_range": Vector2i(2, 3),
				"type": "arm",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.0, 1.8),
				"attach_angle_range": Vector2(0.3, 1.0),
				"foot_type": CreatureGenome.FootType.POINT,
				"thickness": 0.8,
			},
		],
		"optional_limbs": [],
		"has_tail": true,
		"tail_range": Vector2i(1, 3),
		"has_wings": false,
		"valid_head_types": [
			CreatureGenome.HeadType.ROUND,
			CreatureGenome.HeadType.BEAK,
			CreatureGenome.HeadType.FLAT,
		],
		"default_size_class": CreatureGenome.SizeClass.MEDIUM,
	}


static func _serpentine() -> Dictionary:
	return {
		"min_segments": 6,
		"max_segments": 8,
		"base_spacing": 1.2,
		"size_curve": [0.7, 0.9, 1.0, 1.0, 0.9, 0.8, 0.6, 0.4],
		"spine_shape": "s_curve",
		"required_limbs": [],
		"optional_limbs": [],
		"has_tail": true,
		"tail_range": Vector2i(2, 4),
		"has_wings": false,
		"valid_head_types": [
			CreatureGenome.HeadType.ROUND,
			CreatureGenome.HeadType.FLAT,
		],
		"default_size_class": CreatureGenome.SizeClass.MEDIUM,
	}


static func _centaur() -> Dictionary:
	return {
		"min_segments": 5,
		"max_segments": 7,
		"base_spacing": 1.6,
		"size_curve": [0.6, 0.8, 1.0, 0.7, 0.9, 0.8, 0.6],
		"spine_shape": "l_shaped",
		"required_limbs": [
			{
				"segment_range": Vector2i(1, 2),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.2, 2.0),
				"attach_angle_range": Vector2(-0.2, 0.2),
				"foot_type": CreatureGenome.FootType.CLAW,
				"thickness": 1.0,
			},
			{
				"segment_range": Vector2i(3, 4),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.2, 2.0),
				"attach_angle_range": Vector2(-0.2, 0.2),
				"foot_type": CreatureGenome.FootType.CLAW,
				"thickness": 1.0,
			},
			{
				"segment_range": Vector2i(4, 6),
				"type": "arm",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(0.8, 1.5),
				"attach_angle_range": Vector2(0.3, 1.0),
				"foot_type": CreatureGenome.FootType.POINT,
				"thickness": 0.8,
			},
		],
		"optional_limbs": [],
		"has_tail": true,
		"tail_range": Vector2i(2, 5),
		"has_wings": true,
		"valid_head_types": [
			CreatureGenome.HeadType.ROUND,
			CreatureGenome.HeadType.SPIDER,
			CreatureGenome.HeadType.BEAK,
		],
		"default_size_class": CreatureGenome.SizeClass.LARGE,
	}


static func _insectoid() -> Dictionary:
	return {
		"min_segments": 3,
		"max_segments": 4,
		"base_spacing": 1.5,
		"size_curve": [0.5, 0.8, 1.0, 0.7],
		"spine_shape": "horizontal",
		"required_limbs": [
			{
				"segment_range": Vector2i(0, 1),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.0, 1.8),
				"attach_angle_range": Vector2(-0.5, 0.0),
				"foot_type": CreatureGenome.FootType.CLAW,
				"thickness": 0.8,
			},
			{
				"segment_range": Vector2i(1, 1),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.0, 1.8),
				"attach_angle_range": Vector2(-0.2, 0.3),
				"foot_type": CreatureGenome.FootType.CLAW,
				"thickness": 0.8,
			},
			{
				"segment_range": Vector2i(1, 2),
				"type": "leg",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 2),
				"bone_length_range": Vector2(1.0, 1.8),
				"attach_angle_range": Vector2(0.0, 0.5),
				"foot_type": CreatureGenome.FootType.CLAW,
				"thickness": 0.8,
			},
		],
		"optional_limbs": [
			{
				"segment_range": Vector2i(0, 0),
				"type": "antenna",
				"count": 1,
				"mirror": true,
				"bone_count_range": Vector2i(2, 3),
				"bone_length_range": Vector2(0.5, 1.2),
				"attach_angle_range": Vector2(-1.5, -0.8),
				"foot_type": CreatureGenome.FootType.POINT,
				"thickness": 0.4,
			},
		],
		"has_tail": false,
		"tail_range": Vector2i(0, 0),
		"has_wings": true,
		"valid_head_types": [
			CreatureGenome.HeadType.ROUND,
			CreatureGenome.HeadType.SPIDER,
		],
		"default_size_class": CreatureGenome.SizeClass.SMALL,
	}


static func _blob() -> Dictionary:
	return {
		"min_segments": 2,
		"max_segments": 3,
		"base_spacing": 1.0,
		"size_curve": [1.0, 0.8, 0.6],
		"spine_shape": "round",
		"required_limbs": [],
		"optional_limbs": [
			{
				"segment_range": Vector2i(0, 1),
				"type": "pseudopod",
				"count": 2,
				"mirror": false,
				"bone_count_range": Vector2i(1, 2),
				"bone_length_range": Vector2(0.8, 1.5),
				"attach_angle_range": Vector2(-PI, PI),
				"foot_type": CreatureGenome.FootType.POINT,
				"thickness": 0.6,
			},
		],
		"has_tail": false,
		"tail_range": Vector2i(0, 0),
		"has_wings": false,
		"valid_head_types": [
			CreatureGenome.HeadType.ROUND,
			CreatureGenome.HeadType.FLAT,
		],
		"default_size_class": CreatureGenome.SizeClass.SMALL,
	}
