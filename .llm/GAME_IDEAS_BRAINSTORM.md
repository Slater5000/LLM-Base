# Art-Light Game Ideas Brainstorm

> Session: February 2026
> Goal: Games that require minimal art, maximum replayability

---

## Core Constraint

**Art is the bottleneck.** Every visual element becomes a burden. The more we can reuse assets, generate procedurally, or use geometric/abstract visuals, the better.

**Environment art is the hardest part** - tilesets, towns, decorations, placing buildings. Creature/character sprites can be generated with ChatGPT. Backgrounds are often free.

---

## The Active List (Ready to Prototype)

### 1. Co-op Shmup (Pilot + Gunner) — CURRENTLY BEING PROTOTYPED

- **Concept:** Two-player co-op shoot-em-up. One player is the Pilot (moves/dodges with weak forward guns), other player is the Gunner (aims freely with heavy firepower — turrets, missiles, beams).
- **Aesthetic:** Geometry Wars neon glow. Black background, glowing ships, particle-heavy explosions, spring grid warping.
- **Why it works:** Asymmetric co-op creates natural communication. Pilot says "dodge left!" Gunner says "hold still, lining up a shot!" Natural tension between movement and aiming.
- **Art needed:** Minimal — geometric shapes, particles, glow shaders. All procedural.
- **Status:** Prototype built at `scenes/prototypes/shmup/` — Geometry Wars inspired, spring grid, 5 enemy types, geom multiplier, bombs.

### 2. Tower Idle Defense
- Tower in center, enemies constantly approach
- Tower gets stronger over time (idle progression)
- Geometric aesthetic: tower = glowing shape, enemies = colored shapes
- **Art needed:** Minimal - shapes, particles, UI

### 3. Asteroid Mining Ant Farm
- Start in center of asteroid/meteor
- Mine outward in any direction you choose
- Grows like an ant farm over time
- Procedural rock texture, tunnels are negative space
- **Art needed:** Minimal - noise textures, particles, maybe ore colors

### 4. Creature Collector Battle-Only Roguelite
- Pokemon meets Binding of Isaac
- NO exploration, NO towns, NO environment art
- Just battle → battle → battle → battle
- **Art needed:** Creature sprites (ChatGPT), battle backgrounds (free), UI, VFX

**Proposed Loop:**
```
RUN START
├── Pick starting creature (or random draft)
├── Battle 1 → Reward (new creature, upgrade, heal, item)
├── Battle 2 → Reward
├── ...
├── Boss Battle → Major reward
└── Run End → Meta-progression

META LAYER
├── Permanent creature unlocks
├── Starting bonuses
├── Team slot upgrades
└── Challenge modifiers
```

**What makes battles interesting:**
- Enemy team composition forces adaptation
- Creature synergies matter
- Resource management (HP carries over? Items limited?)
- Draft moments ("pick 1 of 3 creatures")
- Creatures evolve/power up mid-run
- Team size limit forces hard choices

### 5. Pac-Man PVP Party

- **Concept:** Asymmetric multiplayer. One player is Pac-Man, others control ghosts. Rounds rotate who's Pac-Man. Ghosts compete individually — everyone for themselves (most kills as ghost, highest score as Pac-Man).
- **Prior art:** Pac-Man Vs. existed (2003, designed by Miyamoto for GameCube + GBA link cable). But nobody's made a modern indie standalone version.
- **Why it works:** Everyone knows the rules instantly. Asymmetric roles keep it fresh. Individual ghost scoring prevents "gang up on Pac-Man" — ghosts compete with EACH OTHER too.
- **Art needed:** Minimal — maze is lines/tiles, characters are circles/shapes with eyes. Classic aesthetic or neon glow.

### 6. Co-op Snake

- **Concept:** Both players control snakes in a small arena. Shared goal (eat targets, survive waves, reach score). Need to work together but avoid each other. Interesting tension — your ally is also an obstacle.
- **Could merge with Tron trail concept** — snakes leave temporary trails that block movement, creating dynamic mazes.
- **Art needed:** Extremely minimal — lines and dots.

### 7. Tower Defense + Payload

