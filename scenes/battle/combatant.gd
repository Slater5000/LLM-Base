extends Node2D
class_name Combatant
## A single creature in battle - displays sprite, HP bar, action bar.
## Handles action bar filling and move execution.

signal action_ready(combatant: Combatant)
signal fainted(combatant: Combatant)
signal took_damage(combatant: Combatant, amount: int)
signal healed(combatant: Combatant, amount: int)

## The creature instance this combatant represents
var creature: CreatureInstance = null

## Is this a player-owned creature?
var is_player_owned: bool = true

## Action bar (0.0 to 1.0) - fills based on speed, fires move at 1.0
var action_bar: float = 0.0

## Action bar fill rate modifier (debuffs can reduce this)
var action_bar_fill_rate: float = 1.0

## Currently selected move index (0-2)
var selected_move_index: int = 0

## Current target for attacks/heals
var current_target: Combatant = null

## Shield amount (absorbs damage before HP)
var shield_amount: int = 0

## Swap freeze timer (can't act for 5s after being swapped in)
var swap_freeze_remaining: float = 0.0

## Status effects
var active_buffs: Array = []
var active_debuffs: Array = []

## Visual references
@onready var sprite: Sprite2D = $CreatureSprite
@onready var hp_bar_fill: ColorRect = $BarsContainer/HPBar/Fill
@onready var hp_bar_bg: ColorRect = $BarsContainer/HPBar/Background
@onready var action_bar_fill: ColorRect = $BarsContainer/ActionBar/Fill
@onready var action_bar_bg: ColorRect = $BarsContainer/ActionBar/Background
@onready var name_label: Label = $BarsContainer/NameLabel
@onready var swap_freeze_label: Label = $SwapFreezeLabel

## Bar dimensions
const HP_BAR_WIDTH := 48.0
const ACTION_BAR_WIDTH := 48.0

## Speed normalization (creature with 300 speed fills bar in 1 second)
const SPEED_BASELINE := 300.0


func _ready() -> void:
	# Hide swap freeze label by default
	if swap_freeze_label:
		swap_freeze_label.hide()


func _physics_process(delta: float) -> void:
	if not creature:
		return

	# Don't process if fainted
	if creature.is_fainted():
		return

	# Handle swap freeze countdown
	if swap_freeze_remaining > 0:
		swap_freeze_remaining -= delta
		_update_swap_freeze_display()
		if swap_freeze_remaining <= 0:
			swap_freeze_remaining = 0
			if swap_freeze_label:
				swap_freeze_label.hide()
		return  # Don't fill action bar while frozen

	# Fill action bar based on speed
	var fill_rate := (creature.speed / SPEED_BASELINE) * action_bar_fill_rate
	action_bar += fill_rate * delta

	if action_bar >= 1.0:
		action_bar = 1.0
		action_ready.emit(self)

	_update_action_bar_visual()


## Setup this combatant with a creature
func setup(creature_instance: CreatureInstance, player_owned: bool) -> void:
	creature = creature_instance
	is_player_owned = player_owned

	# Reset state
	action_bar = 0.0
	action_bar_fill_rate = 1.0
	selected_move_index = 0
	current_target = null
	shield_amount = 0
	swap_freeze_remaining = 0.0
	active_buffs.clear()
	active_debuffs.clear()

	# Setup visuals
	_setup_sprite()
	_update_hp_bar()
	_update_action_bar_visual()
	_update_name_label()


func _setup_sprite() -> void:
	if not creature or not sprite:
		return

	var species := GameState.get_species(creature.species_id)
	if not species or not species.sprite_texture:
		return

	sprite.texture = species.sprite_texture

	# Calculate scale for consistent size (~64px on screen)
	var target_size := 64.0
	var tex_size := species.sprite_texture.get_size()
	var max_dim := maxf(tex_size.x, tex_size.y)
	var base_scale := target_size / max_dim

	# Apply species-specific scale modifier if present
	var scale_mod := species.sprite_scale if species.sprite_scale > 0 else 1.0
	sprite.scale = Vector2(base_scale * scale_mod, base_scale * scale_mod)

	# Flip sprite for enemies (face left)
	if not is_player_owned:
		sprite.flip_h = true


func _update_hp_bar() -> void:
	if not creature or not hp_bar_fill:
		return

	var hp_percent := float(creature.current_hp) / float(creature.max_hp)
	hp_bar_fill.size.x = HP_BAR_WIDTH * hp_percent

	# Color based on HP percentage
	if hp_percent > 0.5:
		hp_bar_fill.color = Color(0.2, 0.8, 0.2)  # Green
	elif hp_percent > 0.25:
		hp_bar_fill.color = Color(0.9, 0.8, 0.1)  # Yellow
	else:
		hp_bar_fill.color = Color(0.9, 0.2, 0.2)  # Red


func _update_action_bar_visual() -> void:
	if not action_bar_fill:
		return

	action_bar_fill.size.x = ACTION_BAR_WIDTH * action_bar

	# Cyan/blue color for action bar
	if swap_freeze_remaining > 0:
		action_bar_fill.color = Color(0.4, 0.4, 0.4)  # Gray when frozen
	else:
		action_bar_fill.color = Color(0.2, 0.6, 0.9)  # Blue


func _update_name_label() -> void:
	if not creature or not name_label:
		return

	var display_name := creature.nickname if creature.nickname != "" else ""
	if display_name == "":
		var species := GameState.get_species(creature.species_id)
		if species:
			display_name = species.display_name

	name_label.text = display_name + " Lv" + str(creature.level)


func _update_swap_freeze_display() -> void:
	if swap_freeze_label:
		swap_freeze_label.text = "%.1f" % swap_freeze_remaining
		swap_freeze_label.show()


## Apply swap-in freeze (5 seconds)
func apply_swap_freeze(duration: float = 5.0) -> void:
	swap_freeze_remaining = duration
	action_bar = 0.0
	_update_swap_freeze_display()


## Reset action bar to 0 (called on failed flee)
func reset_action_bar() -> void:
	action_bar = 0.0
	_update_action_bar_visual()


## Take damage (returns actual damage dealt after shield)
func take_damage(amount: int) -> int:
	if not creature:
		return 0

	var actual_damage := amount

	# Shield absorbs damage first
	if shield_amount > 0:
		var blocked := mini(shield_amount, amount)
		shield_amount -= blocked
		actual_damage -= blocked

	creature.take_damage(actual_damage)
	_update_hp_bar()

	took_damage.emit(self, actual_damage)

	if creature.is_fainted():
		_on_fainted()

	return actual_damage


## Heal the creature
func heal(amount: int) -> int:
	if not creature:
		return 0

	var old_hp := creature.current_hp
	creature.heal(amount)
	var actual_heal := creature.current_hp - old_hp

	_update_hp_bar()
	healed.emit(self, actual_heal)

	return actual_heal


## Add shield
func add_shield(amount: int) -> void:
	shield_amount += amount


## Called when creature faints
func _on_fainted() -> void:
	# Visual feedback
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

	fainted.emit(self)


## Get the currently selected move data
func get_selected_move() -> MoveData:
	if not creature or creature.active_moves.size() <= selected_move_index:
		return null

	var move_id := creature.active_moves[selected_move_index]
	return GameState.get_move(move_id)


## Check if this combatant can act (not fainted, not frozen)
func can_act() -> bool:
	if not creature:
		return false
	return not creature.is_fainted() and swap_freeze_remaining <= 0
