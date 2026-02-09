# Shmup Prototype — Design & Implementation Reference

> **Location:** `scenes/prototypes/shmup/`
> **Origin:** Geometry Wars wave-based shooter, converted to Vampire Survivors / Nova Drift-style game
> **Branch:** `claude/game-dev-foundation-u0fmp`

---

## Core Concept

**Keep from Geometry Wars:** Spring grid, bloom, player movement, bombs, score, lives, VFX system, object pooling
**Remove:** Wave system, multiplier system, fixed arena
**Add:** Scrolling world, continuous spawning, XP/level system, 36 upgrades, 15 enemy types, elite/champion system, pause, level-up UI, performance tracker

### Key Design Decisions
1. Enemy speed barely scales — difficulty comes from quantity + variety + HP
2. 10-minute peak (not 20) — compressed for faster testing
3. Push performance to 1000 enemies — find real limits
4. Twin-stick aiming with full 360-degree mouse support + arrow key fallback
5. Controller support required for level-up UI (D-pad/arrows + A/Space)
6. Bullets must be unmistakably visible

---

## Implementation Phases — All COMPLETE

### Phases A-F: Core Systems
All core systems, 15 enemies, 36 upgrades, 9 evolutions implemented.

### Scrolling World Conversion
**Plan:** `C:\Users\slate\.claude\plans\sparkling-jumping-comet.md`
- Fixed 560x300 arena → 3200x3200 scrolling world with camera follow
- Camera: smooth follow via `position_smoothing_enabled`, `position_smoothing_speed = 8.0`
- `WORLD_RECT = Rect2(-1600, -1600, 3200, 3200)`, `VIEWPORT_SIZE = Vector2(640, 360)`
- `camera_rect` var on shmup_main updated each frame for spawn/despawn queries
- Enemy spawning: radial around camera viewport edge (viewport_half_diag + 40px)
- Enemy despawn: every 1s, cull enemies >600px from camera center
- Player: soft pushback at world edges (80px margin, 400 force), hard clamp safety net
- Rockets: bounce off leash rect centered on player (1000x600), direction-aware reversal
- Pulser: settles near spawn point + toward player, not world center
- Bullets: range-based cleanup (500px from start_pos) instead of arena bounds
- Spring grid: world_to_grid() coordinate converter, camera_ref for position mapping
- Arena border removed entirely (`arena_border = null`)

### Balance & Optimization Pass
- Spatial hash grid for enemy lookups
- DPS rebalance across all weapons
- Conditional redraw optimizations

### FPS Optimization (7 Phases) + Mouse Aiming + Crosshair
**Plan:** `C:\Users\slate\.claude\plans\eventual-dreaming-perlis.md`
**Commit:** `62186b4`

**Phase 1 — Spatial Grid Full Conversion (passive_weapon_manager.gd):**
- Added `_query_nearby(pos, radius)` helper — wraps spatial grid with linear fallback
- Converted 8 weapon functions from O(n) ALL-enemy iteration to O(1) spatial grid queries:
  - `_damage_enemies_in_radius()`, `_find_nearest_enemy_pos()`, `_find_enemy_cluster_center()`
  - Death spiral blade hits, void reaper pull, ice nova, poison cloud, runetracer hits
  - Holy water/inferno/plague zone ticks, thunder strike targeting

**Phase 2 — Laser Beam Spatial Grid (laser_beam.gd):**
- Added `_spatial_grid: RefCounted` var, passed from shmup_main.gd via setup()
- `_apply_beam_damage()` pre-filters enemies with spatial grid query instead of iterating all children

**Phase 3 — Spring Grid Throttling (spring_grid.gd):**
- Redraw every 3 physics frames instead of every frame
- Skip simulation entirely when at rest (all velocities < 0.01 for 10 frames)
- Wake-on-force in `apply_explosive_force`, `apply_implosive_force`, `apply_directed_force`

**Phase 4 — Enemy Off-Screen Draw Culling (enemy_base.gd):**
- Early return in `_draw()` if >400px from camera (160000.0 distance_squared)
- Enemies still process movement/AI off-screen, just skip custom drawing

