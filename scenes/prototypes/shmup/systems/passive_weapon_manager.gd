extends Node2D
## Manages all passive weapons: timers, targeting, damage, and VFX.
## Each weapon has a level (0 = inactive), a cooldown timer, and a fire function.
## VFX use the Nova Drift triple-layer technique: geometry drawn via _draw().

# ==========================================================================
# CONSTANTS (must come before vars for gdlint ordering)
# ==========================================================================

# --- Death Spiral ---
const SPIRAL_HIT_COOLDOWN := 0.4
const SPIRAL_ORBIT_RADIUS := 40.0
const SPIRAL_ROTATION_SPEED := 2.5  # rad/s

# --- Fireball: [timer, radius, damage] per level ---
const FIREBALL_DATA := [
	[3.0, 30.0, 2], [2.5, 40.0, 3],
	[2.0, 50.0, 4], [1.5, 60.0, 5], [1.0, 70.0, 7],
]
# --- Chain Lightning: [timer, chain_count] per level ---
const CHAIN_LIGHTNING_DATA := [
	[2.0, 2], [1.7, 3], [1.4, 4], [1.1, 5], [0.8, 6],
]
# Death Spiral: blade_count per level (1-5)
# --- Ice Nova: [timer, radius, freeze_duration] per level ---
const ICE_NOVA_DATA := [
	[6.0, 50.0, 2.0], [5.0, 60.0, 2.5],
	[4.0, 70.0, 3.0], [3.0, 80.0, 4.0],
	[2.5, 100.0, 5.0],
]
# --- Thunder Strike: [timer, strikes_per_cast] per level ---
const THUNDER_STRIKE_DATA := [
	[3.0, 1], [2.5, 1], [2.0, 1], [1.5, 2], [1.0, 2],
]
const THUNDER_DAMAGE := 3
# --- Gravity Well: [timer, radius, collapse_damage] per level ---
const GRAVITY_WELL_DATA := [
	[7.0, 50.0, 2], [6.0, 60.0, 3],
	[4.5, 70.0, 4], [3.0, 80.0, 6], [2.0, 100.0, 8],
]
const GRAVITY_WELL_PULL_DURATION := 2.0

# --- Thorn Aura: [radius, damage] per level ---
const THORN_AURA_DATA := [
	[30.0, 1], [45.0, 2], [60.0, 3], [80.0, 4], [100.0, 6],
]
const THORN_AURA_TICK := 0.5
# --- Poison Cloud: [radius, dps] per level ---
const POISON_CLOUD_DATA := [
	[40.0, 1.0], [60.0, 2.0], [90.0, 3.0],
]
const POISON_CLOUD_TICK := 0.5
# --- Shockwave: [cooldown, max_radius, damage] per level ---
const SHOCKWAVE_DATA := [
	[4.0, 60.0, 2], [3.5, 80.0, 2],
	[3.0, 100.0, 3], [2.0, 120.0, 4], [1.5, 150.0, 5],
]
# --- Meteor Shower: [cooldown, count] per level ---
const METEOR_SHOWER_DATA := [
	[4.0, 1], [3.5, 1], [3.0, 2], [2.5, 2], [2.0, 3],
]
const METEOR_DAMAGE := 4
const METEOR_RADIUS := 35.0
const METEOR_FALL_TIME := 0.6
const METEOR_SHADOW_TIME := 0.4
# --- Holy Water: [cooldown, radius, zone_duration, dps] ---
const HOLY_WATER_DATA := [
	[5.0, 35.0, 3.0, 1], [4.0, 45.0, 3.5, 1],
	[3.5, 55.0, 4.0, 2], [3.0, 65.0, 4.5, 2],
	[2.5, 80.0, 5.0, 3],
]
const HOLY_WATER_TICK := 0.5
# --- Drone Swarm ---
const DRONE_SWARM_COUNTS := [1, 2, 3, 4, 6]
const DRONE_ORBIT_RADIUS := 80.0
const DRONE_ORBIT_SPEED := 2.0  # rad/s
const DRONE_DAMAGE := 1
const DRONE_HIT_COOLDOWN := 0.3
# --- Homing Missiles: [cooldown, count] per level ---
const HOMING_MISSILE_DATA := [
	[3.0, 1], [2.5, 1], [2.0, 2], [1.5, 3], [1.0, 4],
]
const MISSILE_SPEED := 250.0
const MISSILE_TURN_SPEED := 4.0  # rad/s
const MISSILE_DAMAGE := 3
const MISSILE_LIFESPAN := 3.0
# --- Runetracer: [max_count, lifespan, spawn_cd] ---
const RUNETRACER_DATA := [
	[1, 4.0, 3.0], [1, 6.0, 3.0], [2, 6.0, 2.5],
	[3, 8.0, 2.0], [4, 10.0, 1.5],
]
const RUNETRACER_SPEED := 200.0
const RUNETRACER_DAMAGE := 2
const RUNETRACER_HIT_COOLDOWN := 0.3
# --- Soul Harvest: [chance, radius, damage] per level ---
const SOUL_HARVEST_DATA := [
	[0.15, 35.0, 2], [0.25, 50.0, 3], [0.40, 70.0, 4],
]

# ==========================================================================
# VARIABLES
# ==========================================================================

# External references (set by shmup_main)
var player: Area2D
var enemy_container: Node2D
var vfx_manager: Node2D
var spring_grid: Node2D
var camera: Node2D  # Camera2D with add_trauma()

# Weapon levels (0 = inactive, 1-5 = active)
var weapon_levels: Dictionary = {}
var _weapon_timers: Dictionary = {}

# Active visual effects for _draw()
var _active_effects: Array = []

# Death Spiral state
var _spiral_rotation := 0.0
var _spiral_hit_cooldowns: Dictionary = {}
# Gravity Well state
var _active_wells: Array = []

# Phase E weapon state
var _thorn_aura_timer := 0.0
var _poison_cloud_timer := 0.0
var _active_holy_zones: Array = []
var _active_missiles: Array = []
var _active_runes: Array = []
var _rune_spawn_timer := 0.0
var _drone_rotation := 0.0
var _drone_hit_cooldowns: Dictionary = {}

# Evolution state (set by shmup_main via set_evolution)
var _active_evolutions: Dictionary = {}

# Spatial grid for O(1) neighbor queries (set by setup)
var _spatial_grid: RefCounted
# Cached enemy list (rebuilt once per frame)
var _cached_enemies: Array = []
var _cached_enemies_frame := -1

# Elapsed time reference for hit cooldowns
var _time := 0.0


func setup(
	p_player: Area2D, p_enemies: Node2D,
	p_vfx: Node2D, p_grid: Node2D,
	p_camera: Node2D, p_spatial: RefCounted = null,
) -> void:
	player = p_player
	enemy_container = p_enemies
	vfx_manager = p_vfx
	spring_grid = p_grid
	camera = p_camera
	_spatial_grid = p_spatial


func reset() -> void:
	weapon_levels.clear()
	_weapon_timers.clear()
	_active_effects.clear()
	_spiral_rotation = 0.0
	_spiral_hit_cooldowns.clear()
	_active_wells.clear()
	_thorn_aura_timer = 0.0
	_poison_cloud_timer = 0.0
	_active_holy_zones.clear()
	_active_missiles.clear()
	_active_runes.clear()
	_rune_spawn_timer = 0.0
	_drone_rotation = 0.0
	_drone_hit_cooldowns.clear()
	_active_evolutions.clear()
	_cached_enemies.clear()
	_cached_enemies_frame = -1
	_time = 0.0


func set_weapon_level(weapon_id: String, level: int) -> void:
	var was_inactive: bool = weapon_levels.get(weapon_id, 0) == 0
	weapon_levels[weapon_id] = level
	# Initialize timer on first activation
	if was_inactive and level > 0:
		_weapon_timers[weapon_id] = 0.5  # Brief delay before first fire


func get_weapon_level(weapon_id: String) -> int:
	return weapon_levels.get(weapon_id, 0)


func set_evolution(id: String) -> void:
	_active_evolutions[id] = true


func has_evolution(id: String) -> bool:
	return _active_evolutions.get(id, false)


# ==========================================================================
# MAIN LOOP
# ==========================================================================

func _process(delta: float) -> void:
	if not player or not player.is_alive:
		return

	_time += delta

	# Tick weapon timers — Phase D
	_tick_fireball(delta)
	_tick_chain_lightning(delta)
	_tick_death_spiral(delta)
	_tick_ice_nova(delta)
	_tick_thunder_strike(delta)
	_tick_gravity_well(delta)
	# Phase E weapons
	_tick_thorn_aura(delta)
	_tick_poison_cloud(delta)
	_tick_shockwave(delta)
	_tick_meteor_shower(delta)
	_tick_holy_water(delta)
	_tick_drone_swarm(delta)
	_tick_homing_missiles(delta)
	_tick_runetracer(delta)
	# Soul Harvest has no tick — event-driven via on_enemy_killed()

	# Update persistent entities
	_update_gravity_wells(delta)
	_update_holy_zones(delta)

	# Update active visual effects
	_update_effects(delta)

	# Only redraw when passive weapons or effects exist
	if not weapon_levels.is_empty() or not _active_effects.is_empty():
		queue_redraw()


