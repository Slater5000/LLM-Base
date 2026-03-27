class_name CreaturePixelUtils
## Static pixel drawing and Dead Cells shading utilities.
## Shared by all creature rendering code.
##
## Shading system: 5-color hue-shifted ramps.
## Ramp indices: [0]=outline, [1]=shadow, [2]=base, [3]=highlight, [4]=rim.
## Light direction: top-left (LT_X, LT_Y).

# Light direction constants (top-left)
const LT_X := -0.4
const LT_Y := -0.4


# ═══════════════════════════════════════════════════════════
# COLOR RAMP GENERATION
# ═══════════════════════════════════════════════════════════

static func make_ramp(base: Color) -> Array:
	## Build a 5-step hue-shifted ramp from a base color.
	## Shadows shift cooler (+hue), highlights shift warmer (-hue).
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


static func dim_ramp(ramp: Array, factor: float) -> Array:
	## Dim a ramp by a factor for far-side depth cue.
	var result: Array = []
	for c: Color in ramp:
		result.append(Color(
			c.r * factor, c.g * factor, c.b * factor, c.a,
		))
	return result


# ═══════════════════════════════════════════════════════════
# SHADING HELPERS
# ═══════════════════════════════════════════════════════════

static func shaded_circle(
	img: Image, cx: float, cy: float, r: float,
	ramp: Array, ol: float = 1.0,
) -> void:
	## Draw a circle with 5-layer Dead Cells shading.
	## Layers: outline → shadow → base → highlight → rim.
	fill_circle(img, cx, cy, r + ol, ramp[0])
	fill_circle(img, cx, cy, r, ramp[1])
	var bx := LT_X * r * 0.12
	var by := LT_Y * r * 0.12
	fill_circle(img, cx + bx, cy + by, r * 0.85, ramp[2])
	var hx := LT_X * r * 0.35
	var hy := LT_Y * r * 0.35
	fill_circle(img, cx + hx, cy + hy, r * 0.50, ramp[3])
	if r > 2.5:
		var rx := LT_X * r * 0.55
		var ry := LT_Y * r * 0.55
		fill_circle(
			img, cx + rx, cy + ry,
			maxf(r * 0.20, 1.0), ramp[4],
		)


static func shaded_line(
	img: Image, x0: float, y0: float, x1: float, y1: float,
	ramp: Array, thick: int = 2,
) -> void:
	## Draw a line with outline + fill + highlight.
	draw_line_px(img, x0, y0, x1, y1, ramp[0], thick + 1)
	draw_line_px(img, x0, y0, x1, y1, ramp[2], thick)
	if thick >= 2:
		draw_line_px(
			img, x0 + LT_X, y0 + LT_Y,
			x1 + LT_X, y1 + LT_Y, ramp[3], thick - 1,
		)


# ═══════════════════════════════════════════════════════════
# COORDINATE HELPERS
# ═══════════════════════════════════════════════════════════

static func to_pixels(
	positions: Dictionary, offset_x: float,
	center_y: float, ppu: float,
) -> Dictionary:
	## Convert local-unit positions to pixel positions.
	var result := {}
	for key: String in positions:
		var v: Vector2 = positions[key]
		result[key] = Vector2(
			offset_x + v.x * ppu,
			center_y + v.y * ppu,
		)
	return result


static func to_px(local_r: float, ppu: float) -> float:
	## Convert a local-unit radius/distance to pixels.
	return local_r * ppu


# ═══════════════════════════════════════════════════════════
# PIXEL PRIMITIVES
# ═══════════════════════════════════════════════════════════

static func fill_circle(
	img: Image, cx: float, cy: float,
	radius: float, color: Color,
) -> void:
	## Fill a circle on an Image at pixel level.
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


static func draw_line_px(
	img: Image, x0: float, y0: float,
	x1: float, y1: float, color: Color,
	thick: int = 1,
) -> void:
	## Draw a line on an Image at pixel level.
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
		var px := int(x0 + sx * float(i))
		var py := int(y0 + sy * float(i))
		for oy: int in range(-half, half + 1):
			for ox: int in range(-half, half + 1):
				var fx := px + ox
				var fy := py + oy
				if fx >= 0 and fx < iw and fy >= 0 and fy < ih:
					img.set_pixel(fx, fy, color)
