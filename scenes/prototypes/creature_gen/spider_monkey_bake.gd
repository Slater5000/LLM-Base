extends Node2D
## Spy Kids 2-inspired spider-monkey: centaur body plan.
## Ape upper body rises from spider lower body. Spider head with
## multiple eyes and mandibles. Dead Cells shading pipeline.

# Square frame for vertical centaur proportions
const TEX_W: int = 80
const TEX_H: int = 80
const TEX_CX: float = 40.0
const TEX_CY: float = 43.0
const TEX_PPU: float = 3.5
const FRAME_COUNT: int = 8

# Light direction (top-left)
const LT_X := -0.4
const LT_Y := -0.4

@export var creature_scale := 1.5
@export var facing_left := false
@export var walk_speed := 5.0
@export var phase_offset := 0.0

# Palette — base colors (ramps auto-generated)
@export var fur_color := Color(0.50, 0.35, 0.20)
@export var fur_outline := Color(0.60, 0.45, 0.28)
@export var spider_color := Color(0.15, 0.12, 0.08)
@export var spider_outline := Color(0.25, 0.20, 0.14)
@export var belly_color := Color(0.60, 0.48, 0.35)
@export var eye_color := Color(0.80, 0.20, 0.10)
@export var eye_pupil := Color(0.08, 0.02, 0.0)
@export var leg_color := Color(0.55, 0.45, 0.12)
@export var leg_outline := Color(0.35, 0.28, 0.08)
@export var staff_wood := Color(0.50, 0.35, 0.15)
@export var staff_orb := Color(0.3, 0.8, 0.5)
@export var staff_glow := Color(0.4, 0.9, 0.6, 0.6)

var _texture: ImageTexture
var _sprite: Sprite2D
var _anim_time := 0.0
var _current_frame := 0

# Color ramps: [outline, shadow, base, highlight, rim]
var _fur_ramp: Array
var _spider_ramp: Array
var _belly_ramp: Array
var _leg_ramp: Array
var _staff_ramp: Array
var _orb_ramp: Array


func _ready() -> void:
	_anim_time = phase_offset
	_build_ramps()
	_bake_atlas()
	_setup_sprite()


func _process(delta: float) -> void:
	_anim_time += delta
	var phase := fmod(_anim_time * walk_speed, TAU)
	if phase < 0.0:
		phase += TAU
	var new_frame := clampi(
		int(phase / TAU * float(FRAME_COUNT)),
		0, FRAME_COUNT - 1,
	)
	if new_frame != _current_frame:
		_current_frame = new_frame
		_update_sprite()


func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = _texture
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(0, 0, TEX_W, TEX_H)
	_sprite.scale = Vector2(
		creature_scale * (-1.0 if facing_left else 1.0),
		creature_scale,
	)
	add_child(_sprite)


func _update_sprite() -> void:
	if not _sprite:
		return
	_sprite.region_rect = Rect2(
		_current_frame * TEX_W, 0, TEX_W, TEX_H,
	)
	_sprite.scale = Vector2(
		creature_scale * (-1.0 if facing_left else 1.0),
		creature_scale,
	)


# ═══════════════════════════════════════════════════════════
# COLOR RAMPS — hue-shifted Dead Cells shading
# ═══════════════════════════════════════════════════════════

func _build_ramps() -> void:
	_fur_ramp = _make_ramp(fur_color)
	_spider_ramp = _make_ramp(spider_color)
	_belly_ramp = _make_ramp(belly_color)
	_leg_ramp = _make_ramp(leg_color)
	_staff_ramp = _make_ramp(staff_wood)
	_orb_ramp = _make_ramp(staff_orb)


func _make_ramp(base: Color) -> Array:
	var h := base.h
	var s := base.s
	var v := base.v
	return [
		Color.from_hsv(
			fposmod(h + 0.06, 1.0),
			clampf(s + 0.15, 0.0, 1.0),
			clampf(v - 0.25, 0.05, 1.0),
		),
		Color.from_hsv(
			fposmod(h + 0.03, 1.0),
			clampf(s + 0.08, 0.0, 1.0),
			clampf(v - 0.12, 0.05, 1.0),
		),
		base,
		Color.from_hsv(
			fposmod(h - 0.03, 1.0),
			clampf(s - 0.08, 0.0, 1.0),
			clampf(v + 0.15, 0.0, 1.0),
		),
		Color.from_hsv(
			fposmod(h - 0.06, 1.0),
			clampf(s - 0.18, 0.0, 1.0),
			clampf(v + 0.32, 0.0, 1.0),
		),
	]