func _update_effects(delta: float) -> void:
	var i := _active_effects.size() - 1
	while i >= 0:
		_active_effects[i]["timer"] += delta
		if _active_effects[i]["timer"] >= _active_effects[i]["duration"]:
			var effect: Dictionary = _active_effects[i]
			# Fireball projectile arrival — trigger explosion
			if effect["type"] == "fireball_projectile":
				_fireball_explode(effect)
			# Meteor arrival — trigger impact
			if effect["type"] == "meteor_falling":
				if not effect["has_impacted"]:
					var tgt: Vector2 = effect["target_pos"]
					_meteor_impact(tgt)
			_active_effects.remove_at(i)
		i -= 1


func _fireball_explode(effect: Dictionary) -> void:
	var pos: Vector2 = effect["target_pos"] as Vector2
	var radius: float = float(effect["radius"])
	var damage: int = int(effect["damage"])

	_damage_enemies_in_radius(pos, radius, damage)

	# Inferno: leave burning ground zone
	if has_evolution("inferno"):
		_active_holy_zones.append({
			"pos": pos,
			"radius": radius * 0.8,
			"dps": 2,
			"timer": 0.0,
			"duration": 4.0,
			"tick_timer": 0.0,
			"style": "fire",
		})

	# Explosion VFX — triple expanding rings + particles + grid warp
	_active_effects.append({
		"type": "fireball_ring",
		"pos": pos,
		"radius": radius,
		"timer": 0.0,
		"duration": 0.4,
	})
	vfx_manager.spawn_explosion(pos, Color(1.0, 0.4, 0.1), 25, 4.0)
	if spring_grid:
		spring_grid.apply_explosive_force(pos, 0.8, radius)
	if camera:
		camera.add_trauma(0.15)


# ==========================================================================
# FIREBALL
# ==========================================================================

func _tick_fireball(delta: float) -> void:
	var level := get_weapon_level("fireball")
	if level <= 0:
		return

	var idx := clampi(level - 1, 0, FIREBALL_DATA.size() - 1)
	var cooldown: float = FIREBALL_DATA[idx][0]

	_weapon_timers["fireball"] = _weapon_timers.get("fireball", cooldown) - delta
	if _weapon_timers["fireball"] <= 0.0:
		_weapon_timers["fireball"] = cooldown
		_fire_fireball(level)


func _fire_fireball(level: int) -> void:
	var idx := clampi(level - 1, 0, FIREBALL_DATA.size() - 1)
	var radius: float = FIREBALL_DATA[idx][1]
	var damage: int = FIREBALL_DATA[idx][2]

	# Target nearest enemy
	var target_pos := _find_nearest_enemy_pos(player.position)
	if target_pos == Vector2.ZERO:
		return

	# Launch projectile — travels to target, then explodes on arrival
	var travel_dist := player.position.distance_to(target_pos)
	var travel_time := clampf(travel_dist / 400.0, 0.1, 0.4)  # 400 px/s
	_active_effects.append({
		"type": "fireball_projectile",
		"start_pos": player.position,
		"target_pos": target_pos,
		"radius": radius,
		"damage": damage,
		"timer": 0.0,
		"duration": travel_time,
	})


# ==========================================================================
# CHAIN LIGHTNING
# ==========================================================================

func _tick_chain_lightning(delta: float) -> void:
	var level := get_weapon_level("chain_lightning")
	if level <= 0:
		return

	var idx := clampi(level - 1, 0, CHAIN_LIGHTNING_DATA.size() - 1)
	var cooldown: float = CHAIN_LIGHTNING_DATA[idx][0]

	_weapon_timers["chain_lightning"] = _weapon_timers.get("chain_lightning", cooldown) - delta
	if _weapon_timers["chain_lightning"] <= 0.0:
		_weapon_timers["chain_lightning"] = cooldown
		_fire_chain_lightning(level)


func _fire_chain_lightning(level: int) -> void:
	var idx := clampi(level - 1, 0, CHAIN_LIGHTNING_DATA.size() - 1)
	var chain_count: int = CHAIN_LIGHTNING_DATA[idx][1]
	var is_ts := has_evolution("thunder_storm")
	# Thunder Storm: chain to ALL enemies (capped at 20)
	if is_ts:
		chain_count = 20

	# Build chain starting from nearest enemy to player
	var chain_points: Array[Vector2] = [player.position]
	var hit_enemies: Array = []

	var current_pos := player.position
	for _i in chain_count:
		var nearby: Array = _spatial_grid.query_radius(current_pos, 200.0) if _spatial_grid else []
		var best: Area2D = null
		var best_sq := 40000.0  # 200^2
		for e in nearby:
			if e in hit_enemies:
				continue
			var ent: Area2D = e as Area2D
			if not ent:
				continue
			var d_sq := current_pos.distance_squared_to(ent.position)
			if d_sq < best_sq:
				best_sq = d_sq
				best = ent
		if not best:
			break
		hit_enemies.append(best)
		chain_points.append(best.position)
		current_pos = best.position

	if hit_enemies.is_empty():
		return

	# Damage all chained enemies
	for e in hit_enemies:
		if e.has_method("take_damage"):
			e.take_damage(1)
		# Thunder Storm: freeze each hit enemy
		if is_ts and e.has_method("apply_freeze"):
			e.apply_freeze(1.0, 0.5)

	# VFX — lightning bolt effect (drawn for 0.15s with random regeneration)
	_active_effects.append({
		"type": "chain_lightning",
		"points": chain_points,
		"timer": 0.0,
		"duration": 0.15,
		"seed": randi(),
	})

	# Grid warp along chain
	if spring_grid:
		for pt in chain_points:
			spring_grid.apply_explosive_force(pt, 0.2, 20.0)


# ==========================================================================
# DEATH SPIRAL
# ==========================================================================

func _tick_death_spiral(delta: float) -> void:
	var level := get_weapon_level("death_spiral")
	if level <= 0:
		return

	# Continuous rotation
	_spiral_rotation += SPIRAL_ROTATION_SPEED * delta

	# Void Reaper: 2x orbit radius + gravitational pull
	var is_vr := has_evolution("void_reaper")
	var orbit_r := SPIRAL_ORBIT_RADIUS * (2.0 if is_vr else 1.0)

	# Check blade-enemy collisions
	var blade_count := level
	for i in blade_count:
		var angle := _spiral_rotation + (TAU / blade_count) * i
		var blade_pos := player.position + Vector2.from_angle(angle) * orbit_r

		for enemy in _query_nearby(blade_pos, 12.0):
			var eid: int = enemy.get_instance_id()
			var last_hit: float = _spiral_hit_cooldowns.get(eid, -999.0)
			if _time - last_hit >= SPIRAL_HIT_COOLDOWN:
				_spiral_hit_cooldowns[eid] = _time
				if enemy.has_method("take_damage"):
					enemy.take_damage(2)

	# Void Reaper: pull nearby enemies toward player
	if is_vr:
		var pull_range := orbit_r * 2.5
		for enemy in _query_nearby(player.position, pull_range):
			var d := player.position.distance_to(enemy.position)
			if d > 10.0:
				var pull: Vector2 = (player.position - enemy.position).normalized() * 50.0 * delta
				enemy.position += pull

	# Purge old cooldown entries periodically
	if Engine.get_process_frames() % 300 == 0:
		var to_remove: Array = []
		for eid in _spiral_hit_cooldowns:
			if _time - _spiral_hit_cooldowns[eid] > 2.0:
				to_remove.append(eid)
		for eid in to_remove:
			_spiral_hit_cooldowns.erase(eid)


# ==========================================================================
# ICE NOVA
# ==========================================================================

func _tick_ice_nova(delta: float) -> void:
	var level := get_weapon_level("ice_nova")
	if level <= 0:
		return

	var idx := clampi(level - 1, 0, ICE_NOVA_DATA.size() - 1)
	var cooldown: float = ICE_NOVA_DATA[idx][0]

	_weapon_timers["ice_nova"] = _weapon_timers.get("ice_nova", cooldown) - delta
	if _weapon_timers["ice_nova"] <= 0.0:
		_weapon_timers["ice_nova"] = cooldown
		_fire_ice_nova(level)


func _fire_ice_nova(level: int) -> void:
	var idx := clampi(level - 1, 0, ICE_NOVA_DATA.size() - 1)
	var max_radius: float = ICE_NOVA_DATA[idx][1]
	var freeze_dur: float = ICE_NOVA_DATA[idx][2]

	# Expanding ring effect
	_active_effects.append({
		"type": "ice_nova_ring",
		"pos": player.position,
		"max_radius": max_radius,
		"freeze_dur": freeze_dur,
		"timer": 0.0,
		"duration": 0.4,
		"damaged": false,
	})

	# Grid warp
	if spring_grid:
		spring_grid.apply_explosive_force(player.position, 0.5, max_radius)
	if camera:
		camera.add_trauma(0.1)


func _apply_ice_nova_damage(pos: Vector2, radius: float, freeze_dur: float) -> void:
	for enemy in _query_nearby(pos, radius):
		if enemy.has_method("take_damage"):
			enemy.take_damage(1)
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(freeze_dur, 0.5)


