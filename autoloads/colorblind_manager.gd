extends CanvasLayer
class_name ColorblindManagerClass
## ColorblindManager - Applies colorblind correction shader to the entire screen.
## Autoload that listens to GameState.colorblind_mode changes.

var _overlay: ColorRect
var _shader: Shader
var _material: ShaderMaterial


func _ready() -> void:
	# Render on top of everything
	layer = 128

	# Create fullscreen overlay (starts hidden)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color.WHITE  # Needs a color for shader to render
	_overlay.visible = false
	add_child(_overlay)

	# Pre-load shader
	_shader = preload("res://shaders/colorblind.gdshader")

	# Connect to settings changes
	GameState.settings_changed.connect(_on_settings_changed)

	# Apply initial setting (deferred to ensure GameState is ready)
	call_deferred("_update_shader")


func _on_settings_changed() -> void:
	_update_shader()


func _update_shader() -> void:
	if GameState.colorblind_mode == 0:
		# OFF - hide overlay completely, remove shader
		_overlay.visible = false
		_overlay.material = null
	else:
		# ON - show overlay with shader
		if _material == null:
			_material = ShaderMaterial.new()
			_material.shader = _shader
		_material.set_shader_parameter("mode", GameState.colorblind_mode)
		_overlay.material = _material
		_overlay.visible = true