**Phase 5 — VFX Optimization (vfx_manager.gd + shmup_main.gd):**
- MAX_ACTIVE_PARTICLES = 20 cap — skip new GPU particle systems when at cap (still do grid warp)
- Fodder enemies (grunt, weaver, leech, drone): 0 fragments, no score popup, no hit-stop
- Reduced particle counts across all tiers

**Phase 6 — Separation Grid Optimization (shmup_main.gd):**
- Rewrote `_apply_enemy_separation()` to reuse existing spatial_grid instead of building separate grid
- Batch processing: 200 enemies per frame, cycling through with frame counter

**Phase 7 — 360-Degree Mouse Aiming (player_ship.gd):**
- `get_global_mouse_position()` for full 360-degree aim, arrow keys/stick as fallback
- Mouse mode: `MOUSE_MODE_CONFINED_HIDDEN` (stays in window, cursor hidden)

**Custom Crosshair (ui/crosshair.gd):**
- World-space Node2D following mouse via `get_global_mouse_position()`
- Cyan neon rotating crosshair: 4 lines with gap, glow layer, center dot, glow ring
- z_index = 100, slow spin (`delta * 1.5`)
- Loaded via CROSSHAIR_SCRIPT preload in shmup_main.gd

**Visual Enhancements:**
- Fireball: Replaced simple circles with flickering flame trail, heat haze layers, flame tongue tips. Dynamic flicker using sin() with instance_id offset.
- Ice Freeze: 6 thick crystal branches with frost ring aura + diamond shards. Stronger color tint: `base_color.lerp(Color(0.6, 0.8, 1.0), 0.65)`.

**Nova Drift Visual Overhaul: REVERTED** — Glow circles too visible, needs different approach.

### UI/UX Polish Pass + Camera Clamping + Balance Buffs

**Camera Clamping (shmup_main.gd):**
- Viewport never shows past world border — orange line IS the screen edge at borders
- `camera.global_position.clamp(WORLD_RECT.position + half_vp, WORLD_RECT.end - half_vp)`

**Spawn from Camera Center (enemy_spawner.gd):**
- Regular + surge spawns centered on camera (not player) so enemies are always off-screen
- At borders, player is offset in viewport but enemies still come from all directions
- Spawn distance: viewport_half_diag + 120px from camera center

**Level-Up UI Mouse Support (level_up_ui.gd):**
- Hover cards to select, click to confirm
- Click action bar buttons (Reroll/Lock/Banish/Skip)
- Cursor mode: MOUSE_MODE_CONFINED during menus, MOUSE_MODE_CONFINED_HIDDEN during gameplay
- `shmup_click` input action for mouse button

**Action Bar Styling (level_up_cards_draw.gd):**
- Unique button colors: Reroll=cyan, Lock=yellow, Banish=red, Skip=green
- Hover highlight: brighter background, thicker border, full alpha text
- Bombs counter above buttons with black-outlined text (size 12)

**HUD Text Size Pass (shmup_main.gd):**
- Score 10→12, Time 10→14, Level 10→14, Lives/Bombs 8→11
- Pause/GameOver 14→16, card names 10→11, descriptions 8→9

**Balance Buffs (passive_weapon_manager.gd):**
- Poison Cloud: radii 40-110 → 70-185, DPS 1-5 → 3-14, tick 0.5→0.4s
- Gravity Well: collapse damage 3-12 → 8-30, radii 55-100 → 70-135
- Aura damage pulses: thorn + poison flash/pulse on each damage tick for visual rhythm

**Files modified in UI/UX pass:**

| File | Changes |
|------|---------|
| `shmup_main.gd` | Camera clamping, HUD text sizes, score position, quit button |
| `enemies/enemy_spawner.gd` | Spawn from camera center, surge spawn center |
| `ui/level_up_ui.gd` | Mouse support, hover state, cursor mode switching |
| `ui/level_up_cards_draw.gd` | Button colors, hover highlight, outlined text, bombs position |
| `systems/passive_weapon_manager.gd` | Poison/gravity buffs, aura damage pulse timers |

**Files modified in FPS optimization pass:**

