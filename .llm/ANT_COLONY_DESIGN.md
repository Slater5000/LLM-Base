# Ant Colony: Idle Mining Game — Design Document

> **Working Title:** Ant Colony (or "The Hive", "Queen's Dig", TBD)
> **Genre:** Idle / Incremental + Action Mining Hybrid
> **Engine:** Godot 4.6
> **Perspective:** 2D Side-View Cross-Section (Ant Farm style)
> **Art Style:** Procedural terrain, geometric ants, minimal art required

---

## Elevator Pitch

You are the Queen Ant. You start in a tiny dirt chamber with almost nothing. Dig through procedurally generated terrain, collect food, grow your colony, unlock upgrades, and expand infinitely outward through increasingly difficult terrain. Part idle game, part action miner, part ant farm simulator.

---

## Core Loop

```
QUEEN DIGS DIRT → EXPOSES FOOD → PICK UP OR HAULERS COLLECT → DEPOSIT AT PILE → BUY UPGRADES → DIG BETTER
                                                                                      ↓
                                                                               Hatch more ants
                                                                               Unlock transport
                                                                               Unlock abilities
```

### The Pipeline
**Miners dig dirt → food gets exposed → haulers carry food to pile → spend food on upgrades**

The queen is the primary frontier digger. Miner ants assist by digging dirt toward food sources (NOT mining the food itself — they mine the DIRT surrounding it). Once dirt is cleared and food is exposed, hauler ants pick it up and bring it back.

### Three Bottlenecks
The player always has THREE things to balance:
1. **Dig Power** — how fast dirt is removed to expose food (queen strength + miner ants)
2. **Transport** — how fast exposed food gets back to the pile (hauler ants + infrastructure)
3. **Labor Supply** — how many ants you have and how they're split between mining and hauling

A 4th emergent bottleneck is **tunnel network quality** — a player skill bottleneck, not a stat. How well you design your tunnel layout determines how efficiently workers move. Straight efficient paths vs spaghetti mess. This is where the Dwarf Fortress / Factorio optimization brain kicks in.

**No storage cap.** Unlimited food storage. Let the player have bugo bucks.

### Session Flow
1. **Early game (0-15 min):** You dig manually, alone. Learn the terrain. Find food clusters. Everything is hands-on.
2. **Mid game (15-60 min):** Workers hatched, basic automation running. You dig the hard stuff, they haul.
3. **Late game (hours):** Minecarts, trains, tubes. You're directing an operation, not doing grunt work.
4. **Endgame (tens of hours+):** Rainbow food currency, endgame upgrades, full automation. The colony runs itself. You optimize.

### Vanilla Mode (Separate Game Mode)

Selectable from the main menu as an alternative to the normal game. A **pure ant farm screensaver** for people who want to watch ants on their second monitor without any progression systems, menus, or decisions.

**How it differs from normal mode:**
- **No upgrade tree.** No menus, no forks, no currency spending. No "Evolve" tab.
- **No dirt difficulty scaling.** All dirt is base strength (same number of bites everywhere). Dirt still changes color with distance (visual gradient intact) but hardness doesn't increase.
- **Starts with 2 workers:** 1 miner, 1 hauler. They start working immediately.
- **Player CAN dig** with base bite strength. No dig methods, no stat upgrades. Just basic bite at base power. Optional — you never have to touch the mouse.
- **Player CAN place dirt** (right-click). Baked in from the start — no upgrade needed. Build ramps, bridges, walls to help your ants.
- **Auto-click baked in.** Queen passively begins with auto click so they can hold click to dig. No upgrade needed — it's just how Vanilla Mode works.
- **Player CAN zoom/pan** to watch the colony. Free camera.
- **No food counter visible.** Food is tracked internally for auto-spawning but the player never sees a number or a menu. Pure visual experience.
- **Player CAN name ants.** Click any ant to name it. This is Vanilla Mode's main interaction — watch Greg haul food, watch Steve dig tunnels.
- **Pheromone Highways baked in (cosmetic only).** Ants leave visible pheromone trails that glow on well-traveled routes. **No speed boost** — purely visual. Toggleable in Gameplay settings. Gives the colony that living, breathing look without affecting gameplay balance.
- **Cosmetics from normal mode available.** Any hats, trails, or cosmetics unlocked in normal mode can be used in Vanilla Mode. Vanilla Mode is a **viewer, not an unlocker** — you can't earn new cosmetics here.
- **Multiple save slots.** Vanilla Mode has no endgame barrier, so you can create as many colonies as you want — works like a normal save system. Start new colonies freely, return to old ones anytime.
- **Infinite, gentle scaling.** Colony grows slowly over time, expanding outward. No endgame, no goals. Just watch it go.
- **Also powers the main menu background.** See Main Menu section.

**Auto-Spawner System (Hidden):**

The colony grows itself. All of this is invisible to the player — no numbers, no menus, no decisions. **No manual worker buying.** The algorithm decides what to spawn and when. The only thing the player can do is bring in more food (dig, help haul) to accelerate the process.

**Auto-spawn toggle:** Players can **pause** auto-spawning via Gameplay settings (toggle off). This lets you freeze your colony size if you want. But you cannot manually choose to buy or assign workers — when the toggle is on, the algorithm handles everything.

**Spawning cost formula:** `cost_for_ant_N = floor(8 + N * 4)` where N = total ants spawned so far (not including the 2 starting workers). Deliberately slow — you should have time to notice, name, and appreciate each new ant before the next one arrives.

| Ant # | Food Cost | Approx Time | Feeling |
|-------|-----------|-------------|---------|
| 1-2   | Free (starting) | Immediate | Meet your first two ants |
| 3     | 12        | ~30-45s | "Oh, a new one!" |
| 4     | 16        | ~45-60s | Starting to feel like a colony |
| 5     | 24        | ~60-90s | The family is growing |
| 10    | 44        | ~2-3 min | Busy little operation |
| 20    | 84        | ~4-5 min | Real colony vibes |
| 50    | 204       | ~8-10 min | Impressive network |

**Minimum 5 seconds between spawns** even if food is banked. One ant at a time, always visible, never a burst.

**First 6 ants follow a fixed pattern:** M, H, M, M, H, M. Guarantees a healthy early colony. After that, the ratio AI takes over.

**Miner/Hauler Ratio AI:** Simple rule-based, runs each time a new ant is about to spawn:
- If `idle_haulers >= 2` → spawn **miner** (haulers starving for work, need more digging)
- If `exposed_unclaimed_food >= hauler_count * 3` → spawn **hauler** (food piling up, need more transport)
- Otherwise → maintain **2:1 miner:hauler ratio** (default target)

**Performance-Regulated Soft Cap:** The auto-spawner monitors FPS internally. If FPS drops below a threshold (e.g., 30), spawning pauses. If FPS recovers (player zoomed out, ants spread out, etc.), spawning resumes. The colony finds its natural size based on hardware. Target: 1000+ ants before performance becomes a concern.

**Colony Size** lives in the Gameplay settings tab (accessible from all modes). Sets a soft cap target: Small / Medium / Large / Unlimited (default **Unlimited**, performance-regulated only). For players who want a chill 50-ant colony on a weak laptop.

**The appeal:** Put it on your second monitor. Minimize everything else. Watch ants dig tunnels and haul food. Name them. Give Greg a cowboy hat. That's it. That's the game.

**This replaces the "vanilla 5th option" approach** — instead of cluttering the upgrade tree with boring stat-buff alternatives, players who want the simple ant farm experience get their own dedicated mode. The normal game's forks stay interesting and meaningful without a "do nothing" choice competing with fun options. The name "Vanilla Mode" leans into this — it IS the vanilla experience, and that's a feature, not a limitation.

---

## Main Menu & Navigation

### Main Menu
- **Background:** A running Vanilla Mode-style ant colony. Couple hundred ants, healthy colony, purely cosmetic. **Freshly generated each app launch** — not saved, not persistent. Low ant count for performance.
- **Buttons overlaid on top** of the background colony.

**Main Menu Flow:**
```
MAIN MENU (anthill background)
├── Start Game → [Normal Mode | Vanilla Mode | Back]
│   ├── Normal Mode → Colony Screen
│   │   ├── Current Colony (active save)
│   │   ├── Delete Colony button (with "Are you sure?" confirmation)
│   │   └── Legacy Colonies button (only visible after beating first colony)
│   │       └── Scrollable list of retired colonies (name + click to resume)
│   └── Vanilla Mode → Single save slot (play or reset)
├── Options → Settings Menu
└── Quit
```

### Save System

**One active colony per mode.** Normal Mode has one active colony. Vanilla Mode has one active colony. That's it.

**Normal Mode progression:**
- **First time playing:** One save slot. No Legacy menu visible.
- **Beat the game** (buy "Over the Rainbow") → colony is "completed." Player may choose to start a new colony.
- **Starting a new colony** retires the completed colony to the **Legacy Colonies** screen.
- **Resetting** deletes the current colony back to zero (with confirmation dialog). Does NOT count as beating the game.
- **Legacy Colonies** are fully playable save slots — return to any retired colony, keep playing, save progress.
- **Cannot start a new colony** until the current one is beaten (Over the Rainbow) or reset to zero. Committed to your choices.
- **Colony count** (number of retired colonies) determines meta-progression (+1 starting worker per colony founded).

**Save deletion:** Only accessible from the Colony Screen (Normal Mode menu). NOT from in-game settings/pause menu.

**What persists between colonies:** See Prestige System section.

**No offline progression.** The game only runs when open. No fake idle rewards. It's a screen saver, not a mobile game trying to trick you into thinking you're rewarded for not playing.

### Settings Menu

Settings save **separately from game saves** — persist across all colonies and modes.

**6 tabs:** AUDIO, DISPLAY, GAMEPLAY, PERFORMANCE, ACCESSIBILITY, CONTROLS

| Tab | Settings |
|-----|----------|
| **Audio** | Master volume, Music volume, SFX volume, Ambient volume |
| **Display** | Window Mode (borderless default), Resolution, Max FPS (30/60/120/144/Unlimited), UI Scale, Screen Shake (slider), Pheromone Trail Visibility (slider), Trail Quality (Simple/Normal/Detailed), Ant Detail Level (Dots/Normal/Full), Show Ant Names (toggle) |
| **Gameplay** | Game Speed (0.25x / 0.5x / 1x — no faster than realtime), Zoom Speed, Edge Scrolling (toggle), Auto-Save (toggle), Auto-Save Interval (left/right selector: 1m / 5m / 10m), Number Format (Standard 1500 / Short 1.5K / Scientific 1.5e3), Colony Size (Small / Medium / Large / Unlimited — default Unlimited) |
| **Performance** | Quality Preset (Low/Medium/High), Max Visible Ants (slider, ants beyond cap still simulated but not drawn), Show FPS Counter, FPS Warning (toggle — see Performance Warning System) |
| **Accessibility** | Colorblind Mode (Off/Deuteranopia/Protanopia/Tritanopia), High Contrast Mode, Font Size (Small/Normal/Large), Large Cursor |
| **Controls** | Key Rebinding (Move, Dig, Place, Zoom, Evolve, Build, Pause). Future: Controller Support, Controller Deadzone |

**Architecture notes:**
- Settings persist across save slots (separate save file)
- Number formatting = shared utility class (called thousands of times per frame)
- Max Visible Ants is the single most impactful performance lever
- Auto-reduce system: lightweight autoload monitors FPS, progressively dials down visual settings

---

## The World

### Starting State
- Entire screen is **solid brown dirt**
- Center of screen: a small **half-circle chamber** (flat bottom, curved top)
- Inside the chamber: **the Queen Ant** (player) — noticeably larger than worker ants introduced later
- **The Larder** in center of chamber — the food storage area. Starts with ~5 orange food bits on a dirt pedestal.
- The starting chamber has a **warm orange-yellow glow gradient** on the floor that fades from center outward. **This glow IS the collection zone** — ants entering the glow auto-deposit food. No harsh red circle.
- **The entire starting chamber is the deposit radius.** No radius upgrade — the room size is the radius. If it feels too big, shrink the room.
- The floor under the Larder and starting chamber is **indestructible** — can never mine out your own home base.
- The starting chamber has **visually distinct walls** — smoother, subtle root details, feels like "home" compared to raw tunnel.
- Tunnel background is **very dark brown** (`~Color(0.12, 0.08, 0.05)`). NOT pure black — reads as deep earth shadow, not void. Clearly "empty space" but thematically underground.

**Larder Visual Progression (food pile grows with deposits):**

| Food Amount | Visual |
|-------------|--------|
| 0-50 | Small dirt pedestal, scattered orange pieces on top |
| 50-500 | Growing mound, food visibly piling up, slight warm glow |
| 500-5000 | Proper hill of food, some tumbling off edges, golden-orange glow |
| 5000-50000 | Overflowing mountain, food embedded in nearby walls, strong warm glow |
| 50000+ | Absurd pile, fills most of the starting chamber, practically radiating |

### Terrain System
- **Granular carve aesthetics** — the visual reference is Noita-style destruction: organic crater shapes, sharp irregular edges, bite marks that look like bites. NOT Noita's physics engine (no falling sand, no liquid simulation, no cellular automata). The reference is purely visual — how terrain *looks* when destroyed, not how it *behaves* afterward. Noita was built on a custom engine specifically for pixel physics; we don't need that. We need the *carve feel* — granular enough to avoid blocky tile removal.
- **Likely approach: tile-based logic with pixel-visual overlay.** Each "tile" (for pathfinding, food placement) is a cluster of pixels (e.g., 4x4 or 8x8). Digging removes pixels within tiles using **shaped masks** (circle for explosion, wedge for bite, line for laser, splatter for acid). Pathfinding operates on the tile grid; visuals are per-pixel. Once enough pixels in a tile are cleared, the tile is "open" for pathfinding. Gives organic carve shapes without simulating individual pixel physics. Godot's `Image` class handles per-pixel manipulation on textures. **Chunk-based dirty-rect rendering** — only redraw modified chunks. **Needs research and Phase 1 prototyping to validate performance.**
- **CRITICAL: Visual fidelity must match dig angle.** If the ant bites from the left, the removal shape looks bitten from the left. If the explosion hits from above, the crater faces upward. The dig method's visuals drive the terrain deformation shape. This is the #1 requirement — more important than the technical approach.
- **No dirt gravity/physics** — too performance-heavy. Food already has light physics (falls when support removed). Dirt stays in place even if unsupported. Cut for performance.
- **Engine risk acknowledged.** If Godot can't handle the terrain + 1000 ants + pathfinding at 60fps, options are: optimize further (staggered updates, LOD, off-screen simplification), reduce pixel granularity (larger tiles), or evaluate Unity/Unreal. The Phase 1 terrain prototype will reveal whether this is viable within a week, not a month.
- **Procedurally generated** using noise functions (Perlin/Simplex)
- Food (orange circles) embedded in dirt, distributed throughout:
  - Individual scattered pieces (common)
  - Small clusters of 3-8 (uncommon)
  - Large veins of 10-20+ (rare, like Minecraft ore veins)
