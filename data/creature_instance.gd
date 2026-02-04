class_name CreatureInstance extends RefCounted
## A specific creature owned by the player.
## References a CreatureSpecies but has unique stats, moves, and identity.

## Unique identifier for this specific creature instance
var instance_id: String = ""
## Reference to the species (e.g., "fire_starter_1")
var species_id: String = ""
## Player-given nickname (empty = use species display name)
var nickname: String = ""

## Level and experience
var level: int = 1
var current_xp: int = 0

## Current stats (calculated from base stats + level)
var max_hp: int = 0
var current_hp: int = 0
var attack: int = 0
var defense: int = 0
var speed: int = 0

## Moves this creature knows (up to 15)
var learned_moves: Array[String] = []
## Moves equipped for battle (exactly 3)
var active_moves: Array[String] = []

## Capture metadata
var caught_timestamp: int = 0
var caught_location: String = ""


## Create a new creature instance with a unique ID
static func create(p_species_id: String, p_level: int = 1) -> CreatureInstance:
	var instance := CreatureInstance.new()
	instance.instance_id = _generate_uuid()
	instance.species_id = p_species_id
	instance.level = p_level
	instance.caught_timestamp = int(Time.get_unix_time_from_system())
	return instance


## Generate a simple UUID
static func _generate_uuid() -> String:
	var chars := "abcdef0123456789"
	var uuid := ""
	for i in 32:
		if i in [8, 12, 16, 20]:
			uuid += "-"
		uuid += chars[randi() % chars.length()]
	return uuid


## Get display name (nickname if set, otherwise species name from GameState)
func get_display_name() -> String:
	if nickname != "":
		return nickname
	# Fallback to species_id if no nickname
	# In practice, UI should look up species display_name via GameState
	return species_id


## Check if creature is fainted
func is_fainted() -> bool:
	return current_hp <= 0


## Check if creature is at full health
func is_full_health() -> bool:
	return current_hp >= max_hp


## Heal creature by amount (capped at max_hp)
func heal(amount: int) -> int:
	var old_hp := current_hp
	current_hp = mini(current_hp + amount, max_hp)
	return current_hp - old_hp


## Fully heal creature
func full_heal() -> void:
	current_hp = max_hp


## Take damage (capped at 0)
func take_damage(amount: int) -> int:
	var old_hp := current_hp
	current_hp = maxi(current_hp - amount, 0)
	return old_hp - current_hp


## Calculate stats from base stats and level
## Call this after creating instance or leveling up
func calculate_stats(species: CreatureSpecies) -> void:
	# Simple formula: base + (base * level * 0.1)
	# At level 1: stat = base * 1.1
	# At level 50: stat = base * 6.0
	var level_multiplier := 1.0 + (level * 0.1)

	max_hp = int(species.base_hp * level_multiplier)
	attack = int(species.base_attack * level_multiplier)
	defense = int(species.base_defense * level_multiplier)
	speed = int(species.base_speed * level_multiplier)

	# Heal to full on first calculation (new creature)
	if current_hp == 0:
		current_hp = max_hp


## Learn a new move (if not already known)
func learn_move(move_id: String) -> bool:
	if move_id in learned_moves:
		return false
	if learned_moves.size() >= 15:
		return false
	learned_moves.append(move_id)
	return true


## Set active moves for battle (must be from learned moves)
func set_active_moves(moves: Array[String]) -> bool:
	for move in moves:
		if move not in learned_moves:
			return false
	if moves.size() > 3:
		return false
	active_moves = moves.duplicate()
	return true


## Convert to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"species_id": species_id,
		"nickname": nickname,
		"level": level,
		"current_xp": current_xp,
		"max_hp": max_hp,
		"current_hp": current_hp,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"learned_moves": learned_moves,
		"active_moves": active_moves,
		"caught_timestamp": caught_timestamp,
		"caught_location": caught_location
	}


## Create from saved dictionary
static func from_dict(data: Dictionary) -> CreatureInstance:
	var instance := CreatureInstance.new()
	instance.instance_id = data.get("instance_id", "")
	instance.species_id = data.get("species_id", "")
	instance.nickname = data.get("nickname", "")
	instance.level = data.get("level", 1)
	instance.current_xp = data.get("current_xp", 0)
	instance.max_hp = data.get("max_hp", 0)
	instance.current_hp = data.get("current_hp", 0)
	instance.attack = data.get("attack", 0)
	instance.defense = data.get("defense", 0)
	instance.speed = data.get("speed", 0)

	# Handle arrays
	var learned = data.get("learned_moves", [])
	instance.learned_moves = []
	for move in learned:
		instance.learned_moves.append(str(move))

	var active = data.get("active_moves", [])
	instance.active_moves = []
	for move in active:
		instance.active_moves.append(str(move))

	instance.caught_timestamp = data.get("caught_timestamp", 0)
	instance.caught_location = data.get("caught_location", "")

	return instance