func _dim_ramp(ramp: Array, factor: float) -> Array:
	var result: Array = []
	for c: Color in ramp:
		result.append(Color(
			c.r * factor, c.g * factor, c.b * factor, c.a,
		))
	return result


# ═══════════════════════════════════════════════════════════
# ATLAS BAKE
# ═══════════════════════════════════════════════════════════

func _bake_atlas() -> void:
	var atlas_w := TEX_W * FRAME_COUNT
	var img := Image.create(
		atlas_w, TEX_H, false, Image.FORMAT_RGBA8,
	)
	img.fill(Color(0, 0, 0, 0))
	for f: int in FRAME_COUNT:
		var t := float(f) / float(FRAME_COUNT) * TAU
		var ox := float(f * TEX_W) + TEX_CX
		_bake_frame(img, t, ox)
	_texture = ImageTexture.create_from_image(img)


func _bake_frame(img: Image, t: float, ox: float) -> void:
	var p := _anim_positions(t)
	var px := _to_pixels(p, ox)
	# Back-to-front centaur layering
	_draw_far_legs(img, px)
	_draw_staff_behind(img, px)
	_draw_abdomen(img, px)
	_draw_thorax(img, px)
	_draw_torso(img, px)
	_draw_near_legs(img, px)
	_draw_free_arm(img, px)
	_draw_head(img, px)
	_draw_staff_orb(img, px)


# ═══════════════════════════════════════════════════════════
# ANIMATION — centaur walk cycle
# ═══════════════════════════════════════════════════════════

func _anim_positions(t: float) -> Dictionary:
	# Spider body: stable platform with minimal bob
	var sp_bob := sin(t * 2.0) * 0.15
	# Ape upper body: more expressive sway
	var torso_bob := sin(t * 2.0) * 0.20
	var hd_bob := sin(t * 2.0 + 0.4) * 0.15
	# Spider leg tripod gait
	var leg_a := sin(t) * 0.8
	var leg_b := sin(t + PI) * 0.8
	var leg_c := sin(t + TAU / 3.0) * 0.8
	var lift_a := maxf(sin(t), 0.0) * 0.4
	var lift_b := maxf(sin(t + PI), 0.0) * 0.4
	var lift_c := maxf(sin(t + TAU / 3.0), 0.0) * 0.4
	var arm_sw := sin(t) * 0.6
	var sway := sin(t * 0.5) * 0.25

	return {
		# Spider lower body
		"abd": Vector2(-2.5, 2.0 + sp_bob),
		"thx": Vector2(0.0, 1.5 + sp_bob),
		# Ape upper body (vertical rise)
		"tor": Vector2(0.3, -1.0 + torso_bob),
		"hd": Vector2(0.5, -3.2 + hd_bob),
		# Near spider legs (front→rear, spreading out)
		"sl1_base": Vector2(1.5, 2.0 + sp_bob),
		"sl1_foot": Vector2(3.5 + leg_a, 4.5 - lift_a),
		"sl2_base": Vector2(0.0, 2.5 + sp_bob),
		"sl2_foot": Vector2(1.5 + leg_b, 5.0 - lift_b),
		"sl3_base": Vector2(-1.5, 2.0 + sp_bob),
		"sl3_foot": Vector2(-3.5 + leg_c, 4.5 - lift_c),
		# Far spider legs (dimmer, behind)
		"fl1_base": Vector2(1.2, 1.5 + sp_bob),
		"fl1_foot": Vector2(3.2 - leg_a, 4.0 - lift_b),
		"fl2_base": Vector2(-0.3, 2.0 + sp_bob),
		"fl2_foot": Vector2(1.2 - leg_b, 4.5 - lift_c),
		"fl3_base": Vector2(-1.8, 1.5 + sp_bob),
		"fl3_foot": Vector2(-3.2 - leg_c, 4.0 - lift_a),
		# Free arm (forward)
		"arm_base": Vector2(1.3, -1.5 + torso_bob),
		"arm_elbow": Vector2(2.3, -0.3 + torso_bob + arm_sw),
		"arm_hand": Vector2(2.8, 0.8 + torso_bob + arm_sw),
		# Staff arm (behind, holding staff)
		"staff_shoulder": Vector2(-0.5, -1.5 + torso_bob),
		"staff_grip": Vector2(-0.8, 0.0 + torso_bob),
		"staff_top": Vector2(-0.5 + sway, -5.5 + torso_bob),
		"staff_bottom": Vector2(-0.8, 1.0 + torso_bob),
		"orb": Vector2(-0.5 + sway, -6.2 + torso_bob),
	}


