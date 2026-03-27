extends Node2D
## Procedural creature sprite generator — Noita-style gritty pixel art.
## First test: spider-monkey with staff (32x32, medium tier).

# ── Creature definition ──────────────────────────────────────────
## Body plan for the spider-monkey: monkey torso + spider abdomen,
## 6 spider legs, 2 monkey arms (one holds staff), monkey head.

var sprite_size := Vector2i(32, 32)
var creature_image: Image
var creature_texture: ImageTexture
var anim_frames: Array[Image] = []
var anim_textures: Array[ImageTexture] = []
var current_frame := 0
var anim_timer := 0.0
var anim_speed := 0.15  # seconds per frame
var frame_count := 8

# Attack animation
var attack_frames: Array[Image] = []
var attack_textures: Array[ImageTexture] = []
var is_attacking := false
var attack_frame := 0
var attack_timer := 0.0
var attack_speed := 0.08
var attack_frame_count := 6

# Color palette — Noita-style earthy/organic with slight grit
var fur_color := Color(0.45, 0.30, 0.18)
var fur_dark := Color(0.30, 0.20, 0.10)
var fur_light := Color(0.55, 0.40, 0.25)
var belly_color := Color(0.55, 0.42, 0.30)
var spider_color := Color(0.25, 0.22, 0.18)
var spider_dark := Color(0.15, 0.12, 0.08)
var eye_color := Color(0.85, 0.70, 0.20)
var eye_pupil := Color(0.1, 0.05, 0.0)
var leg_color := Color(0.22, 0.18, 0.12)
var staff_wood := Color(0.50, 0.35, 0.15)
var staff_orb := Color(0.3, 0.8, 0.5)
var staff_glow := Color(0.4, 0.9, 0.6, 0.5)


func _ready() -> void:
	_generate_walk_frames()
	_generate_attack_frames()
	_update_info_label()


func _process(delta: float) -> void:
	if is_attacking:
		attack_timer += delta
		if attack_timer >= attack_speed:
			attack_timer -= attack_speed
			attack_frame += 1
			if attack_frame >= attack_frame_count:
				is_attacking = false
				attack_frame = 0
			queue_redraw()
	else:
		anim_timer += delta
		if anim_timer >= anim_speed:
			anim_timer -= anim_speed
			current_frame = (current_frame + 1) % frame_count
			queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_randomize_palette()
		_generate_walk_frames()
		_generate_attack_frames()
		_update_info_label()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_attacking = true
			attack_frame = 0
			attack_timer = 0.0


func _draw() -> void:
	# Draw at 1:1 pixel scale, camera zoom handles magnification
	var tex: ImageTexture
	if is_attacking and attack_frame < attack_textures.size():
		tex = attack_textures[attack_frame]
	elif current_frame < anim_textures.size():
		tex = anim_textures[current_frame]
	else:
		return

	var offset := -Vector2(sprite_size) / 2.0
	draw_texture(tex, offset)

	# Draw size reference grid
	var rect := Rect2(offset, Vector2(sprite_size))
	draw_rect(rect, Color(1, 1, 1, 0.15), false, 0.5)

	# Label
	var label_pos := offset + Vector2(0, sprite_size.y + 4)
	draw_string(
		ThemeDB.fallback_font, label_pos,
		"%dx%d Spider-Monkey" % [sprite_size.x, sprite_size.y],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.6)
	)


# ── GENERATION ─────────────────────────────────────────────────

func _generate_walk_frames() -> void:
	anim_frames.clear()
	anim_textures.clear()
	for f in range(frame_count):
		var img := _draw_creature_frame(f, frame_count, false)
		anim_frames.append(img)
		var tex := ImageTexture.create_from_image(img)
		anim_textures.append(tex)
	current_frame = 0
	queue_redraw()


func _generate_attack_frames() -> void:
	attack_frames.clear()
	attack_textures.clear()
	for f in range(attack_frame_count):
		var img := _draw_creature_frame(f, attack_frame_count, true)
		attack_frames.append(img)
		var tex := ImageTexture.create_from_image(img)
		attack_textures.append(tex)


