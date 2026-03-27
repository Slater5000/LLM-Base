# Master Game Ideas Doc

> Last updated: March 2026
> Goal: Games that require minimal art, maximum replayability
> **This is the single source of truth for all game ideas.**

---

## ACTIVE SHORTLIST — Next to Build

All min/low art, all coop, all 2D Unity.

| # | Game | Fun | Players | Art | Engine |
|---|------|-----|---------|-----|--------|
| 18 | **Spaceotrauma** | A+ | 4 | Min | Unity |
| 1 | **Co-op Shmup** | A | 2 | Min | Unity |
| 13 | **Space Exterminator** | A/A+ | 2 | Low | Unity |
| 7 | **Tower Defense + Payload** | A | 2-4 | Low | Unity |
| 16 | **VS/Bloons Hybrid** | A | 2 | Low | Unity |

---

## Core Constraints

**Art is the bottleneck.** The more we can reuse assets, generate procedurally, or use geometric/abstract visuals, the better. Environment art is the hardest part — tilesets, towns, decorations, placing buildings. Individual assets (characters, creatures, items) can be generated procedurally via Blender Python scripts or with ChatGPT.

**Co-op is king.** Almost every idea gets the "what if two players" treatment. Local co-op is the sweet spot. Online co-op is the stretch goal.

**Engine rule of thumb:** 2D = Unity. 3D = Unreal. Godot = quick prototypes only (perf ceiling too low for entity-heavy games).

---

## Tags Reference

| Tag | Meaning |
|-----|---------|
| `coop` | Local or online co-op |
| `pvp` | Player vs player |
| `solo` | Single player |
| `online` | Online multiplayer potential |
| `art-min` | Tier 1 — literally shapes/particles |
| `art-low` | Tier 2 — simple shapes + minimal character |
| `art-med` | Tier 3 — sprites or stick figures needed |
| `action` | Real-time action gameplay |
| `sim` | Simulation / management |
| `rpg` | RPG elements |
| `roguelite` | Run-based with meta progression |
| `party` | Party game / quick rounds |
| `idle` | Idle / incremental mechanics |
| `stealth` | Stealth mechanics |
| `racing` | Racing / vehicle gameplay |
| `rhythm` | Rhythm / timing-based |
| `2D` | 2D game |
| `3D` | 3D game |

---

## Coop/Multiplayer — 2D

### 5. Pac-Man PVP Party
`pvp` `online` `party` `art-min` `2D`

Asymmetric multiplayer. One player is Pac-Man, others control ghosts. Rounds rotate roles. Ghosts compete individually — most kills as ghost, highest score as Pac-Man. Everyone for themselves.

- **Art:** Minimal — maze is lines/tiles, characters are circles with eyes. Neon glow aesthetic.
- **Engine:** Unity (online multiplayer)
- **Why it works:** Everyone knows the rules instantly. Individual ghost scoring prevents ganging up — ghosts compete with EACH OTHER.
- **Prior art:** Pac-Man Vs. (2003, Miyamoto, GBA link cable). No modern indie standalone version exists.

---

### 7. Tower Defense + Payload (Co-op Orcs Must Die)
`coop` `action` `art-low` `2D` `online`

Top-down Orcs Must Die. Player IS a character AND places defenses. Walk around the map, build towers/traps, then fight alongside them when waves come. One player builds, one fights. Or both do both.

- **Art:** Low-medium — geometric towers, shape enemies, top-down character.
- **Engine:** Unity
- **Natural coop fit:** Asymmetric roles emerge organically.

---

### 10. Turn-Based Line-Drawing Roguelite
`coop` `roguelite` `action` `art-min` `2D`

Given limited movement distance per turn. Draw your path with the mouse. Press play — watch your character execute, fighting enemies at contact points, following the line until room is cleared. Isaac-style room-by-room roguelite. (Merged with old Draw-Line Strategy idea — same core mechanic.)

- **Art:** Minimal — top-down geometric, trail effects.
- **Engine:** Unity
- **Why it's interesting:** Frozen Synapse meets Isaac. Planning phase + execution payoff. Each room is a puzzle you solve with a line. Could have abilities that trigger at specific points on the path.

---

### 13. Synthetik/Archero-like Space Exterminator
`coop` `action` `roguelite` `art-low` `2D`

Top-down shooter with Synthetik's gun feel or Archero's move-stop-shoot. Space exterminator theme — clearing aliens/bugs from ships or planets.