func _to_pixels(p: Dictionary, ox: float) -> Dictionary:
	var result := {}
	for key: String in p:
		var v: Vector2 = p[key]
		result[key] = Vector2(
			ox + v.x * TEX_PPU,
			TEX_CY + v.y * TEX_PPU,
		)
	return result


func _tr(local_r: float) -> float:
	return local_r * TEX_PPU


# ═══════════════════════════════════════════════════════════
# BODY PARTS (back-to-front centaur order)
# ═══════════════════════════════════════════════════════════

func _draw_far_legs(img: Image, px: Dictionary) -> void:
	var dim := _dim_ramp(_leg_ramp, 0.55)
	for i: int in range(1, 4):
		var base: Vector2 = px["fl%d_base" % i]
		var foot: Vector2 = px["fl%d_foot" % i]
		var knee := Vector2(
			(base.x + foot.x) * 0.5 - _tr(0.6),
			(base.y + foot.y) * 0.5 - _tr(1.0),
		)
		_shaded_line(img, base.x, base.y, knee.x, knee.y, dim, 2)
		_shaded_line(img, knee.x, knee.y, foot.x, foot.y, dim, 2)
		_shaded_circle(img, knee.x, knee.y, _tr(0.35), dim)
		# Dark band at mid-segment
		var mid_x := (base.x + knee.x) * 0.5
		var mid_y := (base.y + knee.y) * 0.5
		_fill_circle(img, mid_x, mid_y, _tr(0.3), dim[0])
		# Claw
		_fill_circle(
			img, foot.x, foot.y + _tr(0.2),
			_tr(0.25), dim[0],
		)


func _draw_staff_behind(img: Image, px: Dictionary) -> void:
	var top: Vector2 = px["staff_top"]
	var btm: Vector2 = px["staff_bottom"]
	var grip: Vector2 = px["staff_grip"]
	var shldr: Vector2 = px["staff_shoulder"]
	# Shaft
	_shaded_line(img, btm.x, btm.y, top.x, top.y, _staff_ramp, 2)
	# Grip wrapping
	for j: int in 3:
		var oy := grip.y - float(j) * _tr(0.5)
		_fill_circle(img, grip.x, oy, _tr(0.22), _staff_ramp[1])
	# Carved notch on shaft
	var mid_x := (grip.x + top.x) * 0.5
	var mid_y := (grip.y + top.y) * 0.5
	_fill_circle(img, mid_x, mid_y, _tr(0.18), _staff_ramp[0])
	# Staff arm
	_shaded_line(
		img, shldr.x, shldr.y, grip.x, grip.y, _fur_ramp, 2,
	)
	var elb_x := (shldr.x + grip.x) * 0.5
	var elb_y := (shldr.y + grip.y) * 0.5
	_shaded_circle(img, elb_x, elb_y, _tr(0.3), _fur_ramp)


func _draw_abdomen(img: Image, px: Dictionary) -> void:
	var abd: Vector2 = px["abd"]
	var r := _tr(2.5)
	_shaded_circle(img, abd.x, abd.y, r, _spider_ramp)
	# Segment stripes
	var stripe := Color(
		_spider_ramp[2].r + 0.04,
		_spider_ramp[2].g + 0.03,
		_spider_ramp[2].b + 0.02,
	)
	_draw_line_px(
		img, abd.x - _tr(0.8), abd.y - _tr(0.4),
		abd.x + _tr(0.9), abd.y - _tr(0.6), stripe,
	)
	_draw_line_px(
		img, abd.x - _tr(1.0), abd.y + _tr(0.3),
		abd.x + _tr(0.5), abd.y + _tr(0.1), stripe,
	)
	# RED MARKS — Spy Kids 2 signature
	var red := Color(0.72, 0.12, 0.08)
	_fill_circle(
		img, abd.x + _tr(0.3), abd.y - _tr(0.1), _tr(0.5), red,
	)
	_fill_circle(
		img, abd.x - _tr(0.4), abd.y + _tr(0.5), _tr(0.4), red,
	)
	_fill_circle(
		img, abd.x + _tr(0.7), abd.y + _tr(0.4), _tr(0.3), red,
	)
	# Spinnerets
	_fill_circle(
		img, abd.x - _tr(2.1), abd.y - _tr(0.15),
		_tr(0.22), _spider_ramp[1],
	)
	_fill_circle(
		img, abd.x - _tr(2.1), abd.y + _tr(0.2),
		_tr(0.22), _spider_ramp[1],
	)