# ==========================================================================
# THUNDER STRIKE
# ==========================================================================

func _tick_thunder_strike(delta: float) -> void:
	var level := get_weapon_level("thunder_strike")
	if level <= 0:
		return

	var idx := clampi(level - 1, 0, THUNDER_STRIKE_DATA.size() - 1)
	var cooldown: float = THUNDER_STRIKE_DATA[idx][0]

	_weapon_timers["thunder_strike"] = _weapon_timers.get("thunder_strike", cooldown) - delta
	if _weapon_timers["thunder_strike"] <= 0.0:
		_weapon_timers["thunder_strike"] = cooldown
		_fire_thunder_strike(level)


func _fire_thunder_strike(level: int) -> void:
	var idx := clampi(level - 1, 0, THUNDER_STRIKE_DATA.size() - 1)
	var strikes: int = THUNDER_STRIKE_DATA[idx][1]

	var enemies := _query_nearby(player.position, 400.0)
	if enemies.is_empty():
		return

	for s in strikes:
		var target: Area2D = enemies[randi() % enemies.size()]
		var strike_pos := target.position

		# Damage
		if target.has_method("take_damage"):
			target.take_damage(THUNDER_DAMAGE)

		# Lightning bolt VFX from top of viewport
		var cam_top_y: float = camera.global_position.y - 180.0 if camera else strike_pos.y - 200.0
		var top_pos := Vector2(strike_pos.x + randf_range(-15, 15), cam_top_y)
		_active_effects.append({
			"type": "thunder_bolt",
			"start": top_pos,
			"end": strike_pos,
			"timer": 0.0,
			"duration": 0.2,
			"seed": randi(),
		})

		# Flash at strike point
		_active_effects.append({
			"type": "flash_circle",
			"pos": strike_pos,
			"timer": 0.0,
			"duration": 0.15,
			"max_radius": 20.0,
			"color": Color(0.5, 0.8, 1.0, 0.8),
		})

		# Grid warp + screen shake
		if spring_grid:
			spring_grid.apply_explosive_force(strike_pos, 1.0, 40.0)
		if camera:
			camera.add_trauma(0.25)

	# Brief screen flash for lightning illumination
	if vfx_manager:
		vfx_manager.flash_screen(Color(0.7, 0.85, 1.0, 0.1), 0.05)


# ==========================================================================
# GRAVITY WELL
# ==========================================================================

func _tick_gravity_well(delta: float) -> void:
	var level := get_weapon_level("gravity_well")
	if level <= 0:
		return

	var idx := clampi(level - 1, 0, GRAVITY_WELL_DATA.size() - 1)
	var cooldown: float = GRAVITY_WELL_DATA[idx][0]

	_weapon_timers["gravity_well"] = _weapon_timers.get("gravity_well", cooldown) - delta
	if _weapon_timers["gravity_well"] <= 0.0:
		_weapon_timers["gravity_well"] = cooldown
		_fire_gravity_well(level)


func _fire_gravity_well(level: int) -> void:
	var idx := clampi(level - 1, 0, GRAVITY_WELL_DATA.size() - 1)
	var radius: float = GRAVITY_WELL_DATA[idx][1]
	var collapse_damage: int = GRAVITY_WELL_DATA[idx][2]

	# Place well at densest enemy cluster near player
	var well_pos := _find_enemy_cluster_center(player.position, 120.0)
	if well_pos == Vector2.ZERO:
		well_pos = player.position + Vector2.from_angle(randf() * TAU) * 60.0

	_active_wells.append({
		"pos": well_pos,
		"timer": 0.0,
		"duration": GRAVITY_WELL_PULL_DURATION,
		"radius": radius,
		"pull_strength": 80.0 + level * 20.0,
		"collapse_damage": collapse_damage,
		"phase": "pulling",  # "pulling" → "collapsing"
	})


func _update_gravity_wells(delta: float) -> void:
	var i := _active_wells.size() - 1
	while i >= 0:
		var well: Dictionary = _active_wells[i]
		well["timer"] += delta

		if well["phase"] == "pulling":
			# Pull enemies toward well center
			var radius: float = well["radius"]
			var strength: float = well["pull_strength"]
			var is_sing := has_evolution("singularity")
			var well_pos: Vector2 = well["pos"]
			var nearby: Array = _spatial_grid.query_radius(well_pos, radius) if _spatial_grid else []
			for enemy in nearby:
				var dist := well_pos.distance_to(enemy.position)
				if dist > 5.0:
					var pull_dir: Vector2 = (well_pos - enemy.position).normalized()
					enemy.position += pull_dir * strength * (1.0 - dist / radius) * delta
					# Singularity: freeze while pulling
					if is_sing and enemy.has_method("apply_freeze"):
						enemy.apply_freeze(0.3, 0.8)

			# Grid implosion effect (continuous)
			if spring_grid and Engine.get_process_frames() % 3 == 0:
				spring_grid.apply_implosive_force(well["pos"], 0.3, radius * 0.8)

			# Transition to collapse
			if well["timer"] >= well["duration"]:
				well["phase"] = "collapsing"
				well["timer"] = 0.0
				# Collapse damage (Singularity: 3x)
				var c_dmg: int = well["collapse_damage"]
				if is_sing:
					c_dmg *= 3
				_damage_enemies_in_radius(
					well["pos"], well["radius"] * 0.6, c_dmg,
				)
				# Collapse VFX
				var c_color := Color(0.7, 0.4, 1.0)
				if is_sing:
					c_color = Color(0.3, 0.5, 1.0)
				vfx_manager.spawn_explosion(
					well["pos"], c_color, 30, 5.0,
				)
				if spring_grid:
					spring_grid.apply_explosive_force(well["pos"], 1.5, well["radius"])
				if camera:
					camera.add_trauma(0.3)

		elif well["phase"] == "collapsing":
			# Brief collapse visual (0.3s)
			if well["timer"] >= 0.3:
				_active_wells.remove_at(i)
				i -= 1
				continue

		i -= 1


# ==========================================================================
# THORN AURA
# ==========================================================================

func _tick_thorn_aura(delta: float) -> void:
	var level := get_weapon_level("thorn_aura")
	if level <= 0:
		return
	_thorn_aura_timer -= delta
	if _thorn_aura_timer > 0.0:
		return
	_thorn_aura_timer = THORN_AURA_TICK
	var idx := clampi(level - 1, 0, THORN_AURA_DATA.size() - 1)
	var radius: float = THORN_AURA_DATA[idx][0]
	var damage: int = THORN_AURA_DATA[idx][1]
	_damage_enemies_in_radius(player.position, radius, damage)


# ==========================================================================
# POISON CLOUD
# ==========================================================================

func _tick_poison_cloud(delta: float) -> void:
	var level := get_weapon_level("poison_cloud")
	if level <= 0:
		return
	_poison_cloud_timer -= delta
	if _poison_cloud_timer > 0.0:
		return
	_poison_cloud_timer = POISON_CLOUD_TICK
	var idx := clampi(level - 1, 0, POISON_CLOUD_DATA.size() - 1)
	var radius: float = POISON_CLOUD_DATA[idx][0]
	var dps: float = POISON_CLOUD_DATA[idx][1]
	var duration: float = POISON_CLOUD_TICK + 0.1
	for enemy in _query_nearby(player.position, radius):
		if enemy.has_method("apply_poison"):
			enemy.apply_poison(duration, dps)


# ==========================================================================
# SHOCKWAVE
# ==========================================================================

func _tick_shockwave(delta: float) -> void:
	var level := get_weapon_level("shockwave")
	if level <= 0:
		return
	var idx := clampi(level - 1, 0, SHOCKWAVE_DATA.size() - 1)
	var cooldown: float = SHOCKWAVE_DATA[idx][0]
	var key := "shockwave"
	_weapon_timers[key] = _weapon_timers.get(key, cooldown) - delta
	if _weapon_timers[key] <= 0.0:
		_weapon_timers[key] = cooldown
		_fire_shockwave(level)


func _fire_shockwave(level: int) -> void:
	var idx := clampi(level - 1, 0, SHOCKWAVE_DATA.size() - 1)
	var max_r: float = SHOCKWAVE_DATA[idx][1]
	var damage: int = SHOCKWAVE_DATA[idx][2]
	_active_effects.append({
		"type": "shockwave_ring",
		"pos": player.position,
		"max_radius": max_r,
		"damage": damage,
		"timer": 0.0,
		"duration": 0.5,
		"damaged": false,
	})
	if spring_grid:
		spring_grid.apply_explosive_force(
			player.position, 0.6, max_r,
		)
	if camera:
		camera.add_trauma(0.15)


# ==========================================================================
# METEOR SHOWER
# ==========================================================================

func _tick_meteor_shower(delta: float) -> void:
	var level := get_weapon_level("meteor_shower")
	if level <= 0:
		return
	var idx := clampi(
		level - 1, 0, METEOR_SHOWER_DATA.size() - 1,
	)
	var cooldown: float = METEOR_SHOWER_DATA[idx][0]
	var key := "meteor_shower"
	_weapon_timers[key] = _weapon_timers.get(key, cooldown) - delta
	if _weapon_timers[key] <= 0.0:
		_weapon_timers[key] = cooldown
		_fire_meteor_shower(level)


