extends Interactable
class_name StorageTerminal
## Storage Terminal - Access creature storage (PC Box system).
## Player approaches and presses E to open storage UI.

@onready var sprite: Sprite2D = $Sprite2D

var _storage_screen_scene: PackedScene = preload("res://scenes/ui/storage/storage_screen.tscn")


func _ready() -> void:
	super._ready()
	interact_prompt = "(E)"


func _on_interact() -> void:
	# Hide prompt while screen is open
	_prompt_control.hide()

	# Create and show storage screen
	var storage_screen := _storage_screen_scene.instantiate()
	storage_screen.closed.connect(_on_storage_closed)
	get_tree().root.add_child(storage_screen)


func _on_storage_closed() -> void:
	_interact_cooldown = INTERACT_COOLDOWN
	if _player_in_range:
		_prompt_control.show()