func _draw_thorax(img: Image, px: Dictionary) -> void:
	var thx: Vector2 = px["thx"]
	var tor: Vector2 = px["tor"]
	_shaded_circle(img, thx.x, thx.y, _tr(1.5), _spider_ramp)
	# Waist connection (spider→ape transition)
	var wx := (thx.x + tor.x) * 0.5
	var wy := (thx.y + tor.y) * 0.5
	_shaded_circle(img, wx, wy, _tr(1.2), _fur_ramp)
	_shaded_line(img, thx.x, thx.y, wx, wy, _spider_ramp, 2)


func _draw_torso(img: Image, px: Dictionary) -> void:
	var tor: Vector2 = px["tor"]
	var r := _tr(2.0)
	# Broad ape torso
	_shaded_circle(img, tor.x, tor.y, r, _fur_ramp)
	# Shoulder bulk
	_fill_circle(
		img, tor.x - _tr(0.7), tor.y - _tr(0.6),
		_tr(0.8), _fur_ramp[2],
	)
	_fill_circle(
		img, tor.x + _tr(0.7), tor.y - _tr(0.6),
		_tr(0.8), _fur_ramp[2],
	)
	# Chest highlight
	_fill_circle(
		img, tor.x + _tr(0.3), tor.y - _tr(0.3),
		_tr(1.0), _fur_ramp[3],
	)
	# Belly
	_shaded_circle(
		img, tor.x + _tr(0.1), tor.y + _tr(0.5),
		_tr(1.0), _belly_ramp, 0.5,
	)
	# Pec line
	_draw_line_px(
		img, tor.x - _tr(0.4), tor.y - _tr(0.5),
		tor.x + _tr(0.5), tor.y + _tr(0.1), _fur_ramp[1],
	)
	# Fur texture
	_fill_circle(
		img, tor.x - _tr(0.7), tor.y - _tr(0.2),
		_tr(0.22), _fur_ramp[1],
	)
	_fill_circle(
		img, tor.x + _tr(0.5), tor.y - _tr(0.6),
		_tr(0.18), _fur_ramp[1],
	)


func _draw_near_legs(img: Image, px: Dictionary) -> void:
	for i: int in range(1, 4):
		var base: Vector2 = px["sl%d_base" % i]
		var foot: Vector2 = px["sl%d_foot" % i]
		var knee := Vector2(
			(base.x + foot.x) * 0.5 - _tr(0.7),
			(base.y + foot.y) * 0.5 - _tr(1.1),
		)
		_shaded_line(
			img, base.x, base.y, knee.x, knee.y, _leg_ramp, 2,
		)
		_shaded_line(
			img, knee.x, knee.y, foot.x, foot.y, _leg_ramp, 2,
		)
		# Joint knob
		_shaded_circle(img, knee.x, knee.y, _tr(0.4), _leg_ramp)
		# Dark band at mid-segment (yellow-black banding)
		var mid_x := (base.x + knee.x) * 0.5
		var mid_y := (base.y + knee.y) * 0.5
		_fill_circle(img, mid_x, mid_y, _tr(0.35), _leg_ramp[0])
		var mid2_x := (knee.x + foot.x) * 0.5
		var mid2_y := (knee.y + foot.y) * 0.5
		_fill_circle(img, mid2_x, mid2_y, _tr(0.3), _leg_ramp[0])
		# Claw tips
		_fill_circle(
			img, foot.x, foot.y + _tr(0.2),
			_tr(0.3), _leg_ramp[0],
		)
		_fill_circle(
			img, foot.x + _tr(0.12), foot.y + _tr(0.25),
			_tr(0.15), _leg_ramp[0],
		)


