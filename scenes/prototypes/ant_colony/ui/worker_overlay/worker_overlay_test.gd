extends Control
## Worker allocation overlay. Centered modal that appears once
## per run after buying the worker upgrade. Slider allocates
## unassigned workers between miners and haulers.

const TOTAL_WORKERS := 8

@onready var _miners_lbl: Label = (
	$Panel/Content/MinersLabel
)
@onready var _haulers_lbl: Label = (
	$Panel/Content/HaulersLabel
)
@onready var _slider: HSlider = (
	$Panel/Content/RatioSlider
)


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	$Panel/Content/OkButton.pressed.connect(
		_on_ok,
	)
	_slider.max_value = TOTAL_WORKERS
	_slider.value = 0
	_slider.value_changed.connect(_on_slider_changed)
	_update_labels(0)


func _on_slider_changed(val: float) -> void:
	_update_labels(int(val))


func _update_labels(miners: int) -> void:
	var haulers: int = TOTAL_WORKERS - miners
	_miners_lbl.text = "MINERS: %d" % miners
	_haulers_lbl.text = "HAULERS: %d" % haulers


func _on_ok() -> void:
	_go_back()


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