- **Food clusters placed in interesting spots** — behind rocks, in tight corners, at awkward depths. The food placement combined with rock formations IS the level design. Players see the food, see the obstacles, and have to figure out the best route to reach it.
- Terrain is **destructible** — digging removes dirt tiles
- Food is exposed when surrounding dirt is dug away — then it pops out and can be collected
- Empty space = tunnels, chambers, negative space the player creates
- **No natural caves at start** — every space is dug by the player or their workers

### Indestructible Rocks
- **Varying sizes** of indestructible rock formations scattered throughout the terrain
- Cannot be dug through — must dig AROUND them
- Creates natural logistics obstacles: "do I tunnel left or right around this boulder?"
- Adds interesting tunnel layout decisions without any combat/hazard/death mechanics
- Procedurally placed, denser at greater distances
- Visually distinct from dirt — darker, harder-looking, maybe with a subtle sheen
- Small rocks (2-3 tiles): minor detours
- Medium rocks (5-10 tiles): real routing decisions
- Large rocks (15+ tiles): major obstacles that shape entire tunnel networks
- **No damage, no death, no hazards.** Just logistics obstacles.

### Distance-Based Gradient System — Geological Eras (No Hard Layers)

Instead of discrete concentric layers with hard borders, terrain difficulty and food types are based on **distance from the starting chamber** with smooth gradient transitions. The terrain passes through distinct **geological eras** that shift the entire color palette — the journey never just "ends at black."

**How it works:**
- `distance_from_origin` determines everything: dirt hardness, dirt color, food value (linear band scaling)
- Colors blend smoothly between eras — no visible borders between "zones"
- Food is always orange — value increases with distance but appearance stays the same
- The terrain gradient IS the visual indicator of depth and food value
- **Indestructible rocks shift tint with era** — gray in topsoil, reddish-gray in clay, blue-gray in basalt, dark violet in crystal. Always clearly "rock" but they belong to their environment.

**Geological Eras:**

| Distance | Era | Palette | Dig Difficulty | Background Accents |
|----------|-----|---------|----------------|-------------------|
| 0-500 | **Topsoil** | Sandy tan → warm brown | 1-2x | Roots, worm tunnels, small stones |
| 500-1500 | **Earth** | Rich brown → dark brown | 2-4x | Organic matter, embedded beetle fossils |
| 1500-3000 | **Clay** | Reddish-brown → terra cotta | 4-8x | Compressed horizontal layers, pottery-like |
| 3000-5000 | **Limestone** | Cream → pale yellow | 8-16x | Fossil shells, ammonite spirals, sediment lines |
| 5000-8000 | **Granite** | Pink-gray speckled | 16-32x | Mica flecks, quartz veins, crystalline texture |
| 8000-12000 | **Basalt** | Dark blue-gray | 32-64x | Volcanic veins, occasional orange lava streaks |
| 12000-16000 | **Crystal** | Deep purple → violet | 64-128x | Amethyst formations, sparkle, crystal shards |
| 16000-24000 | **Prismatic** | Shifting iridescent | 128x+ | Rainbow food territory, otherworldly shimmer |
| 24000-40000 | **Bioluminescent** | Deep sea teal/cyan | Extreme | Glowing fungi, alien organic textures |
| 40000+ | **Cosmic** | Space purple-black + star specks | Extreme | Nebula wisps, rotating colors, infinite variety |

**The deepest layers are MORE colorful, not darker.** The journey goes warm → earthy → pale → hard → dark → sparkly → magical → alien → cosmic. You never hit a boring visual dead end. The Cosmic layer can go on forever — space-purple with varying nebula accents never hits a wall.

**Each era transition is a milestone moment.** "I just broke into the Crystal layer!" feels like an achievement even without a popup. Players recognize where they are by color.

All regular food is **orange** regardless of distance. Value = band number (linear: 1, 2, 3...). Band size (~200 tiles, needs tuning) determines how quickly value scales. See **Food System → Food Value** for details.

**World Discovery / Zoom:**
- Camera starts zoomed in on starting chamber
- When the player reaches the edge of the currently generated area, new terrain generates outward
- Player can **freely zoom in/out** but only to areas they've generated (can't see past frontier)
- Each zoom out reveals more of the colony's tunnel network — satisfying to see your creation from above

### Zoom System
- **Mouse wheel / pinch** to zoom in and out
- Zoomed in: see individual ants, food particles, dig animations, hat details
- Zoomed out: see colony network, tunnel systems, terrain color gradients
- **LOD system required** — zoomed out shows simplified representations:
  - Individual food → colored dots → aggregate glow per chunk
  - Individual ants → dots → count indicators per tunnel
  - Detailed terrain → simplified color blocks
- **Chunk-based rendering** — only render visible chunks at current zoom level

---

## The Player (Queen Ant)

### Appearance
- Larger than worker ants (~2-3x)
- Simple geometric design: 3 ovals (head, thorax, abdomen) + 6 line legs + 2 antennae
- Crown or subtle glow to distinguish from workers
- Food carried visually on top of body (stacked orange circles)
- **Equippable hat** on head (see Hats section)
- **Custom name tag** — player can name their queen from the start (always available, not an upgrade)

