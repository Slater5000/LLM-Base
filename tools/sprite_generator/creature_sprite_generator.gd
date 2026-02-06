@tool
extends EditorScript
## Procedural Creature Sprite Generator
## Run from Editor > Run Script (Ctrl+Shift+X)
## Generates pixel art creature sprites with transparent backgrounds

const SPRITE_SIZE := 96
const OUTPUT_DIR := "res://assets/sprites/creatures/generated/"

# Element color palettes - Gen 4 style: base, shadow, highlight, accent
const PALETTES := {
	"fire": {
		"base": Color(0.95, 0.45, 0.2),
		"shadow": Color(0.7, 0.2, 0.1),
		"highlight": Color(1.0, 0.75, 0.4),
		"accent": Color(1.0, 0.95, 0.6),
		"outline": Color(0.3, 0.1, 0.05)
	},
	"water": {
		"base": Color(0.3, 0.55, 0.9),
		"shadow": Color(0.15, 0.3, 0.6),
		"highlight": Color(0.6, 0.8, 1.0),
		"accent": Color(0.85, 0.95, 1.0),
		"outline": Color(0.1, 0.15, 0.35)
	},
	"earth": {
		"base": Color(0.55, 0.75, 0.35),
		"shadow": Color(0.3, 0.45, 0.2),
		"highlight": Color(0.75, 0.9, 0.55),
		"accent": Color(0.6, 0.45, 0.3),
		"outline": Color(0.15, 0.25, 0.1)
	},
	"air": {
		"base": Color(0.85, 0.8, 0.95),
		"shadow": Color(0.6, 0.55, 0.75),
		"highlight": Color(1.0, 0.98, 1.0),
		"accent": Color(0.95, 0.9, 0.5),
		"outline": Color(0.35, 0.3, 0.45)
	}
}

# Body archetypes for variety
enum BodyType { BIPEDAL, QUADRUPED, SERPENT, BLOB, AVIAN }

var rng := RandomNumberGenerator.new()
var image: Image
var palette: Dictionary


func _run() -> void:
	print("=== Creature Sprite Generator ===")

	# Ensure output directory exists
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR.replace("res://", ProjectSettings.globalize_path("res://")))

	# Generate a batch of creatures
	var elements := ["fire", "water", "earth", "air"]
	var count := 0

	for element in elements:
		for i in range(3):  # 3 per element
			rng.seed = hash(element + str(i) + str(Time.get_unix_time_from_system()))
			var creature_name := _generate_name(element)
			_generate_creature(element, creature_name)
			count += 1

	print("Generated %d creature sprites in %s" % [count, OUTPUT_DIR])


