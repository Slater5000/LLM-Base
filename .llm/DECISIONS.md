# Technical Decisions

> Technical decisions recorded during bootstrap conversation.

---

## Engine Path

**Engine**: Godot 4.6 with GDScript

**Why Godot over Web/TypeScript:**
- Built-in TileMap editor saves significant development time for top-down RPG
- Scene tree architecture maps perfectly to game structure (World → Routes → NPCs → Creatures)
- Built-in export to multiple platforms when ready to distribute
- Visual editor for rapid iteration on 2D pixel art game
- MultiplayerAPI available if PvP is added later

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| **Engine** | Godot 4.6 | Latest stable, improved TileMapLayer system, mature GDScript 2.0 |
| **Language** | GDScript (typed) | Fast iteration, tight engine integration, static typing catches bugs |
| **Renderer** | Compatibility | Pixel art doesn't need Forward+, better performance, wider device support |
| **State management** | Signals + Autoloads | Signals for events, Autoloads for global state (party, game progress) |
| **Physics** | Built-in 2D physics | Simple collision detection, no complex physics simulation needed |
| **Audio** | Built-in AudioStreamPlayer | Supports chiptune formats (OGG, WAV), simple API |
| **Build / Export** | Godot export templates | Windows/Mac/Linux/Web when ready |
| **Networking** | None (architected for later) | Combat logic separated from input for future MultiplayerAPI integration |

---

## Dependencies / Addons

| Package / Addon | Purpose | Alternatives Considered |
|-----------------|---------|------------------------|
| None currently | Start minimal | Add only when specific need arises |

**Philosophy:** Start with zero addons. Godot's built-in features cover all current needs. Add dependencies only when a specific pain point emerges.

---

## Architecture Notes

### Folder Structure
```
project/
├── autoloads/              # Global state managers (CanvasLayer at layer 100)
│   ├── scene_manager.gd    # Scene transitions, player persistence, fade effects
│   ├── dialogue_manager.gd # Dialogue display, typewriter effect
│   ├── game_state.gd       # Save/load, settings, story flags, party data
│   ├── radial_menu.gd      # Hex menu overlay (F to toggle)
│   ├── battle_manager.gd   # Combat state machine (TODO)
│   └── audio_manager.gd    # Music/SFX control (TODO)
├── data/                   # Resource definitions
│   ├── creatures/          # CreatureSpecies .tres files
│   │   └── creature_species.gd  # Resource script
│   ├── moves/              # MoveData .tres files
│   │   └── move_data.gd    # Resource script
│   ├── creature_instance.gd # Runtime creature class (RefCounted)
│   └── synergies/          # Synergy effect data (TODO)
├── scenes/
│   ├── world/              # Overworld, routes, tilemaps
│   ├── player/             # Player character
│   ├── npcs/               # NPC scenes
│   ├── components/         # Reusable components (spawn_point, interactable, etc.)
│   ├── combat/             # Battle scene and components (TODO)
│   └── ui/                 # Menus, HUD
│       └── radial_menu/    # Hex button component
└── resources/              # Shared resources, themes
```

### Data Flow
1. **Autoloads** hold global state (party, progress, settings)
2. **Scenes** emit signals when events occur
3. **UI** listens to signals and updates display
4. **Save/Load** serializes Autoload state to disk

### Signal-Based Communication
- Creatures emit: `action_ready`, `took_damage`, `fainted`
- Battle emits: `battle_started`, `battle_won`, `battle_lost`
- UI listens to signals, never polls state directly

### Multiplayer-Ready Design
- Combat logic accepts commands from any source (player input, AI, or network)
- No hardcoded "player 1" assumptions in battle code
- Game state in Autoloads (easy to sync later)

### Save/Load System
- **Location:** `user://save.json`
- **Format:** JSON with version field for migrations
- **Contents:** player position, facing direction, scene path, story flags, party, settings
- **Pattern:** GameState.save_game() collects data from SceneManager + party, serializes to JSON
- **Load flow:** main.gd checks for save → SceneManager.load_from_save() → transitions to saved scene → positions player
- **Camera handling:** `camera.reset_smoothing()` called after positioning player to prevent pan effect on load

### Radial Menu
- **Style:** Hexagonal buttons in ring around player (Pokedex/tech gadget aesthetic)
- **Input:** F to toggle, WASD/arrows to navigate, mouse hover/click, Escape to close
- **Implementation:** CanvasLayer autoload, custom `_draw()` for hex shapes
- **Options:** Party, Bag (disabled), Dex (disabled), Save, Options, Exit
- **Player blocking:** Player checks `RadialMenu.is_menu_open()` to freeze movement

### Scene Transitions
- **SceneManager autoload** handles all transitions with fade-to-black effect
- **Player persistence:** Player node is preserved across transitions (removed from old scene, added to new)
- **Spawn points:** Marker2D nodes in "spawn_points" group with spawn_id for targeting
- **Edge transitions:** `transition_to_edge()` infers spawn from direction (exit left → spawn "from_right")
- **Door transitions:** `transition_to()` with explicit spawn_id

### Story Flags / NPC Dialogue
- **GameState.story_flags:** Dictionary persisted in save file
- **Pattern:** NPC checks flag on `_ready()` to select dialogue, sets flag on first interaction
- **Example:** Professor Oak checks `met_professor` flag, shows different dialogue after first meeting

### Creature Data Architecture
- **CreatureSpecies (Resource):** Template for a species — base stats, learnable moves, evolution data
- **MoveData (Resource):** Move definition — targeting, effect type, power, duration
- **CreatureInstance (RefCounted):** Runtime instance — unique ID, current stats, learned/active moves
- **Serialization:** `to_dict()` / `from_dict()` for save/load

---

## Rejected Alternatives

| Option | Rejected Because |
|--------|-----------------|
| Web/TypeScript + Phaser | Would need to build tilemap tooling from scratch; Godot's visual editor saves days |
| Godot 4.3 | 4.6 is current stable with better TileMapLayer collision system |
| Grid-based movement | User prefers smooth 8-directional movement for more fluid feel |
| ECS architecture | Overkill for this scope; scene tree + signals is simpler and sufficient |
| Element-based damage multipliers | Design decision: soft counters via archetypes, not damage math |
| Controller support | Not needed; keyboard-only simplifies input handling |