- **Concept:** Top-down Orcs Must Die. Player is a character AND places defenses. Walk around the map, place towers/traps, then fight alongside them when waves come. Solo or co-op scales difficulty naturally.
- **Natural co-op fit:** One player builds, one player fights. Or both do both.
- **Art needed:** Low-medium — geometric towers, shape enemies, top-down character can be simple.

### 8. Idle Mining with Destructible Terrain

- **Concept:** Noita/Worms style bitmap terrain destruction. Dig downward infinitely. Chunk-based system for infinite depth. Marching Squares algorithm for smooth 2D terrain edges.
- **Research:** Explored "A Game About Digging A Hole" (Unreal Engine 5, uses Marching Cubes for 3D voxel terrain). 2D version is simpler and better — ant-farm cross-section view is more readable and satisfying.
- **Art needed:** Low — noise-generated terrain, particle debris, ore colors. All procedural.

---

## Ideas Discussed but Lower Priority

### Blindness/Audio Co-op Game

- **Concept:** Most original concept from the session. "It Takes Two but blind." Limited/no vision as a FEATURE, not a limitation. Sound + shapes + vibration as primary gameplay. Two players helping each other navigate and solve challenges.
- **Why it's special:** Massive creative space. Nobody's really done this well. Could be genuinely innovative.
- **Why it's WARM:** Needs a concrete hook/mechanic beyond the concept. "Blind co-op" is a theme, not a game yet.
- **Art needed:** Extremely minimal by definition — the whole point is you can't see much.

### Chain Attack Roguelite
- Start with 2-chain combos (dodge→swing, swing→shoot)
- Beating bosses/runs adds +1 to chain length
- Eventually chain 5-6 abilities together
- Vulnerability window between chains
- **Issue:** Still needs player art, enemy art, VFX - medium art burden

### Physics Sandbox Games
- Angry Birds style (circles, squares, triangles)
- Bridge builders
- Destruction physics
- Marble/ball games
- **Status:** Open to exploring, naturally art-light

### Drawing Games
- Player creates the art on blank canvas
- Clever because you give them nothing and they make the game
- **Status:** Interesting concept, needs more definition

### Brick Breaker Variant
- Must be fast-paced, shooting tons of balls constantly
- Not punished for missing
- Geometry-based could work
- **Status:** Could explore if unique angle found

### Rhythm + Geometry
- Beat-synced geometric chaos
- Super Hexagon style
- **Status:** Open but not priority

### Gladiator Battle Simulator (moved from Active)

- Two fighters, RNG-based combat chains
- Each move has chance to lead into: another hit, block, counter, etc.
- Chain continues until someone dies
- Player influence: choose gladiator, equipment, stats
- Inspired by: Shadow of Mordor orc pit, Swords and Sandals
- **Key requirement:** Must SEE the fight visually, not just read a log
- **Explored 3D Unity path** with stick figures/ragdolls — decided to stay 2D for now
- **Status:** WARM — good concept but needs the right visual approach

**Visual Solutions for Gladiator:**
- **Option A: Stick Figure Skeletons** - Godot Skeleton2D or Line2D limbs, procedural animation, different heads/weapons/colors per gladiator
- **Option B: Geometric Fighters** - Capsule body, line arms, shape weapons, all tweened procedurally
- **Option C: Weapon-Only** - Skip bodies, two weapons fighting each other (sword vs axe)
- **Option D: Side-View Simplified** - Minimal limbs like Nidhogg, silhouette sells the action

**Recommended approach:** Option A or B with glowing Geometry Wars aesthetic weapons (glowing sword, glowing shield)

**Art needed:** Very low if procedural - one rig, code-driven animation, particles for impacts

---

## Rejected Ideas

| Idea | Reason |
|------|--------|
| Asteroids variants | Didn't catch interest |
| Text/ASCII games | No text preference |
| Deckbuilders | Not interested + Slay the Spire has tons of art |
| Puzzle games | Hard no |
| Management sims | Would rather do idle |
| Vampire Survivors clones | Genre overdone |
| Match-3 | Hard no |
| Grid-based games | Not interested |
| Auto-battlers | Boring without amazing visuals/strategy — not compelling without good art |
| Katamari-like | 3D + needs tons of object art |
| Racing + combat | 3D multiplayer, way too big |
| Agar.io circles | Not into massive multiplayer genre — prefers local co-op |

---

## Priority List (Updated Feb 2026)