func _generate_creature(element: String, creature_name: String) -> void:
	image = Image.create(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	palette = PALETTES[element]

	var body_type: BodyType = rng.randi() % BodyType.size()

	match body_type:
		BodyType.BIPEDAL:
			_draw_bipedal()
		BodyType.QUADRUPED:
			_draw_quadruped()
		BodyType.SERPENT:
			_draw_serpent()
		BodyType.BLOB:
			_draw_blob()
		BodyType.AVIAN:
			_draw_avian()

	# Add element-specific features
	_add_element_features(element)

	# Post-process: add outline
	_add_outline()

	# Add eyes (always last before save)
	_add_eyes()

	# Save
	var path := OUTPUT_DIR + creature_name.to_lower() + "_front.png"
	var global_path := ProjectSettings.globalize_path(path)
	image.save_png(global_path)
	print("  Created: %s (%s)" % [creature_name, BodyType.keys()[body_type]])


func _draw_bipedal() -> void:
	var center_x := SPRITE_SIZE / 2
	var ground_y := SPRITE_SIZE - 12

	# Legs
	var leg_width := rng.randi_range(4, 7)
	var leg_height := rng.randi_range(12, 20)
	var leg_spacing := rng.randi_range(6, 12)

	_draw_rect_shaded(center_x - leg_spacing - leg_width/2, ground_y - leg_height, leg_width, leg_height)
	_draw_rect_shaded(center_x + leg_spacing - leg_width/2, ground_y - leg_height, leg_width, leg_height)

	# Body
	var body_width := rng.randi_range(20, 32)
	var body_height := rng.randi_range(18, 28)
	var body_y := ground_y - leg_height - body_height + 4

	_draw_ellipse_shaded(center_x, body_y + body_height/2, body_width/2, body_height/2)

	# Head
	var head_size := rng.randi_range(14, 22)
	var head_y := body_y - head_size/2 + 2

	_draw_ellipse_shaded(center_x, head_y, head_size/2, head_size/2)

	# Arms (optional)
	if rng.randf() > 0.3:
		var arm_length := rng.randi_range(8, 14)
		var arm_width := rng.randi_range(3, 5)
		var arm_y := body_y + 6

		_draw_rect_shaded(center_x - body_width/2 - arm_length + 2, arm_y, arm_length, arm_width)
		_draw_rect_shaded(center_x + body_width/2 - 2, arm_y, arm_length, arm_width)

	# Tail (optional)
	if rng.randf() > 0.5:
		_draw_tail(center_x, ground_y - leg_height)


func _draw_quadruped() -> void:
	var center_x := SPRITE_SIZE / 2
	var ground_y := SPRITE_SIZE - 10

	# Four legs
	var leg_width := rng.randi_range(4, 6)
	var leg_height := rng.randi_range(10, 16)
	var body_length := rng.randi_range(28, 40)

	# Front legs
	_draw_rect_shaded(center_x - body_length/3, ground_y - leg_height, leg_width, leg_height)
	_draw_rect_shaded(center_x - body_length/3 + leg_width + 2, ground_y - leg_height, leg_width, leg_height)

	# Back legs
	_draw_rect_shaded(center_x + body_length/3 - leg_width - 2, ground_y - leg_height, leg_width, leg_height)
	_draw_rect_shaded(center_x + body_length/3, ground_y - leg_height, leg_width, leg_height)

	# Body (horizontal ellipse)
	var body_height := rng.randi_range(14, 20)
	var body_y := ground_y - leg_height - body_height/2 + 3

	_draw_ellipse_shaded(center_x, body_y, body_length/2, body_height/2)

	# Head
	var head_size := rng.randi_range(12, 18)
	var head_x := center_x - body_length/2 - head_size/3

	_draw_ellipse_shaded(head_x, body_y - 2, head_size/2, head_size/2)

	# Tail
	_draw_tail(center_x + body_length/2, body_y)


func _draw_serpent() -> void:
	var center_x := SPRITE_SIZE / 2
	var center_y := SPRITE_SIZE / 2 + 8

	# Coiled body segments
	var segments := rng.randi_range(4, 7)
	var base_radius := rng.randi_range(6, 10)

	for i in range(segments):
		var angle := i * TAU / segments + rng.randf_range(-0.3, 0.3)
		var dist := 12 + i * 3
		var seg_x := center_x + cos(angle) * dist
		var seg_y := center_y + sin(angle) * dist * 0.6
		var seg_radius := base_radius - i * 0.5

		_draw_ellipse_shaded(int(seg_x), int(seg_y), int(seg_radius), int(seg_radius))

	# Head (larger, at front)
	var head_size := base_radius + 4
	_draw_ellipse_shaded(center_x, center_y - 16, head_size, int(head_size * 0.9))


func _draw_blob() -> void:
	var center_x := SPRITE_SIZE / 2
	var ground_y := SPRITE_SIZE - 14

	# Main blob body
	var width := rng.randi_range(24, 36)
	var height := rng.randi_range(20, 32)

	_draw_ellipse_shaded(center_x, ground_y - height/2, width/2, height/2)

	# Bumps/protrusions
	var num_bumps := rng.randi_range(2, 5)
	for i in range(num_bumps):
		var angle := rng.randf_range(-PI * 0.8, PI * 0.8)
		var bump_x := center_x + cos(angle) * width/2 * 0.7
		var bump_y := ground_y - height/2 + sin(angle) * height/2 * 0.7
		var bump_size := rng.randi_range(5, 10)

		_draw_ellipse_shaded(int(bump_x), int(bump_y), bump_size, bump_size)


func _draw_avian() -> void:
	var center_x := SPRITE_SIZE / 2
	var ground_y := SPRITE_SIZE - 12

	# Thin legs
	var leg_height := rng.randi_range(12, 18)
	_draw_rect_shaded(center_x - 4, ground_y - leg_height, 2, leg_height)
	_draw_rect_shaded(center_x + 2, ground_y - leg_height, 2, leg_height)

	# Body
	var body_width := rng.randi_range(16, 24)
	var body_height := rng.randi_range(14, 20)
	var body_y := ground_y - leg_height - body_height/2

	_draw_ellipse_shaded(center_x, body_y, body_width/2, body_height/2)

	# Head
	var head_size := rng.randi_range(10, 16)
	_draw_ellipse_shaded(center_x, body_y - body_height/2 - head_size/3, head_size/2, head_size/2)

	# Wings
	var wing_width := rng.randi_range(14, 22)
	var wing_height := rng.randi_range(8, 12)

	# Left wing
	_draw_ellipse_shaded(center_x - body_width/2 - wing_width/3, body_y, wing_width/2, wing_height/2)
	# Right wing
	_draw_ellipse_shaded(center_x + body_width/2 + wing_width/3, body_y, wing_width/2, wing_height/2)

	# Tail feathers
	if rng.randf() > 0.3:
		var tail_length := rng.randi_range(10, 18)
		for i in range(3):
			var offset := (i - 1) * 4
			_draw_rect_shaded(center_x + offset - 1, body_y + body_height/2, 3, tail_length)


func _draw_tail(start_x: int, start_y: int) -> void:
	var segments := rng.randi_range(3, 6)
	var length := rng.randi_range(12, 24)
	var thickness := rng.randi_range(4, 8)

	var direction := 1 if rng.randf() > 0.5 else -1

	for i in range(segments):
		var t := float(i) / segments
		var seg_x := start_x + direction * int(t * length)
		var seg_y := start_y + int(sin(t * PI) * 8)
		var seg_size := int(thickness * (1.0 - t * 0.6))

		_draw_ellipse_shaded(seg_x, seg_y, seg_size, max(2, seg_size - 1))


func _add_element_features(element: String) -> void:
	match element:
		"fire":
			_add_flame_crest()
		"water":
			_add_fins()
		"earth":
			_add_crystals()
		"air":
			_add_wisps()


func _add_flame_crest() -> void:
	var col_accent: Color = palette.accent
	var col_highlight: Color = palette.highlight

	# Find top of creature
	var top_y := SPRITE_SIZE
	var top_x := SPRITE_SIZE / 2

	for y in range(SPRITE_SIZE):
		for x in range(SPRITE_SIZE):
			if image.get_pixel(x, y).a > 0:
				if y < top_y:
					top_y = y
					top_x = x
				break

	# Draw flame shapes above
	var flames := rng.randi_range(3, 5)
	for i in range(flames):
		var fx := top_x + rng.randi_range(-8, 8)
		var fy := top_y - rng.randi_range(4, 12)
		var fsize := rng.randi_range(3, 6)

		_draw_ellipse_colored(fx, fy, fsize, fsize + 2, col_accent)
		_draw_ellipse_colored(fx, fy + 1, fsize - 1, fsize, col_highlight)


func _add_fins() -> void:
	var col_highlight: Color = palette.highlight
	var col_base: Color = palette.base

	# Add fin on top
	var center_x := SPRITE_SIZE / 2
	var top_y := _find_top_y()

	# Dorsal fin
	var fin_height := rng.randi_range(6, 12)
	var fin_width := rng.randi_range(8, 14)

	for i in range(fin_height):
		var width_at_height := int(fin_width * (1.0 - float(i) / fin_height))
		for dx in range(-width_at_height/2, width_at_height/2):
			var px := center_x + dx
			var py := top_y - i
			if px >= 0 and px < SPRITE_SIZE and py >= 0 and py < SPRITE_SIZE:
				image.set_pixel(px, py, col_highlight if i < fin_height/2 else col_base)


func _add_crystals() -> void:
	var col_accent: Color = palette.accent

	# Add crystal protrusions
	var crystals := rng.randi_range(2, 4)

	for c in range(crystals):
		var angle := rng.randf_range(0, TAU)
		var cx := SPRITE_SIZE/2 + int(cos(angle) * rng.randi_range(15, 25))
		var cy := SPRITE_SIZE/2 + int(sin(angle) * rng.randi_range(10, 20))
		var size := rng.randi_range(4, 8)

		# Diamond shape
		for i in range(size):
			var width := size - i if i < size/2 else i - size/2
			for dx in range(-width, width + 1):
				var px := cx + dx
				var py := cy - size/2 + i
				if px >= 0 and px < SPRITE_SIZE and py >= 0 and py < SPRITE_SIZE:
					image.set_pixel(px, py, col_accent)


func _add_wisps() -> void:
	var col_highlight: Color = palette.highlight
	var wisp_color: Color = col_highlight.lerp(Color.WHITE, 0.5)

	# Add floating wisps around body
	var wisps := rng.randi_range(3, 6)

	for w in range(wisps):
		var angle := float(w) / wisps * TAU
		var dist := rng.randi_range(20, 32)
		var wx := SPRITE_SIZE/2 + int(cos(angle) * dist)
		var wy := SPRITE_SIZE/2 + int(sin(angle) * dist * 0.7)
		var size := rng.randi_range(2, 4)

		_draw_ellipse_colored(wx, wy, size, size, wisp_color)


func _add_outline() -> void:
	var outline_color: Color = palette.outline
	var temp_image := image.duplicate()

	for y in range(1, SPRITE_SIZE - 1):
		for x in range(1, SPRITE_SIZE - 1):
			if temp_image.get_pixel(x, y).a == 0:
				# Check if any neighbor has color
				var has_neighbor := false
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if temp_image.get_pixel(x + dx, y + dy).a > 0:
							has_neighbor = true
							break
					if has_neighbor:
						break

				if has_neighbor:
					image.set_pixel(x, y, outline_color)


func _add_eyes() -> void:
	# Find face area (upper portion of creature)
	var top_y := _find_top_y()
	var center_x := SPRITE_SIZE / 2

	# Eyes positioned in upper third
	var eye_y := top_y + rng.randi_range(6, 12)
	var eye_spacing := rng.randi_range(4, 10)
	var eye_size := rng.randi_range(2, 4)

	# White of eyes
	_draw_ellipse_colored(center_x - eye_spacing, eye_y, eye_size, eye_size, Color.WHITE)
	_draw_ellipse_colored(center_x + eye_spacing, eye_y, eye_size, eye_size, Color.WHITE)

	# Pupils
	image.set_pixel(center_x - eye_spacing, eye_y, Color.BLACK)
	image.set_pixel(center_x + eye_spacing, eye_y, Color.BLACK)

	# Highlight
	if eye_size >= 3:
		image.set_pixel(center_x - eye_spacing - 1, eye_y - 1, Color.WHITE)
		image.set_pixel(center_x + eye_spacing - 1, eye_y - 1, Color.WHITE)


func _find_top_y() -> int:
	for y in range(SPRITE_SIZE):
		for x in range(SPRITE_SIZE):
			if image.get_pixel(x, y).a > 0:
				return y
	return SPRITE_SIZE / 2


# Drawing primitives with shading

func _draw_rect_shaded(x: int, y: int, w: int, h: int) -> void:
	var col_highlight: Color = palette.highlight
	var col_shadow: Color = palette.shadow
	var col_base: Color = palette.base

	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and px < SPRITE_SIZE and py >= 0 and py < SPRITE_SIZE:
				var color: Color
				var ty := float(py - y) / h
				var tx := float(px - x) / w

				if ty < 0.3 and tx > 0.3 and tx < 0.7:
					color = col_highlight
				elif ty > 0.7 or tx < 0.2 or tx > 0.8:
					color = col_shadow
				else:
					color = col_base

				image.set_pixel(px, py, color)


func _draw_ellipse_shaded(cx: int, cy: int, rx: int, ry: int) -> void:
	var col_highlight: Color = palette.highlight
	var col_shadow: Color = palette.shadow
	var col_base: Color = palette.base

	for py in range(cy - ry, cy + ry + 1):
		for px in range(cx - rx, cx + rx + 1):
			if px >= 0 and px < SPRITE_SIZE and py >= 0 and py < SPRITE_SIZE:
				var dx: float = float(px - cx) / rx if rx > 0 else 0.0
				var dy: float = float(py - cy) / ry if ry > 0 else 0.0

				if dx * dx + dy * dy <= 1.0:
					var color: Color

					# Shading based on position (light from top-left)
					var shade: float = -dx * 0.3 - dy * 0.5

					if shade > 0.3:
						color = col_highlight
					elif shade < -0.3:
						color = col_shadow
					else:
						color = col_base

					image.set_pixel(px, py, color)


func _draw_ellipse_colored(cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for py in range(cy - ry, cy + ry + 1):
		for px in range(cx - rx, cx + rx + 1):
			if px >= 0 and px < SPRITE_SIZE and py >= 0 and py < SPRITE_SIZE:
				var dx: float = float(px - cx) / rx if rx > 0 else 0.0
				var dy: float = float(py - cy) / ry if ry > 0 else 0.0

				if dx * dx + dy * dy <= 1.0:
					image.set_pixel(px, py, color)


func _generate_name(element: String) -> String:
	var prefixes := {
		"fire": ["Blaz", "Pyr", "Scor", "Ember", "Flam", "Char"],
		"water": ["Aqua", "Tid", "Wav", "Splash", "Bub", "Rip"],
		"earth": ["Geo", "Ter", "Crys", "Bould", "Peb", "Grav"],
		"air": ["Zeph", "Gust", "Aer", "Breez", "Wind", "Sky"]
	}

	var suffixes := ["ix", "on", "us", "ara", "ling", "or", "ax", "is", "um"]

	var prefix: String = prefixes[element][rng.randi() % prefixes[element].size()]
	var suffix: String = suffixes[rng.randi() % suffixes.size()]

	return prefix + suffix
