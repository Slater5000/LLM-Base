# Art-Light Game Ideas Brainstorm

> Session: February 2026
> Goal: Games that require minimal art, maximum replayability

---

## Core Constraint

**Art is the bottleneck.** Every visual element becomes a burden. The more we can reuse assets, generate procedurally, or use geometric/abstract visuals, the better.

**Environment art is the hardest part** - tilesets, towns, decorations, placing buildings. Creature/character sprites can be generated with ChatGPT. Backgrounds are often free.

---

## The Active List (Ready to Prototype)

### 1. Tower Idle Defense
- Tower in center, enemies constantly approach
- Tower gets stronger over time (idle progression)
- Geometric aesthetic: tower = glowing shape, enemies = colored shapes
- **Art needed:** Minimal - shapes, particles, UI

### 2. Asteroid Mining Ant Farm
- Start in center of asteroid/meteor
- Mine outward in any direction you choose
- Grows like an ant farm over time
- Procedural rock texture, tunnels are negative space
- **Art needed:** Minimal - noise textures, particles, maybe ore colors

### 3. Gladiator Battle Simulator
- Two fighters, RNG-based combat chains
- Each move has chance to lead into: another hit, block, counter, etc.
- Chain continues until someone dies
- Player influence: choose gladiator, equipment, stats
- Inspired by: Shadow of Mordor orc pit, Swords and Sandals
- **Key requirement:** Must SEE the fight visually, not just read a log

**Visual Solutions for Gladiator:**
- **Option A: Stick Figure Skeletons** - Godot Skeleton2D or Line2D limbs, procedural animation, different heads/weapons/colors per gladiator
- **Option B: Geometric Fighters** - Capsule body, line arms, shape weapons, all tweened procedurally
- **Option C: Weapon-Only** - Skip bodies, two weapons fighting each other (sword vs axe)
- **Option D: Side-View Simplified** - Minimal limbs like Nidhogg, silhouette sells the action

**Recommended approach:** Option A or B with glowing Geometry Wars aesthetic weapons (glowing sword, glowing shield)

**Art needed:** Very low if procedural - one rig, code-driven animation, particles for impacts

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

---

## Ideas Discussed but Lower Priority

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
| Auto-battlers | Visual-dependent, not compelling without good art |
| Katamari-like | 3D + needs tons of object art |
| Co-op driver/gunner | Medium-high art, bigger scope |
| Racing + combat | 3D multiplayer, way too big |

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
**Verdict: Godot for these prototypes**

| Factor | Unity | Godot |
|--------|-------|-------|
| 2D workflow | Good | Excellent |
| Asset Store | Massive | Small |
| Licensing | Revenue fees | Free forever |
| Momentum | None | Already working |

Unity Asset Store trap: Free assets rarely match stylistically, creates Frankenstein visuals.

### Art Generation
- **Creature sprites:** ChatGPT works well (proven with current project)
- **Environments:** The hard part - avoid if possible
- **VFX:** Particles, shaders, procedural
- **UI:** Can be geometric/minimal

---

## Prototype Priority

1. **Gladiator Stick Figure** - Test if the visual approach works
2. **Tower Idle Defense** - Simple, clear mechanics
3. **Asteroid Mining** - Interesting procedural visuals
4. **Battle-Only Creature Roguelite** - Needs more loop design but high potential

---

## What Claude Can Build Without Manual Art

- Stick figures using Line2D + circles
- Procedural animation via tweens
- Geometric shapes with glow shaders
- Particle VFX
- Full game systems

User provides: Art direction feedback, value tweaking