### HOT (has a concept)
1. **Co-op Shmup (Pilot + Gunner)** — PROTOTYPE IN PROGRESS
2. **Pac-Man PVP Party** — asymmetric multiplayer, everyone knows the rules
3. **Co-op Snake** — simple, tension-filled, could merge with Tron trails
4. **Tower Defense + Payload** — natural co-op, top-down Orcs Must Die
5. **Idle Mining with Destructible Terrain** — Noita-style bitmap destruction, infinite depth

### WARM (needs a hook)
1. **Blindness/Audio Co-op Game** — most original concept, needs concrete mechanics
2. **Modernized Pac-Man (solo)** — classic with modern juice/modes
3. **Co-op Tetris / Tricky Towers** — shared board or interacting boards
4. **Co-op Brick Breaker** — dual paddles, combo scoring
5. **Drawing Game** — player makes the art, needs game structure
6. **Gladiator Battle Simulator** — good concept, visual approach TBD, explored 3D but staying 2D

### SIMMERING (interesting but distant)
1. **Snake + Tron Hybrid** — trail mechanics, arena play
2. **Pong Evolved** — classic with modern twist
3. **Rhythm Game** — beat-synced geometry
4. **3D Gladiator** — ragdoll fighters, needs Unity/Unreal, parked for now

---

## Key Design Themes

These patterns keep emerging across every brainstorm session:

1. **Co-op is king.** User gravitates toward co-op for every idea. Even single-player concepts get "what if two players..." treatment. This is the primary design direction.

2. **"Modernize a classic."** Take something everyone knows and make it fresh. Pac-Man, Galaga, Tetris, Brick Breaker, Snake — the rules are pre-taught, the nostalgia is free marketing. Add modern juice, co-op, competitive twists.

3. **"No art = game mechanic."** Blindness/shapes as feature, not limitation. The constraint becomes the innovation. Geometry Wars proved shapes can feel premium.

4. **Multiplayer takes it to the next level.** Almost every concept becomes more interesting with a second player. Local co-op is the sweet spot — shared screen, shared couch, immediate feedback.

---

## Art-Light Games Tier List

How much art does each genre actually need?

### Tier 1 — Literally Just Shapes
- Geometry Wars clone
- Asteroids
- Snake
- Pong / Breakout
- Tetris
- Minesweeper
- Flappy Bird
- Rhythm game
- Audio visualizer
- Drawing games

### Tier 2 — Simple Shapes + Minimal Character
- Galaga / Space Invaders
- Tower Defense
- Pac-Man
- Auto-battler
- Bullet Hell / Shmup
- Idle / Clicker
- Agar.io clone
- Tron / Light Cycles
- Sumo / Push Arena

### Tier 3 — Simple Sprites or Stick Figures
- Platformer
- Fighting game
- Battle royale (top-down)
- Roguelike
- Card game / Deckbuilder
- Racing (top-down)
- Worms clone

### Tier 4 — Moderate Art but Manageable
- Creature battler
- Mining / Digging
- Match-3 / Puzzle
- Farming sim
- City builder

---

## Geometry Wars Research Notes

Deep dive into the series to inform the Shmup prototype and general VFX approach.

### Series Overview
- **GW1** (Xbox 360 Arcade, 2005): The original. Single arena, survival mode. Proved the concept.
- **GW2: Retro Evolved** (2008): Considered the BEST in the series. 6 game modes (Deadline, King, Evolved, Pacifism, Waves, Sequence). Introduced the geom multiplier — enemies drop green diamonds that increase your score multiplier. Perfect game feel.
- **GW3: Dimensions** (2014): Most modern/visually impressive. 3D arenas (play on the surface of shapes — cube, cylinder, peanut). Drones, supers, co-op mode. Beautiful but some argue the 3D arenas hurt clarity.