func _draw_creature_frame(
	frame_idx: int, total_frames: int, attacking: bool
) -> Image:
	var img := Image.create(sprite_size.x, sprite_size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var cx := sprite_size.x / 2  # center x
	var phase := float(frame_idx) / float(total_frames) * TAU

	# Body bob from walk cycle
	var bob := int(sin(phase) * 1.0) if not attacking else 0

	# ── Spider abdomen (back, lower) ──
	_draw_ellipse(img, cx + 1, 20 + bob, 6, 5, spider_color)
	_draw_ellipse(img, cx + 1, 20 + bob, 4, 3, spider_dark)
	# Abdomen markings
	_set_px(img, cx, 18 + bob, fur_dark)
	_set_px(img, cx + 2, 19 + bob, fur_dark)
	_set_px(img, cx - 1, 20 + bob, fur_dark)

	# ── Monkey torso (front, upper) ──
	_draw_ellipse(img, cx, 14 + bob, 5, 4, fur_color)
	# Belly highlight
	_draw_ellipse(img, cx, 15 + bob, 3, 2, belly_color)
	# Fur texture — scattered dark pixels
	_set_px(img, cx - 3, 13 + bob, fur_dark)
	_set_px(img, cx + 2, 12 + bob, fur_dark)
	_set_px(img, cx - 1, 16 + bob, fur_dark)
	_set_px(img, cx + 3, 15 + bob, fur_dark)

	# ── Spider legs (6 total, 3 per side) ──
	for i in range(3):
		var leg_phase := phase + float(i) * TAU / 3.0
		var leg_y_base := 17 + i * 2 + bob
		var leg_swing := int(sin(leg_phase) * 2.0)

		# Left legs
		var lx := cx - 5 - i
		var ly := leg_y_base + leg_swing
		_draw_spider_leg(img, cx - 4, leg_y_base, lx - 3, ly + 2, leg_color)

		# Right legs
		var rx := cx + 5 + i
		var ry := leg_y_base - leg_swing
		_draw_spider_leg(img, cx + 4, leg_y_base, rx + 3, ry + 2, leg_color)

	# ── Monkey arms ──
	var arm_swing := int(sin(phase) * 2.0) if not attacking else 0

	# Left arm (non-staff hand)
	var la_x := cx - 5
	var la_y := 13 + bob + arm_swing
	_draw_line_px(img, cx - 4, 13 + bob, la_x, la_y, fur_color)
	_draw_line_px(img, la_x, la_y, la_x - 1, la_y + 2, fur_light)
	# Hand
	_set_px(img, la_x - 1, la_y + 2, belly_color)

	# Right arm (staff hand)
	var staff_swing := 0
	if attacking:
		# Staff swings forward in attack
		var at := float(frame_idx) / float(total_frames)
		if at < 0.3:
			staff_swing = int(at / 0.3 * -6.0)
		elif at < 0.5:
			staff_swing = -6 + int((at - 0.3) / 0.2 * 10.0)
		else:
			staff_swing = 4 - int((at - 0.5) / 0.5 * 4.0)

	var ra_x := cx + 5
	var ra_y := 13 + bob - arm_swing
	_draw_line_px(img, cx + 4, 13 + bob, ra_x, ra_y, fur_color)

	# ── Staff ──
	var staff_base_x := ra_x + 1
	var staff_base_y := ra_y + 1
	var staff_tip_x := staff_base_x + staff_swing
	var staff_tip_y := staff_base_y - 10
	_draw_line_px(img, staff_base_x, staff_base_y, staff_tip_x, staff_tip_y, staff_wood)
	# Staff orb
	_draw_ellipse(img, staff_tip_x, staff_tip_y - 1, 2, 2, staff_orb)
	# Glow pixel
	_set_px(img, staff_tip_x, staff_tip_y - 2, staff_glow)
	_set_px(img, staff_tip_x - 1, staff_tip_y - 1, staff_glow)
	_set_px(img, staff_tip_x + 1, staff_tip_y - 1, staff_glow)

	# ── Head ──
	_draw_ellipse(img, cx, 8 + bob, 4, 4, fur_color)
	# Face — lighter area
	_draw_ellipse(img, cx, 9 + bob, 2, 2, belly_color)

	# Eyes
	_set_px(img, cx - 2, 7 + bob, eye_color)
	_set_px(img, cx + 1, 7 + bob, eye_color)
	_set_px(img, cx - 2, 8 + bob, eye_pupil)
	_set_px(img, cx + 1, 8 + bob, eye_pupil)

	# Mouth
	_set_px(img, cx - 1, 10 + bob, fur_dark)
	_set_px(img, cx, 10 + bob, fur_dark)

	# Ears
	_set_px(img, cx - 4, 6 + bob, fur_color)
	_set_px(img, cx - 4, 5 + bob, fur_light)
	_set_px(img, cx + 3, 6 + bob, fur_color)
	_set_px(img, cx + 3, 5 + bob, fur_light)

	# ── Noita-style grit pass ──
	_apply_grit(img)

	return img


# ── DRAWING HELPERS ──────────────────────────────────────────────

func _set_px(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < sprite_size.x and y >= 0 and y < sprite_size.y:
		if img.get_pixel(x, y).a > 0.01:
			# Blend with existing
			var existing := img.get_pixel(x, y)
			img.set_pixel(x, y, existing.lerp(color, color.a))
		else:
			img.set_pixel(x, y, color)


func _set_px_overwrite(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < sprite_size.x and y >= 0 and y < sprite_size.y:
		img.set_pixel(x, y, color)


func _draw_ellipse(
	img: Image, cx: int, cy: int, rx: int, ry: int, color: Color
) -> void:
	for dy in range(-ry, ry + 1):
		for dx in range(-rx, rx + 1):
			var nx := float(dx) / float(rx) if rx > 0 else 0.0
			var ny := float(dy) / float(ry) if ry > 0 else 0.0
			if nx * nx + ny * ny <= 1.0:
				_set_px(img, cx + dx, cy + dy, color)


func _draw_line_px(
	img: Image, x0: int, y0: int, x1: int, y1: int, color: Color
) -> void:
	# Bresenham
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var cx := x0
	var cy := y0
	for _i in range(100):  # safety limit
		_set_px(img, cx, cy, color)
		if cx == x1 and cy == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			cx += sx
		if e2 <= dx:
			err += dx
			cy += sy


func _draw_spider_leg(
	img: Image, x0: int, y0: int, x1: int, y1: int, color: Color
) -> void:
	# Two-segment leg with a "knee" midpoint pushed outward
	var mx := (x0 + x1) / 2 + (x1 - x0) / 3
	var my := (y0 + y1) / 2 - 2  # knee bends up
	_draw_line_px(img, x0, y0, mx, my, color)
	_draw_line_px(img, mx, my, x1, y1, color)


func _apply_grit(img: Image) -> void:
	## Noita-style grit: slightly vary existing pixel colors for organic feel
	for y in range(sprite_size.y):
		for x in range(sprite_size.x):
			var c := img.get_pixel(x, y)
			if c.a < 0.01:
				continue
			# Subtle random brightness variation
			var v := randf_range(-0.06, 0.06)
			c.r = clampf(c.r + v, 0.0, 1.0)
			c.g = clampf(c.g + v, 0.0, 1.0)
			c.b = clampf(c.b + v, 0.0, 1.0)
			img.set_pixel(x, y, c)


func _randomize_palette() -> void:
	## Generate a new random color palette while keeping Noita feel
	var hue := randf()
	var sat := randf_range(0.3, 0.6)
	var val := randf_range(0.3, 0.5)

	fur_color = Color.from_hsv(hue, sat, val)
	fur_dark = Color.from_hsv(hue, sat + 0.1, val - 0.12)
	fur_light = Color.from_hsv(hue, sat - 0.1, val + 0.12)
	belly_color = Color.from_hsv(hue + 0.05, sat - 0.15, val + 0.15)

	var spider_hue := hue + randf_range(-0.1, 0.1)
	spider_color = Color.from_hsv(spider_hue, sat * 0.6, val * 0.7)
	spider_dark = Color.from_hsv(spider_hue, sat * 0.5, val * 0.4)

	leg_color = Color.from_hsv(spider_hue, sat * 0.5, val * 0.5)

	var orb_hue := randf()
	staff_orb = Color.from_hsv(orb_hue, 0.7, 0.8)
	staff_glow = Color.from_hsv(orb_hue, 0.5, 0.9, 0.5)

	eye_color = Color.from_hsv(randf_range(0.1, 0.2), 0.8, 0.85)


func _update_info_label() -> void:
	var label := get_node_or_null("../UI/Controls/InfoLabel")
	if label:
		label.text = (
			"Space = new palette\n"
			+ "Click = attack\n"
			+ "Size: %dx%d" % [sprite_size.x, sprite_size.y]
		)
