extends Control
## In-game HUD layout mockup. Shows food, distance, workers,
## and tool indicator at viewport corners.
## TAB cycles tools. [ / ] adjusts radius for tools that have it.

const TOOLS := [
	{"name": "DIG", "radius": true},
	{"name": "PHEROMONE", "radius": true},
	{"name": "INSPECT", "radius": false},
	{"name": "RALLY", "radius": true},
]
var _tool_idx: int = 0
var _radius: int = 1


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	_update_tool_label()


func _update_tool_label() -> void:
	var info: Dictionary = TOOLS[_tool_idx]
	var txt := "TOOL: %s" % info.name
	if info.radius:
		txt += "  R:%d" % _radius
	$BottomLeft.text = txt


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_TAB:
			_tool_idx = (
				(_tool_idx + 1) % TOOLS.size()
			)
			_update_tool_label()
		KEY_BRACKETLEFT:
			if TOOLS[_tool_idx].radius:
				_radius = max(1, _radius - 1)
				_update_tool_label()
		KEY_BRACKETRIGHT:
			if TOOLS[_tool_idx].radius:
				_radius = min(5, _radius + 1)
				_update_tool_label()


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