- **Art:** Low — top-down character, alien enemies, spaceship environments.
- **Engine:** Unity

---

### 14. Creature Collector Battle-Only Roguelite
`coop` `rpg` `roguelite` `art-med` `2D`

Pokemon meets Binding of Isaac. NO exploration, NO towns. Just battle -> reward -> battle -> boss -> meta-progression. Draft creatures mid-run. Synergies matter. HP carries over between fights. Multiplayer: competitive or coop battles.

- **Art:** Medium — creature sprites (ChatGPT), battle backgrounds, UI, VFX.
- **Engine:** Unity
- **Loop:** Pick starter -> fight -> draft 1 of 3 creatures -> fight -> evolve mid-run -> boss -> meta-unlock

---

### 15. Co-op Snake + Something
`coop` `party` `art-min` `2D` `online`

Both players control snakes in an arena. Shared goal but your ally is also an obstacle. Could merge with Tron trail concept — temporary trails create dynamic mazes.

- **Needs:** The "something" — what's layered on top of snake? Combat? Tower defense? Puzzle elements?
- **Art:** Extremely minimal — lines and dots.
- **Engine:** Unity (for online)

---

### 16. VS/Bloons Hybrid (Don't Touch the Bottom)
`coop` `action` `art-low` `2D`

Vampire Survivors meets Bloons Super Monkey. Enemies swarm toward the bottom of the screen — don't let them through. You're the last line of defense.

- **Needs:** What makes this not just "tower defense without towers"? Player movement? Abilities? Upgrade tree?
- **Engine:** Unity

---

### 18. Spaceotrauma
`coop` `action` `art-min` `2D` `online`

One vehicle/ship, multiple players with roles. Space exploration with Geometry Wars visuals. Each player controls a different system (weapons, shields, engines, navigation). Roguelite structure with procedural encounters.

- **Reference:** Lovers in a Dangerous Spacetime, Ship of Fools, FTL
- **Engine:** Unity

---

### 29. Creature Evolution Battle Simulator
`solo` `pvp` `online` `sim` `action` `art-low` `2D`

Mad scientist creature forge — choose traits/genes for a creature species (environment, diet, population size, breeding rate, weight, intelligence, weapons, defenses, evolution speed) and watch it get procedurally generated as a pixel sprite. Then watch your species evolve over time with randomized mutation factors. Goal: create the ultimate combat being and battle other players' evolved creatures.

- **Hook:** Spy Kids 2 mad scientist lab vibes — like Steve Buscemi on his island choosing creature traits and watching them come alive. Spore meets TABS meets WorldBox.
- **Key mechanics:**
  - Trait/gene selection with a budget — spend points on attributes, tradeoffs matter
  - Procedurally generated 2D pixel sprites based on chosen traits (Noita-style gritty pixel art)
  - Watch creatures evolve over time — visual mutations, stat changes, adaptation
  - Size-to-numbers ratio: tiny breeding swarm (100 zubats) vs massive titan (1 groudon)
  - HoMM2-style battlefield — your army on left, enemy on right, creatures fight autonomously
  - Multiplayer: create a species, pit them vs friends or AI
  - Intelligence trait influences evolution rate and combat tactics
  - Balance between evolution speed and brute force
- **Stretch: Civilization mode** — like 9 Kings/Stick Wars, armies on opposite sides of field, watch species race to evolve, traits influence intelligence/evolution rate/defenses/weapons
- **Art:** Low — all creatures procedurally generated (baked pixel sprites like Ant Farm worker_manager approach). Battlefield is simple 2D field. No hand-drawn assets needed.
- **Engine:** Godot (prototype) → Unity (production)
- **Reference:** TABS, WorldBox, Spore creature creator, HoMM2 battle screen, 9 Kings, Stick Wars
- **Status:** PROTOTYPING — spider-monkey test creature built with baked atlas pipeline at `scenes/prototypes/creature_gen/`
- **Why it's special:** Nobody's combined a deep creature trait system with procedural pixel art generation and TABS-style autonomous battles. The "design a species from scratch and watch it evolve" loop is endlessly replayable.

---

## Coop/Multiplayer — 3D

### 3. Death Race
`coop` `pvp` `online` `racing` `action` `art-med` `3D`

Multiplayer racing with weapons, but weapons only work in specific zones on the track. Pure racers shine in clean sections, fighters shine in weapon zones. Best overall player wins.

