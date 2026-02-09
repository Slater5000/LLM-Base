# Ant Colony -- New Repo Kickoff Guide

> **Purpose:** Everything a new Claude Code session needs to start building the
> Ant Colony game in a fresh Godot 4.6 project. Copy the "First Message" into
> the new window to begin.

---

## First Message (copy this into the new Claude Code window)

```
I'm starting a new Godot 4.6 game -- an idle mining ant colony game. There's a
reference project on this machine with all the design work already done.

REFERENCE PROJECT: c:\Projects\Firstpass\LLM-Base

Before doing ANYTHING else, read ALL of these docs from that project cover to
cover. They are large -- read in chunks if needed but read EVERY line:

1. KICKOFF (read this first, tells you the build strategy):
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

Read EVERYTHING before writing any code. I want you to fully understand the
game, the UI, the architecture, and the build plan before we start.

ASSETS TO COPY into this project first:
  - assets/sprites/ui/kenney/       (entire folder -- Kenney Brown Fantasy UI tiles)
  - assets/fonts/BoldPixels.ttf     (pixel font)
  - assets/fonts/default_theme.tres (project-wide default theme)

BUILD STRATEGY: Vanilla Mode first. After proving terrain works (Phase 1),
build the complete ant farm screensaver (Phase 2) before any Normal Mode
systems. This stress-tests the hardest tech (1000 ants + pathfinding + terrain)
before layering on upgrades, menus, and progression.

Read the design doc's Build Order Steps 1-5, Vanilla Mode section (lines 48-101),
and Technical Research sections before writing any code.

DO NOT build menus yet -- they're prototyped in the reference project. We'll
port them when gameplay needs them.
```

---

## The Game In One Sentence

You are the Queen Ant. Dig through procedural terrain, collect food, grow your
colony from nothing to thousands of autonomous workers with transport networks.

---

## Pre-Settled Architecture Decisions

These are DECIDED. Do not re-debate in the new session.

| Decision | Answer |
|----------|--------|
| Engine | Godot 4.6 |
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
| No tier locking | Can buy any upgrade in any order (no "unlock tier N first") |
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

**Step 1: Terrain + Camera**
- Chunk-based destructible 2D terrain (pixel-visual + tile-logic hybrid)
- Procedural noise generation with food clusters embedded in dirt
- Distance-based color gradient (10 geological eras: warm > earthy > crystal > cosmic)
- Free camera pan + zoom (not locked to queen)
- Chunk load/unload + save/load to disk
- 640x360 viewport

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
- Pheromone Highways: visible trails that glow on well-traveled routes (cosmetic only, no speed boost)
- Achievement ant: "Greg" spawns as first worker

**2d: Performance Milestone**
- Target: 500+ ants at 60fps on destructible terrain
- Auto-hibernate: far-away ants get simplified AI + skip rendering
- This is the make-or-break moment. If it works, proceed. If not, optimize here.

### What Phase 2 Delivers
A complete, playable Vanilla Mode. The ant farm screensaver works. You can:
- Watch ants dig and haul autonomously
- Optionally dig yourself (basic bite, place dirt)
- Name ants, watch pheromone trails form
- Colony grows itself via auto-spawner
- Performance proven at scale

---

### Phase 3: Normal Mode Foundation (Steps 6-7)

Now layer Normal Mode on top of the proven Vanilla engine.

- Dirt difficulty scaling (harder with distance -- Vanilla has none)
- Visible food counter (HUD -- port from reference project)
- Evolve menu (port from reference project)
- Auto Mining upgrade (first unlock)
- Dig Strength (0/50 scaling), Food Magnet, Carry Cap, Player Speed
- Dig Range / Speed / Radius fork (pick 2 of 3)
- Place Dirt as an upgrade (already works in engine from Vanilla)

### Phase 4: Dig Methods + Worker Upgrades (Steps 7-9)
- Gun / Laser / Butt Acid / Explosion fork (pick 1 of 4)
- Manual worker hatching (spend food, choose miner or hauler -- permanent)
- Customize screen (port from reference project -- name, color, hat)
- Worker Overlay / Allocate (port from reference project)
- Miner Strength (0/50), Range/Speed/Radius fork, Dig Method fork
- Ant Haul Capacity (0/10), Ant Move Speed (0/10)

