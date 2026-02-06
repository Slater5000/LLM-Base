extends Node2D
class_name BattleScene
## Main battle scene - displays creatures, handles combat visuals.

signal battle_ready
signal combatant_action_ready(combatant: Node2D)

## References set by scene
@onready var background: Sprite2D = $Background
@onready var player_side: Node2D = $Creatures/PlayerSide
@onready var enemy_side: Node2D = $Creatures/EnemySide
@onready var pause_indicator: Label = $UI/PauseIndicator
@onready var debug_label: Label = $UI/DebugLabel
@onready var battle_hud: BattleHUD = $UI/BattleHUD

## Battle context (set by BattleManager)
var _target_species: String = ""
var _is_wild_encounter: bool = false
var _was_scanned: bool = false

## Combatant arrays
var _player_combatants: Array[Combatant] = []
var _enemy_combatants: Array[Combatant] = []

## Combatant scene for instantiation
const COMBATANT_SCENE := preload("res://scenes/battle/combatant.tscn")

## Staggered positions for 3v3 layout (relative to side anchor)
## Player side anchor is at (160, 180), enemy at (480, 180)
const PLAYER_POSITIONS := [
	Vector2(0, -50),    # Top slot
	Vector2(-30, 20),   # Middle slot (slightly back)
	Vector2(0, 90)      # Bottom slot
]
const ENEMY_POSITIONS := [
	Vector2(0, -50),    # Top slot
	Vector2(30, 20),    # Middle slot (slightly back)
	Vector2(0, 90)      # Bottom slot
]


func _ready() -> void:
	# Set process mode to stop when paused
	process_mode = Node.PROCESS_MODE_PAUSABLE
	print("[BattleScene] Ready")

	# Connect to BattleManager signals
	var battle_manager := get_node_or_null("/root/BattleManager")
	if battle_manager:
		battle_manager.battle_paused.connect(_on_battle_paused)
		battle_manager.battle_resumed.connect(_on_battle_resumed)


func _on_battle_paused() -> void:
	if pause_indicator:
		pause_indicator.show()


func _on_battle_resumed() -> void:
	if pause_indicator:
		pause_indicator.hide()


## Called by BattleManager to initialize the battle
func setup(target_species: String, is_wild: bool, was_scanned: bool) -> void:
	_target_species = target_species
	_is_wild_encounter = is_wild
	_was_scanned = was_scanned

	print("[BattleScene] Setup - target: ", target_species, " wild: ", is_wild)

	# Update debug label
	if debug_label:
		var scan_status := "scanned" if was_scanned else "not scanned"
		debug_label.text = "Battle vs " + target_species + " (" + scan_status + ")\nPress SPACE to pause, ESC to exit"

	# Setup player combatants from party
	_setup_player_combatants()

	# Setup enemy combatants
	if is_wild:
		_setup_wild_enemies(target_species)
	else:
		# TODO: Trainer battles - enemies passed in from BattleManager
		pass

	# Setup the HUD
	_setup_hud()

	battle_ready.emit()


## Setup player side combatants from party (first 3 non-fainted)
func _setup_player_combatants() -> void:
	_player_combatants.clear()

	# Get party creatures
	var party := GameState.get_party()
	var slot_index := 0

	for i in range(party.size()):
		if slot_index >= 3:
			break

		var creature: CreatureInstance = party[i]
		if creature and not creature.is_fainted():
			var combatant := _spawn_combatant(creature, true, slot_index)
			_player_combatants.append(combatant)
			slot_index += 1

	print("[BattleScene] Spawned ", _player_combatants.size(), " player combatants")


## Setup wild encounter enemies (target + 2 helpers)
func _setup_wild_enemies(target_species: String) -> void:
	_enemy_combatants.clear()

	# Create the target creature at appropriate level
	var target_creature := _create_wild_creature(target_species)
	var target_combatant := _spawn_combatant(target_creature, false, 0)
	_enemy_combatants.append(target_combatant)

	# Create 2 helper creatures
	var helpers := _select_helper_species(target_species)
	for i in range(helpers.size()):
		var helper_creature := _create_wild_creature(helpers[i])
		var helper_combatant := _spawn_combatant(helper_creature, false, i + 1)
		_enemy_combatants.append(helper_combatant)

	print("[BattleScene] Spawned ", _enemy_combatants.size(), " enemy combatants")


## Spawn a combatant node and add to appropriate side
func _spawn_combatant(creature: CreatureInstance, is_player: bool, slot_index: int) -> Combatant:
	var combatant: Combatant = COMBATANT_SCENE.instantiate()

	# Add to correct parent
	var parent := player_side if is_player else enemy_side
	parent.add_child(combatant)

	# Position based on slot
	var positions := PLAYER_POSITIONS if is_player else ENEMY_POSITIONS
	if slot_index < positions.size():
		combatant.position = positions[slot_index]

	# Setup with creature data
	combatant.setup(creature, is_player)

	# Connect signals
	combatant.action_ready.connect(_on_combatant_action_ready)
	combatant.fainted.connect(_on_combatant_fainted)

	return combatant


