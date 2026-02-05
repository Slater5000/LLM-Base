extends CanvasLayer
class_name DialogueManagerClass
## DialogueManager - Handles all dialogue display and state.
## Autoload that shows dialogue box, typewriter effect, multi-page support.
##
## Usage:
##   DialogueManager.show_dialogue(["Hello!", "How are you?"])
##   await DialogueManager.dialogue_finished

signal dialogue_started
signal dialogue_finished
signal page_advanced

## Whether dialogue is currently being displayed
var is_active: bool = false

## Current dialogue pages
var _pages: Array[String] = []
var _current_page: int = 0

## Typewriter state
var _displayed_text: String = ""
var _target_text: String = ""
var _char_index: int = 0
var _typewriter_timer: float = 0.0

## Characters per second for typewriter effect
@export var typewriter_speed: float = 40.0

## UI References
@onready var _dialogue_box: Control = $DialogueBox
@onready var _text_label: RichTextLabel = $DialogueBox/MarginContainer/VBoxContainer/TextLabel
@onready var _continue_indicator: Label = $DialogueBox/MarginContainer/VBoxContainer/ContinueIndicator


func _ready() -> void:
	_dialogue_box.hide()
	_continue_indicator.hide()


func _process(delta: float) -> void:
	if not is_active:
		return

	# Typewriter effect
	if _char_index < _target_text.length():
		_typewriter_timer += delta
		var chars_to_add := int(_typewriter_timer * typewriter_speed)
		if chars_to_add > 0:
			_typewriter_timer = 0.0
			var end_index := mini(_char_index + chars_to_add, _target_text.length())
			_displayed_text = _target_text.substr(0, end_index)
			_text_label.text = _displayed_text
			_char_index = end_index

			# Show continue indicator when text is complete
			if _char_index >= _target_text.length():
				_continue_indicator.show()


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()

		# If typewriter is still running, complete it instantly
		if _char_index < _target_text.length():
			_char_index = _target_text.length()
			_displayed_text = _target_text
			_text_label.text = _displayed_text
			_continue_indicator.show()
		else:
			# Advance to next page or close
			_advance_page()


## Show dialogue with one or more pages of text.
## Returns immediately; await dialogue_finished if you need to wait.
func show_dialogue(pages: Array) -> void:
	if is_active:
		push_warning("DialogueManager: Already showing dialogue")
		return

	if pages.is_empty():
		return

	# Convert to typed array
	_pages.clear()
	for page in pages:
		_pages.append(str(page))

	_current_page = 0
	is_active = true

	_dialogue_box.show()
	_show_current_page()

	dialogue_started.emit()


## Close dialogue immediately
func close_dialogue() -> void:
	if not is_active:
		return

	is_active = false
	_dialogue_box.hide()
	_continue_indicator.hide()
	_pages.clear()

	dialogue_finished.emit()


func _show_current_page() -> void:
	if _current_page >= _pages.size():
		close_dialogue()
		return

	_target_text = _pages[_current_page]
	_displayed_text = ""
	_char_index = 0
	_typewriter_timer = 0.0
	_text_label.text = ""
	_continue_indicator.hide()


func _advance_page() -> void:
	_current_page += 1
	page_advanced.emit()

	if _current_page >= _pages.size():
		close_dialogue()
	else:
		_show_current_page()


## Check if dialogue is currently active
func is_dialogue_active() -> bool:
	return is_active