### Controls
- **WASD** — Movement (left, right, up, down)
- **Mouse position** — Aim direction (queen's head tracks mouse, allows aiming up/down/left/right in 2D side-view)
- **Left Click** — Dig in aimed direction
- **Hold Left Click** — Auto-mine (continuous digging at cooldown rate)
- **Right Click** — Place dirt at mouse position (fixed range, doesn't scale with any upgrade). When hovering over transport/logistics, right-click opens context menu instead.
- **Hold duration** — Controls bite size (tap = small, short hold = medium, long hold = large)
- **Scroll Wheel** — Zoom in/out
- **Tab** — Cycle active tool (e.g., swap between basic dig and unlocked dig method like Gun/Laser/Acid/Explosion)
- **[ / ]** — Adjust dig radius size. Only appears once Dig Radius upgrades are purchased. R:1 at level 1-4, R:2 at level 5-9, R:3 at level 10. Displayed next to tool indicator on HUD.
- **E** — Open Evolve (upgrade) menu
- **B** — Open Build menu (transport placement)
- **Escape** — Pause menu
- **Click on any ant** — Customize screen (name, color, hat)

### Build Menu & Transport Placement

**B key** opens the Build Menu — a centered radial hex ring showing available transport types. Each type is a button arranged in a circular layout around the center of the screen, with a description tooltip below on hover. Background blurs when the menu is open. Transport types progressively unlock as upgrades are purchased from the Evolve tree.

> **Test UI note:** The "PRESS 1-6 TO UNLOCK TRANSPORT TYPES" text and number-key unlock controls in the build menu test scene are for testing purposes only — not part of the final game UI. In the real game, transport types unlock through the Evolve tree.

**Two-click placement system:**
1. Select a transport type from the Build Menu
2. Click **start position** in the world
3. Click **end position** in the world
4. **Green highlight** = valid placement, **Red highlight** = invalid
5. **Escape or right-click** to cancel placement

**Per-type placement behavior:**
- **Conveyor Belt:** Click start tile, click end tile. Belt auto-routes between them along surfaces.
- **Pylon / Aerial Tramway:** Must connect back to the base transport network (no isolated pylons). If two pylons have line-of-sight, wire is drawn automatically. Wires can't go through walls.
- **Lift:** Vertical only. Click top position, then bottom position.
- **Zip Line:** Two-click like conveyor. Needs a surface attachment point at both ends.
- **Teleporters:** Place entrance pad, then exit pad. 1 pair only. Repositionable.
- **Pneumatic Tubes:** Place entrance, aim exit at any angle (360 degrees). Straight line through solid terrain.

### In-Game HUD

Minimal, non-intrusive overlay showing essential information at the viewport corners:

- **Top-right:** Food count with orange food icon
- **Top-left:** Distance from base, Worker count (M:x H:x for miners/haulers)
- **Bottom-left:** Active tool indicator with radius (e.g., "Tool: DIG R:1"). Radius only shown if Dig Radius upgrades have been purchased.

The HUD is always visible during gameplay (except in Vanilla Mode where the food counter is hidden — see Vanilla Mode section).

> **Test UI note:** The "TAB = CYCLE TOOL | [ ] = RADIUS SIZE" instruction text at the bottom of the HUD test scene is for testing purposes only — not part of the final game HUD.

### Movement Rules
- **Wall climbing** — Ants stick to any surface (floor, walls, ceiling)
- **No jumping at start** — unlockable via Jump+Dash or other Player Traversal pick
- **Traversal solution** — Place dirt (right-click) to create climbable surfaces / ramps / bridges (Place Dirt upgrade)
- **Gravity** — Ants fall if not touching a surface (unless Jetpack traversal pick)
- Movement speed upgradeable
- **Queen NEVER has a speed penalty.** Not from carrying food, not from anything. Always at full speed.

### Digging
- Click in a direction → Queen bites/digs a chunk of dirt in that direction
- **Dig has a cooldown** between bites (prevents auto-clicker cheese). Upgrades reduce cooldown.
- **Hold click = auto-mine** — continuously digs at cooldown rate, no spam clicking
- Dirt takes **multiple bites** to remove (based on distance-difficulty vs dig power)
- Visual: chomping animation, dirt particles fly off (Noita-style pixel debris)
- **Bite size: automatic, not an upgrade.** Works like Stardew Valley's watering can — hold longer for bigger bite. As soon as you CAN bite a larger size (via Dig Radius upgrades), you can switch between all unlocked sizes.
  - Small: 1-2 tile radius. Precise tunneling, detail work (tap click)
  - Medium: 3-4 tile radius. Standard mining (short hold)
  - Large: 6+ tile radius. Blast mining (long hold, unlocked via upgrades)
- **Dig speed** = cooldown reduction (starts slow, upgradeable)
- When all dirt around a food piece is removed, the food pops out and can be collected
- **Food has light physics** — if dirt beneath/around food is destroyed (e.g., by explosion dig method), food falls to the nearest floor rather than floating in mid-air
- **Dig Methods** replace basic bite animation — see Upgrade System → PLAYER ANT for Gun, Laser, Butt Acid, Explosion (pick 1 of 4)
- **Endgame (rainbow food):** Super Mandibles (one-bite anything), Auto Attack (auto-dig wherever facing)

### Place Dirt (Right-Click)
- **Requires Place Dirt upgrade** from LOGISTICS panel
- **Right-click** to place dirt at mouse position within range
- **Fixed baked-in range** — decent mid-range distance, never changes, NOT tied to any upgrade (tying it to Dig Range would make Dig Range mandatory/OP)
- **Doesn't need to connect to anything** — floating dirt in mid-air is fine (build bridges, platforms, ramps)
- **Placed dirt = base hardness** — easy to re-dig if you make a mistake
- **Cannot place over transport routes** — shows warning icon / red highlight. Prevents accidentally breaking infrastructure.
- **Cannot place in starting chamber** — Larder area is always protected
- **Visual:** Dirt chunks fly from queen in aimed direction and solidify on impact

### Carrying
- Touch exposed food → it attaches to top of Queen's body
- **Carry capacity** starts at 5 pieces (same base as haulers)
- Food visually stacks on the ant
- **No speed penalty.** Queen always moves at full speed regardless of how much food she's carrying.
- **Food auto-deposits** when entering the Larder (starting chamber glow zone). Just walk in.
- **Upgradeable progression:**
  - More carry slots (Carry Capacity upgrade, 0/10 tiers)
  - Void storage (food auto-deposits on pickup — endgame rainbow food unlock)

---

## Food System

### Food as Primary Currency
- **All food is orange.** No color tiers, no shape differentiation. Simple, clean.
- Food **value** is determined by **distance from base** using linear band scaling
- All food converts to a single currency number at the food pile
- **"+N food" popups** on deposit show the value of what was delivered
- Food pile visually grows as you deposit more (small pile → medium mound → large hill → overflowing)
- **No storage cap.** Unlimited. Let the number grow forever.
- The terrain color gradient (which changes with distance) serves as the visual value indicator — you know food is worth more when it's deep in dark terrain

### Food Value — Distance Band Scaling
Food value scales linearly based on distance bands (layers) from the starting chamber:

- **Layer 1** (closest to base) = value **1**
- **Layer 2** = value **2**
- **Layer 3** = value **3**
- ...and so on, linearly

**Band size** (how many tiles per layer) needs tuning through playtesting. The key properties:
- Linear and understandable — player can predict value at any distance
- Non-linear scaling possible if balance demands it, but must remain simple to understand
- No visual differentiation between food of different values — all orange circles
- Value is implicit from location, not explicit from appearance

### Rainbow Food — Endgame Currency (SEPARATE)
- **Rainbow food is NOT just "better food"** — it is its own separate currency
- Found only at extreme distances (16000+)
- **Always exists** at 16000+ — rare spawns, mysterious shimmer. Player encounters them before understanding what they are.
- Has its own upgrade menu / section (not mixed with regular food upgrades)
- Used for endgame-only special upgrades
- Cannot be converted to regular food or vice versa
- Extremely rare — finding one is an event
- Rainbow food menu only **visible and accessible** after buying "Over the Rainbow" (see below)

### The Larder (Food Pile)
- Located in the starting chamber
- **Warm glow gradient** on tunnel floor marks the collection zone (no harsh red circle). Fades from center outward.
- **The starting chamber IS the collection radius.** No radius upgrade — the room size is the radius. Enter the glow, auto-deposit.
- Workers automatically deposit food here when they enter the glow zone
- Indestructible floor — can never mine out your own home base
- Visually grows through stages as food accumulates (see Starting State section for progression table)

### Ant Egg Colors
Real ant eggs are **white/cream/translucent**. So:
- **Ant eggs: White/cream** (when we show hatching visuals)
- **Food: Orange** (strong contrast against brown dirt AND white eggs)

### Food Visibility
- **Food is always visible through dirt.** Bright colored shapes are clearly visible embedded in the terrain at all times.
- No detection radius, no hidden food, no reveal system. You can always see what's ahead and plan your dig path.
- This keeps gameplay focused on **routing decisions** (which food to go for, how to get there efficiently) rather than blind exploration.

---

## Upgrade System

### Structure: "Evolve" Menu — Three Panels
Open with **E** at any time (pauses or overlays). The upgrade menu is called **"Evolve"** — thematically, every upgrade is your colony evolving. **Three tabs** — Player, Logistics, Colony — in a centered panel with scrollable content per tab. Tab bar at top, scrollable upgrade tree below. Animated rainbow food count displayed in the top-right corner of the panel. Spend **food currency** to unlock nodes.

**No tier locking.** Upgrades are laid out top-to-bottom as intended progression, but nothing is gated behind prerequisites. You can skip entire rows and save up for something further down. It wouldn't be efficient (lower upgrades are cheaper and useful), but you can. Nothing is a requirement — every purchase is your choice.

**Rainbow Food upgrades** are a separate section — only visible once rainbow food has been found. Functions as an endgame "cheat menu" with absurd power fantasy unlocks.

**Transport infrastructure is FREE to place once unlocked.** You spend food to unlock the UPGRADE (e.g., "Minecart System"), then you can place unlimited track/carts for free. No per-piece cost. Building the network is the fun part, not the tax.

**All tiered upgrades are 0/10** (ten purchases each) unless otherwise noted. 0/10 means: you have 10 upgrades to buy. Each one gives the same increment. Start at 0, buy up to 10. Simple.

**Upgrade Toggleability:** All upgrades with active effects (Auto Conveyor, Ant Cannon, Food Singularity, Relay Chains, Boogie Bomb, etc.) can be **toggled on/off** at any time. Purchases are permanent — you can't un-buy or switch forks — but activation is optional. This lets players experiment without regret.

**Cost Display:** Once an upgrade is fully purchased, its **cost disappears** from the UI. Only unpurchased upgrades show their cost. This keeps the tree clean and makes it visually obvious what you still need to buy.

### Build Choice Forks

The upgrade tree contains **mutually exclusive forks** at key progression points. Fork size varies by context:
- **Pick 2 of 3** — for stat choices where you want variety without being gimped (e.g., dig range/speed/radius)
- **Pick 1 of 4** — for transformative choices that define your playstyle (e.g., dig methods, player traversal)
- **Pick 1 of 3** — for hauling efficiency choices with distinct identities
- **Pick 1 of 2** — for infrastructure choices with clear tradeoffs (e.g., tramway vs conveyor)

All forks are **permanent per colony.** Different colonies = different builds = reason to prestige. **All fork options are pure positives** — no drawbacks unique to one option. Differentiation is what they're good AT, not what they cost.

**Progression flow:**
```
EARLY GAME: Buy standard upgrades → encounter first fork → commit to a direction
MID GAME: More standard upgrades + more forks → build identity solidifies
LATE GAME: All forks chosen → colony has a clear identity → push toward rainbow food
ENDGAME: Rainbow food cheat menu → absurd power fantasy → infinite scaling
```

### Dig Power Scaling — Cross-Colony Persistence

Both player dig strength and miner dig strength have extended progression:
- **Regular tree:** ~50 tiers of scaling strength (costs regular food, must be re-purchased each colony)
- **Tier 50 = endgame unlock:** All cross-colony saved progress activates instantly
- **Tiers 51+:** Continue buying with rainbow food, progress persists forever between colonies
- New colony: grind 1→50 again, then at 50 you instantly jump to wherever you left off (e.g., 65) and continue
- This is the one exception to "clean slate every time" — just reward the player for playing
- Eventually you're one-shotting everything with a gun and it's hilarious. That's the reward for hundreds of hours.

### PLAYER ANT

The queen's personal abilities, stats, and automation tools. This is your "character build."

**Upgrade order (top to bottom in panel):**

| Upgrade | Type | Effect |
|---------|------|--------|
| Auto Mining | Standard | Hold click to continuously dig. **First unlock in the game** — don't make the player click-spam. |
| Scaling Dig Strength | Standard (0/50) | Increases player dig damage. Cross-colony persistence after tier 50. See Dig Power Scaling above. |
| Food Magnet | Standard (0/10) | Exposed food flies toward queen from increasing distance. Convenience, not game-breaking. |
| Player Speed | Standard (0/10) | Queen moves faster. |
| Carry Capacity | Standard (0/10) | Queen carries more food. Visually stacks on ant body. |
| Dig Range / Dig Speed / Dig Radius | **Pick 2 of 3** (each 0/10) | Range = dig from further away. Speed = faster cooldown. Radius = bigger bite. Can't have all three. |
| Auto Worker | Standard | Set miner/hauler ratio + food threshold. When food exceeds threshold, auto-hires at the set ratio. Idle game QOL. |
| Architect Ant | Standard | Special ant that auto-places and upgrades logistics infrastructure. "Follow the frontier" — prioritizes extending transport toward active mining areas. Only moves/adjusts endpoints of existing transport, doesn't build new routes from scratch. Physically walks to the position before making changes (visible on screen). Per-transport toggle: player can enable/disable architect for each transport type. Competent, not weak. Single purchase. |
| Auto Evolve | Standard | UI feature: checkbox on each upgrade node — "auto-buy when affordable." Player decides WHAT to auto-buy, system handles the clicking. |
| Gun / Laser / Butt Acid / Explosion | **Pick 1 of 4** | Transforms HOW the queen digs. Biggest build-defining choice. See Dig Methods below. |

Void Storage moved to Rainbow Food endgame. Magnet + Capacity + Speed is a clean trio — convenience, volume, mobility.

**Auto Worker + Architect Ant + Auto Evolve** are the mid-game automation trio. All buyable (not a fork), each filling a distinct role. The Architect is a single, competent ant that cycles through your transport systems placing infrastructure. You will appreciate and love your architect ant.

**Dig Methods (Pick 1 of 4):**

| Method | Fantasy | Identity | Natural Limitation |
|--------|---------|----------|--------------------|
| **Gun** | Ranged shooter | Balanced range + speed | Jack of all trades, master of none |
| **Laser** | Mouth laser | Speed king — insane dig speed, short base range | Short range without Range stat investment |
| **Butt Acid** | Turn around, spray acid | Area control — acid lingers 2-3s, keeps dissolving dirt. Medium base range. | Need to face away from target, delayed full effect |
| **Explosion** | AOE bomb | Size king — massive AOE burst. Range AND Radius both increase blast size (can stack for enormous explosions). | Point-blank, no directional control, slower recharge |

**Dig method toggle:** Basic bite is always available alongside your chosen method. Pick Explosion but need precision tunneling? Switch to basic bite. Dig methods are toggleable, not permanent replacements.

These replace the default bite animation but don't lock you out of it. Each has distinct visuals and feel. The player's choice here + their 2-of-3 stat pick creates **12 possible dig builds.**

**Stat Interaction per Method:**

| Method | Range stat does | Speed stat does | Radius stat does |
|--------|----------------|-----------------|------------------|
| **Gun** | Bullet travels further | Fire rate up | More dirt removed per hit |
| **Laser** | Beam reaches further (BIG deal for Laser) | Beam fires faster (more DPS) | Beam removes wider dirt area |
| **Butt Acid** | Spray reaches further (starts moderate, becomes long-range) | Spray cooldown faster, more acid pools | Acid splash area larger (more lingering coverage) |
| **Explosion** | Blast size bigger (same as Radius) | Faster recharge between explosions | Blast size bigger (same as Range) |

**Note on Explosion:** Range and Radius both increase blast size for Explosion. Picking both = massive explosion but slow recharge. This is intentional — Explosion is the "go big" method. The meaningful choice for Explosion players is: all-in on size (Range + Radius) vs balanced (either + Speed).

**Note on visuals:** Stat upgrades affect the visual (bigger bullet, wider beam, etc.) but the MECHANICAL effect is always "more dirt pixels removed per attack." The visual reflects the reality.

### COLONY

Worker ant upgrades. Miners get their **OWN** dig method pick, independent from the player's choice.

**Upgrade order (top to bottom in panel):**

| Upgrade | Type | Effect |
|---------|------|--------|
| Unlock Workers | Standard | Unlocks miners and haulers. See Worker Unlock Flow below. |
| Scaling Miner Strength | Standard (0/50) | Miner dig damage scales with terrain difficulty. Cross-colony persistence after tier 50. |
| Ant Move Speed | Standard (0/10) | All worker ants move faster. |
| Ant Haul Capacity | Standard (0/10) | Haulers carry more food per trip. Base 5, +1 per tier, max 15. |
| Relay Chain / Food Singularity / Ant Cannon | **Pick 1 of 3** | Mid-game hauling efficiency. Cannon = active/exciting, Singularity = passive/magical, Relay = team-coordination. See Hauling Efficiency below. |
| Miner Dig Range / Speed / Radius | **Pick 2 of 3** (each 0/10) | Same stat types as player but for miners. Independent choice. |
| Miner Gun / Laser / Butt Acid / Explosion | **Pick 1 of 4** | Same dig methods as player but for miners. Independent choice. |

**Miners get their own build identity.** "My queen has a laser but my miners have guns" is a valid build. This is an idle game — the automation deserves as much creative identity as the player.

**Worker Unlock Flow:**
1. Buy "Unlock Workers" → miners and haulers both become available
2. If any unassigned basic gatherers exist, a **slider UI** appears to assign them (Miner ↔ Hauler ratio)
3. After assignment, two buttons appear permanently: **Buy Miner** and **Buy Hauler** (each costs food)
4. All assignments are permanent — no swapping roles

**Hauler AI — Claiming System (Blackboard Pattern):**
Central **Food Manager** runs every ~0.5 seconds, coordinating all haulers:
- Assigns nearest unclaimed food to idle haulers
- **Claims** prevent two haulers targeting the same food piece
- **Proximity-based claim stealing:** If a closer hauler becomes idle and an existing claim is held by a distant hauler, the closer hauler steals the claim. The distant hauler gets reassigned.
- Food being carried or on transport gets an `in_transport` flag — invisible to hauler targeting
- This ensures efficient hauler distribution without player micromanagement

**Hauling Efficiency — Pick 1 of 3:**

| Option | How It Works | Strengths |
|--------|-------------|-----------|
| **Ant Cannon** | Physical turret placed at base. Haulers deposit food, walk to turret, get launched toward nearest food cluster. Ants STICK to whatever surface they hit (no bounce), then resume AI pathfinding. Toggle: AI-aimed (auto-targets nearest food cluster) or player-aimed (manual turret rotation). Toggleable on/off. | Active, exciting. Rewards clean tunnel design. |
| **Food Singularity** | Unclaimed exposed food slowly slides along the ground toward home, following the hauler flow field. Only affects food that isn't being carried or on transport. Passive, always-on. Toggleable on/off. Falls back to loading station radius pull if flow field is unavailable. Needs "direction home" awareness — not just nearest station, but toward the food pile. | Passive, magical. Reduces hauler trips. Synergizes with transport infrastructure. |
| **Relay Chains** | Haulers form bucket brigades. When a hauler carrying food encounters another hauler with available capacity closer to home, they transfer food instantly on contact. **Partial transfers** — if Steve has 7/15 capacity, Greg gives him 8 food (filling Steve to 15), Greg keeps the remaining 2. **Capacity-based claiming** prevents conflicts — nearby haulers "claim" available inventory slots so two carriers can't try to fill the same space. After handing off, the now-lighter hauler walks back toward the frontier for more food. Food hops ant-to-ant through the colony. Toggleable on/off. | More haulers = shorter relay segments = dramatically faster food flow. Solves the late-game distance problem elegantly. Visually adorable (bucket brigade). Makes having lots of haulers feel rewarding — they're all busy, never idle. |

**Relay Chains — How the AI works:**
Each hauler carrying food scans nearby for haulers with available capacity that are closer to home. Transfer is **instant on contact** — no pause, no animation. Just a number transfer and visual size change. After transferring, the lighter hauler walks back toward the food frontier. The receiving hauler continues toward home (or passes food along to the next relay).

**Self-organizing distribution:** Without explicit zone assignment, haulers naturally settle into "segments" of the route. Haulers near food pick up and pass quickly. Middle haulers shuttle food through relay hops. Haulers near home receive and deposit. The MORE haulers on a route, the SHORTER each segment, and the FASTER food flows. This is the key scaling property — Relay Chains get measurably faster with every additional hauler.

**Interaction with Hauler AI Claiming:** When food is transferred between haulers, the Food Manager's claim transfers to the receiving hauler. Food remains continuously "claimed" — just by a different ant. Clean handoff, no double-targeting.

### LOGISTICS

Transport infrastructure, colony logistics, and player traversal. All transport infrastructure is **free to place** once unlocked. The upgrade cost IS the gate.

**Conveyor belts work on ANY solid surface** — floor, walls, ceiling. Anywhere there's continuous solid terrain, you can run a conveyor.

**Upgrade order (top to bottom in panel):**

| Upgrade | Type | Effect |
|---------|------|--------|
| Place Dirt | Standard | Place dirt blocks to build ramps/bridges/walls. **First unlock in Logistics.** |
| Transport Capacity | Standard (0/10) | More cars/units per transport route. Each tier adds capacity to your chosen transport system. |
| Lift / Minecart / Platform / Zip Line | **Pick 1 of 4** | Transport Tier 1: how ants + food move through your colony. See below. |
| Pheromone Highways | Standard | All ants + player leave pheromone trails. Well-traveled routes give speed boost. See below. |
| Auto Conveyor | Standard (Toggleable) | Auto-extends a slow conveyor belt from your food pile toward the furthest active mine. One direction, auto-placed. First taste of "things happen without me building them." |
| Aerial Tramway / Conveyor Belt | **Pick 1 of 2** | Transport Tier 2: food-only transport optimization. See below. |
| More Legs / Grapple Hook / Jetpack / Jump+Dash | **Pick 1 of 4** | Player Traversal: queen's personal movement ability. See below. |
| Teleporters / Pneumatic Tubes | **Pick 1 of 2** | Endgame Transport: strategic shortcuts. See below. |

**Pheromone Highways (Standard Upgrade — Core System):**

Unlocks pheromone trails for **all ants AND the player.** Every ant that walks a tile deposits pheromone. Pheromone decays over time. Ants on high-pheromone tiles get a speed boost. This is a core colony-wide upgrade, not a fork — too fundamental and interesting to limit to one build.

**How it works:**
- Every tile an ant walks on gains pheromone (small increment per step)
- Pheromone decays over time (~10% every few seconds — exact rate needs tuning)
- Speed boost on pheromone tiles: up to ~20-30% faster on heavily-used routes (needs tuning — 50% might be too strong as a core upgrade)
- Applies to miners, haulers, AND player queen

**AI behavior:** Individual ants don't plan group routes. Each ant's pathfinder treats pheromone tiles as "cheaper" to traverse, so they naturally prefer well-traveled paths when roughly equivalent to other options. Swarm intelligence emerges from selfish individual choices — exactly how real ants work.

**Emergent behavior over time:**
- Early: faint scattered trails everywhere. Minimal benefit.
- As colony grows: some routes naturally get used more (shorter, more direct). These trails brighten.
- Late game: clear, bright highways visible through the colony. You can SEE your colony's circulatory system.
- When you dig a new shortcut: traffic naturally shifts as pheromone builds on the new route and decays on the old one.

**Visual:** Faint pink-purple glow on tunnel floors. Stronger pheromone = brighter/wider glow. Major highways clearly visible at a glance. Dead/unused tunnels are dark — instant visual feedback on colony efficiency. At zoom-out, highways look like glowing veins through the colony.

**Note:** Pheromone values and speed formulas need playtesting. The core mechanic is solid but the numbers (deposit rate, decay rate, max speed boost) must be tuned to feel right without being overpowered.

**Transport Tier 1 — Pick 1 of 4:**

| Option | Directions | Speed | Best For |
|--------|-----------|-------|----------|
| **Lift** | Vertical (up/down) | Fast | Deep vertical mining colonies |
| **Minecart** | Horizontal (left/right) | Fast | Wide horizontal tunnel networks |
| **Platform** | 4-directional (NSEW) | Slowish | Flexible general-purpose |
| **Zip Line** | Diagonal | Fast down, slow up | Diagonal shortcuts, uses gravity |

Pick 1 creates real sacrifice. "I have elevators, so I dig horizontally myself or build dirt ramps."

**Transport Tier 2 — Pick 1 of 2 (food only):**

| Option | Routing | Speed | Limitation |
|--------|---------|-------|------------|
| **Aerial Tramway** | Crosses open air between pylons | Medium-slow | Needs line-of-sight between pylons, wires can't go through walls. Pylons must connect back to base network (no isolated pylons). Auto-wire: if two pylons have line-of-sight, wire is drawn automatically. |
| **Conveyor Belt** | Follows any solid surface (floor, wall, ceiling) | Fast | Needs unbroken surface, can't cross gaps |

Tramway rewards big open chambers. Conveyor rewards clean connected tunnel networks.

**Worker interaction with transport:** Workers dump food at **loading stations** (marked points on tracks/belts/pylons). The transport system picks it up and delivers to the pile. Workers only need to pathfind to the nearest loading station, not all the way back to the pile.

**Player Traversal — Pick 1 of 4:**

| Option | Fantasy | Speed | Natural Limitation |
|--------|---------|-------|--------------------|
| **More Legs (Mega Speed)** | The Flash | Very fast | Needs surfaces — can't cross gaps you've dug |
| **Grapple Hook** | Spider-Man | Fast (burst) | Can't hover — needs target wall within range, attaches to surfaces |
| **Jetpack** | Helicopter | Medium | Can hover — slower than everything else but works anywhere |
| **Mega Jump + Mega Dash** | Mario | Moderate | In-air dash. Limited height, limited dash distance |

No artificial fuel/cooldown mechanics. Each is limited by the terrain naturally.

**Endgame Transport — Pick 1 of 2:**

| Option | Range | Count | Who Uses It |
|--------|-------|-------|-------------|
| **Teleporters** | Unlimited | **1 pair** | Player + food + haulers |
| **Pneumatic Tubes** | Unlimited | Unlimited | Food only |

**Teleporters:** Place entrance + exit pads in your tunnels. **1 pair only.** Player walks on entrance → appears at exit. Food placed on entrance → appears at exit. **Hauler ants CAN use them** — walk on entrance, appear at exit with their cargo. Pads can be repositioned. Instant, no delay. Strategic choice of WHERE to place the single pair is the entire game.

**Pneumatic Tubes:** Place entrance + aim exit **any angle** (360 degrees, straight line) through **solid terrain**. No range limit — as long as the path is through solid ground. Haulers dump food at entrance, it shoots out the exit. If someone digs through the tube's path, **the tube breaks** — creates tension between mining expansion and tube network preservation. **Unlimited tube count.** Faint dotted line visual indicator showing tube path through terrain. Food only.

**Neither replaces Tier 1 or Tier 2 transport.** Worker ants can't use tubes for their own movement (teleporters are the exception). These are primarily food shortcuts. Ant Relay Chain was considered but tabled — balance was tricky, though the visual of ants marching in a chain was cool.

### COSMETICS

Not gameplay upgrades — purely visual. Could be a dedicated tab or page separate from the skill tree.

| Upgrade | Effect |
|---------|--------|
| Dirt Customization | Change the look of all dirt (overrides distance gradients). Cosmetic personalization. |
| Ant Customization | Change ant colors/patterns. Two modes: apply to ALL ants, or click individual ant to customize in their own menu |

Some cosmetics also purchasable with Rainbow Food (see Rainbow Food section).

### BAKED IN (not upgrades — always available from start)

| Feature | How It Works |
|---------|-------------|
| Bite Size Toggle | Automatic — hold longer for bigger bite (Stardew Valley watering can style). Unlocked sizes available as soon as dig radius upgrades allow them. |
| Name Queen | Always available — give your queen a custom name tag from the start |
| Name Any Ant | Always available — click any ant to rename it |

### RAINBOW FOOD — Endgame Cheat Menu

Found extremely rarely at distances 16000+. Rainbow food **always exists** at 16000+ — rare spawns, mysterious shimmer. Players encounter them before understanding what they are. Need 10-30 rainbow food per unlock depending on power level. This is a wall of absurd power fantasy rewards — like unlocking a cheat menu for playing the game for hundreds of hours. Queen must physically collect rainbow food herself.

**How to access:** A **rainbow button** appears on the Evolve menu after buying "Over the Rainbow." Clicking it switches from the 3-tab evolve view to a dedicated rainbow menu. Click back to return to the normal evolve view.

**Layout:** Centered panel with "OVER THE RAINBOW" banner (rainbow-cycling text in the count display). Three category sections arranged vertically with scrollable content. Each upgrade is a rectangular tile in a horizontal row per category. Tiles show rainbow-hued text with black outline, and cost below. Click tiles to toggle on/off. Hover for tooltip descriptions. No tree structure, no progression order — buy whatever you want in any order.

**All rainbow food unlocks are TOGGLEABLE.** Turn them on/off at will from the cheat menu. Sometimes you want Giant Queen off to see your colony normally. Sometimes you turn off Hive Mind to go back to miner/hauler specialization. The cheat menu is a menu, not permanent changes.

**"Over the Rainbow" — Endgame Gate:**
Very expensive standard purchase at the **bottom of the Player tab** in the Evolve menu (regular food cost, displayed in rainbow-cycling text). This is the endgame milestone — buying it **unlocks the rainbow food menu button.** Before this purchase, rainbow food currency accumulates silently but the button isn't visible and the menu isn't accessible. This is the "you beat the game" moment.

**Rainbow Food Persistence Between Colonies:**
- **Rainbow food currency:** Persists between colonies (never lost)
- **Cosmetic purchases** (Big Head Mode, trails, hats, Boogie Bomb): Available **immediately** in every colony, no gate. Once bought, always active.
- **Gameplay purchases** (Hive Mind, Void Storage, etc.): Persist (don't need to re-buy), but only **activate** after buying "Over the Rainbow" in each new colony. This means each colony has a progression arc before the cheat menu kicks in.

**LOGISTICS** (3 tiles)

| Unlock | Cost | Effect |
|--------|------|--------|
| Hive Mind | 30 | All ants can mine AND haul (closest task priority). No specialization needed. |
| Speed of Light | 25 | All transport infrastructure runs 2-5x faster. |
| Global Conveyor | 20 | Auto-generated optimal transport route through your entire tunnel network. Food dropped anywhere on the highway gets swept home. |

**POWER FANTASY** (5 tiles)

| Unlock | Cost | Effect |
|--------|------|--------|
| Quantum | 30 | Indestructible rocks act as empty space for the queen. Seamlessly pass through them like air. |
| Auto Attack | 25 | Auto-dig toggle — queen passively digs wherever she's facing. |
| Auto-Pilot | 20 | Auto-move toggle — queen automatically moves forward. Combined with Auto Attack = idle drill. |
| Giant Queen | 25 | Queen becomes 5x bigger. Digs proportionally bigger. Visual power flex. |
| Void Storage | 20 | Queen's food instantly stored on pickup, no carrying. No more hauling for the player. |

**COSMETIC** (6 tiles)

| Unlock | Cost | Effect |
|--------|------|--------|
| Big Head | 10 | All ants have comically oversized heads. |
| Big Ant | 10 | All ants grow ~2x larger. Combine with Big Head for maximum absurdity. |
| Rainbow Trail | 15 | Queen leaves a rainbow trail as she moves. **Mutually exclusive with Fire Trail — pick one.** |
| Fire Trail | 15 | Queen leaves a fire trail as she moves. **Mutually exclusive with Rainbow Trail — pick one.** |
| Boogie Bomb | 10 | Toggle button — all ants stop and dance when active, resume work when toggled off. On/off at will, not timed. |
| Ant Colors | 10 | Unlock ant color customization palette. Rainbow food cosmetic unlock. |

### Build Combinations Summary

The total possible builds from all forks:

| Fork | Options | Possibilities |
|------|---------|---------------|
| Player Dig Stats | Pick 2 of 3 | 3 combos |
| Player Dig Method | Pick 1 of 4 | 4 choices |
| Transport Tier 1 | Pick 1 of 4 | 4 choices |
| Transport Tier 2 | Pick 1 of 2 | 2 choices |
| Player Traversal | Pick 1 of 4 | 4 choices |
| Hauling Efficiency | Pick 1 of 3 | 3 choices |
| Endgame Transport | Pick 1 of 2 | 2 choices |
| Miner Dig Stats | Pick 2 of 3 | 3 combos |
| Miner Dig Method | Pick 1 of 4 | 4 choices |

**Total unique builds: 3 x 4 x 4 x 2 x 4 x 3 x 2 x 3 x 4 = 27,648 combinations.** Each colony is genuinely different.

### Upgrade Cost Scaling
Idle game standard: each upgrade tier costs ~3-5x the previous. Creates natural plateaus where the player needs to push further out to afford the next upgrade. 0/10 upgrades have gentler curves. 0/50 upgrades (dig strength) have very gradual curves that become steep near endgame. Exact values need balance tuning through playtesting.

---

## Worker Ants

### Basics
- Hatched by spending food (requires "Unlock Workers" upgrade)
- Much smaller than the Queen (~0.5x her size)
- Same basic ant shape but simpler (less detail at distance)
- **Autonomous** — they do their jobs without player input

### No Worker Deletion — Engineering Solves Performance

**You cannot delete, release, or remove workers. Ever.** Every ant you hatch is permanent. This eliminates all exploitation concerns (no buy/sell cycling, no cost curve gaming, no ratio rebalancing tricks). Decisions are permanent — that's the game.

**Overinvested in miners?** Buy more haulers. The cost curve keeps climbing, but that's the consequence. This is what makes prestige meaningful — "next colony, I'll get the ratio right."

**Performance is handled by the game, not the player:**

- **Auto-hibernate system:** When FPS dips below a threshold, far-from-camera workers enter hibernate mode — simplified AI (just timers, no pathfinding), skip rendering. They still "exist" and do their jobs (food accumulates, dirt gets dug), just cheaply. Workers wake back up when performance recovers (player zooms out, workers spread out, etc.).
- **The player never has to manage this.** No delete button, no cap setting, no "release for refund" menu. The game gracefully handles it.
- **Target: 1000+ ants before hibernate kicks in.** If the game can't sustain 1000 active ants, that's an engineering problem to solve in Phase 1, not a design problem to patch with a delete button.

**Performance Warning System:**
- FPS drops below 45 → subtle yellow indicator near worker count ("Colony straining")
- FPS drops below 30 → red warning
- Informational only — no hard block, player can still buy workers
- **Toggleable in options menu.** Some players don't want the warning. Respect that.

**If P1 engineering fails:** This is the Phase 1 prototype's job. If we can't hit 1000 ants at 60fps with terrain + pathfinding, we know within a week and can pivot (optimize harder, switch engines, or revisit the delete-button approach). We don't build 18 steps of game on a foundation that can't support it.

### Worker Unlock Flow

1. Buy **"Unlock Workers"** upgrade — this single upgrade unlocks both miners and haulers
2. If any unassigned basic gatherers exist, a **slider UI** appears: split them between Miners and Haulers
3. After assignment, two permanent buttons appear: **Buy Miner** (costs food) and **Buy Hauler** (costs food)
4. All role assignments are permanent — no swapping

### Worker Roles — Permanent Commitment

**When you buy an ant, you choose: Miner or Hauler. That choice is permanent. No swapping.**

This is a one-time purchase decision, not ongoing micromanagement. Overinvested in miners? Buy more haulers. The bottleneck naturally shifts, and you address it by buying more of what you need. You never open a "reassign workers" menu. Buy it and move on.

**Two specialized roles:**

**Miners** — dig DIRT toward food sources (and expand the frontier)
```
IDLE → FIND_NEAREST_DIRT_NEAR_FOOD → TRAVEL → DIG_DIRT → [food exposed?] → FIND_NEXT_TARGET → repeat
```
- Target: dirt blocks adjacent to food (or just... any dirt, if no food targets nearby)
- **Max 5 miners per dirt block** (stacking cap, balanceable)
- Multiple miners on same block = faster digging (combined bite power)
- **Spread logic:** Miners prefer blocks with fewer miners already on them. If a block has 5, they pick a different nearby block. Natural dispersal across the dig face.
- **Miners expand the frontier.** They are NOT limited to areas the player has already opened. They dig NEW tunnels into unexplored dirt on their own. This means:
  - Miners naturally push the explored boundary outward
  - Late game, miners ARE your expansion — you manage, not dig
  - No manual checkpoint gates — the colony grows organically
  - This triggers camera zoom-out as the explored area grows
- **Stacking visual:** In tunnels (narrow 2D space), miners stack vertically — one on top of the other, like a little ant pile pressed against the dig face. Each ant visually distinct with slight offset. At 5 miners it's a visible pile.
- Once food is exposed, miners move on to the next dirt block near the next food source
- **Miners never touch food** — that's the hauler's job
- **Miners always have work** — the world is infinite dirt. Even if all food in the current area is exposed, miners keep pushing outward. Effectively impossible to run out of targets.

**Haulers** — pick up exposed food, carry to pile (or loading station)
```
IDLE → FIND_NEAREST_EXPOSED_FOOD → TRAVEL_TO_FOOD → PICK_UP → TRAVEL_TO_PILE_OR_STATION → DEPOSIT → repeat
```
- Target: exposed food sitting in tunnels
- **Base carry capacity: 5 food.** Haul Capacity upgrade (0/10) adds +1 per tier → max **15 food.**
- **Haulers are SLOW** — significantly slower than miners, especially when carrying food
- **Graduated speed penalty** based on load: `speed_multiplier = 1.0 - (food_carried / max_capacity) * 0.6`. At max load = 40% speed. Half load = 70%. Carrying 1 food = ~96%. Empty = full speed.
- This means distance is the natural ratio balancer:
  - **Early game** (food near base): Short trips, fast turnaround. ~3:1 miners:haulers works.
  - **Mid game** (food 500+ away): Longer trips, haulers in transit most of the time. Ratio shifts to ~2:1 or 1:1.
  - **Late game** (food 2000+ away): Massive round trips. You need tons of haulers. Ratio flips to 1:2 or more haulers than miners.
- The miner/hauler split is a **real decision** that shifts over time — and transport infrastructure is the answer to the late-game hauler bottleneck
- This makes transport upgrades (minecarts, belts, tubes) feel like massive relief — the Dome Keeper earned automation payoff
- If transport infrastructure exists, haulers go to nearest **loading station** instead of the pile
- When no food available, haulers idle at their current location (little idle wiggle animation, cute)
- Haulers can genuinely run out of work if miners haven't exposed new food yet — this is the pipeline working correctly

### Ant Movement in Tunnels (2D Side View)
- Ants going the **same direction** → **ant marching formation** (single file line). They're ants. This is what ants do. Looks adorable.
- Ants going **opposite directions** → pass through each other (overlapping). In narrow tunnels, one column going left, one going right.
- No "lanes" — this is a 2D cross-section, there is no width/depth dimension.

### Visual Distinction by Role
- **Regular workers:** basic small ant
- **Miners:** slightly bigger mandibles (visible even at small scale)
- **Haulers:** slightly larger abdomen (carries more)
- Workers at distance (zoomed out): just colored dots

### Worker Pathfinding (Performance Critical)
- **NOT A* for every worker every frame** — way too expensive
- Smart default: go to closest untargeted food/dirt. If current target already has max workers, pick next closest.
- Fallback: simple **flow field** pathfinding — precalculated per chunk, updated when terrain changes
- Workers that can't find a path → idle near last known location
- **Staggered updates** — not all workers recalculate paths on the same frame
- **Off-screen workers** — simplified simulation (just increment timers, don't animate)

---

## Automation Progression

This is the idle game heart. The player goes from doing everything manually to being an overseer.

### Stage 1: Manual (0-15 min)
- You dig alone
- You carry food alone
- You are the entire colony

### Stage 2: Helpers (15-30 min)
- First workers hatched (basic gatherers — pick up exposed food)
- They gather food from tunnels you've already dug
- You focus on digging new tunnels, they haul

### Stage 3: Castes (30-60 min)
- Unlock miner and hauler specializations
- Each new egg: choose Miner or Hauler (permanent)
- Miners help you dig AND push the frontier on their own
- Haulers carry exposed food back efficiently
- You start thinking about how many of each to hatch, and tunnel layout

### Stage 4: Transport Tier 1 (1-2 hours)
- Place transport infrastructure in your main tunnels (free after unlock)
- Lift / Minecart / Platform / Zip Line (pick 1 of 4) automatically ferry food
- Workers dump food at loading stations instead of walking all the way back
- **VISUAL PAYOFF** — watching little trains zip through your tunnels

### Stage 5: Conveyor Belts + Tramways (2-4 hours)
- Passive transport — food just flows along belts
- Tramways cross open caverns on cables
- Workers dump food on belts/tramways, transport carries it to pile
- Player designs transport networks

### Stage 6: Mid-Game Automation (3-5 hours)
- Architect Ant auto-places transport infrastructure
- Auto Evolve and Auto Worker handle tedious purchases
- Hauling Efficiency fork: Ant Cannon / Food Singularity / Relay Chains (pick 1 of 3)

### Stage 7: Endgame Transport (5-8 hours)
- Teleporters OR Pneumatic Tubes (pick 1 of 2) for food shortcuts
- Workers still use Tier 1 infrastructure — these are food shortcuts, not ant shortcuts

### Stage 8: Over the Rainbow + Cheat Menu (8+ hours)
- Buy "Over the Rainbow" — expensive endgame gate purchase
- Reach extreme distances, find rainbow food
- Unlock absurd power fantasy upgrades (Void Storage, Hive Mind, etc.)
- **The colony runs itself — true idle gameplay**
- Player's role is strategic: where to expand, what cheats to unlock next

---

## Named Ants System

### Customize Screen (Click Any Ant)
- **No upgrade needed.** The moment you hatch your first ant, you can customize it.
- **Single left-click on any ant** opens the Customize screen.
- Same screen for workers and queen, with one difference (see below).

**Customize screen layout (top to bottom):**
1. **Banner:** "CUSTOMIZE"
2. **Name input:** LineEdit with rainbow-cycling "GREG" placeholder. Type a name or clear to remove. Greg is canonically the first named ant. Always.
3. **Ant preview:** Dark inset panel showing the ant being customized (3 ovals + legs + antennae). Queen version shows 1.3x scale with gold crown.
4. **"ANT COLOR" label + color palette:** 3×8 grid of colored swatches (pastels, mediums, darks). Clicking a swatch recolors the ant preview in real-time. **LOCKED by default** — requires the endgame Rainbow Food "Ant Customization" upgrade to unlock. Rainbow Greg is the endgame dream.
5. **"GIVE HAT?" button (worker ants only):** Gives the queen's currently equipped hat to this ant. Replaces the old double-click interaction.
6. **"HAT COLLECTION" grid (queen only):** 5-column grid of collected hats, styled like the color palette but with hat-themed colors. Click to equip. Only visible when customizing the queen.
7. **SAVE / CANCEL buttons**

- Remove a name by clearing the text field and saving (blank = no name)
- Name as many ants as you want. Remove names whenever you want.
- Named ants get a **subtle glow** + name tag above their head
- Named ants wearing hats have the hat visually on their head
- **No stat buffs.** Pure attachment and cosmetics.

**Test UI reference:** `scenes/prototypes/ant_colony/ui/ant_naming/ant_naming_test.tscn` has toggle buttons showing all screen states:
- **QUEEN / WORKER toggle** — switches between worker view (color palette + GIVE HAT?) and queen view (color palette + hat collection grid)
- **UNLOCK / LOCK toggle** — switches between locked palette (grayed-out swatches + "LOCKED" label) and unlocked palette (interactive swatches)

### Achievement Ants (Special Reward Units)
Achievements unlock **unique special ants** that spawn into your colony. These are BONUS ants (don't replace existing ones). Each has a pre-set name and unique visual.

| Achievement | Reward Ant | Visual |
|------------|-----------|--------|
| Hatch your first worker | **Greg** (the OG) | Subtle glow, the first of many |
| Reach yellow food zone (dist 200) | **Digsby** | Yellow tint |
| Have 10 workers | **Sarge** | Slightly bigger |
| Reach blue food zone (dist 1000) | **Frostbite** | Blue shimmer |
| Total 1,000 food collected | **Atlas** | Green glow |
| Build first transport system | **Conductor** | Tiny hat |
| Reach obsidian zone (dist 8000) | **Shadow** | Dark with white outline |
| Find rainbow food (dist 16000) | **Prisma** | Rainbow shimmer |

These are one-time rewards. Can't be repeated. Each achievement ant is unique. They work like regular ants but are always visually distinct. Their names can't be changed (they're special).

---

## Hats (Collectible Cosmetics)

### Discovery
- **Random chance to spawn in newly generated terrain layers** — not pre-placed at fixed milestones
- **Max 1 hat per layer** — ensures spread across the world, no clustering
- **Never spawns in already-discovered layers** — only appears in new terrain as the world expands
- Hats are buried in the dirt — look like a tiny colored pixel/shape until dug out
- When dug out: satisfying reveal animation, popup notification
- **Queen must physically collect it** — player reward for exploring, like a golden cookie
- **5-10+ hats minimum**, some also purchasable with rainbow food
- Unlocked hats go into a **hat collection** on the cosmetics page

### Equipping
- Queen ant can wear one hat at a time (select from HAT COLLECTION grid in queen's Customize screen)
- Hat appears on the ant's head, visible at close zoom
- **Can give your hat to a named ant** via the "GIVE HAT?" button in that ant's Customize screen
- Purely cosmetic — no stat effects
- Hat management lives in the Customize screen (click any ant or the queen)

### Example Hats
| Hat | How to Find | Visual |
|-----|-------------|--------|
| Hard Hat | Near surface, early game | Yellow construction helmet |
| Top Hat | Mid-distance | Tiny black top hat |
| Crown | Shinier version of queen's default | Gold crown |
| Propeller Cap | Deep in terrain | Beanie with spinning propeller |
| Wizard Hat | Very deep | Purple pointed hat |
| Party Hat | Random rare find | Colorful cone |
| Viking Helm | Deep, near crystal zone | Horned helmet |
| Flower Crown | Near surface, rare | Ring of tiny flowers |
| Astronaut Helmet | Extremely deep | Bubble helmet |
| Pirate Hat | Achievement-based | Tricorn hat |

---

## Prestige System — Build Diversity Model

### Core Philosophy
- **Never feel forced to prestige.** Infinite scaling means you can stay in one colony forever.
- **Same endgame ceiling** reachable in any build — prestige doesn't make you more powerful, just faster.
- **Old colonies are fully playable save slots.** You can return to ANY previous colony and keep playing it.
- **No legacy stat bonuses.** No faster dig, no starting upgrades, no carried stats. Clean slate every time.
- **Prestige = try a different build.** The reason to start a new colony is to explore different upgrade combinations.

### The Build Diversity System
The upgrade tree contains **mutually exclusive forks** — pick 1 of 4, pick 2 of 3, or pick 1 of 2 depending on the fork. You physically cannot have all upgrades in one colony. Each colony is a unique "build" with **27,648 possible combinations.**

This means:
- Each colony has a distinct identity (laser queen with gun miners, elevator + tramway + grapple hook, etc.)
- Experienced players want to try different combinations
- No single "optimal" build — all branches balanced, just different playstyles
- Achievements tied to specific builds encourage completionism

See **Upgrade System → Build Combinations Summary** for the full breakdown.

### Meta-Reward: +1 Starting Worker Per Colony Founded
Each time you found a new colony, you start with +1 basic worker ant (unassigned gatherer).

- **Colony 1:** 0 bonus workers (baseline)
- **Colony 5:** 4 bonus workers
- **Colony 10:** 9 bonus workers
- **Colony 50:** 49 bonus workers

**How it works:**
1. Start a new colony → bonus workers appear as basic gatherers in the starting chamber
2. They pick up exposed food (basic gatherer behavior) immediately
3. When you unlock workers (Unlock Workers upgrade), the **ALLOCATE overlay** appears once — centered modal on top of the Evolve screen
4. Slider max = number of unassigned workers (e.g. Colony 3 = 2 bonus workers, slider range 0-2). Slider splits between Miners and Haulers. Labels update live as you drag.
5. Press **OK** to confirm — no cancel, assignment is permanent (same rule as all worker commitment). Overlay appears only once per run, at the moment the upgrade is purchased.
6. If the player has 0 unassigned workers (Colony 1), the overlay does not appear at all

**Why starting workers:**
- Thematic — it's an ant game, the reward is more ants
- Natural diminishing returns — queen's dig speed is the bottleneck early, not hauler count
- Integer values, no decimal weirdness
- Doesn't interact with the build system (percentage-based upgrades scale the same regardless of worker count)

**Balance safeguard:** Worker-count upgrades only compete with OTHER worker-count upgrades in Build Choice nodes, and are placed late in the tree. By the time you reach them, the starting worker bonus is a drop in the bucket.

### Cosmetic Prestige Rewards
- **Ant Themes:** Visual skins on all ants (golden ants, ghost ants, robot ants, leaf-cutter style)
- **Build Completion Achievements:** "Complete the game as a pure-miner build" → unlocks unique cosmetic
- All cosmetics carry across colonies (permanent collection)

### What Does NOT Carry Over
- No upgrade progress (except dig power scaling — see below)
- No food (regular)
- No worker count (except the +1 per colony bonus)
- No map knowledge
- No transport infrastructure
- No transport speed scaling, no worker efficiency scaling — those don't exist
- Literally nothing except: dig power progress + rainbow food + cosmetics + colony count

### What DOES Carry Over
- **Dig power scaling progress** (player dig strength + miner dig strength) — tiers 51+ persist across colonies. Must re-grind tiers 1-50 each colony, then saved progress activates. See Upgrade System → Dig Power Scaling.
- **Rainbow food currency** — persists between colonies, never lost
- **Rainbow cosmetic purchases** — Big Head Mode, trails, hats, Boogie Bomb. Available immediately in every colony, no gate.
- **Rainbow gameplay purchases** — Hive Mind, Void Storage, etc. Persist (don't need to re-buy), but only **activate** after buying "Over the Rainbow" in each new colony.
- **Cosmetics** — ant customizations, colony themes, hats
- **Colony count** — determines starting worker bonus (+1 per colony founded)

---

## Design Decisions Log

Decisions made during brainstorming, preserved for reference:

| Decision | Reasoning |
|----------|-----------|
| No storage cap | Boring, punishing. Let the number grow. |
| No offline progression | Game only runs when open. Simpler, more honest. |
| No random tunnel events | Golden cookie mechanic = forced screen watching = psycho behavior. None of the events make you engage with gameplay or are balanced early vs late. CUT. |
| No enemies/hazards/combat | Pure mining/idle. No damage, no death, no soldier ants. Maybe future expansion. |
| ~~No pheromone trail system~~ | ~~SUPERSEDED~~ — Pheromone Highways is now a core upgrade in LOGISTICS. See "Pheromone Highways = core upgrade" decision below. |
| Transport is free to place | Once you unlock minecarts, place unlimited track for free. The upgrade IS the cost. |
| Dig has cooldown (not click speed) | Prevents auto-clicker cheese. Upgrades reduce cooldown. |
| Distance gradient, not hard layers | Smooth color/difficulty transitions. No shape problem (circles vs rectangles). Milestone discoveries at certain distances. |
| Rainbow food = separate currency | Not "better food." Own upgrade tab. Endgame only. |
| Naming ants is free from start | No upgrade gate on naming/customization. Click any ant → Customize screen. Color palette locked behind rainbow food upgrade. |
| Foreman/Hive Mind CUT | Redundant with speed + AI upgrades. Speed makes them faster. Manager makes them smarter. Don't need "buff aura" middlemen. |
| Miner stacking cap (5 per block) | Visual/balance solution. Multiple miners on same dirt = faster but capped. Excess miners target next block. |
| Worker march formation | Same-direction ants = single file. Opposite direction = pass through each other. Adorable and functional. |
| Permanent worker commitment | Buy a miner, it's a miner forever. Buy a hauler, it's a hauler forever. No reassignment menu, no swapping. Rebalance by buying MORE of what you need. Every decision is a one-time purchase, not ongoing maintenance. |
| Miner spread logic | Miners prefer dirt blocks with fewer miners on them. Automatic dispersal, no player micromanagement. |
| Miners expand the frontier | Miners dig NEW tunnels on their own, not just assist at the player's dig face. They push the explored boundary, trigger zoom-out, and drive late-game expansion. No manual checkpoint gates. |
| No player-assigned dig zones | Workers are fully automatic. Maybe a priority zone system later, but default is smart AI. |
| Miner stacking visual | Vertical pile in tunnels — one on top of the other. No "fan around" (it's 2D, only left/right/up/down in a tunnel). Each ant visually offset so you can count them. |
| Food always visible | Food is always visible through dirt. No detection radius, no hidden food, no reveal system. Gameplay focuses on routing decisions (which food to go for) rather than blind exploration. Removes Food Sense upgrades, Omniscience, and entire SENSE category. |
| Indestructible rocks | Varying sizes scattered in terrain. Can't dig through — must dig around. Pure logistics obstacles, no damage/death/hazards. Adds interesting tunnel routing decisions. |
| Build diversity prestige | Mutually exclusive upgrade forks (pick 1 of 2). Can't have all upgrades in one colony. Each colony is a unique "build." Reason to start new colonies = try different combinations. |
| Old colonies fully playable | Starting a new colony doesn't delete old ones. Old colonies are full save slots you can return to and keep playing at any time. Not museums — fully interactive. |
| No legacy stat bonuses | No faster dig, no starting upgrades, no carried movement buffs between colonies. Clean slate every time. Only meta-reward is +1 starting worker per colony + cosmetics. |
| +1 starting worker per colony | Prestige meta-reward: each colony founded gives +1 basic gatherer at start of next colony. Natural diminishing returns (queen dig speed is the bottleneck). Assigned via slider when castes unlock. |
| Scout Ants CUT | Considered as colony tab upgrade and endgame feature. Cut entirely — miners expand frontier, food is always visible. Scout ants are redundant. |
| Colony twist hazards CUT | No underwater, volcanic, crystal colony variants with unique hazards. No death, no damage, no bullshit. Indestructible rocks provide logistics interest without any threat mechanics. |
| Game speed as meta-reward CUT | 3x+ simulation speed would cause performance issues (3x pathfinding, 3x physics). Also less thematic than starting workers. |
| Two upgrade tiers | Build Choice forks (pick 1 of 2, gameplay-defining, percentage-based) + Standard upgrades (available to all, includes infinite scalers). Build choices create identity; standard upgrades create progression. |
| Percentage-based Build Choices | All Build Choice upgrades are percentage-based (not flat additive). Prevents starting worker count from warping which branch is "best." Worker-count choices only compete with other worker-count choices, placed late in tree. |
| ~~Endgame = infinite scaling on 3 bottlenecks~~ | ~~SUPERSEDED~~ — Only dig power scaling persists between colonies now. Transport Speed ∞ and Worker Efficiency ∞ were CUT. See "Transport Speed ∞ CUT" and "Worker Efficiency ∞ CUT" decisions. |
| Unassigned workers can be assigned | Workers hatched before caste unlock are basic gatherers. When castes unlock, slider UI lets you assign them to Miner or Hauler. Still permanent once assigned. |
| Build completion achievements | Achievements tied to completing the game with specific builds. Encourages trying all combinations. Each achievement unlocks a cosmetic reward. |
| Ant skins = cosmetic prestige | Ant themes (visual skins on all ants). Unlocked via achievements, per colony. |
| Camera: free pan + zoom | Player can freely zoom in/out and pan across discovered areas. Not locked to queen. See your full colony from above. |
| No worker cap | No hard limit on worker count. Performance is the natural cap. Add a limit later if performance demands it. |
| No tutorial | Controls should be self-explanatory. No guided tutorial, no popup tips. Learn by doing. |
| Tunnel background: very dark brown | Very dark brown `~Color(0.12, 0.08, 0.05)`, NOT pure black. Reads as deep earth shadow, not void. |
| Dev menu required | Can't playtest a multi-hour idle game without shortcuts. Need give-food, hatch-workers, unlock-upgrades, teleport, speed-multiplier, etc. F12 or backtick, stripped from release. |
| Balance through playtesting | Upgrade costs, hatching curves, and all numbers determined through actual play, not spreadsheet theory. Dev menu enables rapid iteration. |
| Time Warp CUT | Just balance better. If the game needs a speed toggle, the pacing is wrong. |
| ~~Pick 1 of 2 (not 2 of 3)~~ | ~~SUPERSEDED~~ — Fork sizes now vary by context. See "Fork sizes vary" decision below. |
| Build forks within same category | Each fork compares apples to apples (e.g., two mining approaches, not one mining + one transport). Prevents "obvious best" cross-category combos, makes balancing easier. |
| Three tabs: Player, Logistics, Colony | Tabbed centered panel. Tab order: Player, Logistics, Colony. No tier locking — can skip rows and save up. Nothing is a requirement. |
| Miner + Hauler = single unlock | One "Unlock Workers" upgrade opens both roles. Slider UI for existing unassigned workers, then Buy Miner / Buy Hauler buttons. No separate caste unlocks. |
| Haulers are very slow | Haulers move significantly slower than miners, especially when loaded (~50% speed when carrying). Creates a real miner/hauler ratio decision and makes transport upgrades feel like massive relief. |
| Manager AI CUT | Redundant. Full automation is achieved through transport infrastructure, not an AI toggle. |
| Smarter AI CUT | Workers should be smart by default. Paying to fix dumb AI feels like a tax, not an upgrade. Value-weighted targeting is baked into worker behavior. |
| Food Bank CUT | Boring. Passive interest doesn't create interesting decisions. |
| Bite Size Toggle = baked in | Not an upgrade. Automatic like Stardew Valley watering can — hold longer for bigger bite. Unlocked sizes available as soon as Wide Bite upgrades allow them. |
| Queen naming = baked in | Always available from start, not an upgrade. Player should be able to name their queen immediately. |
| Dirt Customization added | Essentials upgrade that changes the look of ALL dirt, overriding distance-based gradients. Cosmetic personalization. |
| Food has light physics | Food falls to nearest floor when supporting dirt is destroyed (explosion dig method). No floating food in mid-air. |
| Infinite scalers persist between runs | ~~The 3 infinite scalers~~ → Only dig power scaling persists between runs now. Transport Speed ∞ and Worker Efficiency ∞ CUT. Must re-grind 1-50 each colony, then saved tiers 51+ activate. |
| Dig methods replace basic bite | 4 dig methods (Gun, Laser, Butt Acid, Explosion) replace the old bite animation. Pick 1 of 4. Biggest build-defining choice for the queen. |
| Miners get own dig method | Miners pick their own dig method independently of the queen. "Laser queen with gun miners" is a valid build. More diversity for the automation side. |
| Dig stats: pick 2 of 3 | Dig Range / Dig Speed / Dig Radius — pick 2, lock out 1. Creates 3 distinct dig profiles. Both player and miners have their own independent 2-of-3 pick. |
| 0/10 tiers | All standard upgrades have 10 purchases. 0/10 = start at 0, buy 10. Each gives the same increment. |
| 0/50 tiers for dig strength | Dig strength (player + miner) has 50 tiers in regular tree. Extended progression. Cross-colony persistence at tier 50+. |
| Zip Lines added | 4th Transport Tier 1 option: diagonal, fast going down, slow going up. Fills the diagonal movement gap. |
| Transport Tier 1: pick 1 of 4 | Lift/Minecart/Platform/Zip Line. Pick 1 creates real sacrifice — no combo covers all directions. |
| Conveyor belts on walls | Conveyors work on ANY solid surface (floor, wall, ceiling), not just flat ground. Makes conveyor vs tramway a genuine choice. |
| Cargo Drones CUT | "How many?" problem — either too few (useless) or too many (OP). No clean balanced number. |
| Train Upgrade CUT | Same concept as minecart, no distinct identity. |
| Critical Strike CUT | Lone RNG mechanic with no other RNG. Feels random and disconnected. |
| TNT/Explosives → Explosion dig method | Replaced by the Explosion pick in the dig methods fork. |
| Super Mandibles → Rainbow Food | Recycled as endgame cheat. |
| Transport Speed ∞ CUT | Transport improves via infrastructure tiers (minecart → conveyor → teleporter), not infinite slider. |
| Worker Efficiency ∞ CUT | Worker quantity IS the scaling. Buy more workers. |
| Ant Cannon mid-game | Haulers get shot toward nearest food cluster after depositing. Range-limited, rewards clean tunnel design. Too fun for endgame — put it in mid-game. |
| ~~Teleporter: limited count~~ | ~~SUPERSEDED~~ — now 1 pair, player + food + haulers. See "Teleporters: 1 pair only" below. |
| ~~Tubes: short range~~ | ~~SUPERSEDED~~ — tubes now have no range limit, any-angle. See "Tubes: any-angle, unlimited" below. |
| Endgame transport doesn't obsolete earlier | Ants can't use teleporters/tubes. Tier 1 infrastructure stays relevant because it moves ANTS. |
| Void Storage → Rainbow Food | Too powerful for regular tree. Endgame reward. |
| ~~Architect Ant → Rainbow Food~~ | ~~SUPERSEDED~~ — Architect is now mid-game standard upgrade. See "Architect Ant = mid-game" below. |
| Rainbow Food = cheat menu | Not 1-2 items — a WALL of absurd unlocks. Power fantasy, automation, cosmetics. Like unlocking cheats for playing the game. |
| Auto-buy system | Auto Worker (auto-hires) + Auto Evolve (auto-buys when food > threshold). Standard idle game convenience in mid-game. |
| Noita-style pixel terrain | Granular pixel-based dirt, not chunky tiles. Individual dirt pixels destructible. NOT full Noita physics. Needs research — possible hybrid approach (pixel visuals, tile-based logic). |
| Hats spawn randomly in new layers | Not pre-placed at milestones. Random chance per new layer, max 1 per layer, queen must collect personally. |
| Cosmetics separate page | Dirt customization + ant customization (apply-all or individual). Dedicated cosmetics page, not mixed with skill tree. |
| Big Head Mode | All ants get comically large heads. Rainbow food cosmetic unlock. |
| Boogie Bomb | Button that makes all ants dance on command. Visual only, doesn't interrupt work. |
| Hive Mind AI: closest task | If Hive Mind unlocked, ants do whatever's closest — nearest food = haul, nearest dirt near food = mine. Natural self-balancing. |
| Fork sizes vary | Not one universal rule. Pick 2 of 3 for stats, pick 1 of 4 for transformative choices, pick 1 of 2 for infrastructure. Whatever fits the fork. |
| Mega Speed needs surfaces | Natural limitation: can't cross gaps. In a game about digging tunnels, this is genuinely meaningful. No artificial cooldown needed. |
| Jetpack = slow but free | No fuel mechanic. Slower than other traversal but works anywhere including mid-air. Freedom vs speed is the tradeoff. |
| No dirt gravity | Dirt stays in place even if unsupported. Too performance-heavy. Only food has light physics (falls when support removed). |
| Terrain visual = dig angle | CRITICAL: removal shape must match the ant's bite/dig angle. Left bite = left-shaped removal. Explosion from above = downward crater. Dig method visuals drive deformation shape. |
| Ant Cannon = physical turret | Not an invisible AI mechanic — actual turret placed in base. Rotates to aim. Toggle AI/player control. Ants STICK to surfaces on hit (no bounce physics). |
| ~~Hauling Efficiency fork: Compression Haulers~~ | ~~SUPERSEDED~~ — Compression Haulers replaced by Relay Chains. Compression was just "haulers walk faster" — a stat buff with extra steps. See "Relay Chains replace Compression Haulers" below. |
| Hauling Efficiency fork updated | Mid-game pick 1 of 3: Ant Cannon (active/exciting), Food Singularity (passive/magical), Relay Chains (team-coordination). |
| ~~Endgame transport: pick 1 of 3~~ | ~~SUPERSEDED~~ — now pick 1 of 2 (Teleporters vs Tubes). Ant Relay Chain tabled. See "Endgame transport: pick 1 of 2" below. |
| Tubes break if dug through | Creates tension between mining expansion and tube network preservation. Real strategic tradeoff. |
| Auto-buy = mid-game, not rainbow | Fundamental idle game QOL. Auto Worker (set ratio + threshold) and Auto Evolve (checkbox per node). Don't make the player click every 10 minutes — that's Runescape-tier hostile. |
| Rainbow food unlocks toggleable | All rainbow unlocks can be turned on/off at will. Cheat menu is a menu, not permanent changes. |
| ~~Architect Ant = cheapest rainbow~~ | ~~SUPERSEDED~~ — Architect moved to mid-game standard. "Over the Rainbow" is now the endgame gate. |
| ~~Boogie Bomb interrupts briefly~~ | ~~SUPERSEDED~~ — Boogie Bomb is now a toggle (on/off), not a timed 2-3 second interrupt. See "Boogie Bomb = toggle" below. |
| Auto Conveyor (standard upgrade) | Auto-extends slow conveyor from food pile toward furthest mine. One direction. Everyone can buy. Proto-Architect Ant. |
| Food Singularity moved to mid-game | Too cool for rainbow-only. Competes with Ant Cannon in hauling efficiency fork. Performance concerns with many food pieces. |
| Food tiers REMOVED | All food is orange. No color/shape tiers. Value = linear distance-band scaling (layer 1 = 1, layer 2 = 2, etc.). Terrain gradient is the visual indicator. Simplifies design, avoids infinite color/shape scaling problem. |
| All fork options = pure positives | No drawbacks unique to one option. Differentiation is what they're good AT, not what they cost. No positive/negative tradeoffs. |
| ~~Compression Haulers replace Hauler Rush~~ | ~~SUPERSEDED~~ — Compression Haulers scrapped entirely. Replaced by Relay Chains. See "Relay Chains replace Compression Haulers" below. |
| Architect Ant = mid-game | NOT rainbow food, NOT endgame. Standard upgrade alongside Auto Evolve + Auto Worker in Player Ant panel. Competent single-purchase ant that cycles through transport systems. "You will appreciate and love your architect ant." |
| Over the Rainbow = endgame gate | Very expensive standard purchase at bottom of upgrade tree. Buying it unlocks the rainbow food menu. Replaces Architect Ant as the endgame milestone. |
| Endgame transport: pick 1 of 2 | Teleporters (1 pair, player + food + haulers) vs Pneumatic Tubes (unlimited, any-angle, food only). Ant Relay Chain tabled — balance was tricky. |
| Teleporters: 1 pair only | Player + food + haulers can all use them. Repositionable. No second pair via rainbow food (inconsistent pattern — nothing else works like "buy more of a fork you already picked"). |
| Tubes: any-angle, unlimited | 360-degree straight line through solid terrain. No range limit. Unlimited count. Break if dug through. Faint dotted line visual indicator. Walls are natural balance — ants can't cross walls anyway. |
| Hauler AI claiming system | Central Food Manager (blackboard pattern), runs every ~0.5s. Claims prevent two haulers targeting same food. Proximity-based claim stealing: closer idle hauler steals claim from distant hauler. |
| Upgrades are toggleable | All upgrades with active effects can be toggled on/off. Purchase is permanent (can't un-buy or switch forks), but activation is optional. Auto Conveyor, Food Singularity, Ant Cannon, Boogie Bomb all toggleable. |
| Boogie Bomb = toggle | On/off toggle, not timed 2-3 second interrupt. Player controls when ants dance and when they stop. |
| Auto Conveyor = toggleable | Standard upgrade, toggleable on/off. Auto-extends slow conveyor from food pile toward furthest mine. |
| Rainbow food persistence rules | Currency persists always. Cosmetics: immediately available in every colony. Gameplay purchases: persist but only activate after buying Over the Rainbow per colony. |
| Second teleporter from rainbow CUT | Inconsistent pattern — nothing else gives "more of a fork you already picked." Removed from rainbow menu. |
| Food Singularity: ground travel | Unclaimed food slides along ground following hauler flow field toward home. Not just nearest station — needs "direction home" awareness. Loading station radius pull as performance fallback. |
| Butt Acid = area control | Identity changed from "best range" to "acid lingers and dissolves dirt over time." Medium base range. Prevents Range stat from being a trap pick for Acid players. |
| Explosion: Range + Radius both = size | For Explosion only, Range and Radius both increase blast size. Picking both = massive explosion, sacrifices Speed. Explosion is the "go big" method. Meaningful choice: all-in on size vs balanced with speed. |
| Dig method toggle | Basic bite always available alongside chosen dig method. Explosion doesn't lock you out of precision tunneling. All methods toggleable, not permanent replacements. |
| Upgrade tree = "Evolve" | The upgrade menu is called "Evolve." Thematic: every upgrade is your colony evolving. |
| Vanilla Mode (separate game mode) | Main menu option: pure ant farm screensaver. No upgrades, no menus, no scaling difficulty. Starts with 2 workers, auto-spawns ants via hidden formula. Player can dig/zoom/pan but never has to. Replaces the "vanilla 5th option" approach — keeps the Evolve tree clean without boring stat-buff alternatives cluttering it. |
| Vanilla 5th fork options TABLED | Considered "Primal Jaws/Legs/Colony/Miners" as vanilla 5th options in dig method, transport, traversal, and miner forks. Trade tech for brute strength, ants get bigger. Tabled in favor of Vanilla Mode — separate game mode is cleaner than cluttering the tree. Archived for future reference if needed. |
| Big Ant Mode (rainbow cosmetic) | All ants grow ~2x larger. Combine with Big Head Mode for maximum absurdity. Rainbow food cosmetic unlock. |
| ~~Release Worker = no refund, curve never resets~~ | ~~SUPERSEDED~~ — see "No worker deletion" below. |
| ~~Release Worker = no refund, counter decrements~~ | ~~SUPERSEDED~~ — see "No worker deletion" below. Even single-punishment (lost food) is exploitable when rich — becomes free ratio respec. Any delete button is gameable. |
| No worker deletion — engineering solves performance | Workers are permanent. No delete, no release, no refund system. Eliminates all exploitation. Performance handled by auto-hibernate (far workers get simplified AI + skip rendering when FPS dips). Player never manages performance — game handles it. Target: 1000+ ants before hibernate needed. If engineering can't solve it, Phase 1 prototype reveals that immediately. |
| Performance warning system | FPS < 45 = yellow indicator, FPS < 30 = red warning. Informational only, no hard block. Toggleable off in options menu. Player's colony, player's choice. |
| Vanilla Mode: auto-spawner formula | `cost_for_ant_N = floor(8 + N * 4)`. Deliberately slow — time to name and appreciate each ant. 5-second minimum gap between spawns. First 6 ants fixed pattern (M,H,M,M,H,M), then ratio AI. |
| Vanilla Mode: ratio AI | Simple rules: idle_haulers >= 2 → spawn miner. Exposed food >= hauler_count * 3 → spawn hauler. Otherwise maintain 2:1 miner:hauler. Self-correcting, looks smart, actually just 3 checks. |
| Vanilla Mode: performance soft cap | Auto-spawner monitors FPS. Below threshold → pause spawning. Recovers → resume. Colony finds natural size based on hardware. Colony Size setting in Gameplay tab (Small/Medium/Large/Unlimited). |
| Vanilla Mode: cosmetics = viewer not unlocker | Can name ants (free), use hats/cosmetics from normal mode. Cannot earn new cosmetics or achievements. Cosmetics are the bridge between modes. |
| Vanilla Mode: multiple save slots | Same save system as normal mode. Each Vanilla Mode colony is its own save. Start new ones, return to old ones. |
| 1000 ants = minimum target | If the game can't handle 1000 ants, something is wrong. This is the performance bar for the engine/architecture. Phase 1 prototype must validate this. |
| Noita reference = visual only | NOT Noita physics (no falling sand, no cellular automata). Just the granular carve aesthetic — organic craters, sharp irregular edges, not blocky tile removal. Noita was a custom engine for pixel physics; we need shaped masks on a tile grid with pixel-visual overlay. |
| Engine risk strategy | Godot first, with escape hatch. Phase 1 terrain prototype validates feasibility within a week. If it can't hit 60fps with terrain + 1000 ants, options: optimize, reduce granularity, or evaluate Unity/Unreal. |
| ~~Compression = trip complete~~ | ~~SUPERSEDED~~ — Compression Haulers scrapped. See "Relay Chains replace Compression Haulers" below. |
| Hauler carry: 5 base, 15 max | Haul Capacity upgrade (0/10, +1 per tier). Clean numbers. 5 → 15. |
| Graduated hauler speed penalty | `speed_mult = 1.0 - (carried / max) * 0.6`. Max load = 40% speed, half = 70%, 1 food = ~96%. Makes Relay Chains efficient — after a partial handoff, lighter hauler walks back fast. |
| Miner:hauler ratio shifts with distance | Early (near base): 3:1 miners:haulers. Mid (500+): 2:1 or 1:1. Late (2000+): 1:2 — haulers become bottleneck. Transport infrastructure solves the late-game hauler problem. Natural balance, no forced ratio. |
| Relay Chains replace Compression Haulers | Compression was "haulers walk faster" — a stat buff with extra steps. Relay Chains create a new mechanic (bucket brigade) that scales with hauler count, solves the distance problem elegantly, and is visually adorable. Partial transfers based on capacity, instant on contact, capacity-based claiming prevents conflicts. |
| Pheromone Highways = core upgrade (not fork) | Too good to limit to one fork option. Applies to ALL ants + player. Standard upgrade in LOGISTICS panel. Well-traveled routes glow and give speed boost. Emergent swarm intelligence from individual selfish decisions — real ant behavior. Speed boost needs tuning (20-30% max, not 50%). |

---

## Visual Design

### Terrain
- **Brown dirt** — base, procedural noise texture. NOT flat color — subtle variation using noise.
- **Gradient color shifts** based on distance from origin (see Distance Scaling table)
- **Food** is always bright and visible against the dirt — strong contrast
- **Tunnels** are very dark brown (`~Color(0.12, 0.08, 0.05)`) — the negative space IS the player's creation

### Ants
- Geometric: ovals + lines
- Queen: 3 ovals, 6 legs (Line2D), 2 antennae, slightly larger. Crown/glow + equippable hat.
- Workers: 2-3 ovals, simplified legs (maybe just 4), smaller. Miners have bigger mandibles, haulers have bigger abdomen.
- Named ants: subtle glow + name tag + optional hat
- Achievement ants: unique color/glow, fixed name tag
- At distance (zoomed out): just colored dots with direction indicators.

### Food
- **All orange circles** — no color/shape differentiation by value
- Value determined by distance from base (linear band scaling)
- When carried: stacked on ant's back, slightly bouncing with movement
- Food pile: heap of orange circles, grows visually with amount stored
- **Rainbow food** (16000+): rainbow shimmer, pulsing star — visually distinct endgame currency

### Infrastructure
- **Minecart tracks:** two parallel lines with cross-ties
- **Minecarts/Trains:** rectangles on the tracks with food circles inside
- **Conveyor belts:** animated dashed lines showing direction
- **Aerial tramways:** pylons with thin wire, gondola hanging from wire
- **Pneumatic tubes:** faint dotted line through terrain showing tube path, food shoots through. Visually subtle when inactive.
- **Teleporters:** two glowing rings (entry/exit) with particle effects. 1 pair only.
- **Loading stations:** small marked points on transport lines where workers dump food

### UI
- **Food counter** — top of screen, shows current food amount (with suffix notation for big numbers)
- **Rainbow food counter** — separate, only visible once found
- **Distance indicator** — furthest distance reached from origin
- **Worker count** — how many active workers, by role
- **Upgrade menu** — three-panel overlay (Player Ant, Colony, Logistics)

---

## Performance Strategy

### The Core Challenge
An infinitely expanding world with destructible terrain, hundreds/thousands of worker ants, transport systems, and zoom from micro to macro scale.

### Terrain: Chunk-Based System
- World divided into **chunks** (e.g., 64x64 or 128x128 tiles)
- Only **visible chunks** are rendered
- Chunks generated on-demand when first visible
- Chunks saved to disk when far from camera
- **Terrain data** is a 2D byte array per chunk (0 = empty, 1-255 = dirt types)
- Dig operations modify chunk data → chunk re-renders

### Rendering: LOD (Level of Detail)
Based on zoom level:

| Zoom Level | Terrain | Ants | Food | Infrastructure |
|------------|---------|------|------|----------------|
| Close (1x) | Full tile detail, noise texture | Full sprite, animated legs, hat | Individual circles | Full detail |
| Medium (2-4x) | Simplified tiles, solid colors | Small dots with direction | Colored dots | Lines only |
| Far (8x+) | Color blocks per chunk | Count number per region | Aggregate glow | Hidden |
| Macro (16x+) | Gradient colors only | Colony density heatmap | Value heatmap | Hidden |

### Entity Management: Ants at Scale
Inspired by Gnorp Apologue (hundreds of entities) and WorldBox (thousands):

1. **Object pooling** — Pre-allocate ant nodes, reuse them
2. **Off-screen ants don't render** — if ant is outside camera view, skip all visual updates
3. **Off-screen ants simulate simply** — increment a timer, when timer completes = "food delivered", no pathfinding needed
4. **Staggered AI updates** — each ant recalculates path on a different frame (spread across N frames)
5. **Flow fields instead of A*** — one flow field per chunk pointing toward food pile, all ants read it. Recalculate only when terrain changes.
6. **LOD for ants** — close = full detail, medium = dot, far = aggregated count

### Number Scaling
- Use **float/double** until we hit precision issues (~10^15)
- Display with **suffix notation**: K, M, B, T, Qa, Qi...
- Food values per tier scale exponentially so raw numbers stay manageable

### Chunk Loading Strategy for Zoom
**Solution: Multi-resolution terrain cache (Google Maps approach)**
- Store terrain at multiple resolutions (full → 1/4 → 1/16 → 1/64)
- When zoomed out, render the appropriate resolution
- Only load full-res for chunks near the camera when zoomed in

### Save System
- **Auto-save** on meaningful actions (upgrade bought, food deposited) + timer (every 30-60 sec)
- Chunk terrain data saves to disk
- All ant data saved (names, hats, achievement ants, positions)
- All upgrade states saved
- All transport infrastructure saved
- Single save slot to start, more later if needed

---

## Research Notes: Patterns Stolen from Idle Games

### From Cookie Clicker
- Workers produce FPS (food per second) → watching counter go up IS the game
- Upgrades multiply output → compound growth dopamine

### From Gnorp Apologue
- Simple entity AI → entities do ONE thing well
- Visual spectacle from quantity → hundreds of ants doing simple things looks amazing
- Upgrade entities, not just production → make ants BETTER, not just add more

### From WorldBox
- Chunk-based world → only simulate/render what's visible
- Entity LOD → simplified at distance
- Named entities → player attachment

### From Tap Wizard 2
- Active play more rewarding than idle → you always get more by playing
- Depth reveals over time → don't show everything at once

### From The Perfect Tower 2
- Automation IS the endgame → setting up systems is the game
- Each automation layer enables the next

### From Idle Miner Tycoon
- Three bottleneck pipeline → dig/transport/labor always competing
- Manager automation → specialized units run systems for you
- Loading stations → workers interact with transport at designated points

### From Dome Keeper
- Manual carry → automation feels EARNED → the tedium of early hauling makes automation satisfying

### From Dwarf Fortress / Kingdoms and Castles
- Worker allocation creates meaningful decisions
- Tunnel/layout design is a player SKILL bottleneck, not just a stat

---

## Sound Design Direction (Future)
- Digging: crunchy, satisfying bites (think Minecraft dirt breaking)
- Food pickup: light "pop" or "pling"
- Depositing food: satisfying "chunk" into pile
- Worker hatching: organic crack/pop
- Minecart/train: rumbling along tracks
- Zoom out: ambient hum of colony activity grows
- New food tier discovery: dramatic reveal sound
- Upgrade purchase: cha-ching / level-up sound
- Hat found: special jingle
- Achievement ant earned: fanfare

---

## Potential Future Systems

### Combat / Hazards (NOT in initial build)
- Underground threats: beetles, centipedes, rival ant colonies
- Soldier ants defend tunnels
- Explicitly cut for now — pure mining/idle

### Colony Rooms
- Specific chambers with functions: nursery (faster hatching), food storage (bonus capacity), throne room (passive bonuses)
- Player builds rooms by digging specific shapes

### Weather / Surface
- Eventually dig to the surface (upward!)
- Rain floods tunnels (drainage systems needed)
- Surface has unique food sources (leaves, seeds, dead bugs)

### Other Colonies (Multiplayer?)
- Dig toward another player's colony
- Trade or war
- Extremely ambitious but cool to think about

---

## Build Order (Step by Step)

Building it right from the start, in the correct order of operations.

**BUILD STRATEGY: Vanilla Mode first.** After proving terrain works (Steps 1-5),
build the complete Vanilla Mode ant farm screensaver (worker AI, auto-spawner,
pathfinding at scale) before any Normal Mode systems. This forces the hardest
tech problems (1000 ants at 60fps on destructible terrain) to be solved early.
Normal Mode upgrades, menus, and progression layer on top afterward. See
`ANT_COLONY_KICKOFF.md` for the full 8-phase breakdown.

### Step 1: Terrain + Camera
- Noita-inspired pixel-granular destructible 2D terrain (research needed)
- Procedural noise-based dirt generation with food embedded
- Distance-based color gradient
- Camera follow + zoom in/out (free pan)
- Chunk loading/unloading
- Save/load terrain chunks to disk

### Step 2: Player Ant + Movement
- Queen ant with WASD movement
- Wall climbing (stick to surfaces)
- Gravity (fall when not touching surface)
- Basic collision with terrain

### Step 3: Digging
- Click to dig in mouse direction
- Dig cooldown between bites
- Multiple bites per block (hardness based on distance)
- Dirt particles on dig (Noita-style pixel debris)
- Terrain modification (remove pixels from chunks)
- Hold-duration bite size (Stardew Valley watering can style)

### Step 4: Food + Collection
- Procedural food placement embedded in terrain (clusters, veins, interesting spots)
- Food always visible through dirt (no fog of war)
- Food exposed when surrounding dirt dug away → pops out
- Walk over food to pick up, stacks on ant body
- Carry capacity limit + food physics (falls when support removed)

### Step 5: Food Pile + Deposit
- Starting chamber with food pile
- Warm glow gradient deposit zone (no harsh red circle)
- Walk to pile to deposit
- Food counter UI (with suffix notation)
- Pile grows visually

### Step 6: Upgrade Menu + First Upgrades
- Skill tree menu (Tab/E to open)
- Auto Mining (first unlock)
- Scaling Dig Strength (0/50)
- Dig Range / Dig Speed / Dig Radius (pick 2 of 3, 0/10 each)
- Food Magnet + Carry Capacity + Player Speed (0/10 each)
- Place Dirt

### Step 7: Dig Methods
- Gun / Laser / Butt Acid / Explosion (pick 1 of 4)
- Distinct visuals, projectiles, AOE for each method
- Replace base bite animation entirely

### Step 8: Worker Ants + Naming
- Unlock Workers upgrade
- Egg hatching (spend food → choose Miner or Hauler, permanent)
- Miner AI (dig dirt near food, stacking cap, spread logic, frontier expansion)
- Hauler AI (pick up exposed food, carry to pile, slow when loaded)
- Customize screen (click ant → name, color, hat — free from start)
- Achievement ant: Greg spawns on first worker hatched
- Ant marching formation (same direction = single file)

### Step 9: Miner Upgrades
- Scaling Miner Strength (0/50)
- Miner Dig Range / Speed / Radius (pick 2 of 3)
- Miner Dig Method (pick 1 of 4, independent from player)
- Ant Haul Capacity (0/10)
- Ant Move Speed (0/10)

### Step 10: Transport Tier 1
- Lift / Minecart / Platform / Zip Line (pick 1 of 4, free to place)
- Loading stations (workers dump food here)
- Workers interact with transport

### Step 11: Transport Tier 2
- Aerial Tramway / Conveyor Belt (pick 1 of 2, food only)
- Conveyors on any solid surface (floor, wall, ceiling)
- Tramway pylons + wires across caverns

### Step 12: Player Traversal
- Mega Speed / Grapple Hook / Jetpack / Jump+Dash (pick 1 of 4)
- Each with distinct feel and natural limitations

### Step 13: Mid-Game Automation Trio
- Auto Worker (set miner/hauler ratio + food threshold, auto-hires)
- Architect Ant (auto-places transport infrastructure, competent, cycles through systems)
- Auto Evolve (checkbox per upgrade node — auto-buy when affordable)
- All three in the Player Ant panel, mid-game automation trio

### Step 14: Hauling Efficiency Fork
- Ant Cannon / Food Singularity / Relay Chains (pick 1 of 3)
- Auto Conveyor (standard, toggleable)

### Step 15: Endgame Transport
- Teleporters / Pneumatic Tubes (pick 1 of 2)
- Teleporters: 1 pair, player + food + haulers
- Tubes: any-angle, unlimited count, food only, break if dug through

### Step 16: Hats + Achievements
- Hats spawn randomly in new terrain layers (max 1 per layer)
- Queen must physically collect hats
- Achievement ants (milestone-based special ants)
- Hat collection / cosmetics page
- Discovery notifications

### Step 17: Over the Rainbow + Cheat Menu
- "Over the Rainbow" — expensive endgame gate purchase (regular food)
- Rainbow food at extreme distances (16000+), queen collects personally
- Rainbow food tab with power fantasy unlocks
- Hive Mind, Void Storage, etc.
- Cosmetic unlocks (Big Head Mode, trails, Boogie Bomb toggle)
- Dig Power cross-colony persistence (tiers 51+)
- Rainbow persistence: cosmetics always, gameplay gated behind Over the Rainbow per colony

### Step 18: Polish
- Sound design
- Particle effects for everything
- Performance optimization pass
- Full save system verification
- Dev menu testing of all balance curves

---

## Open Questions

1. ~~**Camera**~~ **ANSWERED:** Free pan + zoom across discovered areas. Not locked to queen.
2. ~~**Worker cap**~~ **ANSWERED:** No hard cap. Target 1000+ ants. No worker deletion — engineering solves performance via auto-hibernate system (far workers get simplified AI + skip rendering when FPS dips). Performance warning system (yellow at FPS<45, red at FPS<30, toggleable in options). Vanilla Mode has performance-regulated auto-spawner + optional colony size slider.
3. ~~**Tunnel background**~~ **ANSWERED:** Very dark brown `~Color(0.12, 0.08, 0.05)`, NOT pure black.
4. ~~**Save system**~~ **ANSWERED:** Multiple save slots — each colony is a save slot. Old colonies fully playable.
5. ~~**Tutorial**~~ **ANSWERED:** No tutorial. Controls should be self-explanatory.
6. ~~**Music**~~ **ANSWERED:** User will source later. Not a design question.
7. ~~**Prestige**~~ **ANSWERED:** Build Diversity model. See Prestige System section.
8. ~~**Endgame tab**~~ **ANSWERED:** Rainbow Food cheat menu. Wall of power fantasy unlocks. See Upgrade System → RAINBOW FOOD.
9. ~~**Build Choice forks**~~ **ANSWERED:** All forks now defined — see Upgrade System section. 9 forks total, 27,648 possible builds.
10. **Hatching cost curve:** Exact formula for egg cost scaling. Will be determined through playtesting, not theory.
11. **Upgrade costs/balance:** All numbers need playtesting. Can't be designed on paper — needs a dev menu to test quickly.
12. **Noita-style terrain implementation:** Pixel-granular vs tile-based vs hybrid approach. Needs technical research and prototyping. Major architectural decision.
13. **Grapple hook range:** Too short = useless, too long = OP. Needs playtesting to find the sweet spot.
14. **Dig method balance:** Gun/Laser/Butt Acid/Explosion all need to feel equally powerful but different. Laser + Range investment shouldn't be strictly better than Gun. Needs playtesting.
15. **Ant Cannon tuning:** Range limit, wall collision behavior, trajectory physics. Needs prototyping.
16. **Rainbow food rarity:** How often does it spawn? How many per unlock? Too rare = frustrating, too common = not special. Needs playtesting.

---

## Dev Menu (Testing Tool)

**Required for development.** Can't playtest a multi-hour idle game by playing hundreds of hours. Need shortcuts.

Proposed dev menu features:
- **Give food** (set amount, or give 999999)
- **Give rainbow food**
- **Hatch N workers** (instant, free, choose role)
- **Unlock all upgrades** / unlock specific upgrade
- **Set distance** (teleport queen to any distance for testing terrain/food tiers)
- **Set game time** (simulate X minutes of elapsed time for spawning/difficulty)
- **Toggle food visibility** (hide food in dirt, for testing player experience without visible food)
- **Speed multiplier** (2x/5x/10x for fast-forwarding idle sections)
- **Reset colony** (fresh start without closing game)
- **Toggle UI overlays** (show pathfinding, flow fields, worker targets)

Access via debug key (F12 or backtick). Stripped from release build.

---

## Technical Research Needed

Systems that require investigation before implementation begins. Each needs prototyping or reference game analysis.

### 1. Noita-Style Pixel Terrain (CRITICAL)
- **What:** Pixel-granular destructible terrain instead of tile-based
- **Why:** Organic bite marks, satisfying digging feel, visual quality
- **Research:** Noita (Nolla Games), Liero, Cortex Command terrain systems
- **Key question:** Full pixel simulation vs hybrid (pixel visuals + tile logic for pathfinding)?
- **Performance concerns:** Millions of pixels at scale, chunk management, LOD when zoomed out
- **Godot approach:** Likely Image/ImageTexture manipulation per chunk, or custom shader-based terrain

### 2. Procedural Terrain Generation
- **What:** Perlin/Simplex noise for dirt, food cluster placement, rock formation placement
- **Research:** How to distribute food in interesting spots (behind rocks, tight corners, awkward depths)
- **Key question:** How to make food placement feel designed, not random? Noise + rules?
- **Food scaling:** Less common food early, denser clusters later, rare veins of high-value food at depth

### 3. Ant Pathfinding at Scale
- **What:** Hundreds/thousands of ants navigating destructible terrain
- **Research:** Flow fields vs A*, staggered updates, off-screen simulation
- **Key question:** Flow fields per chunk? Recalculate on terrain change? How to handle dynamic terrain?
- **Performance budget:** Target ant count before LOD/simplification kicks in

### 4. Chunk System + LOD
- **What:** Loading/unloading terrain chunks, multi-resolution for zoom levels
- **Research:** Google Maps approach (multi-resolution cache), Factorio-style chunk management
- **Key question:** How many resolution levels? How to transition smoothly between LODs?
- **Zoom levels:** Close (individual pixels) → Medium (simplified blocks) → Far (color heatmap)

### 5. Food Physics
- **What:** Lightweight falling/settling when supporting terrain is destroyed
- **Research:** Not full Noita physics — just "food falls to nearest floor"
- **Key question:** How to detect "support removed"? Raycasting downward each frame? Event-driven on dig?

### 6. Transport Infrastructure in Pixel Terrain
- **What:** How minecarts/elevators/conveyors/tramways work in pixel-based (not tile-based) terrain
- **Research:** How to define "surfaces" for conveyor placement in pixel terrain
- **Key question:** Snap to pixel surface? Use underlying tile grid? Freeform placement with angle detection?

### 7. Idle Game Economy Math
- **What:** Cost curves, scaling formulas, dig strength 0/50 progression, food tier values
- **Research:** Cookie Clicker cost formulas, Idle Miner Tycoon progression curves
- **Key question:** How steep should 0/50 dig strength curve be? When does food tier N become the dominant currency?
- **Rainbow food rarity:** Spawns per chunk at 16000+ distance, expected time to first find

### 8. Auto-Buy Systems
- **What:** Auto Worker (auto-hire) and Auto Evolve (auto-buy when affordable) systems
- **Research:** Cookie Clicker auto-buy, Idle Miner Tycoon managers, Tap Wizard 2 automation
- **Key question:** How does auto-buy prioritize when multiple upgrades are affordable? Cheapest first? Most efficient? Player-configured priority?
- **Note:** This is a mid-game regular feature, NOT a rainbow food reward. Fundamental idle game QOL.

### 9. Performance Optimization (CROSS-CUTTING)
- **What:** Every system decision must be evaluated through the performance lens
- **Target:** 500+ ants + pixel terrain + transport infrastructure + food physics running simultaneously
- **Research areas:**
  - Pixel terrain: chunk-based Image manipulation, dirty rect rendering, only redraw changed chunks
  - Ant simulation: off-screen simplification, staggered AI updates, spatial hashing for proximity queries
  - Transport: only simulate visible transport, aggregate off-screen transport as timers
  - Food physics: event-driven (on dig) not per-frame, batch food movement
  - VFX: particle pooling, disable off-screen effects, LOD for zoom levels
  - Rendering: draw calls per frame budget, instanced rendering for identical ant sprites
- **Key question:** What's the performance ceiling in Godot 4.6 for this type of game? What are the bottlenecks — CPU (AI/pathfinding), GPU (pixel terrain rendering), or memory (chunk storage)?
- **Strategy:** Profile early and often. Dev menu speed multiplier helps stress-test. Set hard frame budget targets and optimize to them.