## Create a wild creature instance
func _create_wild_creature(species_id: String) -> CreatureInstance:
	# Determine level based on player's party average (±2 levels)
	var avg_level := _get_party_average_level()
	var wild_level := clampi(avg_level + randi_range(-2, 2), 1, 50)

	return GameState.create_creature(species_id, wild_level, "Wild Encounter")


## Get average level of player's active party
func _get_party_average_level() -> int:
	var total := 0
	var count := 0

	for creature in GameState.get_party():
		if creature:
			total += creature.level
			count += 1

	return total / count if count > 0 else 5


## Select 2 helper species for wild encounter
func _select_helper_species(target_species: String) -> Array[String]:
	var helpers: Array[String] = []

	# Get all discovered species (for now, use all species as fallback)
	var all_species := GameState.get_all_species()
	var available: Array[String] = []

	for species in all_species:
		if species.species_id != target_species:
			available.append(species.species_id)

	# Shuffle and pick up to 2
	available.shuffle()

	for i in range(mini(2, available.size())):
		helpers.append(available[i])

	return helpers


## Called when a combatant's action bar fills
func _on_combatant_action_ready(combatant: Combatant) -> void:
	combatant_action_ready.emit(combatant)

	# Execute the selected move
	_execute_move(combatant)

	# Reset action bar after move
	combatant.action_bar = 0.0

	# Notify BattleManager that a player action occurred (for flee tracking)
	if combatant.is_player_owned:
		var battle_manager := get_node_or_null("/root/BattleManager")
		if battle_manager:
			battle_manager.on_player_action()


## Called when a combatant faints
func _on_combatant_fainted(combatant: Combatant) -> void:
	print("[BattleScene] Combatant fainted: ", combatant.creature.species_id if combatant.creature else "unknown")
	_check_battle_end()


## Execute a combatant's selected move
func _execute_move(combatant: Combatant) -> void:
	var move := combatant.get_selected_move()
	if not move:
		print("[BattleScene] No move selected for combatant")
		return

	print("[BattleScene] Executing move: ", move.display_name)

	# Get target based on move type
	var target := _get_auto_target(combatant, move)
	if not target:
		print("[BattleScene] No valid target")
		return

	# Execute based on move effect type
	match move.effect_type:
		"damage":
			_apply_damage(combatant, target, move)
		"heal":
			_apply_heal(combatant, target, move)
		"shield":
			_apply_shield(combatant, target, move)
		"buff":
			_apply_buff(combatant, target, move)
		"debuff":
			_apply_debuff(combatant, target, move)
		_:
			# Default to damage
			_apply_damage(combatant, target, move)


## Get auto-target for a move
func _get_auto_target(user: Combatant, move: MoveData) -> Combatant:
	var allies := _player_combatants if user.is_player_owned else _enemy_combatants
	var enemies := _enemy_combatants if user.is_player_owned else _player_combatants

	# Filter to alive targets
	var alive_allies := allies.filter(func(c): return c and c.creature and not c.creature.is_fainted())
	var alive_enemies := enemies.filter(func(c): return c and c.creature and not c.creature.is_fainted())

	match move.effect_type:
		"heal", "shield", "buff":
			# Target self or lowest HP ally
			if move.target_type == "self":
				return user
			elif alive_allies.size() > 0:
				# Target lowest HP ally
				var lowest: Combatant = alive_allies[0]
				for ally in alive_allies:
					if ally.creature.current_hp < lowest.creature.current_hp:
						lowest = ally
				return lowest
		"debuff":
			# Target enemy (fastest or highest HP)
			if alive_enemies.size() > 0:
				return alive_enemies[0]
		_:
			# Damage moves target enemies
			if alive_enemies.size() > 0:
				# Target lowest HP enemy for focus fire
				var lowest: Combatant = alive_enemies[0]
				for enemy in alive_enemies:
					if enemy.creature.current_hp < lowest.creature.current_hp:
						lowest = enemy
				return lowest

	return null


## Apply damage from a move
func _apply_damage(attacker: Combatant, defender: Combatant, move: MoveData) -> void:
	if not attacker.creature or not defender.creature:
		return

	# Damage formula: (attacker.attack / defender.defense) * move.power
	var damage := int((float(attacker.creature.attack) / float(defender.creature.defense)) * move.power)
	damage = maxi(damage, 1)  # Minimum 1 damage

	var actual_damage := defender.take_damage(damage)
	print("[BattleScene] ", attacker.creature.species_id, " dealt ", actual_damage, " damage to ", defender.creature.species_id)

	# TODO: Spawn floating damage number


