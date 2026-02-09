extends Control
## Mode select test: Normal / Education panels with save management.
## Load Colony and Legacy Colonies open Stardew-style overlay menus.
## Toggle button switches between first-time and has-save states.

var _has_save := true


func _ready() -> void:
	$BackButton.pressed.connect(_go_back)
	$ToggleStateBtn.pressed.connect(_toggle_state)

	# Normal mode
	var normal_content: VBoxContainer = (
		$PanelContainer/NormalPanel/Content
	)
	var delete_x: TextureButton = (
		normal_content.get_node("PlayContainer/DeleteX")
	)
	delete_x.pressed.connect(_show_confirm)
	var legacy_btn: Button = (
		normal_content.get_node("LegacyButton")
	)
	legacy_btn.pressed.connect(_show_legacy)

	# Education mode
	var edu_content: VBoxContainer = (
		$PanelContainer/EducationPanel/Content
	)
	var load_btn: Button = edu_content.get_node("LoadButton")
	load_btn.pressed.connect(_show_load)

	# Load overlay
	_wire_overlay($LoadOverlay)
	# Legacy overlay
	_wire_overlay($LegacyOverlay)

	# Confirm dialog
	var confirm_content: VBoxContainer = (
		$ConfirmOverlay/ConfirmPanel/Content
	)
	var yes_btn: Button = (
		confirm_content.get_node("ButtonRow/YesButton")
	)
	yes_btn.pressed.connect(_hide_confirm)
	var no_btn: Button = (
		confirm_content.get_node("ButtonRow/NoButton")
	)
	no_btn.pressed.connect(_hide_confirm)

	_update_normal_panel()


func _wire_overlay(overlay: ColorRect) -> void:
	var vbox: VBoxContainer = (
		overlay.get_node("Panel/Content/VBox")
	)
	var close_btn: Button = vbox.get_node("CloseBtn")
	close_btn.pressed.connect(overlay.hide)

	var save_list: VBoxContainer = (
		vbox.get_node("SaveScroll/SaveList")
	)
	for slot in save_list.get_children():
		var trash: TextureButton = (
			slot.get_node_or_null("TrashBtn")
		)
		if trash:
			trash.pressed.connect(_show_confirm)


func _toggle_state() -> void:
	_has_save = not _has_save
	if _has_save:
		$ToggleStateBtn.text = "Toggle: Has Save"
	else:
		$ToggleStateBtn.text = "Toggle: No Save"
	_update_normal_panel()


func _update_normal_panel() -> void:
	var content: VBoxContainer = (
		$PanelContainer/NormalPanel/Content
	)
	var colony_info: Label = content.get_node("ColonyInfo")
	var delete_x: TextureButton = (
		content.get_node("PlayContainer/DeleteX")
	)
	var legacy_btn: Button = (
		content.get_node("LegacyButton")
	)

	colony_info.visible = _has_save
	delete_x.visible = _has_save
	legacy_btn.visible = _has_save


func _show_load() -> void:
	$LoadOverlay.visible = true


func _show_legacy() -> void:
	$LegacyOverlay.visible = true


func _show_confirm() -> void:
	$ConfirmOverlay.visible = true


func _hide_confirm() -> void:
	$ConfirmOverlay.visible = false


func _go_back() -> void:
	get_tree().change_scene_to_file(AntColonyUI.LAUNCHER)