### Phase 5: Transport (Steps 10-11)
- Build menu (port from reference project)
- Lift / Minecart / Platform / Zip Line fork (pick 1 of 4)
- Aerial Tramway / Conveyor Belt fork (pick 1 of 2)
- Loading stations, worker interaction with transport

### Phase 6: Traversal + Automation (Steps 12-14)
- Mega Speed / Grapple / Jetpack / Jump+Dash fork (pick 1 of 4)
- Auto Worker, Architect Ant, Auto Evolve (mid-game automation trio)
- Ant Cannon / Food Singularity / Relay Chains fork (pick 1 of 3)
- Auto Conveyor

### Phase 7: Endgame (Steps 15-17)
- Teleporters / Pneumatic Tubes fork (pick 1 of 2)
- Hats (spawn in terrain, queen collects)
- Achievement ants + discovery notifications
- Over the Rainbow gate + rainbow food (16000+ distance)
- Rainbow menu (port from reference project)
- Power fantasy unlocks + cosmetics

### Phase 8: Polish + Full Menu Flow (Step 18)
- Settings menu (port from reference project)
- Pause menu (port from reference project)
- Main Menu + Mode Select (port from reference project)
- Sound design, particles, performance pass
- Full save system (one active colony per mode, legacy colonies)

---

## When To Port Each Menu

Port menus from the reference project when gameplay needs them. Each menu's
complete source code is in the reference project and documented in the UI Reference.

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

**Note:** Vanilla Mode (Phase 2) needs NO ported menus. Ant naming in Vanilla is a
simple click-to-name popup, not the full Customize screen.

---

## Technical Research Areas (Read Before Coding)

The design doc's "Technical Research Needed" section (lines 1524-1588) covers 9 areas.

**Critical for Phase 1 (terrain):**
1. **Noita-Style Pixel Terrain (CRITICAL)** -- Pixel visuals + tile logic hybrid.
   Image/ImageTexture manipulation per chunk, or shader-based terrain.
2. **Procedural Terrain Generation** -- Noise for dirt, food cluster placement.
4. **Chunk System + LOD** -- Multi-resolution for zoom levels, chunk load/unload.
5. **Food Physics** -- Lightweight "food falls to nearest floor" on dig.

**Critical for Phase 2 (Vanilla Mode / ant farm):**
3. **Ant Pathfinding at Scale** -- Flow fields per chunk, staggered updates.
   This is THE performance bottleneck. Must work before Normal Mode begins.
9. **Performance Optimization** -- 500+ ants + terrain + food physics at 60fps.
   Staggered AI, off-screen simulation, auto-hibernate, spatial hashing.

Research areas 6-8 (transport, economy math, auto-buy) become relevant in later phases.

---

## Reference File Quick Map

All paths relative to `c:\Projects\Firstpass\LLM-Base\`:

| File | What | Lines |
|------|------|-------|
| `.llm/ANT_COLONY_DESIGN.md` | Complete game design bible | 1588 |
| `.llm/ANT_COLONY_UI_REFERENCE.md` | UI menu specs + patterns | ~540 |
| `.llm/ANT_COLONY_KICKOFF.md` | This file | -- |
| `.llm/DECISIONS.md` | Architecture decisions | -- |
| `.llm/PATTERNS.md` | Code patterns (FSM, events, pooling) | -- |
| `.llm/PRINCIPLES.md` | Development guidelines | -- |
| `.llm/GDSCRIPT_LESSONS.md` | GDScript gotchas | -- |
| `scenes/prototypes/ant_colony/ui/` | 11 menu prototypes (24 files) | -- |
| `scenes/prototypes/ant_colony/ui/shared/` | UI constants + theme | -- |
| `assets/sprites/ui/kenney/` | Kenney UI tile pack (brown fantasy) | -- |
| `assets/fonts/BoldPixels.ttf` | Pixel font | -- |

---

## Dev Menu (Build Early)

The design doc specifies a dev menu (lines 1504-1520) for testing. Build this in
Phase 1 alongside terrain -- you'll need it constantly:

- Give food / Give rainbow food
- Hatch N workers (instant, free)
- Unlock upgrades
- Set distance (teleport queen)
- Speed multiplier (2x/5x/10x)
- Reset colony
- Toggle debug overlays (pathfinding, flow fields, worker targets)

Access: F12 or backtick. Strip from release.