| File | Changes |
|------|---------|
| `systems/passive_weapon_manager.gd` | _query_nearby() helper, 8 spatial grid conversions, fireball visual |
| `weapons/laser_beam.gd` | Spatial grid pre-filtering for beam damage |
| `effects/spring_grid.gd` | Throttle redraw to every 3 frames, rest detection |
| `enemies/enemy_base.gd` | Off-screen draw culling, ice visual enhancement |
| `effects/vfx_manager.gd` | Particle throttle cap (20), const ordering fix |
| `shmup_main.gd` | Pass spatial_grid to laser, fodder VFX reduction, separation reuse, mouse mode, crosshair |
| `player/player_ship.gd` | Mouse aiming with arrow key fallback |
| `ui/crosshair.gd` | NEW — custom neon crosshair |

---

## 15 Enemy Types

| # | Name | Role | Shape | Color | Key Mechanic |
|---|------|------|-------|-------|-------------|
| 1 | GRUNT | Fodder | Diamond | Blue | Direct chase |
| 2 | WEAVER | Rusher | Diamond | Green | Chase + jink dodge |
| 3 | SPINNER | Special | Octagon | Bright Violet | Splits on death, shoots |
| 4 | ROCKET | Rusher | Triangle | Orange | Fast bounce off leash rect |
| 5 | TANK | Tank+Ranged | Hexagon | Red | Slow, 3-bullet spread |
| 6 | SNIPER | Ranged | Thin diamond | Cyan | Maintains distance, telegraph shot |
| 7 | CHARGER | Burst Rush | Pentagon | Crimson | 3 flashes → charge at 350px/s |
| 8 | ORBITER | Support | Hex ring | Gold | Shield aura (50% damage reduction) |
| 9 | HIVE | Spawner | Large circle | Purple | Spawns Drones, high HP |
| 10 | MINELAYER | Hazard | Inv triangle | Lime | Drops persistent mines |
| 11 | GHOST | Phaser | Diamond+tail | White-blue | Phases in/out (invulnerable when phased) |
| 12 | PULSER | Turret | Circle+cross | Electric Indigo | Stationary, 8-bullet ring |
| 13 | LEECH | Swarm | Tiny crescent | Dark red | Packs of 3-5, self-heal on contact |
| 14 | BOMBER | Chain React | Circle+fuse | Orange-yellow | Explodes on death, damages enemies too |
| 15 | SERPENT | Multi-seg | 4-5 circles | Purple-blue | Split when middle segment hit |

---

## 36 Total Upgrades (27 upgrades + 9 evolutions)

**15 Passive Weapons:** Fireball, Chain Lightning, Death Spiral, Ice Nova, Poison Cloud, Runetracer, Meteor Shower, Thunder Strike, Holy Water, Homing Missiles, Gravity Well, Shockwave, Drone Swarm, Soul Harvest, Thorn Aura

**5 Bullet Mods:** Rapid Fire, Heavy Rounds, Spread Shot, Piercing, Laser Beam

**2 Status Effects:** Ignite (burn), Freeze

**5 Stat Upgrades:** Speed Boost, Magnet, XP Boost, Extra Life, Extra Bomb

**9 Evolutions:** Bullet Storm, Railgun, Inferno, Thunder Storm, Void Reaper, Prismatic Storm, Singularity, Guardian Angel, Plague

---

## Temporary Pickup System

**Plan:** `C:\Users\slate\.claude\plans\swirling-scribbling-dove.md`

10 temporary pickup types that drop from enemies during gameplay. Separate from the permanent upgrade system — these are instant/timed effects that create moment-to-moment excitement.

### Architecture

| File | Purpose |
|------|---------|
| `collectibles/pickup.gd` | Pooled Area2D pickup with 14 type variants (10 pickups + 5 TURBO letters) |
| `systems/pickup_manager.gd` | Drop rates, buff tracking, TURBO state, all 10 effect implementations |
| `shmup_main.gd` | Pool (30 slots), spawn hook, signals, magnet fix, HUD, cleanup |
| `enemies/enemy_base.gd` | `is_converted` flag + converted chase behavior |

### 10 Pickup Types

