# Ant Colony -- Kickoff Guide (v2)

> **Purpose:** Everything a new Claude Code session needs to continue building the
> Ant Colony game. The project already exists with terrain working. Copy the
> "First Message" into the new window to begin.

---

## First Message (copy this into the new Claude Code window)

```
I'm continuing work on an idle mining ant colony game in Godot 4.6. The project
already has terrain generation, camera, and chunk management working.

THIS PROJECT: C:\Projects\Firstpass\Ant_Farm
REFERENCE PROJECT: c:\Projects\Firstpass\LLM-Base

Before doing ANYTHING else, read ALL of these docs from the reference project
cover to cover. They are large -- read in chunks if needed but read EVERY line:

1. KICKOFF (read this first -- has lessons learned + build strategy):
   c:\Projects\Firstpass\LLM-Base\.llm\ANT_COLONY_KICKOFF.md

2. DESIGN DOC (the bible -- 1588 lines, read ALL of it):
   c:\Projects\Firstpass\LLM-Base\.llm\ANT_COLONY_DESIGN.md

3. UI REFERENCE (complete specs for 11 prototyped menus -- read ALL of it):
   c:\Projects\Firstpass\LLM-Base\.llm\ANT_COLONY_UI_REFERENCE.md

4. ARCHITECTURE REFERENCE (read all of these too):
   c:\Projects\Firstpass\LLM-Base\.llm\DECISIONS.md
   c:\Projects\Firstpass\LLM-Base\.llm\PATTERNS.md
   c:\Projects\Firstpass\LLM-Base\.llm\PRINCIPLES.md
   c:\Projects\Firstpass\LLM-Base\.llm\GDSCRIPT_LESSONS.md

Then read ALL existing code in this project:
   C:\Projects\Firstpass\Ant_Farm\ant-farm\main.gd
   C:\Projects\Firstpass\Ant_Farm\ant-farm\main.tscn
   C:\Projects\Firstpass\Ant_Farm\ant-farm\project.godot
   C:\Projects\Firstpass\Ant_Farm\ant-farm\systems\terrain\*.gd
   C:\Projects\Firstpass\Ant_Farm\ant-farm\systems\camera\game_camera.gd

Read EVERYTHING before writing any code. Understand the game, the existing code,
the architecture, and the build plan. The terrain system already works at 60 FPS
with 96 chunks -- build on it, don't rewrite it.

CRITICAL RENDERER INFO: This project MUST use Forward Plus + D3D12.
GL Compatibility and Vulkan both cap at 40 FPS on this machine due to an NVIDIA
driver issue. Do NOT change the renderer. See the kickoff doc's "Lessons Learned"
section for full details.

BUILD STRATEGY: Vanilla Mode first. Terrain works (Phase 1 Step 1 done).
Continue with Phase 1 Steps 2-5 (player ant, digging, food, deposit).

DO NOT build menus yet -- they're prototyped in the reference project. We'll
port them when gameplay needs them.
```

---

## The Game In One Sentence

You are the Queen Ant. Dig through procedural terrain, collect food, grow your
colony from nothing to thousands of autonomous workers with transport networks.

---

## Lessons Learned (CRITICAL -- read before coding)

### Renderer: Forward Plus + D3D12 ONLY

Tested all renderer/driver combinations on this machine (NVIDIA GPU, Windows):

| Renderer | Driver | FPS | Status |
|----------|--------|-----|--------|
| GL Compatibility | OpenGL (default) | **40** | BROKEN -- hard cap from driver |
| Forward Plus | Vulkan | **40** | BROKEN -- same issue |
| **Forward Plus** | **D3D12** | **60** | WORKING -- use this |

The 60 FPS cap is Windows DWM compositor (normal for windowed apps). 60 is the
target. DO NOT try to "fix" it -- other renderers break to 40.

**project.godot must have:**
```
config/features=PackedStringArray("4.6", "Forward Plus")

[rendering]
rendering_device/driver.windows="d3d12"
```

### Terrain Rendering Performance

The current terrain renderer uses fill_rect per tile (4096 calls per 512x512
chunk) which is good. However, these operations can be further optimized:

**Current bottlenecks in chunk generation:**
1. `EraPalette.get_dirt_color()` -- per-tile noise sample + sqrt (distance) +
   linear search through 10 eras + color lerp + boundary blend. That's a LOT
   of math for each of 4096 tiles.
2. `_render_chamber_glow()` -- per-PIXEL get_pixel/set_pixel from GDScript.
   Each call crosses the GDScript→C++ boundary. Very slow.
3. `_render_food()` -- same per-pixel issue for food glow rings.

**Optimization opportunities (apply when needed):**
- Pre-compute one era color per chunk center (all tiles same color). The user
  said "dirt can be less visually detailed." Each chunk is only 512px -- one
  color per chunk looks fine at gameplay zoom levels.
- Replace chamber glow per-pixel blending with tile-level fill_rect
  (pre-compute blended color, fill whole 8x8 tile block).
- Replace food circles with tile-level fill_rect (color the food tile orange).
- Skip noise sampling entirely for dirt -- just use era distance color.
- If sub-tile visual detail is desired later, use a shader instead of GDScript
  pixel loops.

### Window Settings

The project currently has exclusive fullscreen + borderless set. For development,
you may want windowed mode instead:
```
window/size/mode=0          # 0=windowed, 4=exclusive fullscreen
window/size/borderless=false
```

---

## What Already Exists (Phase 1, Step 1 — DONE)

The Godot project at `ant-farm/` has a working terrain prototype:

| File | What | Lines |
|------|------|-------|
| `main.gd` + `main.tscn` | Scene root, FPS counter, camera + chunk manager setup | ~30 |
| `systems/terrain/terrain_constants.gd` | All terrain constants (tile size 8px, chunk 64 tiles) | ~44 |
| `systems/terrain/terrain_noise.gd` | 3 FastNoiseLite instances (dirt, rock, food) | ~43 |
| `systems/terrain/chunk_data.gd` | Pure data: tile grid (PackedByteArray) + food positions | ~43 |
| `systems/terrain/chunk_manager.gd` | Lifecycle: load/unload/position chunks per camera | ~104 |
| `systems/terrain/chunk_renderer.gd` | Image→ImageTexture rendering per chunk | ~158 |
| `systems/terrain/era_palette.gd` | 10 geological eras, distance-based color gradient | ~101 |
| `systems/terrain/geological_era.gd` | Data class for one era (start/end distance, colors) | ~40 |
| `systems/terrain/rock_placer.gd` | Noise-based indestructible rock blobs | ~46 |
| `systems/terrain/food_placer.gd` | Food singles, clusters, veins | ~130 |
| `systems/terrain/starting_chamber.gd` | Half-circle chamber at origin, initial food | ~127 |
| `systems/camera/game_camera.gd` | Free camera: WASD pan, scroll zoom, edge scroll | ~65 |

**What works:**
- Procedural terrain with 10 geological eras (color changes with distance)
- Rock formations that increase in density further out
- Food clusters, veins, and scattered singles
- Starting chamber carved at origin with initial food pile
- Chamber glow effect
- Free camera with smooth zoom and WASD pan
- Chunk loading/unloading based on camera position (96 chunks at 60 FPS)
- FPS counter overlay

**What's next (Phase 1, Steps 2-5):**
- Player ant (queen) with movement and gravity
- Digging system (mouse-aim, hold-to-dig, pixel debris)
- Food pickup and carry
- Food pile deposit in starting chamber

---

## Pre-Settled Architecture Decisions

These are DECIDED. Do not re-debate.

