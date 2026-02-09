extends Control
## Rainbow menu test. Grid of tile_0018 panels with rainbow-colored text.

const COLS := 6
const ROWS := 3
const TILE_W := 92.0
const TILE_H := 40.0
const TILE_GAP := 8.0
const HEADER_GAP := 20.0
const ROW_GAP := 12.0
const HEADER_SZ := 16
const ITEM_SZ := 16
const OUTLINE := Color(0, 0, 0, 1)
const OFFSETS: Array[Vector2] = [
	Vector2(-1, 0), Vector2(1, 0),
	Vector2(0, -1), Vector2(0, 1),
]

const CATEGORIES := [
	"POWER FANTASY",
	"AUTOMATION + TRANSPORT",
	"ECONOMY + COSMETIC",
]

const ITEMS := [
	["Quantum", "Laser Eyes", "Auto-Pilot",
		"Mega Bite", "Giant Queen", "Void Storage"],
	["Hive Mind", "Speed Light", "Global Conv",
		"Midas Touch", "", ""],
	["Big Head", "Big Ant", "Rainbow Trail",
		"Fire Trail", "Boogie Bomb", "Extra Hats"],
]

var _panel_style: StyleBoxTexture
var _item_index := 0


func _ready() -> void:
	_panel_style = StyleBoxTexture.new()
	_panel_style.texture = load(AntColonyUI.PANEL_MASTER)
	_panel_style.texture_margin_left = 8.0
	_panel_style.texture_margin_top = 8.0
	_panel_style.texture_margin_right = 8.0
	_panel_style.texture_margin_bottom = 8.0
	$BackButton.pressed.connect(_go_back)
	$DrawNode.draw.connect(_on_draw)
	$DrawNode.queue_redraw()


func _on_draw() -> void:
	var draw_node: Node2D = $DrawNode
	var font := ThemeDB.fallback_font
	var total_grid_w: float = (
		COLS * TILE_W + (COLS - 1) * TILE_GAP
	)
	var start_x: float = (
		(AntColonyUI.VIEWPORT_W - total_grid_w) / 2.0
	)
	var cur_y := 28.0
	_item_index = 0

	for row in ROWS:
		var header: String = CATEGORIES[row]
		var tw: float = font.get_string_size(
			header, HORIZONTAL_ALIGNMENT_LEFT,
			-1, HEADER_SZ,
		).x
		var hpos := Vector2(
			AntColonyUI.VIEWPORT_W / 2.0 - tw / 2.0,
			cur_y,
		)
		_outlined(
			draw_node, font, hpos, header,
			HEADER_SZ, AntColonyUI.ACCENT_ORANGE,
		)
		cur_y += HEADER_GAP

		var items_row: Array = ITEMS[row]
		for col in COLS:
			if col >= items_row.size():
				break
			var item_name: String = items_row[col]
			if item_name.is_empty():
				_item_index += 1
				continue
			var tx: float = (
				start_x + col * (TILE_W + TILE_GAP)
			)
			var ty: float = cur_y

			draw_node.draw_style_box(
				_panel_style,
				Rect2(tx, ty, TILE_W, TILE_H),
			)

			var hue: float = (
				float(_item_index) / 16.0
			)
			var rainbow := Color.from_hsv(
				hue, 0.7, 0.95,
			)

			var ntw: float = font.get_string_size(
				item_name,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1, ITEM_SZ,
			).x
			var ipos := Vector2(
				tx + TILE_W / 2.0 - ntw / 2.0,
				ty + TILE_H / 2.0 + 4.0,
			)
			_outlined(
				draw_node, font, ipos,
				item_name, ITEM_SZ, rainbow,
			)
			_item_index += 1

		cur_y += TILE_H + ROW_GAP


func _outlined(
	node: Node2D, font: Font, pos: Vector2,
	text: String, sz: int, col: Color,
) -> void:
	for off: Vector2 in OFFSETS:
		node.draw_string(
			font, pos + off, text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, sz, OUTLINE,
		)
	node.draw_string(
		font, pos, text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col,
	)


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