- **Key mechanics:**
  - Weapon loadout before race (pick your kit)
  - Weapon zones on track (not everywhere — creates pacing)
  - Click stick to auto-drive forward, turn around, shoot behind you while driving backward
  - X to jump, dash side-to-side while driving. Super arcadey.
  - Modes: first to finish line OR last alive (laps until one remains)
  - Coop mode: one drives, one shoots
  - Inspired by **Mad Dash** (OG Xbox) — monkey bars, swimming, climbing, sliding on vines, unique traversal mechanics
- **Art:** Medium — vehicles, tracks, weapon effects. Stylized/arcadey helps.
- **Engine:** Unreal
- **Why it's special:** Weapon zones create natural pacing. The turn-around-and-shoot mechanic is hilarious and skill-expressive. Coop driver+shooter adds another mode.

---

### 11. Skateboard/Hoverboard Combat
`coop` `action` `art-med` `3D`

Momentum and gravity-based movement. Jumps, tricks, sliding (like Kena's bow slide). Hit enemies with your board, shoot while grinding. Echo Point Nova vibes.

- **Needs:** Arena or linear? Competitive or PvE?
- **Engine:** Unreal
- **Reference:** Echo Point Nova, that PVP sliding game, Boson X movement feel

---

### 19. Survival Crafting RPG (Combat-Centric)
`coop` `rpg` `action` `art-med` `3D`

Survival crafting but instead of mining rocks and chopping trees, you fight rock monsters and tree monsters. Everything revolves around combat strength — survival materials come from enemy drops, not passive gathering.

- **Needs:** Scope is potentially huge. How to keep it manageable?
- **Engine:** Unreal
- **Why it's interesting:** Removes the boring part of survival games (hold click on rock). Every resource interaction is a fight.

---

### 20. Katamari Homage
`coop` `pvp` `party` `art-med` `3D`

Collecting to grow bigger. Could be coop (grow together) or PVP (who grows biggest). Maybe RPG format — grow through levels/worlds.

- **Needs:** What's the twist beyond "it's Katamari"? The coop/PVP angle is promising.
- **Engine:** Unreal (3D rolling physics)

---

## Coop/Multiplayer — Either 2D or 3D

### 1. Co-op Shmup (Pilot + Gunner)
`coop` `action` `art-min` `2D or 3D` `online`

Two-player co-op shoot-em-up. Pilot moves/dodges with weak forward guns, Gunner aims freely with heavy firepower (turrets, missiles, beams). Geometry Wars neon glow aesthetic. Asymmetric co-op creates natural tension: "dodge left!" vs "hold still, lining up a shot!"

- **Art:** Minimal — geometric shapes, particles, glow shaders. All procedural.
- **Engine:** Godot prototype EXISTS at `scenes/prototypes/shmup/`. Production version -> Unity (2D) or Unreal (3D).
- **Status:** PROTOTYPED in Godot. 15 enemies, 36 upgrades, VS-style progression, spring grid, mouse aiming. Full design at `.llm/SHMUP_DESIGN.md`.

---

### 2. Loot Goblin
`coop` `pvp` `stealth` `action` `art-low` `2D or 3D` `roguelite`

You ARE the goblin. Sneak through a castle, grab high-value loot, avoid enemies. Normal enemies patrol the area. "Adventurer" party enters as a time pressure mechanic — they clear rooms and loot as they go (like watching a Pokemon trainer). If they spot you, endless chase. You're incentivized to loot fast before they arrive, or tail them and grab scraps.

- **Hook:** Role reversal — you're the monster. Adventurers are the boss.
- **Key mechanics:**
  - Weight/capacity management (can't grab everything)
  - Traps and decoys to distract enemies and adventurers
  - Physics — knock tables for ring-around-the-rosy, enemies can knock furniture away
  - Shop sim layer: sell loot in your own shop, customers want specific items from specific dungeons, upgrade shop
  - **Coop mode:** Run a shop together
  - **Competitive mode:** Competing shops, enter the same dungeon to compete for valuable goods to sell
- **Art:** Polygon/cartoony style. Low-medium — character sprites, dungeon tiles, loot items. ChatGPT can generate most sprites.
- **Engine:** Unity (2D) or Unreal (3D)
- **Why it's special:** Nobody's made this. The stealth + collection + shop loop is unique. The adventurer AI creates emergent stories.

---

### 6. Top-Down Boss Rush (Cuphead x Furi x Isaac)
`coop` `action` `roguelite` `art-low` `2D or 3D`

Cuphead-style boss fights but top-down like Isaac. More Furi than Isaac — boss rush focused, not exploration. Each room is a boss or mini-boss.

- **Art:** Low if geometric/stylized. Boss designs can be shape-based with strong silhouettes.
- **Engine:** Unity (2D) or Unreal (3D)
- **Why it works:** Boss rush = less content per hour but higher quality per encounter. Roguelite structure adds replay. Coop boss fights are inherently fun.

---

### 17. Gladiator Battle Simulator
`coop` `pvp` `art-low` `2D or 3D`

Two fighters, RNG-based combat chains. Each move chains into: another hit, block, counter, etc. Player picks gladiator, equipment, stats. Must SEE the fight visually. Swords and Sandals / Shadow of Mordor orc pit inspired.

- **Art:** Low if procedural — stick figure skeletons or geometric fighters with glow weapons.
- **Engine:** Unity (2D) or Unreal (3D)
- **Visual approach:** Nidhogg-style silhouettes or Geometry Wars glow aesthetic on weapons.

---

### 23. Fly Game
`coop` `action` `art-low` `2D or 3D`

You're a fly. Land on food/people for points. Collect coins in the air, fly through hoops. Avoid cats and fly swatters. Simple arcade loop.

---

### 25. Fart Balloon Party Game
`coop` `party` `pvp` `art-min` `2D or 3D`

Keep balloon in the air with farts. Knock back other players with farts. Party game — quick rounds, simple controls, guaranteed laughs.

---

## Single Player — 2D

### 4. Ant Colony Sim
`solo` `sim` `idle` `art-low` `2D`

Side-view ant farm sim. Dig tunnels, manage colony, evolve ants. WorldBox-style observation meets real-time simulation. Pheromone highways, relay chains, education mode.

- **Art:** Procedural terrain, simple ant sprites, particle effects.
- **Engine:** Godot version ~33% done at `C:\Projects\Firstpass\Ant_Farm`. Considering Unity port for performance (need 1000 ants, hitting walls at 200 in Godot even with C++ GDExtension).
- **Status:** ACTIVE. Full design at `.llm/ANT_COLONY_DESIGN.md`. Unity kickoff docs written.

---

### 8. Evolution God Game (WorldBox x Godhood)
`solo` `sim` `art-low` `2D`

God-game where you influence evolution, not directly control. WorldBox-style sandbox simulation meets Godhood's intervention mechanics.

- **Needs:** What's the core verb? Are you nudging species? Placing biomes? Throwing disasters? Needs a hook beyond "evolution sim."
- **Engine:** Unity (entity-heavy sim)

---

### 28. Brick Breaker (Unreal)
`solo` `action` `art-min` `2D`

75% complete Unreal project exists from last year. Fast-paced, tons of balls, not punished for missing. Could finish or restart in Unity. Could be coop.

---

## Single Player — 3D

### 12. Boson X + Thumper Hybrid
`solo` `action` `rhythm` `art-min` `3D`

Platforming forward constantly like Boson X, but landing on specific tiles damages a boss. Little enemies on the track to shoot or dodge. Circle-style side-to-side movement.

- **Art:** Minimal — geometric track, glowing tiles, particle bosses.
- **Engine:** Unreal (3D forward-runner)
- **Why it's interesting:** Nobody's combined rhythm-runner with boss fights through platform selection. The track IS the attack.

---

### 24. Buggy Game RPG
`solo` `rpg` `art-med` `3D`

The game is intentionally "breaking" — you're sucked in, things go buggy. Real footage of you in mad scientist coat for narrative, like Control's live-action Threshold Kids segments. Fourth-wall breaking humor.

---

## Single Player — Either 2D or 3D

### 21. Bug RPG
`solo` `rpg` `art-med` `2D or 3D`

Play as a bug, fight other bugs. That's the whole note. Could be cool with the right tone — Hollow Knight proved bug worlds work.

### 22. Trash Monster RPG
`solo` `rpg` `art-med` `2D or 3D`

Fight trash monsters, restore beauty to the world. Environmental theme. Before/after transformation as you clear areas.

---

## Just a Concept

### 26. Blindness/Audio Co-op Game
`coop` `art-min`

"It Takes Two but blind." Limited/no vision as a FEATURE. Sound + shapes + vibration as primary gameplay. Most original concept — massive creative space — but "blind co-op" is a theme, not a game yet. Needs a concrete mechanic.

---

## REJECTED — Explored and dismissed

| Idea | Reason |
|------|--------|
| Asteroids variants | Didn't catch interest |
| Text/ASCII games | No text preference |
| Deckbuilders | Not interested + heavy art (Slay the Spire) |
| Puzzle games | Hard no |
| Management sims | Would rather do idle |
| Vampire Survivors clones | Genre overdone |
| Match-3 | Hard no |
| Grid-based games | Not interested |
| Auto-battlers | Boring without amazing visuals — not compelling without good art |
| Katamari-like (pure clone) | 3D + tons of object art (homage version in WARM) |
| Racing + combat (realistic) | Too big (arcadey Death Race version in HOT) |
| Agar.io / massive multiplayer | Not into massive multiplayer — prefers local/small group coop |
| Idle Mining w/ Destructible Terrain | Redundant with Ant Colony Sim |
| Draw-Line Strategy | Merged into Turn-Based Line-Drawing Roguelite (#10) |

---

## Design Themes (recurring patterns)

1. **Co-op is king.** Every idea gets "what if two players." Local co-op is the sweet spot.
2. **Modernize a classic.** Take something everyone knows, add modern juice and co-op. Rules are pre-taught, nostalgia is free marketing.
3. **"No art = game mechanic."** Shapes as feature, not limitation. Geometry Wars proved shapes can feel premium.
4. **Role reversal / perspective flip.** Loot Goblin (you're the monster), Fly Game (you're the pest). Fresh takes on familiar dynamics.
5. **Arcadey over realistic.** Every racing/combat/action idea leans into wacky, over-the-top, fun-first.

---

## Art Burden Tiers

### Tier 1 — Literally Just Shapes
Shmup, Snake, Pong/Breakout, Rhythm game, Fart Balloon, Lovers-style Coop

### Tier 2 — Simple Shapes + Minimal Character
Tower Defense, Pac-Man, VS/Bloons hybrid, Line-drawing roguelite, Brick Breaker

### Tier 3 — Simple Sprites or Stick Figures
Loot Goblin, Boss Rush, Gladiator, Space Exterminator, Fly Game

### Tier 4 — Moderate Art but Manageable
Creature battler, Racing, Survival crafting, Bug RPG, Katamari, Skateboard

---

## Engine Decision Matrix

| Game Type | Engine | Why |
|-----------|--------|-----|
| 2D anything | Unity | C# is AI-friendly, DOTS for entity-heavy, 2D is first-class |
| 2D quick prototype | Godot | Fast iteration, free, good for testing if an idea has legs |
| 3D anything | Unreal | User knows editor, best visual fidelity, C++ for us + Blueprints for user |
| Online multiplayer (2D) | Unity | Mirror/Fishnet are mature, Netcode for GameObjects |
| Online multiplayer (3D) | Unreal | Built-in replication, dedicated server support |

---

## VFX We Can Build From Code (No Art Assets)

- Particle systems (explosions, trails, debris, sparks)
- Spring grid (Geometry Wars background warping)
- Glow / Bloom (neon aesthetic via shaders)
- Screen shake (camera trauma system)
- Chromatic aberration (RGB split on impact)
- Shockwave distortion (circular distortion on explosions)
- Chain lightning (procedural lines between targets)
- Plasma beams (animated line effects with glow)
- Procedural trails (fading paths behind moving objects)
- Procedural animation (tweens, sine waves, spring physics)
- Procedural terrain (Marching Squares, noise-based)

---

## Geometry Wars Research Notes

### Series Overview
- **GW1** (360, 2005): Single arena survival. Proved the concept.
- **GW2: Retro Evolved** (2008): BEST in series. 6 modes. Geom multiplier. Perfect game feel.
- **GW3: Dimensions** (2014): 3D arenas (surface of shapes). Drones, supers, co-op. Beautiful but 3D hurts clarity.

### Key Design Lessons
- **Grid warping = spring physics.** Point masses + springs. Explosions push, springs pull (pull only, never push). Border anchored.
- **Color = behavior.** Blue = chase, Green = evasive, Pink = splits, Orange = fast, Red = ranged/tanky.
- **Never spawn in corners** — feels unfair.
- **Particles fade FAST** — clarity over spectacle.
- **Geom multiplier** — enemies drop pickups that increase score multiplier. Risk/reward: rush for geoms (dangerous) or play safe (lower score).
- **Bombs** — panic button. Limited. Feels amazing at the last second.