func _fire_meteor_shower(level: int) -> void:
	var idx := clampi(
		level - 1, 0, METEOR_SHOWER_DATA.size() - 1,
	)
	var count: int = METEOR_SHOWER_DATA[idx][1]
	for i in count:
		# Target: random nearby enemy, or random pos near player
		var offset := Vector2.from_angle(randf() * TAU) * 60.0
		var target_pos := _find_nearest_enemy_pos(
			player.position + offset,
		)
		if target_pos == Vector2.ZERO:
			target_pos = player.position + Vector2(
				randf_range(-80, 80), randf_range(-80, 80),
			)
		var total_dur: float = METEOR_SHADOW_TIME + METEOR_FALL_TIME
		_active_effects.append({
			"type": "meteor_shadow",
			"pos": target_pos,
			"timer": 0.0,
			"duration": METEOR_SHADOW_TIME,
		})
		_active_effects.append({
			"type": "meteor_falling",
			"target_pos": target_pos,
			"timer": 0.0,
			"duration": total_dur,
			"shadow_time": METEOR_SHADOW_TIME,
			"has_impacted": false,
		})


func _meteor_impact(pos: Vector2) -> void:
	_damage_enemies_in_radius(pos, METEOR_RADIUS, METEOR_DAMAGE)
	_active_effects.append({
		"type": "meteor_ring",
		"pos": pos,
		"timer": 0.0,
		"duration": 0.4,
	})
	if vfx_manager:
		vfx_manager.spawn_explosion(
			pos, Color(1.0, 0.5, 0.1), 30, 5.0,
		)
	if spring_grid:
		spring_grid.apply_explosive_force(
			pos, 1.2, METEOR_RADIUS,
		)
	if camera:
		camera.add_trauma(0.2)


# ==========================================================================
# HOLY WATER
# ==========================================================================

func _tick_holy_water(delta: float) -> void:
	var level := get_weapon_level("holy_water")
	if level <= 0:
		return
	var idx := clampi(level - 1, 0, HOLY_WATER_DATA.size() - 1)
	var cooldown: float = HOLY_WATER_DATA[idx][0]
	var key := "holy_water"
	_weapon_timers[key] = _weapon_timers.get(key, cooldown) - delta
	if _weapon_timers[key] <= 0.0:
		_weapon_timers[key] = cooldown
		_fire_holy_water(level)


func _fire_holy_water(level: int) -> void:
	var idx := clampi(level - 1, 0, HOLY_WATER_DATA.size() - 1)
	var radius: float = HOLY_WATER_DATA[idx][1]
	var dur: float = HOLY_WATER_DATA[idx][2]
	var dps: int = HOLY_WATER_DATA[idx][3]
	var zone_pos := _find_enemy_cluster_center(
		player.position, 100.0,
	)
	if zone_pos == Vector2.ZERO:
		zone_pos = player.position + Vector2(
			randf_range(-50, 50), randf_range(-50, 50),
		)
	_active_holy_zones.append({
		"pos": zone_pos,
		"radius": radius,
		"dps": dps,
		"timer": 0.0,
		"duration": dur,
		"tick_timer": 0.0,
	})


func _update_holy_zones(delta: float) -> void:
	var i := _active_holy_zones.size() - 1
	while i >= 0:
		var zone: Dictionary = _active_holy_zones[i]
		zone["timer"] += delta
		if zone["timer"] >= zone["duration"]:
			_active_holy_zones.remove_at(i)
			i -= 1
			continue
		zone["tick_timer"] -= delta
		if zone["tick_timer"] <= 0.0:
			zone["tick_timer"] = HOLY_WATER_TICK
			var pos: Vector2 = zone["pos"]
			var radius: float = zone["radius"]
			var dmg: int = zone["dps"]
			var style: String = zone.get("style", "holy")
			if style == "fire":
				# Inferno: damage + burn
				for enemy in _query_nearby(pos, radius):
					if enemy.has_method("take_damage"):
						enemy.take_damage(dmg)
					if enemy.has_method("apply_burn"):
						enemy.apply_burn(0.6, 2.0)
			elif style == "plague":
				# Plague: apply poison instead of raw dmg
				for enemy in _query_nearby(pos, radius):
					if enemy.has_method("apply_poison"):
						enemy.apply_poison(1.0, float(dmg))
			else:
				_damage_enemies_in_radius(pos, radius, dmg)
		i -= 1


# ==========================================================================
# DRONE SWARM
# ==========================================================================

func _tick_drone_swarm(delta: float) -> void:
	var level := get_weapon_level("drone_swarm")
	if level <= 0:
		return
	_drone_rotation += DRONE_ORBIT_SPEED * delta
	var idx := clampi(
		level - 1, 0, DRONE_SWARM_COUNTS.size() - 1,
	)
	var drone_count: int = DRONE_SWARM_COUNTS[idx]

	# Build drone positions
	var drone_positions: Array[Vector2] = []
	for i in drone_count:
		var angle := _drone_rotation + (TAU / drone_count) * i
		drone_positions.append(
			player.position
			+ Vector2.from_angle(angle) * DRONE_ORBIT_RADIUS,
		)

	# Check collisions via spatial grid
	var is_ga := has_evolution("guardian_angel")
	var hit_r := 42.0 if is_ga else 14.0
	var dmg := DRONE_DAMAGE * 2 if is_ga else DRONE_DAMAGE
	var max_dist := DRONE_ORBIT_RADIUS + hit_r + 10.0
	var nearby_enemies: Array = []
	if _spatial_grid:
		nearby_enemies = _spatial_grid.query_radius(
			player.position, max_dist,
		)
	for enemy in nearby_enemies:
		for dp in drone_positions:
			if dp.distance_to(enemy.position) < hit_r:
				var eid: int = enemy.get_instance_id()
				var last: float = _drone_hit_cooldowns.get(
					eid, -999.0,
				)
				if _time - last >= DRONE_HIT_COOLDOWN:
					_drone_hit_cooldowns[eid] = _time
					if enemy.has_method("take_damage"):
						enemy.take_damage(dmg)
					# Guardian Angel: mini-shockwave
					if is_ga:
						_active_effects.append({
							"type": "shockwave_ring",
							"pos": dp,
							"max_radius": 30.0,
							"damage": 1,
							"timer": 0.0,
							"duration": 0.3,
							"damaged": false,
						})
				break

	# Purge old cooldowns periodically
	if Engine.get_process_frames() % 300 == 0:
		var to_remove: Array = []
		for eid in _drone_hit_cooldowns:
			if _time - _drone_hit_cooldowns[eid] > 2.0:
				to_remove.append(eid)
		for eid in to_remove:
			_drone_hit_cooldowns.erase(eid)


# ==========================================================================
# HOMING MISSILES
# ==========================================================================

func _tick_homing_missiles(delta: float) -> void:
	var level := get_weapon_level("homing_missiles")
	if level <= 0:
		_update_missiles(delta)
		return
	var idx := clampi(
		level - 1, 0, HOMING_MISSILE_DATA.size() - 1,
	)
	var cooldown: float = HOMING_MISSILE_DATA[idx][0]
	var key := "homing_missiles"
	_weapon_timers[key] = _weapon_timers.get(key, cooldown) - delta
	if _weapon_timers[key] <= 0.0:
		_weapon_timers[key] = cooldown
		_fire_homing_missiles(level)
	_update_missiles(delta)


func _fire_homing_missiles(level: int) -> void:
	var idx := clampi(
		level - 1, 0, HOMING_MISSILE_DATA.size() - 1,
	)
	var count: int = HOMING_MISSILE_DATA[idx][1]
	for i in count:
		var angle := randf() * TAU
		_active_missiles.append({
			"pos": player.position,
			"vel": Vector2.from_angle(angle) * MISSILE_SPEED,
			"timer": 0.0,
		})


func _update_missiles(delta: float) -> void:
	if _active_missiles.is_empty():
		return
	var i := _active_missiles.size() - 1
	while i >= 0:
		var m: Dictionary = _active_missiles[i]
		m["timer"] += delta
		if m["timer"] >= MISSILE_LIFESPAN:
			_active_missiles.remove_at(i)
			i -= 1
			continue
		var pos: Vector2 = m["pos"]
		var vel: Vector2 = m["vel"]

		# Find nearest enemy via spatial grid
		var target: Area2D = null
		if _spatial_grid:
			target = _spatial_grid.get_nearest(
				pos, 300.0,
			)
		if target:
			var desired: Vector2 = (
				target.position - pos
			).normalized()
			var current := vel.normalized()
			var angle_diff := current.angle_to(desired)
			var max_turn := MISSILE_TURN_SPEED * delta
			angle_diff = clampf(
				angle_diff, -max_turn, max_turn,
			)
			vel = vel.rotated(angle_diff)
			vel = vel.normalized() * MISSILE_SPEED
		pos += vel * delta
		m["pos"] = pos
		m["vel"] = vel

		# Hit detection via spatial grid
		var hit := false
		var hit_e: Area2D = null
		if _spatial_grid:
			hit_e = _spatial_grid.get_nearest(
				pos, 12.0,
			)
		if hit_e:
			if hit_e.has_method("take_damage"):
				hit_e.take_damage(MISSILE_DAMAGE)
			_active_effects.append({
				"type": "flash_circle",
				"pos": pos,
				"timer": 0.0,
				"duration": 0.15,
				"max_radius": 15.0,
				"color": Color(1.0, 0.4, 0.65, 0.7),
			})
			if spring_grid:
				spring_grid.apply_explosive_force(
					pos, 0.3, 15.0,
				)
			hit = true
		if hit:
			_active_missiles.remove_at(i)
		i -= 1