| Pickup | Shape | Color | Effect | Duration |
|--------|-------|-------|--------|----------|
| Magnet Pulse | 8-point star | Magenta | Tweens ALL XP gems to player (0.3s ease-in cubic) | Instant |
| Chronofreeze | Hourglass | Ice Blue | `apply_freeze(8.0, 1.0)` on all enemies; new spawns also frozen | 8s |
| Healing Drop | Plus/cross | Red | +1 life | Instant |
| Instant Level-Up | Upward chevron | Gold | Fills XP to trigger level-up UI naturally | Instant |
| TURBO T/U/R/B/O | Letter shapes | Red/Orange/Yellow/Lime/Cyan | Collect all 5 → mega-buff: 2x speed, 2x fire rate, invincibility | 10s |
| Enemy Conversion | Pentagon + star | Purple | Up to 8 nearby enemies turn cyan, chase + attack other enemies at 1.5x speed | 10s |
| Positional Challenge | Diamond ring → zone | White | Stand within 40px for 3s. Reward: 500 score + 1 bomb + magnet pulse | 12s timeout |
| Angelic Boon | 6-pointed star | White-Gold | Invincibility + 1.5x movement speed | 10s |
| Berserk's Rage | Jagged triangle | Dark Red | 2x fire rate | 15s |
| Rapid Fire | Double chevron | Yellow-Green | 1.5x speed + 1.67x fire rate (-40% cooldown) | 10s |

### Drop Rate System

Drop rates per enemy kill, scaled by time (`1.0 + elapsed / 600.0`, so 2x at 10 min):

| Enemy Tier | Base Drop % | Pool |
|------------|-------------|------|
| Fodder (grunt, weaver, leech, drone) | 0.5% | Common |
| Mid (spinner, rocket, sniper) | 1.5% | Common |
| Strong (charger, orbiter, pulser) | 2% | Common |
| Special (minelayer, bomber, ghost) | 1% | Common |
| Boss (tank, hive, serpent) | 5% | Rare (guaranteed rare type) |

**Common pool:** Magnet Pulse, Chronofreeze, Healing Drop, Berserk's Rage, Rapid Fire, TURBO letter (weighted 2x if player missing letters)
**Rare pool:** Instant Level-Up, Enemy Conversion, Angelic Boon, Positional Challenge

TURBO letter selection always picks a letter the player is missing. No duplicates.

### Buff Stacking

Order-independent stacking via "recalculate from base" approach. When any buff starts/ends, all active multipliers are re-applied from `_base_fire_rate` and `_base_max_speed`:

```
rate = base * (berserk? 2.0) * (rapid? 1.67) * (turbo? 2.0)
speed = base * (rapid? 1.5) * (angelic? 1.5) * (turbo? 2.0)
```

Base values update when permanent upgrades (move_speed, fire_rate) are applied.

### Pickup Behavior

- **Pooled:** 30-slot pool, same activate/deactivate pattern as geoms
- **Magnetic pull:** 50px base range (geoms: 35px), affected by Magnet stat upgrade
- **Lifetime:** 20s (geoms: 15s), blinks in last 5s
- **Bobbing:** Gentle vertical bob (`sin(t * 3.0) * 1.5`), type-varying rotation speed
- **Glow ring:** Most types have pulsing glow arc via `_draw()`
- **Exception:** Positional Challenge does NOT magnetically pull — player must walk to it

### Enemy Conversion Details

- Sets `is_converted = true` on up to 8 enemies within 120px
- Converted enemies: cyan pulsing color, chase nearest non-converted enemy, deal 1 damage on contact (<12px)
- Search capped at 30 iterations per frame for performance
- Cleared on die(), configure(), and 10s timer expiry

### Magnet Upgrade Bug Fix

The magnet stat upgrade (+30% per level, 5 levels) was tracked in `upgrade_manager` but never applied to geoms. Now fixed:
- `shmup_main._current_magnet_range` updated on upgrade
- Applied to all geoms on level change AND on each geom spawn
- Also scales pickup `magnetic_range` (base 50px)

### HUD

- **Buff indicators:** Small colored labels at bottom of screen showing active buff name abbreviation
- **TURBO letters:** 5 letter labels (T U R B O) at bottom-center, dim gray when uncollected, colored when collected
- Driven by `pickup_manager` signals: `buff_started`, `buff_ended`, `turbo_letter_collected`, `turbo_activated`