## Apply healing from a move
func _apply_heal(healer: Combatant, target: Combatant, move: MoveData) -> void:
	if not healer.creature or not target.creature:
		return

	# Heal formula: (healer.attack / 150) * move.power
	var heal_amount := int((float(healer.creature.attack) / 150.0) * move.power)
	heal_amount = maxi(heal_amount, 1)

	var actual_heal := target.heal(heal_amount)
	print("[BattleScene] ", healer.creature.species_id, " healed ", target.creature.species_id, " for ", actual_heal)


## Apply shield from a move
func _apply_shield(user: Combatant, target: Combatant, move: MoveData) -> void:
	if not user.creature or not target.creature:
		return

	# Shield formula: (user.defense / 150) * move.power
	var shield_amount := int((float(user.creature.defense) / 150.0) * move.power)
	shield_amount = maxi(shield_amount, 1)

	target.add_shield(shield_amount)
	print("[BattleScene] ", user.creature.species_id, " granted ", shield_amount, " shield to ", target.creature.species_id)


## Apply buff from a move
func _apply_buff(user: Combatant, target: Combatant, move: MoveData) -> void:
	if not user.creature or not target.creature:
		return

	# TODO: Implement buff system with duration and stat modifiers
	print("[BattleScene] ", user.creature.species_id, " buffed ", target.creature.species_id, " with ", move.display_name)


## Apply debuff from a move
func _apply_debuff(user: Combatant, target: Combatant, move: MoveData) -> void:
	if not user.creature or not target.creature:
		return

	# Handle bar_fill_rate debuff (like Sand Blast)
	if move.stat_affected == "bar_fill_rate":
		# stat_modifier is a decimal like -0.2 for -20%
		target.action_bar_fill_rate *= (1.0 + move.stat_modifier)
		var percent := int(abs(move.stat_modifier) * 100)
		print("[BattleScene] ", user.creature.species_id, " slowed ", target.creature.species_id, "'s action bar by ", percent, "%")
	else:
		# TODO: Handle other stat debuffs (attack, defense, speed)
		print("[BattleScene] ", user.creature.species_id, " debuffed ", target.creature.species_id, " with ", move.display_name)


## Check for victory or defeat
func _check_battle_end() -> void:
	# Check if all enemies fainted
	var all_enemies_fainted := true
	for enemy in _enemy_combatants:
		if enemy and enemy.creature and not enemy.creature.is_fainted():
			all_enemies_fainted = false
			break

	if all_enemies_fainted:
		print("[BattleScene] VICTORY!")
		var battle_manager := get_node_or_null("/root/BattleManager")
		if battle_manager and battle_manager.has_method("_end_battle"):
			# Give a brief pause before ending
			await get_tree().create_timer(1.0).timeout
			battle_manager._end_battle("victory")
		return

	# Check if all player combatants fainted
	var all_players_fainted := true
	for player in _player_combatants:
		if player and player.creature and not player.creature.is_fainted():
			all_players_fainted = false
			break

	if all_players_fainted:
		print("[BattleScene] DEFEAT!")
		var battle_manager := get_node_or_null("/root/BattleManager")
		if battle_manager and battle_manager.has_method("_end_battle"):
			await get_tree().create_timer(1.0).timeout
			battle_manager._end_battle("defeat")
		return


## Reset all player action bars to 0 (called on failed flee)
func reset_player_action_bars() -> void:
	for combatant in _player_combatants:
		if combatant and combatant.has_method("reset_action_bar"):
			combatant.reset_action_bar()


## Setup the battle HUD
func _setup_hud() -> void:
	if not battle_hud:
		return

	# Pass player combatants to the HUD
	battle_hud.setup(_player_combatants, _is_wild_encounter)

	# Connect HUD signals
	battle_hud.swap_requested.connect(_on_swap_requested)
	battle_hud.flee_requested.connect(_on_flee_requested)
	battle_hud.move_selected.connect(_on_move_selected)


## Called when player requests a swap
func _on_swap_requested() -> void:
	print("[BattleScene] Swap requested")
	# TODO: Open swap overlay
	var battle_manager := get_node_or_null("/root/BattleManager")
	if battle_manager:
		battle_manager.toggle_pause()  # Pause for swap selection


## Called when player requests to flee
func _on_flee_requested() -> void:
	print("[BattleScene] Flee requested")
	var battle_manager := get_node_or_null("/root/BattleManager")
	if battle_manager:
		battle_manager.attempt_flee()


## Called when player selects a move for a combatant
func _on_move_selected(combatant: Combatant, move_index: int) -> void:
	print("[BattleScene] Move selected: ", move_index, " for ", combatant.creature.species_id if combatant.creature else "unknown")
	# The move_index is already set on the combatant by the MovePanel
	# Move execution happens when action bar fills (in _on_combatant_action_ready)


## Get player combatants (for external access)
func get_player_combatants() -> Array[Combatant]:
	return _player_combatants


## Get enemy combatants (for external access)
func get_enemy_combatants() -> Array[Combatant]:
	return _enemy_combatants