# ==========================================================================
# RUNETRACER
# ==========================================================================

func _tick_runetracer(delta: float) -> void:
	var level := get_weapon_level("runetracer")
	if level <= 0:
		_update_runes(delta)
		return
	var idx := clampi(
		level - 1, 0, RUNETRACER_DATA.size() - 1,
	)
	var max_count: int = RUNETRACER_DATA[idx][0]
	var spawn_cd: float = RUNETRACER_DATA[idx][2]

	# Count only full runes toward max (not mini-runes)
	var full_count := 0
	for rune in _active_runes:
		if not rune.get("is_mini", false):
			full_count += 1
	if full_count < max_count:
		_rune_spawn_timer -= delta
		if _rune_spawn_timer <= 0.0:
			_rune_spawn_timer = spawn_cd
			_spawn_rune()

	_update_runes(delta)


func _spawn_rune() -> void:
	var dir := Vector2.from_angle(randf() * TAU)
	_active_runes.append({
		"pos": player.position,
		"vel": dir * RUNETRACER_SPEED,
		"timer": 0.0,
		"lifespan": 999999.0,
		"hit_cooldowns": {},
	})


func _update_runes(delta: float) -> void:
	if _active_runes.is_empty():
		return
	var is_ps := has_evolution("prismatic_storm")
	var cam_rect := _get_camera_rect()
	# Inset bounce zone so runes stay visibly on-screen
	var margin := 10.0
	var br := Rect2(
		cam_rect.position + Vector2(margin, margin),
		cam_rect.size - Vector2(margin * 2, margin * 2),
	)
	var i := _active_runes.size() - 1
	while i >= 0:
		var rune: Dictionary = _active_runes[i]
		rune["timer"] += delta
		# Mini-runes (Prismatic Storm) expire; full runes are permanent
		if rune.get("is_mini", false):
			if rune["timer"] >= rune["lifespan"]:
				_active_runes.remove_at(i)
				i -= 1
				continue

		# Move
		var pos: Vector2 = rune["pos"]
		var vel: Vector2 = rune["vel"]
		pos += vel * delta

		# Bounce off inset camera viewport edges
		var bounced := false
		if pos.x < br.position.x:
			pos.x = br.position.x
			vel.x = absf(vel.x)
			bounced = true
		elif pos.x > br.end.x:
			pos.x = br.end.x
			vel.x = -absf(vel.x)
			bounced = true
		if pos.y < br.position.y:
			pos.y = br.position.y
			vel.y = absf(vel.y)
			bounced = true
		elif pos.y > br.end.y:
			pos.y = br.end.y
			vel.y = -absf(vel.y)
			bounced = true
		# Hard clamp safety net for fast camera moves
		pos = pos.clamp(br.position, br.end)
		rune["pos"] = pos
		rune["vel"] = vel

		# Prismatic Storm: spawn mini-rune on bounce
		if bounced and is_ps and not rune.get("is_mini", false):
			var mini_dir := Vector2.from_angle(
				randf() * TAU,
			)
			_active_runes.append({
				"pos": pos,
				"vel": mini_dir * RUNETRACER_SPEED * 0.7,
				"timer": 0.0,
				"lifespan": 1.5,
				"hit_cooldowns": {},
				"is_mini": true,
			})

		# Collision check every 2 frames for perf
		if Engine.get_process_frames() % 2 == 0:
			_rune_check_hits(rune)
		i -= 1


func _rune_check_hits(rune: Dictionary) -> void:
	var pos: Vector2 = rune["pos"]
	var cooldowns: Dictionary = rune["hit_cooldowns"]
	var is_mini: bool = rune.get("is_mini", false)
	var is_ps := has_evolution("prismatic_storm")
	var hr := 14.0
	if is_ps:
		hr = 10.0 if is_mini else 21.0
	for enemy in _query_nearby(pos, hr):
		var eid: int = enemy.get_instance_id()
		var last: float = cooldowns.get(eid, -999.0)
		if _time - last >= RUNETRACER_HIT_COOLDOWN:
			cooldowns[eid] = _time
			if enemy.has_method("take_damage"):
				enemy.take_damage(RUNETRACER_DAMAGE)


# ==========================================================================
# SOUL HARVEST (event-driven, called from shmup_main)
# ==========================================================================

func on_enemy_killed(pos: Vector2) -> void:
	var level := get_weapon_level("soul_harvest")
	if level <= 0:
		return
	var idx := clampi(
		level - 1, 0, SOUL_HARVEST_DATA.size() - 1,
	)
	var chance: float = SOUL_HARVEST_DATA[idx][0]
	if randf() > chance:
		return
	var radius: float = SOUL_HARVEST_DATA[idx][1]
	var damage: int = SOUL_HARVEST_DATA[idx][2]

	# Plague: spawn persistent poison cloud instead of instant AoE
	if has_evolution("plague"):
		_active_holy_zones.append({
			"pos": pos,
			"radius": radius,
			"dps": damage,
			"timer": 0.0,
			"duration": 3.0,
			"tick_timer": 0.0,
			"style": "plague",
		})
	else:
		_damage_enemies_in_radius(pos, radius, damage)

	_active_effects.append({
		"type": "soul_harvest_ring",
		"pos": pos,
		"max_radius": radius,
		"timer": 0.0,
		"duration": 0.35,
	})
	var harvest_color := Color(0.2, 0.6, 0.1) if has_evolution("plague") else Color(0.8, 0.3, 0.9)
	if vfx_manager:
		vfx_manager.spawn_explosion(
			pos, harvest_color, 20, 3.0,
		)
	if spring_grid:
		spring_grid.apply_explosive_force(pos, 0.5, radius)
	if camera:
		camera.add_trauma(0.1)


# ==========================================================================
# DRAW — All weapon VFX
# ==========================================================================

func _draw() -> void:
	# Persistent auras and orbiting weapons
	_draw_death_spiral()
	_draw_gravity_wells()
	_draw_thorn_aura()
	_draw_poison_cloud()
	_draw_drone_swarm()
	_draw_holy_zones()
	_draw_runes()
	_draw_missiles()

	for effect in _active_effects:
		match effect["type"]:
			"fireball_projectile":
				_draw_fireball_projectile(effect)
			"fireball_ring":
				_draw_fireball_ring(effect)
			"chain_lightning":
				_draw_chain_lightning(effect)
			"ice_nova_ring":
				_draw_ice_nova_ring(effect)
			"thunder_bolt":
				_draw_thunder_bolt(effect)
			"flash_circle":
				_draw_flash_circle(effect)
			"shockwave_ring":
				_draw_shockwave_ring(effect)
			"meteor_shadow":
				_draw_meteor_shadow(effect)
			"meteor_falling":
				_draw_meteor_falling(effect)
			"meteor_ring":
				_draw_meteor_ring(effect)
			"soul_harvest_ring":
				_draw_soul_harvest_ring(effect)


# --- Death Spiral blades ---

func _draw_death_spiral() -> void:
	var level := get_weapon_level("death_spiral")
	if level <= 0 or not player:
		return

	var is_vr := has_evolution("void_reaper")
	var orbit_r := SPIRAL_ORBIT_RADIUS * (2.0 if is_vr else 1.0)
	var blade_count := level
	for i in blade_count:
		var angle := _spiral_rotation + (TAU / blade_count) * i
		var blade_pos := player.position + Vector2.from_angle(angle) * orbit_r

		if is_vr:
			# Void Reaper: dark purple blades
			_draw_blade(blade_pos, angle, 3.0, Color(0.3, 0.0, 0.4, 0.12))
			_draw_blade(blade_pos, angle, 2.0, Color(0.5, 0.1, 0.6, 0.35))
			_draw_blade(blade_pos, angle, 1.2, Color(0.7, 0.3, 0.9, 0.9))
		else:
			_draw_blade(blade_pos, angle, 2.5, Color(0.7, 0.0, 0.1, 0.15))
			_draw_blade(blade_pos, angle, 1.5, Color(0.9, 0.1, 0.2, 0.4))
			_draw_blade(blade_pos, angle, 1.0, Color(0.9, 0.1, 0.2, 1.0))

		# Trail — 4 previous positions as fading dots
		var tc := Color(0.5, 0.1, 0.6) if is_vr else Color(0.9, 0.1, 0.2)
		for t_idx in 4:
			var trail_angle := angle - SPIRAL_ROTATION_SPEED * (t_idx + 1) * 0.03
			var trail_pos := player.position + Vector2.from_angle(trail_angle) * orbit_r
			var trail_alpha := 0.3 - t_idx * 0.07
			draw_circle(trail_pos, 3.0 - t_idx * 0.5, Color(tc.r, tc.g, tc.b, trail_alpha))

	# Void Reaper: outer pull range indicator ring
	if is_vr:
		var pull_r := orbit_r * 2.5
		var pa := sin(_time * 3.0) * 0.03 + 0.06
		draw_arc(
			player.position, pull_r, 0, TAU, 24,
			Color(0.5, 0.1, 0.6, pa), 1.0,
		)