func _draw_free_arm(img: Image, px: Dictionary) -> void:
	var base: Vector2 = px["arm_base"]
	var elbow: Vector2 = px["arm_elbow"]
	var hand: Vector2 = px["arm_hand"]
	_shaded_line(
		img, base.x, base.y, elbow.x, elbow.y, _fur_ramp, 2,
	)
	_shaded_line(
		img, elbow.x, elbow.y, hand.x, hand.y, _fur_ramp, 2,
	)
	_shaded_circle(img, elbow.x, elbow.y, _tr(0.35), _fur_ramp)
	# Hand / fist
	_shaded_circle(
		img, hand.x, hand.y, _tr(0.5), _belly_ramp, 0.5,
	)
	# Fingers
	_draw_line_px(
		img, hand.x, hand.y,
		hand.x + _tr(0.4), hand.y + _tr(0.3), _fur_ramp[0],
	)
	_draw_line_px(
		img, hand.x, hand.y,
		hand.x + _tr(0.2), hand.y + _tr(0.5), _fur_ramp[0],
	)


func _draw_head(img: Image, px: Dictionary) -> void:
	## Spider head — multiple eyes, mandibles, fur tufts.
	var hd: Vector2 = px["hd"]
	var r := _tr(1.8)

	# Main head (dark spider coloring)
	_shaded_circle(img, hd.x, hd.y, r, _spider_ramp)

	# --- SPIDER EYE CLUSTER ---
	# Primary eye (large, forward-facing)
	var e1x := hd.x + _tr(0.5)
	var e1y := hd.y - _tr(0.15)
	_fill_circle(img, e1x, e1y, _tr(0.6), _spider_ramp[0])
	_fill_circle(img, e1x, e1y, _tr(0.45), eye_color)
	_fill_circle(
		img, e1x + _tr(0.1), e1y + _tr(0.05),
		_tr(0.22), eye_pupil,
	)
	_fill_circle(
		img, e1x - _tr(0.1), e1y - _tr(0.1),
		_tr(0.1), Color.WHITE,
	)

	# Secondary eye (slightly below/behind)
	var e2x := hd.x + _tr(0.35)
	var e2y := hd.y + _tr(0.5)
	_fill_circle(img, e2x, e2y, _tr(0.5), _spider_ramp[0])
	_fill_circle(img, e2x, e2y, _tr(0.38), eye_color)
	_fill_circle(
		img, e2x + _tr(0.08), e2y + _tr(0.03),
		_tr(0.18), eye_pupil,
	)
	_fill_circle(
		img, e2x - _tr(0.08), e2y - _tr(0.08),
		_tr(0.08), Color.WHITE,
	)

	# Small auxiliary eyes (just colored dots)
	_fill_circle(
		img, hd.x + _tr(0.05), hd.y - _tr(0.65),
		_tr(0.22), eye_color,
	)
	_fill_circle(
		img, hd.x - _tr(0.25), hd.y - _tr(0.3),
		_tr(0.18), eye_color,
	)

	# --- MANDIBLES / CHELICERAE ---
	var mb_x := hd.x + _tr(0.3)
	var mb_y := hd.y + _tr(1.2)
	# Upper mandible (curves forward-up)
	_shaded_line(
		img, mb_x, mb_y,
		mb_x + _tr(1.0), mb_y - _tr(0.4), _spider_ramp, 1,
	)
	# Lower mandible (curves forward-down)
	_shaded_line(
		img, mb_x, mb_y + _tr(0.3),
		mb_x + _tr(0.8), mb_y + _tr(0.7), _spider_ramp, 1,
	)
	# Fang tips (pale)
	_fill_circle(
		img, mb_x + _tr(1.0), mb_y - _tr(0.4),
		_tr(0.15), Color(0.92, 0.90, 0.85),
	)
	_fill_circle(
		img, mb_x + _tr(0.8), mb_y + _tr(0.7),
		_tr(0.15), Color(0.92, 0.90, 0.85),
	)

	# --- FUR TUFTS (hybrid ape feature) ---
	_fill_circle(
		img, hd.x - _tr(0.3), hd.y - _tr(1.4),
		_tr(0.3), _fur_ramp[1],
	)
	_fill_circle(
		img, hd.x + _tr(0.1), hd.y - _tr(1.6),
		_tr(0.25), _fur_ramp[2],
	)
	_fill_circle(
		img, hd.x - _tr(0.6), hd.y - _tr(1.1),
		_tr(0.2), _fur_ramp[1],
	)