| Decision | Answer |
|----------|--------|
| Engine | Godot 4.6 |
| **Renderer** | **Forward Plus + D3D12 (NOT GL Compatibility, NOT Vulkan)** |
| Viewport | 640x360 pixel art, canvas_items stretch |
| Terrain approach | Pixel-visual + tile logic hybrid (NOT full Noita pixel physics) |
| Pathfinding | Flow fields per chunk, NOT individual A* per ant |
| Ant updates | Staggered (spread across N frames), off-screen = timer simulation |
| Food visibility | Always visible through dirt, no fog of war |
| Dirt gravity | None (food has light fall physics, dirt is static) |
| Food color | ALL food is orange. Value comes from distance, not appearance |
| Worker roles | Permanent (miner or hauler, never swap) |
| Worker deletion | Never allowed. Performance via auto-hibernate |
| Transport cost | Free to place once upgrade is unlocked |
| Upgrade menu name | "Evolve" |
| Evolve layout | 3 tabs: PLAYER, LOGISTICS, COLONY |
| No tier locking | Can buy any upgrade in any order |
| Fork permanence | Per colony, can never switch after choosing |
| No offline progress | Game only runs when open |
| No enemies/combat | Pure mining/idle |
| Tunnel background | Very dark brown Color(0.12, 0.08, 0.05), NOT black |
| Vanilla Mode | Separate game mode, ant farm screensaver, no upgrades |
| Font | BoldPixels.ttf, default size 16 |
| UI panel texture | Kenney tile_0030 (PANEL_ROUNDED), 14px nine-patch margin |
| UI text style | Black text, white outline (outline_size 2), ALL CAPS |

---

## Build Strategy: Vanilla Mode First

**Why Vanilla first?** Vanilla Mode is the pure ant farm screensaver -- no upgrades,
no menus, no progression systems. Building it first forces you to solve the THREE
hardest technical problems (terrain, mass ant AI, pathfinding at scale) before
layering on any Normal Mode complexity. If 1000 ants can't run at 60fps on
destructible terrain, you find out in Phase 2, not Phase 8.

---

## Build Phases

### Phase 1: Terrain Prototype (Design Doc Steps 1-5)

Prove the core tech works. If this fails, nothing else matters.

**Step 1: Terrain + Camera** — DONE (already in the project)

**Step 2: Player Ant + Movement**
- Queen ant: 3 ovals (abdomen + thorax + head) + 6 line legs + 2 antennae
- WASD movement, wall climbing, gravity
- Mouse position = aim direction

**Step 3: Digging**
- Click to dig in mouse direction
- Cooldown between bites (NOT click-speed-dependent)
- Hold = auto-mine, hold duration = bite size (Stardew watering can style)
- Multiple bites per block (NO difficulty scaling in Vanilla -- all dirt is base strength)
- Pixel debris particles on dig
- Place dirt with right-click (baked into Vanilla, no upgrade needed)
- Auto-click baked in (hold click = continuous dig, no upgrade needed)

**Step 4: Food + Collection**
- Orange circles embedded in dirt, always visible through terrain
- Food exposed when surrounding dirt removed, then pops out
- Walk over to pick up, stacks visually on ant body
- Carry capacity starts at 5, no speed penalty

**Step 5: Food Pile + Deposit**
- Starting chamber with warm glow gradient (deposit zone)
- Auto-deposit on entering glow zone
- Food tracked internally (NO visible counter in Vanilla -- pure visual experience)
- Pile grows visually through stages

---

### Phase 2: Vanilla Mode Complete (the ant farm screensaver)

**Goal:** A fully playable Vanilla Mode -- put it on your second monitor and watch
ants dig tunnels. This is the performance stress test.

**2a: Worker Ant AI**
- Miner AI: dig dirt near food sources, stacking cap, spread logic, frontier expansion
- Hauler AI: pick up exposed food, carry to pile, pathfind back
- Flow field pathfinding per chunk (the critical tech)
- Staggered AI updates (spread across N frames)
- Off-screen ants = timer-based simulation
- Ant drawing: same 3-oval body as queen, smaller scale

**2b: Auto-Spawner System** (design doc lines 68-101)
- Starts with 2 workers (1 miner, 1 hauler)
- Cost formula: `floor(8 + N * 4)` where N = total spawned so far
- First 6 ants: fixed pattern M, H, M, M, H, M
- After that: ratio AI (idle haulers -> spawn miner, food piling up -> spawn hauler, default 2:1)
- Minimum 5 seconds between spawns, one at a time
- Performance-regulated soft cap (pause spawning if FPS < 30)
- All invisible to player -- no numbers, no menus