func _draw_blade(pos: Vector2, angle: float, scale_factor: float, color: Color) -> void:
	# Crescent/scythe shape — 20px long
	var s := 10.0 * scale_factor
	var pts := PackedVector2Array([
		Vector2(0, -s),
		Vector2(s * 0.5, -s * 0.3),
		Vector2(s * 0.3, s * 0.5),
		Vector2(0, s * 0.3),
		Vector2(-s * 0.15, 0),
	])
	# Rotate and translate
	var xform := Transform2D(angle + PI / 2.0, pos)
	draw_set_transform_matrix(xform)
	draw_colored_polygon(pts, color)
	draw_set_transform_matrix(Transform2D.IDENTITY)


# --- Fireball projectile (traveling ball) ---

func _draw_fireball_projectile(effect: Dictionary) -> void:
	var t: float = float(effect["timer"]) / float(effect["duration"])
	var start: Vector2 = effect["start_pos"] as Vector2
	var target: Vector2 = effect["target_pos"] as Vector2
	var pos: Vector2 = start.lerp(target, t)
	var sz := 5.0; var fl := _time * 25.0
	var md := (target - start).normalized()
	var perp := Vector2(-md.y, md.x)

	# Flame trail — 6 jittering embers
	for i in 6:
		var tt := clampf(t - float(i + 1) * 0.04, 0.0, 1.0)
		var tp: Vector2 = start.lerp(target, tt)
		tp += perp * sin(fl + i * 1.7) * 3.0
		var f := float(i) / 6.0
		draw_circle(tp, sz * (0.7 - i * 0.08), Color(
			lerpf(1.0, 0.8, f), lerpf(0.5, 0.1, f),
			0.05, 0.4 - i * 0.06,
		))

	# Layered glow: heat haze → flame → core → white-hot
	draw_circle(pos, sz * (2.8 + sin(fl) * 0.5), Color(1.0, 0.15, 0.0, 0.1))
	draw_circle(pos, sz * (1.6 + sin(fl * 1.3) * 0.3), Color(1.0, 0.45, 0.1, 0.4))
	draw_circle(pos, sz * 0.9, Color(1.0, 0.7, 0.2, 0.9))
	draw_circle(pos, sz * 0.35, Color(1.0, 1.0, 0.7, 0.95))

	# Flame tips — 3 flickering tongues
	for fi in 3:
		var fa := fl * 1.5 + fi * TAU / 3.0
		var td := (Vector2.from_angle(fa) * 0.5 - md).normalized()
		var te := pos + td * sz * (1.2 + sin(fa * 2.0) * 0.4)
		draw_line(pos, te, Color(1.0, 0.6, 0.1, 0.5), 1.5)


# --- Fireball ring ---