### Key Design Lessons from GW
- **Grid warping = spring physics.** Background grid is a mesh of point masses connected by springs. Explosions push points outward. Springs pull them back (pull force only, never push — prevents instability). Border points are anchored.
- **Enemy color = behavior:** Blue = chasing, Green = evasive/wandering, Pink = splits into smaller enemies, Orange = fast/dart, Red = ranged or tanky. Color IS communication.
- **Never spawn enemies in corners** — feels unfair if player is trapped.
- **Particles fade FAST** — screen clarity over spectacle. If particles linger, the screen becomes unreadable.
- **Clarity over spectacle** — every visual element serves gameplay. If it's just pretty but obscures threats, cut it.
- **Geom multiplier** — enemies drop pickups that increase score multiplier. Creates risk/reward: do you rush to grab geoms (dangerous) or play safe (lower score)?
- **Bombs** — screen-clearing panic button. Limited resource. Feels amazing to use at the last second.

### Prototype Approach
**"GW2's brain in GW3's body."** Take GW2's game modes, scoring, and enemy design philosophy. Wrap it in GW3-level visual polish (within 2D). Add co-op as the differentiator.

---

## VFX Capabilities (What Claude Can Build From Code)

All of these can be implemented procedurally — no art assets needed:

- **Particle systems** — explosions, trails, debris, sparks, fire, smoke
- **Spring grid** — Geometry Wars background warping effect
- **Glow / Bloom** — neon aesthetic via shaders or WorldEnvironment
- **Screen shake** — impact feel, camera trauma system
- **Chromatic aberration** — RGB split on damage/impact
- **Shockwave distortion** — circular distortion effect on explosions
- **Chain lightning** — procedural Line2D between targets
- **Plasma beams** — animated line effects with glow
- **Procedural trails** — Line2D following moving objects, fading over time
- **Procedural animation** — tweens, sine waves, spring physics for movement

---

## Engine Comparison for Multiplayer

| Factor | Godot | Unity | Unreal | Web (JS/TS) |
|--------|-------|-------|--------|-------------|
| **Local co-op** | Easy — split input | Easy | Overkill | Possible but awkward |
| **LAN** | ENet built-in | Mirror/Fishnet | Built-in | WebSockets |
| **Online P2P** | ENet + hole-punch or Steam | NGO/Mirror | Built-in | WebRTC |
| **Online Client-Server** | Possible but DIY | NGO, mature | Most mature | Node.js, natural fit |
| **Steam integration** | GodotSteam plugin | Steamworks.NET | Built-in | N/A |
| **Rollback netcode** | Partial — community plugins | Good middleware | Good middleware | DIY or GGPO.js |
| **Learning curve** | Low | Medium | High | Low (if you know JS) |
| **Cost** | Free | Revenue fees | Revenue fees | Free |

### Verdict by Use Case
- **Quick prototypes / local co-op:** Godot (we're already here, it's free, 2D is great)
- **Polished online multiplayer:** Unity (most mature middleware ecosystem, Mirror/Fishnet are battle-tested)
- **MMO / large scale:** Unreal (dedicated server support, replication system, but massive overkill for indie)
- **Zero-install / share via URL:** Web (WebSockets, zero friction, but limited for complex games)

---

## Technical Decisions

### 2D vs 3D
**Verdict: Stay 2D**

3D multiplies art burden:
- 3D models required
- Textures/materials
- Rigging and animation (harder than 2D)
- Lighting setup
- Camera management

2D wins for art-light because:
- Shapes and lines are trivial
- Procedural animation is simpler
- Particles/VFX easier
- Can literally ship with geometry

### Unity vs Godot
**Verdict: Godot for prototypes, Unity if we go polished online multiplayer**

| Factor | Unity | Godot |
|--------|-------|-------|
| 2D workflow | Good | Excellent |
| Asset Store | Massive | Small |
| Licensing | Revenue fees | Free forever |
| Momentum | None | Already working |
| Multiplayer | Mature (NGO/Mirror) | DIY / community |

Unity Asset Store trap: Free assets rarely match stylistically, creates Frankenstein visuals.

### Art Generation
- **Creature sprites:** ChatGPT works well (proven with current project)
- **Environments:** The hard part - avoid if possible
- **VFX:** Particles, shaders, procedural
- **UI:** Can be geometric/minimal

---

## What Claude Can Build Without Manual Art

- Stick figures using Line2D + circles
- Procedural animation via tweens
- Geometric shapes with glow shaders
- Particle VFX
- Spring grid backgrounds
- Full game systems
- Shockwave/distortion shaders
- Chain lightning / beam effects
- Procedural terrain (Marching Squares)

User provides: Art direction feedback, value tweaking
