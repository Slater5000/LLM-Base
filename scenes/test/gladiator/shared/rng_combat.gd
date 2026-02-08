class_name RNGCombat
extends Node
## Handles RNG-based combat chains between two gladiators
## Each move has weighted outcomes that chain into other moves

signal combat_started
signal combat_ended(winner)  # Duck typed - works with any fighter class
signal move_executed(attacker, move: String, outcome: String)
signal chain_continued(attacker, next_move: String)

@export var time_between_moves: float = 0.8
@export var time_between_chains: float = 0.3

# Duck typed - accepts any object with play_animation(), take_damage(), is_alive()
var fighter_a
var fighter_b
var current_attacker
var current_defender
var is_fighting: bool = false
var move_timer: float = 0.0

# Move definitions with damage and chain options
const MOVES := {
	"punch": {
		"damage": 10,
		"speed": 0.4,
		"outcomes": {
			"hit": {"weight": 50, "chains": ["punch", "kick", "uppercut"]},
			"blocked": {"weight": 30, "chains": ["block", "dodge"]},
			"dodged": {"weight": 15, "chains": ["dodge", "sweep"]},
			"countered": {"weight": 5, "chains": ["hit"]},
		}
	},
	"kick": {
		"damage": 15,
		"speed": 0.5,
		"outcomes": {
			"hit": {"weight": 45, "chains": ["sweep", "punch", "kick"]},
			"blocked": {"weight": 35, "chains": ["dodge", "block"]},
			"dodged": {"weight": 15, "chains": ["dodge", "uppercut"]},
			"countered": {"weight": 5, "chains": ["hit"]},
		}
	},
	"block": {
		"damage": 0,
		"speed": 0.3,
		"outcomes": {
			"success": {"weight": 70, "chains": ["punch", "kick"]},
			"broken": {"weight": 20, "chains": ["dodge", "block"]},
			"counter": {"weight": 10, "chains": ["uppercut", "sweep"]},
		}
	},
	"dodge": {
		"damage": 0,
		"speed": 0.35,
		"outcomes": {
			"success": {"weight": 60, "chains": ["punch", "kick", "uppercut"]},
			"caught": {"weight": 25, "chains": ["block", "dodge"]},
			"perfect": {"weight": 15, "chains": ["uppercut", "sweep", "kick"]},
		}
	},
	"uppercut": {
		"damage": 25,
		"speed": 0.6,
		"outcomes": {
			"hit": {"weight": 40, "chains": ["kick", "sweep"]},
			"blocked": {"weight": 35, "chains": ["block", "dodge"]},
			"dodged": {"weight": 20, "chains": ["dodge"]},
			"countered": {"weight": 5, "chains": ["hit"]},
		}
	},
	"sweep": {
		"damage": 12,
		"speed": 0.55,
		"outcomes": {
			"hit": {"weight": 45, "chains": ["uppercut", "punch"]},
			"jumped": {"weight": 35, "chains": ["kick", "dodge"]},
			"blocked": {"weight": 15, "chains": ["block"]},
			"countered": {"weight": 5, "chains": ["hit"]},
		}
	},
}

# Starting moves for initiating combat
const OPENER_MOVES := ["punch", "kick", "dodge"]


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if not is_fighting:
		return

	move_timer -= delta
	if move_timer <= 0:
		_execute_next_move()


func start_combat(a, b) -> void:
	fighter_a = a
	fighter_b = b

	# Randomly decide who attacks first
	if randf() > 0.5:
		current_attacker = fighter_a
		current_defender = fighter_b
	else:
		current_attacker = fighter_b
		current_defender = fighter_a

	is_fighting = true
	move_timer = 0.5  # Brief pause before combat starts
	combat_started.emit()


func stop_combat() -> void:
	is_fighting = false


func _execute_next_move() -> void:
	if not is_fighting:
		return

	# Check for victory
	if not fighter_a.is_alive():
		_end_combat(fighter_b)
		return
	if not fighter_b.is_alive():
		_end_combat(fighter_a)
		return

	# Pick a move
	var move_name: String
	if current_attacker.current_animation == "idle":
		# Starting fresh, pick an opener
		move_name = OPENER_MOVES[randi() % OPENER_MOVES.size()]
	else:
		# Continue chain based on previous outcome
		move_name = _pick_chain_move()

	# Execute the move
	_perform_move(move_name)


func _pick_chain_move() -> String:
	# Default to random opener if no chain data
	return OPENER_MOVES[randi() % OPENER_MOVES.size()]


func _perform_move(move_name: String) -> void:
	var move_data: Dictionary = MOVES.get(move_name, MOVES["punch"])

	# Play attacker animation
	current_attacker.play_animation(move_name)

	# Roll for outcome
	var outcome := _roll_outcome(move_data["outcomes"])
	var outcome_data: Dictionary = move_data["outcomes"][outcome]

	# Apply effects based on outcome
	match outcome:
		"hit":
			# Attacker lands the hit
			await get_tree().create_timer(move_data["speed"] * 0.7).timeout
			current_defender.take_damage(move_data["damage"])
			current_defender.play_animation("hit")
			move_executed.emit(current_attacker, move_name, outcome)

		"blocked":
			# Defender blocks
			await get_tree().create_timer(move_data["speed"] * 0.5).timeout
			current_defender.play_animation("block")
			move_executed.emit(current_attacker, move_name, outcome)

		"dodged", "jumped":
			# Defender dodges
			await get_tree().create_timer(move_data["speed"] * 0.4).timeout
			current_defender.play_animation("dodge")
			move_executed.emit(current_attacker, move_name, outcome)

		"countered":
			# Defender counters - swap roles and deal damage
			await get_tree().create_timer(move_data["speed"] * 0.6).timeout
			current_attacker.take_damage(int(move_data["damage"] * 0.5))
			current_attacker.play_animation("hit")
			_swap_roles()
			move_executed.emit(current_defender, "counter", outcome)

		"success", "perfect":
			# Defensive move succeeded
			move_executed.emit(current_attacker, move_name, outcome)
			if outcome == "perfect":
				_swap_roles()

		"broken", "caught":
			# Defensive move failed
			current_attacker.take_damage(5)
			move_executed.emit(current_attacker, move_name, outcome)

	# Determine next move
	var next_moves: Array = outcome_data.get("chains", OPENER_MOVES)
	var next_move: String = next_moves[randi() % next_moves.size()]

	# 30% chance to swap attacker/defender for variety
	if randf() < 0.3 and move_name not in ["block", "dodge"]:
		_swap_roles()

	chain_continued.emit(current_attacker, next_move)

	# Set timer for next move
	move_timer = time_between_moves + randf_range(-0.2, 0.2)


func _roll_outcome(outcomes: Dictionary) -> String:
	var total_weight := 0
	for outcome_name in outcomes:
		total_weight += outcomes[outcome_name]["weight"]

	var roll := randi() % total_weight
	var cumulative := 0

	for outcome_name in outcomes:
		cumulative += outcomes[outcome_name]["weight"]
		if roll < cumulative:
			return outcome_name

	return outcomes.keys()[0]


func _swap_roles() -> void:
	var temp = current_attacker
	current_attacker = current_defender
	current_defender = temp


func _end_combat(winner) -> void:
	is_fighting = false
	winner.play_animation("victory")

	var loser = fighter_a if winner == fighter_b else fighter_b
	loser.play_animation("defeat")

	combat_ended.emit(winner)