func _draw_staff_orb(img: Image, px: Dictionary) -> void:
	var orb: Vector2 = px["orb"]
	var r := _tr(1.0)
	# Glow aura
	_fill_circle(img, orb.x, orb.y, r * 2.5, Color(
		staff_glow.r, staff_glow.g, staff_glow.b, 0.10,
	))
	_fill_circle(img, orb.x, orb.y, r * 1.8, Color(
		staff_glow.r, staff_glow.g, staff_glow.b, 0.20,
	))
	_fill_circle(img, orb.x, orb.y, r * 1.3, Color(
		staff_glow.r, staff_glow.g, staff_glow.b, 0.32,
	))
	# Orb body
	_shaded_circle(img, orb.x, orb.y, r, _orb_ramp)
	# Bright core
	_fill_circle(
		img, orb.x + LT_X * _tr(0.25),
		orb.y + LT_Y * _tr(0.25),
		r * 0.35, _orb_ramp[4],
	)
	# White glint
	_fill_circle(
		img, orb.x + LT_X * _tr(0.35),
		orb.y + LT_Y * _tr(0.35),
		_tr(0.15), Color.WHITE,
	)


# ═══════════════════════════════════════════════════════════
# SHADING HELPERS
# ═══════════════════════════════════════════════════════════

func _shaded_circle(
	img: Image, cx: float, cy: float, r: float,
	ramp: Array, ol: float = 1.0,
) -> void:
	_fill_circle(img, cx, cy, r + ol, ramp[0])
	_fill_circle(img, cx, cy, r, ramp[1])
	var bx := LT_X * r * 0.12
	var by := LT_Y * r * 0.12
	_fill_circle(img, cx + bx, cy + by, r * 0.85, ramp[2])
	var hx := LT_X * r * 0.35
	var hy := LT_Y * r * 0.35
	_fill_circle(img, cx + hx, cy + hy, r * 0.50, ramp[3])
	if r > 2.5:
		var rx := LT_X * r * 0.55
		var ry := LT_Y * r * 0.55
		_fill_circle(
			img, cx + rx, cy + ry,
			maxf(r * 0.20, 1.0), ramp[4],
		)


func _shaded_line(
	img: Image, x0: float, y0: float, x1: float, y1: float,
	ramp: Array, thick: int = 2,
) -> void:
	_draw_line_px(img, x0, y0, x1, y1, ramp[0], thick + 1)
	_draw_line_px(img, x0, y0, x1, y1, ramp[2], thick)
	if thick >= 2:
		_draw_line_px(
			img, x0 + LT_X, y0 + LT_Y,
			x1 + LT_X, y1 + LT_Y, ramp[3], thick - 1,
		)


# ═══════════════════════════════════════════════════════════
# PIXEL HELPERS
# ═══════════════════════════════════════════════════════════

func _fill_circle(
	img: Image, cx: float, cy: float,
	radius: float, color: Color,
) -> void:
	var r_sq := radius * radius
	var min_x := maxi(0, int(cx - radius - 1))
	var max_x := mini(img.get_width() - 1, ceili(cx + radius))
	var min_y := maxi(0, int(cy - radius - 1))
	var max_y := mini(img.get_height() - 1, ceili(cy + radius))
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var dx := float(x) + 0.5 - cx
			var dy := float(y) + 0.5 - cy
			if dx * dx + dy * dy <= r_sq:
				img.set_pixel(x, y, color)


func _draw_line_px(
	img: Image, x0: float, y0: float,
	x1: float, y1: float, color: Color,
	thick: int = 1,
) -> void:
	var dx := x1 - x0
	var dy := y1 - y0
	var steps := int(maxf(absf(dx), absf(dy))) + 1
	if steps <= 0:
		return
	var sx := dx / float(steps)
	var sy := dy / float(steps)
	var iw := img.get_width()
	var ih := img.get_height()
	var half := thick / 2
	for i: int in range(steps + 1):
		var cx := int(x0 + sx * float(i))
		var cy := int(y0 + sy * float(i))
		for oy: int in range(-half, half + 1):
			for lox: int in range(-half, half + 1):
				var fx := cx + lox
				var fy := cy + oy
				if fx >= 0 and fx < iw and fy >= 0 and fy < ih:
					img.set_pixel(fx, fy, color)