func _draw_fireball_ring(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var max_r: float = effect["radius"]
	var pos: Vector2 = effect["pos"]

	# Three expanding rings at different speeds
	var r1 := max_r * t
	var r2 := max_r * t * 0.85
	var r3 := max_r * t * 0.65
	var alpha := (1.0 - t) * (1.0 - t)  # Quadratic fade

	# Inner bright orange
	draw_arc(pos, r3, 0, TAU, 20, Color(1.0, 0.6, 0.2, alpha * 0.6), 2.0)
	# Mid orange-red
	draw_arc(pos, r2, 0, TAU, 20, Color(1.0, 0.3, 0.1, alpha * 0.4), 3.0)
	# Outer dim red
	draw_arc(pos, r1, 0, TAU, 20, Color(1.0, 0.15, 0.05, alpha * 0.2), 4.0)


# --- Chain Lightning ---

func _draw_chain_lightning(effect: Dictionary) -> void:
	var points: Array = effect["points"]
	if points.size() < 2:
		return

	var t: float = effect["timer"] / effect["duration"]
	var alpha := (1.0 - t)
	var bolt_seed: int = effect["seed"]

	# Re-randomize every 0.03s for flickering
	var flicker_frame := int(effect["timer"] / 0.03)
	var rng := RandomNumberGenerator.new()
	rng.seed = bolt_seed + flicker_frame

	for seg_i in range(points.size() - 1):
		var start: Vector2 = points[seg_i]
		var end: Vector2 = points[seg_i + 1]
		_draw_jagged_bolt(start, end, rng, alpha)

		# Flash at each hit point (except the first which is player)
		if seg_i > 0:
			draw_circle(start, 4.0 * alpha, Color(1.0, 1.0, 1.0, alpha * 0.7))


func _draw_jagged_bolt(
	start: Vector2, end: Vector2,
	rng: RandomNumberGenerator, alpha: float,
) -> void:
	var segments := 8
	var perp := (end - start).orthogonal().normalized()
	var bolt_points := PackedVector2Array()

	for j in segments + 1:
		var frac := float(j) / float(segments)
		var base_pos: Vector2 = start.lerp(end, frac)
		if j > 0 and j < segments:
			base_pos += perp * rng.randf_range(-5.0, 5.0)
		bolt_points.append(base_pos)

	# Triple-layer: wide dim blue → medium cyan → thin white core
	for k in range(bolt_points.size() - 1):
		# Outer glow
		draw_line(bolt_points[k], bolt_points[k + 1],
			Color(0.3, 0.4, 1.0, alpha * 0.3), 5.0)
		# Mid glow
		draw_line(bolt_points[k], bolt_points[k + 1],
			Color(0.4, 0.7, 1.0, alpha * 0.6), 2.5)
		# Core
		draw_line(bolt_points[k], bolt_points[k + 1],
			Color(1.0, 1.0, 1.0, alpha), 1.0)


# --- Ice Nova ring ---

func _draw_ice_nova_ring(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var max_r: float = effect["max_radius"]
	var pos: Vector2 = effect["pos"]
	var r := max_r * ease(t, 0.3)  # Fast expand, slow at end
	var alpha := (1.0 - t)

	# Apply damage when ring reaches 80% expansion (once)
	if t > 0.5 and not effect["damaged"]:
		effect["damaged"] = true
		_apply_ice_nova_damage(pos, max_r, effect["freeze_dur"])

	# Crystalline ring — use fewer segments for geometric look
	var seg_count := 14
	# Outer dim glow
	draw_arc(pos, r + 3.0, 0, TAU, seg_count, Color(0.4, 0.6, 1.0, alpha * 0.15), 5.0)
	# Mid blue
	draw_arc(pos, r, 0, TAU, seg_count, Color(0.6, 0.85, 1.0, alpha * 0.5), 2.5)
	# Core white
	draw_arc(pos, r - 1.0, 0, TAU, seg_count, Color(1.0, 1.0, 1.0, alpha * 0.7), 1.0)

	# Ice shard particles along the ring edge
	var shard_count := 8
	for s in shard_count:
		var shard_angle := (TAU / shard_count) * s + t * 2.0
		var shard_pos := pos + Vector2.from_angle(shard_angle) * r
		var shard_size := 3.0 * alpha
		# Small diamond shard
		draw_line(shard_pos + Vector2(0, -shard_size), shard_pos + Vector2(0, shard_size),
			Color(0.8, 0.9, 1.0, alpha * 0.6), 1.5)
		draw_line(shard_pos + Vector2(-shard_size * 0.5, 0), shard_pos + Vector2(shard_size * 0.5, 0),
			Color(0.8, 0.9, 1.0, alpha * 0.6), 1.5)


# --- Thunder Bolt ---

func _draw_thunder_bolt(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var alpha := (1.0 - t * t)
	var start: Vector2 = effect["start"]
	var end_pos: Vector2 = effect["end"]

	var rng := RandomNumberGenerator.new()
	var flicker_frame := int(effect["timer"] / 0.025)
	rng.seed = effect["seed"] + flicker_frame

	# Main bolt
	_draw_jagged_bolt(start, end_pos, rng, alpha)

	# Branch bolts (2-3 smaller offshoots)
	var branch_count := 2
	for b in branch_count:
		var branch_frac := rng.randf_range(0.2, 0.7)
		var branch_start: Vector2 = start.lerp(end_pos, branch_frac)
		var branch_dir := Vector2.from_angle(rng.randf_range(-PI / 3, PI / 3) + (end_pos - start).angle())
		var branch_end := branch_start + branch_dir * rng.randf_range(20, 45)
		_draw_jagged_bolt(branch_start, branch_end, rng, alpha * 0.6)

	# Strike point glow
	draw_circle(end_pos, 8.0 * alpha, Color(0.5, 0.8, 1.0, alpha * 0.3))


# --- Flash circle ---

func _draw_flash_circle(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var max_r: float = effect["max_radius"]
	var pos: Vector2 = effect["pos"]
	var color: Color = effect["color"]

	var r := max_r * ease(t, 0.3)
	color.a *= (1.0 - t)
	draw_circle(pos, r, color)


# --- Gravity Wells ---

func _draw_gravity_wells() -> void:
	for well in _active_wells:
		var pos: Vector2 = well["pos"]
		var radius: float = well["radius"]
		var t: float = well["timer"]

		if well["phase"] == "pulling":
			var pull_frac: float = t / well["duration"]
			# Dark core
			draw_circle(pos, 8.0, Color(0.15, 0.0, 0.2, 0.8))
			# Swirling particle ring — 8 dots orbiting inward
			for p_idx in 8:
				var orbit_angle := (TAU / 8) * p_idx + t * 3.0
				var orbit_r := radius * (1.0 - pull_frac * 0.5) * (0.4 + 0.6 * sin(orbit_angle * 2.0 + t))
				orbit_r = maxf(orbit_r, 10.0)
				var dot_pos := pos + Vector2.from_angle(orbit_angle) * orbit_r
				draw_circle(dot_pos, 2.0, Color(0.6, 0.3, 1.0, 0.6))
			# Distortion ring at edge
			var ring_alpha := 0.2 + sin(t * 5.0) * 0.1
			draw_arc(pos, radius, 0, TAU, 20, Color(0.5, 0.2, 0.8, ring_alpha), 1.5)

		elif well["phase"] == "collapsing":
			# Expanding bright collapse ring
			var ct: float = well["timer"] / 0.3
			var cr := radius * 0.3 * ct
			var ca := (1.0 - ct)
			draw_arc(
				pos, cr, 0, TAU, 20,
				Color(0.8, 0.5, 1.0, ca), 3.0,
			)
			draw_circle(
				pos, 6.0 * (1.0 - ct), Color(1.0, 0.9, 1.0, ca),
			)


# --- Thorn Aura ---

func _draw_thorn_aura() -> void:
	var level := get_weapon_level("thorn_aura")
	if level <= 0 or not player:
		return
	var idx := clampi(level - 1, 0, THORN_AURA_DATA.size() - 1)
	var radius: float = THORN_AURA_DATA[idx][0]
	var pos := player.position
	var pulse := sin(_time * 4.0) * 0.05 + 1.0
	var r := radius * pulse
	var seg := 12
	# Outer dim
	draw_arc(pos, r, 0, TAU, seg, Color(0.6, 0.9, 0.2, 0.08), 5.0)
	# Mid green
	draw_arc(
		pos, r * 0.9, 0, TAU, seg,
		Color(0.6, 0.9, 0.2, 0.2), 2.5,
	)
	# Inner bright
	draw_arc(
		pos, r * 0.85, 0, TAU, seg,
		Color(0.8, 1.0, 0.4, 0.3), 1.0,
	)
	# Thorn spikes
	for i in seg:
		var spike_angle := (TAU / seg) * i + _time * 0.5
		var base_pt := pos + Vector2.from_angle(spike_angle) * r
		var tip := pos + Vector2.from_angle(spike_angle) * (r + 6.0)
		var perp := Vector2.from_angle(spike_angle + PI / 2.0) * 2.0
		draw_line(
			base_pt - perp, tip,
			Color(0.7, 1.0, 0.3, 0.4), 1.0,
		)
		draw_line(
			base_pt + perp, tip,
			Color(0.7, 1.0, 0.3, 0.4), 1.0,
		)


# --- Poison Cloud ---

func _draw_poison_cloud() -> void:
	var level := get_weapon_level("poison_cloud")
	if level <= 0 or not player:
		return
	var idx := clampi(level - 1, 0, POISON_CLOUD_DATA.size() - 1)
	var radius: float = POISON_CLOUD_DATA[idx][0]
	var pos := player.position
	var pulse := sin(_time * 3.0) * 0.05 + 1.0
	var r := radius * pulse
	# Outer dim green
	draw_arc(
		pos, r, 0, TAU, 20, Color(0.3, 0.9, 0.2, 0.08), 6.0,
	)
	# Mid green
	draw_arc(
		pos, r * 0.75, 0, TAU, 16,
		Color(0.3, 0.9, 0.2, 0.12), 3.0,
	)
	# Inner fill
	draw_arc(
		pos, r * 0.5, 0, TAU, 12,
		Color(0.4, 1.0, 0.3, 0.06), 8.0,
	)
	# Floating poison dots (4 rotating)
	for i in 4:
		var angle := _time * 1.5 + (TAU / 4.0) * i
		var dot_r := r * (0.5 + sin(_time * 2.0 + i) * 0.3)
		var dot_pos := pos + Vector2.from_angle(angle) * dot_r
		draw_circle(dot_pos, 2.0, Color(0.3, 1.0, 0.2, 0.3))


# --- Shockwave Ring ---

func _draw_shockwave_ring(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var max_r: float = effect["max_radius"]
	var pos: Vector2 = effect["pos"]
	var r := max_r * ease(t, 0.3)
	var alpha := (1.0 - t)
	# Apply damage at 40% expansion (once)
	if t > 0.4 and not effect["damaged"]:
		effect["damaged"] = true
		_damage_enemies_in_radius(
			pos, max_r, effect["damage"],
		)
	# Triple-layer white/silver ring
	draw_arc(
		pos, r + 2.0, 0, TAU, 24,
		Color(0.8, 0.85, 1.0, alpha * 0.12), 5.0,
	)
	draw_arc(
		pos, r, 0, TAU, 24,
		Color(0.9, 0.95, 1.0, alpha * 0.4), 2.5,
	)
	draw_arc(
		pos, r - 1.0, 0, TAU, 24,
		Color(1.0, 1.0, 1.0, alpha * 0.7), 1.0,
	)


# --- Meteor Shadow ---

func _draw_meteor_shadow(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var pos: Vector2 = effect["pos"]
	var r := METEOR_RADIUS * ease(t, 0.5)
	var alpha := 0.15 + t * 0.15
	draw_circle(pos, r, Color(0.1, 0.05, 0.0, alpha))
	# Warning ring
	draw_arc(
		pos, r, 0, TAU, 16,
		Color(1.0, 0.4, 0.1, alpha * 2.0), 1.0,
	)


# --- Meteor Falling ---

func _draw_meteor_falling(effect: Dictionary) -> void:
	var t: float = effect["timer"]
	var shadow_t: float = effect["shadow_time"]
	if t < shadow_t:
		return
	var fall_t := (t - shadow_t) / METEOR_FALL_TIME
	fall_t = clampf(fall_t, 0.0, 1.0)
	var target: Vector2 = effect["target_pos"]
	var start := target + Vector2(30, -120)
	var pos: Vector2 = start.lerp(target, ease(fall_t, 2.0))
	var s := 5.0
	# Triple-layer fireball
	draw_circle(pos, s * 2.5, Color(1.0, 0.3, 0.0, 0.15))
	draw_circle(pos, s * 1.5, Color(1.0, 0.5, 0.1, 0.5))
	draw_circle(pos, s * 0.7, Color(1.0, 0.8, 0.3, 0.9))
	# Trail
	for tr in 4:
		var tt := clampf(fall_t - (tr + 1) * 0.05, 0.0, 1.0)
		var tp: Vector2 = start.lerp(target, ease(tt, 2.0))
		draw_circle(
			tp, s * (0.8 - tr * 0.15),
			Color(1.0, 0.4, 0.05, 0.2 - tr * 0.04),
		)


# --- Meteor Ring (impact) ---

func _draw_meteor_ring(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var pos: Vector2 = effect["pos"]
	var r := METEOR_RADIUS * t
	var alpha := (1.0 - t) * (1.0 - t)
	draw_arc(
		pos, r * 0.7, 0, TAU, 20,
		Color(1.0, 0.6, 0.2, alpha * 0.6), 2.0,
	)
	draw_arc(
		pos, r, 0, TAU, 20,
		Color(1.0, 0.3, 0.1, alpha * 0.3), 3.0,
	)


# --- Holy Water Zones ---

func _draw_holy_zones() -> void:
	for zone in _active_holy_zones:
		var pos: Vector2 = zone["pos"]
		var r: float = zone["radius"]
		var lt: float = zone["timer"] / zone["duration"]
		var a := 1.0
		if lt < 0.1:
			a = lt / 0.1
		elif lt > 0.8:
			a = (1.0 - lt) / 0.2
		var style: String = zone.get("style", "holy")
		var pal: Array
		if style == "fire":
			pal = [Color(1, .3, 0), Color(1, .5, .1), Color(1, .8, .3)]
		elif style == "plague":
			pal = [Color(.2, .5, .1), Color(.3, .8, .2), Color(.5, 1, .4)]
		else:
			pal = [Color(.4, .5, 1), Color(.5, .6, 1), Color(.8, .9, 1)]
		var ripple := sin(_time * 4.0 + zone.hash()) * 0.1
		draw_circle(pos, r, Color(pal[0].r, pal[0].g, pal[0].b, a * 0.06))
		draw_arc(pos, r * (1.0 + ripple), 0, TAU, 20, Color(pal[1].r, pal[1].g, pal[1].b, a * 0.25), 2.0)
		draw_arc(pos, r * 0.6, 0, TAU, 16, Color(pal[1].r, pal[1].g, pal[1].b, a * 0.15), 3.0)
		draw_circle(pos, r * 0.15, Color(pal[2].r, pal[2].g, pal[2].b, a * 0.2))


# --- Drone Swarm ---

func _draw_drone_swarm() -> void:
	var level := get_weapon_level("drone_swarm")
	if level <= 0 or not player:
		return
	var is_ga := has_evolution("guardian_angel")
	var idx := clampi(
		level - 1, 0, DRONE_SWARM_COUNTS.size() - 1,
	)
	var drone_count: int = DRONE_SWARM_COUNTS[idx]
	for i in drone_count:
		var angle := _drone_rotation + (TAU / drone_count) * i
		var pos := player.position + (
			Vector2.from_angle(angle) * DRONE_ORBIT_RADIUS
		)
		# Guardian Angel: 1.5x draw scale, white-gold
		var sc := 1.5 if is_ga else 1.0
		var pulse := sin(_time * 6.0 + i * 1.5) * 0.15
		var r := (5.0 + pulse) * sc
		# Outer glow
		draw_circle(
			pos, r * 2.5,
			Color(1.0, 0.85, 0.2, 0.08),
		)
		# Mid ring
		draw_arc(
			pos, r * 1.8, 0, TAU, 12,
			Color(1.0, 0.9, 0.3, 0.2), 1.5,
		)
		# Inner ring
		draw_arc(
			pos, r * 1.2, 0, TAU, 10,
			Color(1.0, 0.95, 0.5, 0.4), 1.0,
		)
		# Core
		draw_circle(
			pos, r * 0.7,
			Color(1.0, 0.95, 0.7, 0.9),
		)
		# Hot center
		draw_circle(
			pos, r * 0.3,
			Color(1.0, 1.0, 0.9, 1.0),
		)
		# Trail dots (warm gold)
		for t_idx in 3:
			var ta := angle - DRONE_ORBIT_SPEED * (t_idx + 1) * 0.04
			var tp := player.position + (
				Vector2.from_angle(ta) * DRONE_ORBIT_RADIUS
			)
			draw_circle(
				tp, 2.5 - t_idx * 0.5,
				Color(1.0, 0.9, 0.3, 0.2 - t_idx * 0.05),
			)


# --- Runetracer ---

func _draw_runes() -> void:
	var is_ps := has_evolution("prismatic_storm")
	for rune in _active_runes:
		var pos: Vector2 = rune["pos"]
		var vel: Vector2 = rune["vel"]
		var angle: float = vel.angle()
		var spin := _time * 3.0
		var is_mini: bool = rune.get("is_mini", false)
		var s := 5.0 if is_mini else (21.0 if is_ps else 7.0)
		var star := PackedVector2Array([
			Vector2(0, -s),        # top spike
			Vector2(s * 0.25, -s * 0.25),  # inner
			Vector2(s, 0),         # right spike
			Vector2(s * 0.25, s * 0.25),   # inner
			Vector2(0, s),         # bottom spike
			Vector2(-s * 0.25, s * 0.25),  # inner
			Vector2(-s, 0),        # left spike
			Vector2(-s * 0.25, -s * 0.25), # inner
		])
		var xform := Transform2D(spin, pos)
		draw_set_transform_matrix(xform)
		# Outer glow
		var outer := PackedVector2Array()
		for pt in star:
			outer.append(pt * 1.8)
		# Prismatic: rainbow hue cycle
		var hue := fmod(_time * 0.5 + pos.x * 0.01, 1.0) if is_ps else 0.14
		var rc := Color.from_hsv(hue, 0.3, 1.0, 0.1)
		var mc := Color.from_hsv(hue, 0.4, 1.0, 0.35)
		var cc := Color.from_hsv(hue, 0.15, 1.0, 0.9)
		draw_colored_polygon(outer, rc)
		var mid := PackedVector2Array()
		for pt in star:
			mid.append(pt * 1.3)
		draw_colored_polygon(mid, mc)
		draw_colored_polygon(star, cc)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# Trail (3 fading dots behind)
		var trail_step := vel.normalized() * 8.0
		for t_idx in 3:
			var tp := pos - trail_step * (t_idx + 1)
			var ta := 0.25 - t_idx * 0.08
			draw_circle(
				tp, 3.0 - t_idx * 0.5,
				Color(1.0, 0.95, 0.5, ta),
			)


# --- Homing Missiles ---

func _draw_missiles() -> void:
	for m in _active_missiles:
		var pos: Vector2 = m["pos"]
		var vel: Vector2 = m["vel"]
		var angle: float = vel.angle()
		# Chevron/V-arrow shape (magenta — distinct from
		# orange Rocket enemies)
		var s := 5.0
		var chev := PackedVector2Array([
			Vector2(0, -s),          # tip
			Vector2(s * 0.5, s * 0.2),  # right wing
			Vector2(s * 0.3, s * 0.6),  # right tail
			Vector2(0, s * 0.2),     # notch
			Vector2(-s * 0.3, s * 0.6), # left tail
			Vector2(-s * 0.5, s * 0.2), # left wing
		])
		var xform := Transform2D(angle + PI / 2.0, pos)
		draw_set_transform_matrix(xform)
		# Outer glow
		var outer := PackedVector2Array()
		for pt in chev:
			outer.append(pt * 2.0)
		draw_colored_polygon(
			outer, Color(1.0, 0.3, 0.6, 0.1),
		)
		# Mid
		var mid := PackedVector2Array()
		for pt in chev:
			mid.append(pt * 1.4)
		draw_colored_polygon(
			mid, Color(1.0, 0.4, 0.65, 0.35),
		)
		# Core
		draw_colored_polygon(
			chev, Color(1.0, 0.7, 0.85, 0.9),
		)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		# Trail dots (magenta)
		var back := -vel.normalized()
		for t_idx in 3:
			var tp := pos + back * (t_idx + 1) * 6.0
			draw_circle(
				tp, 2.0 - t_idx * 0.4,
				Color(1.0, 0.3, 0.6, 0.3 - t_idx * 0.08),
			)


# --- Soul Harvest Ring ---

func _draw_soul_harvest_ring(effect: Dictionary) -> void:
	var t: float = effect["timer"] / effect["duration"]
	var max_r: float = effect["max_radius"]
	var pos: Vector2 = effect["pos"]
	var r := max_r * ease(t, 0.3)
	var alpha := (1.0 - t) * (1.0 - t)
	# Purple expanding ring
	draw_arc(
		pos, r + 2.0, 0, TAU, 20,
		Color(0.5, 0.1, 0.6, alpha * 0.15), 5.0,
	)
	draw_arc(
		pos, r, 0, TAU, 20,
		Color(0.8, 0.3, 0.9, alpha * 0.45), 2.5,
	)
	draw_arc(
		pos, r - 1.0, 0, TAU, 20,
		Color(1.0, 0.7, 1.0, alpha * 0.6), 1.0,
	)
	# Soul wisps floating upward
	for w in 4:
		var wa := (TAU / 4.0) * w + t * 3.0
		var wr := r * 0.7
		var wp := pos + Vector2.from_angle(wa) * wr
		wp.y -= t * 15.0
		draw_circle(
			wp, 2.0 * (1.0 - t),
			Color(0.9, 0.6, 1.0, alpha * 0.5),
		)


func _query_nearby(pos: Vector2, radius: float) -> Array:
	if _spatial_grid:
		return _spatial_grid.query_radius(pos, radius)
	var result: Array = []
	for e in _get_active_enemies():
		if pos.distance_to(e.position) <= radius:
			result.append(e)
	return result

func _find_nearest_enemy_pos(from: Vector2) -> Vector2:
	if _spatial_grid:
		var n: Area2D = _spatial_grid.get_nearest(from, 400.0)
		return n.position if n else Vector2.ZERO
	var best_d := 999999.0; var best_p := Vector2.ZERO
	for e in _get_active_enemies():
		var d := from.distance_to(e.position)
		if d < best_d:
			best_d = d; best_p = e.position
	return best_p

func _find_enemy_cluster_center(
	near: Vector2, radius: float,
) -> Vector2:
	var nearby := _query_nearby(near, radius)
	if nearby.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for e in nearby:
		sum += e.position
	return sum / float(nearby.size())

func _damage_enemies_in_radius(
	pos: Vector2, radius: float, damage: int,
) -> void:
	for e in _query_nearby(pos, radius):
		if e.has_method("take_damage"):
			e.take_damage(damage)

func _get_active_enemies() -> Array:
	var frame := Engine.get_process_frames()
	if frame != _cached_enemies_frame:
		_cached_enemies_frame = frame
		_cached_enemies.clear()
		if enemy_container:
			for c in enemy_container.get_children():
				if c.get("is_active"):
					_cached_enemies.append(c)
	return _cached_enemies

func _get_camera_rect() -> Rect2:
	if not camera:
		return Rect2(-320, -180, 640, 360)
	var cp: Vector2 = camera.global_position
	return Rect2(cp - Vector2(320, 180), Vector2(640, 360))