**2c: Naming + Pheromone Trails**
- Click any ant to name it (Vanilla Mode's main interaction)
- Pheromone Highways: visible trails that glow on well-traveled routes (cosmetic only)
- Achievement ant: "Greg" spawns as first worker

**2d: Performance Milestone**
- Target: 500+ ants at 60fps on destructible terrain
- Auto-hibernate: far-away ants get simplified AI + skip rendering
- This is the make-or-break moment. If it works, proceed. If not, optimize here.

---

### Phases 3-8 (Normal Mode -- layer on Vanilla engine)

Same as before. See design doc for full details.

- **Phase 3:** Normal Mode foundation (dirt scaling, HUD, Evolve menu, first upgrades)
- **Phase 4:** Dig methods + worker upgrades (Gun/Laser/Acid/Explosion fork)
- **Phase 5:** Transport (Lift/Minecart/Platform/ZipLine fork)
- **Phase 6:** Traversal + automation (MegaSpeed/Grapple/Jetpack fork)
- **Phase 7:** Endgame (teleporters, hats, rainbow food, Over the Rainbow gate)
- **Phase 8:** Polish + full menu flow (settings, pause, main menu, sound, save)

---

## When To Port Each Menu

Port menus from the reference project when gameplay needs them.

| Menu | Port At | Why |
|------|---------|-----|
| HUD | Phase 3 | Normal Mode needs visible food counter |
| Evolve Menu | Phase 3 | Upgrade system needs a UI |
| Customize (Ant Naming) | Phase 4 | Normal Mode workers need full customization |
| Worker Overlay (Allocate) | Phase 4 | Miner/hauler ratio slider |
| Build Menu | Phase 5 | Transport placement needs radial menu |
| Settings | Phase 8 | Full settings for polish |
| Rainbow Menu | Phase 7 | Endgame cheat menu |
| Pause Menu | Phase 8 | Polish pass |
| Main Menu | Phase 8 | Final menu flow |
| Mode Select | Phase 8 | Save slot management |

**Note:** Vanilla Mode (Phase 2) needs NO ported menus.

---

## Technical Research Areas

**Critical for remaining Phase 1 (player + digging):**
- Player physics: gravity, wall climbing, WASD movement on 2D terrain
- Dig mask shapes: circle, hold-to-grow, pixel debris particles
- Food "pop out" animation when dirt is removed

**Critical for Phase 2 (Vanilla Mode / ant farm):**
- **Ant Pathfinding at Scale** -- Flow fields per chunk, staggered updates.
  This is THE performance bottleneck.
- **Performance Optimization** -- 500+ ants + terrain at 60fps.
  Staggered AI, off-screen simulation, auto-hibernate, spatial hashing.

---

## Reference File Quick Map

All reference files live in the **reference project** at `c:\Projects\Firstpass\LLM-Base\`.
The **game project** is at `C:\Projects\Firstpass\Ant_Farm\ant-farm\`.

| File (in reference project) | What | Lines |
|------|------|-------|
| `.llm/ANT_COLONY_DESIGN.md` | Complete game design bible | 1588 |
| `.llm/ANT_COLONY_UI_REFERENCE.md` | UI menu specs + patterns | ~540 |
| `.llm/ANT_COLONY_KICKOFF.md` | This file | -- |
| `.llm/DECISIONS.md` | Architecture decisions | -- |
| `.llm/PATTERNS.md` | Code patterns (FSM, events, pooling) | -- |
| `.llm/PRINCIPLES.md` | Development guidelines | -- |
| `.llm/GDSCRIPT_LESSONS.md` | GDScript gotchas | -- |
| `scenes/prototypes/ant_colony/ui/` | 11 menu prototypes (24 files) | -- |

**Asset sources (on desktop):**

| Source | What |
|--------|------|
| `C:\Users\slate\OneDrive\Desktop\asset packs\kenney_ui-pack-pixel-adventure\` | Kenney UI tile pack |
| `C:\Users\slate\OneDrive\Desktop\asset packs\BoldPixels.ttf` | Pixel font |

---

## Dev Menu (Build Early)

Build this in Phase 1 alongside terrain -- you'll need it constantly:

- Give food / Give rainbow food
- Hatch N workers (instant, free)
- Unlock upgrades
- Set distance (teleport queen)
- Speed multiplier (2x/5x/10x)
- Reset colony
- Toggle debug overlays (pathfinding, flow fields, worker targets)

Access: F12 or backtick. Strip from release.
