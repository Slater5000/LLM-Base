# Ant Colony: Idle Mining Game — Design Document (Unity 6)

> **NOTE:** This is the Unity 6 adaptation of the game design document.
> The original Godot 4.6 version is at `.llm/ANT_COLONY_DESIGN.md`.
> Game design is identical — only engine-specific technical details differ.

> **Working Title:** Ant Colony (or "The Hive", "Queen's Dig", TBD)
> **Genre:** Idle / Incremental + Action Mining Hybrid
> **Engine:** Unity 6 (URP - Universal Render Pipeline)
> **Language:** C#
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

**Spawning cost formula:** `cost_for_ant_N = Mathf.FloorToInt(8 + N * 4)` where N = total ants spawned so far (not including the 2 starting workers). Deliberately slow — you should have time to notice, name, and appreciate each new ant before the next one arrives.

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

**Unity save implementation:** JSON serialization to `Application.persistentDataPath`. Use `JsonUtility` for simple data or Newtonsoft JSON for complex nested structures. Chunk terrain data as binary files alongside JSON metadata.

### Settings Menu

Settings save **separately from game saves** — persist across all colonies and modes. Save to `PlayerPrefs` or dedicated JSON file.

**6 tabs:** AUDIO, DISPLAY, GAMEPLAY, PERFORMANCE, ACCESSIBILITY, CONTROLS

| Tab | Settings |
|-----|----------|
| **Audio** | Master volume, Music volume, SFX volume, Ambient volume (via AudioMixer) |
| **Display** | Window Mode (borderless default), Resolution, Max FPS (30/60/120/144/Unlimited via Application.targetFrameRate), UI Scale, Screen Shake (slider), Pheromone Trail Visibility (slider), Trail Quality (Simple/Normal/Detailed), Ant Detail Level (Dots/Normal/Full), Show Ant Names (toggle) |
| **Gameplay** | Game Speed (0.25x / 0.5x / 1x via Time.timeScale — no faster than realtime), Zoom Speed, Edge Scrolling (toggle), Auto-Save (toggle), Auto-Save Interval (left/right selector: 1m / 5m / 10m), Number Format (Standard 1500 / Short 1.5K / Scientific 1.5e3), Colony Size (Small / Medium / Large / Unlimited — default Unlimited) |
| **Performance** | Quality Preset (Low/Medium/High via QualitySettings), Max Visible Ants (slider, ants beyond cap still simulated but not drawn), Show FPS Counter, FPS Warning (toggle — see Performance Warning System) |
| **Accessibility** | Colorblind Mode (Off/Deuteranopia/Protanopia/Tritanopia), High Contrast Mode, Font Size (Small/Normal/Large), Large Cursor |
| **Controls** | Key Rebinding via Input System's `InputActionRebindingExtensions` (Move, Dig, Place, Zoom, Evolve, Build, Pause). Future: Controller Support, Controller Deadzone |

**Architecture notes:**
- Settings persist across save slots (separate save file or PlayerPrefs)
- Number formatting = static utility class (called thousands of times per frame)
- Max Visible Ants is the single most impactful performance lever
- Auto-reduce system: lightweight singleton monitors FPS, progressively dials down visual settings

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
- Tunnel background is **very dark brown** (`new Color(0.12f, 0.08f, 0.05f)`). NOT pure black — reads as deep earth shadow, not void. Clearly "empty space" but thematically underground.

**Larder Visual Progression (food pile grows with deposits):**

| Food Amount | Visual |
|-------------|--------|
| 0-50 | Small dirt pedestal, scattered orange pieces on top |
| 50-500 | Growing mound, food visibly piling up, slight warm glow |
| 500-5000 | Proper hill of food, some tumbling off edges, golden-orange glow |
| 5000-50000 | Overflowing mountain, food embedded in nearby walls, strong warm glow |
| 50000+ | Absurd pile, fills most of the starting chamber, practically radiating |

### Terrain System
- **Granular carve aesthetics** — the visual reference is Noita-style destruction: organic crater shapes, sharp irregular edges, bite marks that look like bites. NOT Noita's physics engine (no falling sand, no liquid simulation, no cellular automata). The reference is purely visual — how terrain *looks* when destroyed, not how it *behaves* afterward.
- **Likely approach: tile-based logic with pixel-visual overlay.** Each "tile" (for pathfinding, food placement) is a cluster of pixels (e.g., 4x4 or 8x8). Digging removes pixels within tiles using **shaped masks** (circle for explosion, wedge for bite, line for laser, splatter for acid). Pathfinding operates on the tile grid; visuals are per-pixel. Once enough pixels in a tile are cleared, the tile is "open" for pathfinding. Gives organic carve shapes without simulating individual pixel physics.
- **Unity implementation:** `Texture2D.SetPixels32()` and `Apply()` for per-pixel manipulation per chunk. `ComputeShader` for GPU-accelerated terrain modification at scale. **Chunk-based dirty-rect rendering** — only update modified Texture2D regions and call `Apply()` on changed chunks.
- **CRITICAL: Visual fidelity must match dig angle.** If the ant bites from the left, the removal shape looks bitten from the left. If the explosion hits from above, the crater faces upward. The dig method's visuals drive the terrain deformation shape. This is the #1 requirement — more important than the technical approach.
- **No dirt gravity/physics** — too performance-heavy. Food already has light physics (falls when support removed). Dirt stays in place even if unsupported. Cut for performance.
- **Procedurally generated** using noise functions (Unity.Mathematics or FastNoiseLite)
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
- **Mouse wheel / pinch** to zoom in and out (Cinemachine or custom camera controller)
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
- **Unity rendering:** SpriteRenderer for body ovals, LineRenderer for legs/antennae, or single procedural sprite

### Controls
- **WASD** — Movement (left, right, up, down) via Input System
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

**B key** opens the Build Menu — a centered radial hex ring showing available transport types. Each type is a button arranged in a circular layout around the center of the screen, with a description tooltip below on hover. Background blurs when the menu is open (URP fullscreen blur or render to RenderTexture). Transport types progressively unlock as upgrades are purchased from the Evolve tree.

**Two-click placement system:**
1. Select a transport type from the Build Menu
2. Click **start position** in the world
3. Click **end position** in the world
4. **Green highlight** = valid placement, **Red highlight** = invalid
5. **Escape or right-click** to cancel placement

**Per-type placement behavior:**
- **Conveyor Belt:** Click start tile, click end tile. Belt auto-routes between them along surfaces.
- **Pylon / Aerial Tramway:** Must connect back to the base transport network (no isolated pylons). If two pylons have line-of-sight, wire is drawn automatically. Wires can't go through walls. Use `Physics2D.Linecast()` for LOS checks.
- **Lift:** Vertical only. Click top position, then bottom position.
- **Zip Line:** Two-click like conveyor. Needs a surface attachment point at both ends.
- **Teleporters:** Place entrance pad, then exit pad. 1 pair only. Repositionable.
- **Pneumatic Tubes:** Place entrance, aim exit at any angle (360 degrees). Straight line through solid terrain.

### In-Game HUD

Minimal, non-intrusive Canvas overlay showing essential information at the viewport corners:

- **Top-right:** Food count with orange food icon
- **Top-left:** Distance from base, Worker count (M:x H:x for miners/haulers)
- **Bottom-left:** Active tool indicator with radius (e.g., "Tool: DIG R:1"). Radius only shown if Dig Radius upgrades have been purchased.

The HUD is always visible during gameplay (except in Vanilla Mode where the food counter is hidden — see Vanilla Mode section).

### Movement Rules
- **Wall climbing** — Ants stick to any surface (floor, walls, ceiling). Custom 2D physics or raycast-based surface detection.
- **No jumping at start** — unlockable via Jump+Dash or other Player Traversal pick
- **Traversal solution** — Place dirt (right-click) to create climbable surfaces / ramps / bridges (Place Dirt upgrade)
- **Gravity** — Ants fall if not touching a surface (unless Jetpack traversal pick). Use Rigidbody2D or custom gravity.
- Movement speed upgradeable
- **Queen NEVER has a speed penalty.** Not from carrying food, not from anything. Always at full speed.

### Digging
- Click in a direction → Queen bites/digs a chunk of dirt in that direction
- **Dig has a cooldown** between bites (prevents auto-clicker cheese). Upgrades reduce cooldown.
- **Hold click = auto-mine** — continuously digs at cooldown rate, no spam clicking
- Dirt takes **multiple bites** to remove (based on distance-difficulty vs dig power)
- Visual: chomping animation, dirt particles fly off (Unity Particle System for pixel debris)
- **Bite size: automatic, not an upgrade.** Works like Stardew Valley's watering can — hold longer for bigger bite. As soon as you CAN bite a larger size (via Dig Radius upgrades), you can switch between all unlocked sizes.
  - Small: 1-2 tile radius. Precise tunneling, detail work (tap click)
  - Medium: 3-4 tile radius. Standard mining (short hold)
  - Large: 6+ tile radius. Blast mining (long hold, unlocked via upgrades)
- **Dig speed** = cooldown reduction (starts slow, upgradeable)
- When all dirt around a food piece is removed, the food pops out and can be collected
- **Food has light physics** — if dirt beneath/around food is destroyed (e.g., by explosion dig method), food falls to the nearest floor rather than floating in mid-air. Use `Physics2D.Raycast()` downward.
- **Dig Methods** replace basic bite animation — see Upgrade System → PLAYER ANT for Gun, Laser, Butt Acid, Explosion (pick 1 of 4)
- **Endgame (rainbow food):** Super Mandibles (one-bite anything), Auto Attack (auto-dig wherever facing)

### Place Dirt (Right-Click)
- **Requires Place Dirt upgrade** from LOGISTICS panel
- **Right-click** to place dirt at mouse position within range
- **Fixed baked-in range** — decent mid-range distance, never changes, NOT tied to any upgrade
- **Doesn't need to connect to anything** — floating dirt in mid-air is fine (build bridges, platforms, ramps)
- **Placed dirt = base hardness** — easy to re-dig if you make a mistake
- **Cannot place over transport routes** — shows warning icon / red highlight
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

### Dig Power Scaling — Cross-Colony Persistence

Both player dig strength and miner dig strength have extended progression:
- **Regular tree:** ~50 tiers of scaling strength (costs regular food, must be re-purchased each colony)
- **Tier 50 = endgame unlock:** All cross-colony saved progress activates instantly
- **Tiers 51+:** Continue buying with rainbow food, progress persists forever between colonies
- New colony: grind 1→50 again, then at 50 you instantly jump to wherever you left off (e.g., 65) and continue
- This is the one exception to "clean slate every time" — just reward the player for playing

### PLAYER ANT

The queen's personal abilities, stats, and automation tools. This is your "character build."

**Upgrade order (top to bottom in panel):**

| Upgrade | Type | Effect |
|---------|------|--------|
| Auto Mining | Standard | Hold click to continuously dig. **First unlock in the game** — don't make the player click-spam. |
| Scaling Dig Strength | Standard (0/50) | Increases player dig damage. Cross-colony persistence after tier 50. |
| Food Magnet | Standard (0/10) | Exposed food flies toward queen from increasing distance. |
| Player Speed | Standard (0/10) | Queen moves faster. |
| Carry Capacity | Standard (0/10) | Queen carries more food. Visually stacks on ant body. |
| Dig Range / Dig Speed / Dig Radius | **Pick 2 of 3** (each 0/10) | Range = dig from further away. Speed = faster cooldown. Radius = bigger bite. Can't have all three. |
| Auto Worker | Standard | Set miner/hauler ratio + food threshold. When food exceeds threshold, auto-hires at the set ratio. |
| Architect Ant | Standard | Special ant that auto-places and upgrades logistics infrastructure. Single purchase. |
| Auto Evolve | Standard | UI feature: checkbox on each upgrade node — "auto-buy when affordable." |
| Gun / Laser / Butt Acid / Explosion | **Pick 1 of 4** | Transforms HOW the queen digs. Biggest build-defining choice. |

**Dig Methods (Pick 1 of 4):**

| Method | Fantasy | Identity | Natural Limitation |
|--------|---------|----------|--------------------|
| **Gun** | Ranged shooter | Balanced range + speed | Jack of all trades, master of none |
| **Laser** | Mouth laser | Speed king — insane dig speed, short base range | Short range without Range stat investment |
| **Butt Acid** | Turn around, spray acid | Area control — acid lingers 2-3s, keeps dissolving dirt. Medium base range. | Need to face away from target, delayed full effect |
| **Explosion** | AOE bomb | Size king — massive AOE burst. Range AND Radius both increase blast size. | Point-blank, no directional control, slower recharge |

**Dig method toggle:** Basic bite is always available alongside your chosen method. Pick Explosion but need precision tunneling? Switch to basic bite.

**Stat Interaction per Method:**

| Method | Range stat does | Speed stat does | Radius stat does |
|--------|----------------|-----------------|------------------|
| **Gun** | Bullet travels further | Fire rate up | More dirt removed per hit |
| **Laser** | Beam reaches further (BIG deal for Laser) | Beam fires faster (more DPS) | Beam removes wider dirt area |
| **Butt Acid** | Spray reaches further | Spray cooldown faster, more acid pools | Acid splash area larger |
| **Explosion** | Blast size bigger (same as Radius) | Faster recharge between explosions | Blast size bigger (same as Range) |

### COLONY

Worker ant upgrades. Miners get their **OWN** dig method pick, independent from the player's choice.

**Upgrade order (top to bottom in panel):**

| Upgrade | Type | Effect |
|---------|------|--------|
| Unlock Workers | Standard | Unlocks miners and haulers. |
| Scaling Miner Strength | Standard (0/50) | Miner dig damage scales with terrain difficulty. Cross-colony persistence after tier 50. |
| Ant Move Speed | Standard (0/10) | All worker ants move faster. |
| Ant Haul Capacity | Standard (0/10) | Haulers carry more food per trip. Base 5, +1 per tier, max 15. |
| Relay Chain / Food Singularity / Ant Cannon | **Pick 1 of 3** | Mid-game hauling efficiency. |
| Miner Dig Range / Speed / Radius | **Pick 2 of 3** (each 0/10) | Same stat types as player but for miners. Independent choice. |
| Miner Gun / Laser / Butt Acid / Explosion | **Pick 1 of 4** | Same dig methods as player but for miners. Independent choice. |

**Hauling Efficiency — Pick 1 of 3:**

| Option | How It Works | Strengths |
|--------|-------------|-----------|
| **Ant Cannon** | Physical turret placed at base. Haulers deposit food, walk to turret, get launched toward nearest food cluster. Ants STICK to whatever surface they hit. Toggle AI-aimed or player-aimed. | Active, exciting. Rewards clean tunnel design. |
| **Food Singularity** | Unclaimed exposed food slowly slides along the ground toward home, following the hauler flow field. Passive, always-on. Toggleable on/off. | Passive, magical. Reduces hauler trips. |
| **Relay Chains** | Haulers form bucket brigades. Partial transfers on contact based on capacity. Lighter hauler walks back for more. More haulers = shorter segments = faster flow. | Team coordination. Visually adorable. |

### LOGISTICS

Transport infrastructure, colony logistics, and player traversal. All transport infrastructure is **free to place** once unlocked.

**Upgrade order (top to bottom in panel):**

| Upgrade | Type | Effect |
|---------|------|--------|
| Place Dirt | Standard | Place dirt blocks to build ramps/bridges/walls. **First unlock in Logistics.** |
| Transport Capacity | Standard (0/10) | More cars/units per transport route. |
| Lift / Minecart / Platform / Zip Line | **Pick 1 of 4** | Transport Tier 1. |
| Pheromone Highways | Standard | All ants + player leave pheromone trails. Well-traveled routes give speed boost. |
| Auto Conveyor | Standard (Toggleable) | Auto-extends a slow conveyor belt from your food pile toward the furthest active mine. |
| Aerial Tramway / Conveyor Belt | **Pick 1 of 2** | Transport Tier 2: food-only transport optimization. |
| More Legs / Grapple Hook / Jetpack / Jump+Dash | **Pick 1 of 4** | Player Traversal. |
| Teleporters / Pneumatic Tubes | **Pick 1 of 2** | Endgame Transport. |

**Transport Tier 1 — Pick 1 of 4:**

| Option | Directions | Speed | Best For |
|--------|-----------|-------|----------|
| **Lift** | Vertical (up/down) | Fast | Deep vertical mining colonies |
| **Minecart** | Horizontal (left/right) | Fast | Wide horizontal tunnel networks |
| **Platform** | 4-directional (NSEW) | Slowish | Flexible general-purpose |
| **Zip Line** | Diagonal | Fast down, slow up | Diagonal shortcuts, uses gravity |

**Transport Tier 2 — Pick 1 of 2 (food only):**

| Option | Routing | Speed | Limitation |
|--------|---------|-------|------------|
| **Aerial Tramway** | Crosses open air between pylons | Medium-slow | Needs line-of-sight between pylons |
| **Conveyor Belt** | Follows any solid surface (floor, wall, ceiling) | Fast | Needs unbroken surface, can't cross gaps |

**Player Traversal — Pick 1 of 4:**

| Option | Fantasy | Speed | Natural Limitation |
|--------|---------|-------|--------------------|
| **More Legs (Mega Speed)** | The Flash | Very fast | Needs surfaces — can't cross gaps |
| **Grapple Hook** | Spider-Man | Fast (burst) | Can't hover — needs target wall within range |
| **Jetpack** | Helicopter | Medium | Can hover — slower but works anywhere |
| **Mega Jump + Mega Dash** | Mario | Moderate | In-air dash. Limited height/distance |

**Endgame Transport — Pick 1 of 2:**

| Option | Range | Count | Who Uses It |
|--------|-------|-------|-------------|
| **Teleporters** | Unlimited | **1 pair** | Player + food + haulers |
| **Pneumatic Tubes** | Unlimited | Unlimited | Food only |

### RAINBOW FOOD — Endgame Cheat Menu

Found extremely rarely at distances 16000+. Need 10-30 rainbow food per unlock.

**"Over the Rainbow" — Endgame Gate:**
Very expensive standard purchase at the **bottom of the Player tab** in the Evolve menu. Buying it **unlocks the rainbow food menu button.**

**LOGISTICS** (3 tiles)

| Unlock | Cost | Effect |
|--------|------|--------|
| Hive Mind | 30 | All ants can mine AND haul (closest task priority). |
| Speed of Light | 25 | All transport infrastructure runs 2-5x faster. |
| Global Conveyor | 20 | Auto-generated optimal transport route through entire tunnel network. |

**POWER FANTASY** (5 tiles)

| Unlock | Cost | Effect |
|--------|------|--------|
| Quantum | 30 | Indestructible rocks act as empty space for the queen. |
| Auto Attack | 25 | Auto-dig toggle — queen passively digs wherever she's facing. |
| Auto-Pilot | 20 | Auto-move toggle — queen automatically moves forward. |
| Giant Queen | 25 | Queen becomes 5x bigger. Digs proportionally bigger. |
| Void Storage | 20 | Queen's food instantly stored on pickup, no carrying. |

**COSMETIC** (6 tiles)

| Unlock | Cost | Effect |
|--------|------|--------|
| Big Head | 10 | All ants have comically oversized heads. |
| Big Ant | 10 | All ants grow ~2x larger. |
| Rainbow Trail | 15 | Queen leaves a rainbow trail. **Mutually exclusive with Fire Trail.** |
| Fire Trail | 15 | Queen leaves a fire trail. **Mutually exclusive with Rainbow Trail.** |
| Boogie Bomb | 10 | Toggle — all ants stop and dance when active, resume when toggled off. |
| Ant Colors | 10 | Unlock ant color customization palette. |

### Build Combinations Summary

**Total unique builds: 3 x 4 x 4 x 2 x 4 x 3 x 2 x 3 x 4 = 27,648 combinations.** Each colony is genuinely different.

### Upgrade Cost Scaling
Idle game standard: each upgrade tier costs ~3-5x the previous. Creates natural plateaus. Exact values need balance tuning through playtesting.

---

## Worker Ants

### Basics
- Hatched by spending food (requires "Unlock Workers" upgrade)
- Much smaller than the Queen (~0.5x her size)
- Same basic ant shape but simpler (less detail at distance)
- **Autonomous** — they do their jobs without player input

### No Worker Deletion — Engineering Solves Performance

**You cannot delete, release, or remove workers. Ever.** Every ant you hatch is permanent.

**Performance is handled by the game, not the player:**

- **Auto-hibernate system:** When FPS dips below a threshold, far-from-camera workers enter hibernate mode — simplified AI (just timers, no pathfinding), skip rendering. They still "exist" and do their jobs, just cheaply. Workers wake back up when performance recovers.
- **Unity implementation:** Disable SpriteRenderer + skip Update() for hibernated ants. Use Job System for batch processing hibernated ant timers.
- **Target: 1000+ ants before hibernate kicks in.** If the game can't sustain 1000 active ants, that's an engineering problem to solve in Phase 1.
- **DOTS/ECS migration:** If MonoBehaviour-based ants hit a ceiling, migrate ant simulation to Unity DOTS (Entity Component System) for cache-friendly, burst-compiled mass entity updates.

**Performance Warning System:**
- FPS drops below 45 → subtle yellow indicator near worker count
- FPS drops below 30 → red warning
- Informational only — no hard block
- **Toggleable in options menu.**

### Worker Roles — Permanent Commitment

**When you buy an ant, you choose: Miner or Hauler. That choice is permanent. No swapping.**

**Two specialized roles:**

**Miners** — dig DIRT toward food sources (and expand the frontier)
```
IDLE → FIND_NEAREST_DIRT_NEAR_FOOD → TRAVEL → DIG_DIRT → [food exposed?] → FIND_NEXT_TARGET → repeat
```
- Target: dirt blocks adjacent to food
- **Max 5 miners per dirt block** (stacking cap)
- **Spread logic:** Miners prefer blocks with fewer miners already on them.
- **Miners expand the frontier.** They dig NEW tunnels into unexplored dirt on their own.
- **Miners never touch food** — that's the hauler's job

**Haulers** — pick up exposed food, carry to pile (or loading station)
```
IDLE → FIND_NEAREST_EXPOSED_FOOD → TRAVEL_TO_FOOD → PICK_UP → TRAVEL_TO_PILE_OR_STATION → DEPOSIT → repeat
```
- **Base carry capacity: 5 food.** Haul Capacity upgrade (0/10) adds +1 per tier → max **15 food.**
- **Haulers are SLOW** — significantly slower than miners, especially when carrying food
- **Graduated speed penalty:** `speed_multiplier = 1.0f - (food_carried / max_capacity) * 0.6f`. At max load = 40% speed.
- If transport infrastructure exists, haulers go to nearest **loading station** instead of the pile

**Hauler AI — Claiming System (Blackboard Pattern):**
Central **Food Manager** singleton runs every ~0.5 seconds, coordinating all haulers:
- Assigns nearest unclaimed food to idle haulers
- **Claims** prevent two haulers targeting the same food piece
- **Proximity-based claim stealing:** closer hauler steals claim from distant hauler

### Worker Pathfinding (Performance Critical)
- **NOT A* for every worker every frame** — way too expensive
- **Flow field** pathfinding — precalculated per chunk, updated when terrain changes
- **Unity implementation:** NativeArray-based flow fields computed via Job System + Burst Compiler. Cache-friendly data layout for thousands of simultaneous reads.
- **Staggered updates** — not all workers recalculate paths on the same frame
- **Off-screen workers** — simplified simulation (just increment timers, don't animate)
- **Spatial hashing** for proximity queries (which ants are near this food? Which miners are near this tile?)

---

## Automation Progression

This is the idle game heart. The player goes from doing everything manually to being an overseer.

### Stage 1: Manual (0-15 min)
- You dig alone, you carry food alone, you are the entire colony

### Stage 2: Helpers (15-30 min)
- First workers hatched. They gather food from tunnels you've already dug.

### Stage 3: Castes (30-60 min)
- Miner and hauler specializations. Each new egg: choose role (permanent).

### Stage 4: Transport Tier 1 (1-2 hours)
- Lift / Minecart / Platform / Zip Line automatically ferry food through tunnels.

### Stage 5: Conveyor Belts + Tramways (2-4 hours)
- Passive transport — food flows along belts, tramways cross caverns.

### Stage 6: Mid-Game Automation (3-5 hours)
- Architect Ant, Auto Evolve, Auto Worker handle tedious stuff.
- Hauling Efficiency fork: Ant Cannon / Food Singularity / Relay Chains.

### Stage 7: Endgame Transport (5-8 hours)
- Teleporters OR Pneumatic Tubes for food shortcuts.

### Stage 8: Over the Rainbow + Cheat Menu (8+ hours)
- Rainbow food, absurd power fantasy upgrades. The colony runs itself.

---

## Named Ants System

### Customize Screen (Click Any Ant)
- **No upgrade needed.** Click any ant to customize it.
- Same screen for workers and queen, with minor differences.

**Layout:** Banner "CUSTOMIZE", Name input, Ant preview, Color palette (locked behind rainbow food upgrade), Hat collection (queen) or Give Hat button (worker), SAVE / CANCEL.

### Achievement Ants (Special Reward Units)

| Achievement | Reward Ant | Visual |
|------------|-----------|--------|
| Hatch your first worker | **Greg** (the OG) | Subtle glow |
| Reach yellow food zone (dist 200) | **Digsby** | Yellow tint |
| Have 10 workers | **Sarge** | Slightly bigger |
| Reach blue food zone (dist 1000) | **Frostbite** | Blue shimmer |
| Total 1,000 food collected | **Atlas** | Green glow |
| Build first transport system | **Conductor** | Tiny hat |
| Reach obsidian zone (dist 8000) | **Shadow** | Dark with white outline |
| Find rainbow food (dist 16000) | **Prisma** | Rainbow shimmer |

---

## Hats (Collectible Cosmetics)

- Random chance to spawn in newly generated terrain layers — max 1 per layer
- Hats are buried in dirt — look like a tiny colored pixel until dug out
- Queen must physically collect it
- **5-10+ hats minimum**, some also purchasable with rainbow food
- Queen can wear one hat at a time, can give hat to named ant via Customize screen
- Purely cosmetic — no stat effects

### Example Hats
Hard Hat, Top Hat, Crown, Propeller Cap, Wizard Hat, Party Hat, Viking Helm, Flower Crown, Astronaut Helmet, Pirate Hat

---

## Prestige System — Build Diversity Model

### Core Philosophy
- **Never feel forced to prestige.** Infinite scaling means you can stay in one colony forever.
- **Old colonies are fully playable save slots.** Return to ANY previous colony.
- **No legacy stat bonuses.** Clean slate every time.
- **Prestige = try a different build.** 27,648 possible combinations.

### Meta-Reward: +1 Starting Worker Per Colony Founded
Each time you found a new colony, you start with +1 basic worker ant.

### What DOES Carry Over
- Dig power scaling progress (tiers 51+)
- Rainbow food currency
- Rainbow cosmetic purchases (immediately available)
- Rainbow gameplay purchases (persist but only activate after buying Over the Rainbow per colony)
- Cosmetics
- Colony count (determines starting worker bonus)

### What Does NOT Carry Over
- No upgrade progress (except dig power)
- No food (regular)
- No worker count (except the +1 per colony bonus)
- No map knowledge, no transport infrastructure

---

## Visual Design

### Terrain
- **Brown dirt** — base, procedural noise texture. NOT flat color.
- **Gradient color shifts** based on distance from origin
- **Food** is always bright orange — strong contrast
- **Tunnels** are very dark brown `new Color(0.12f, 0.08f, 0.05f)`

### Ants
- Geometric: ovals + lines
- Queen: 3 ovals, 6 legs (LineRenderer), 2 antennae, slightly larger. Crown/glow + hat.
- Workers: 2-3 ovals, simplified legs (maybe just 4), smaller.
- At distance (zoomed out): just colored dots with direction indicators.
- **Unity rendering:** SpriteRenderer per ant part, or single procedural sprite, or GPU instanced sprites for mass rendering.

### Food
- **All orange circles** — no color/shape differentiation
- Rainbow food (16000+): rainbow shimmer, pulsing star

### Infrastructure
- Minecart tracks: two parallel lines with cross-ties
- Conveyor belts: animated dashed lines showing direction
- Aerial tramways: pylons with thin wire, gondola hanging from wire
- Pneumatic tubes: faint dotted line through terrain
- Teleporters: two glowing rings with particle effects
- Loading stations: small marked points on transport lines

### UI
- Built with Unity UI (uGUI) + TextMeshPro
- See `ANT_COLONY_UI_REFERENCE_UNITY.md` for complete specs

---

## Performance Strategy

### The Core Challenge
An infinitely expanding world with destructible terrain, hundreds/thousands of worker ants, transport systems, and zoom from micro to macro scale.

### Terrain: Chunk-Based System
- World divided into **chunks** (e.g., 64x64 or 128x128 tiles)
- Only **visible chunks** are rendered (SpriteRenderer or MeshRenderer with Texture2D)
- Chunks generated on-demand when first visible
- Chunks saved to disk when far from camera (`Application.persistentDataPath`)
- **Terrain data** is a 2D byte array per chunk (0 = empty, 1-255 = dirt types)
- Dig operations modify chunk data → update Texture2D → call `Apply()`
- **ComputeShader option:** For GPU-accelerated dig operations on chunk textures

### Rendering: LOD (Level of Detail)
Based on zoom level:

| Zoom Level | Terrain | Ants | Food | Infrastructure |
|------------|---------|------|------|----------------|
| Close (1x) | Full tile detail, noise texture | Full sprite, animated legs, hat | Individual circles | Full detail |
| Medium (2-4x) | Simplified tiles, solid colors | Small dots with direction | Colored dots | Lines only |
| Far (8x+) | Color blocks per chunk | Count number per region | Aggregate glow | Hidden |
| Macro (16x+) | Gradient colors only | Colony density heatmap | Value heatmap | Hidden |

### Entity Management: Ants at Scale

1. **Object pooling** — Use `UnityEngine.Pool.ObjectPool<T>` for ant GameObjects
2. **Off-screen ants don't render** — disable SpriteRenderer when outside camera frustum
3. **Off-screen ants simulate simply** — increment a timer, when timer completes = "food delivered"
4. **Staggered AI updates** — each ant recalculates path on a different frame (spread across N frames)
5. **Flow fields via Job System** — NativeArray-based flow field per chunk, computed with Burst Compiler. All ants read it. Recalculate only when terrain changes.
6. **GPU instancing** — for rendering hundreds of identical ant sprites efficiently. SRP Batcher handles draw call batching.
7. **Spatial hashing** — for proximity queries (NativeMultiHashMap from Collections package)
8. **DOTS/ECS option** — if MonoBehaviour approach hits ceiling, migrate ant data to ECS for cache-friendly updates at massive scale

### Number Scaling
- Use `double` until precision issues (~10^15)
- Display with **suffix notation**: K, M, B, T, Qa, Qi...
- Static utility class for number formatting

### Save System
- **Auto-save** on meaningful actions + timer
- JSON to `Application.persistentDataPath` (JsonUtility or Newtonsoft JSON)
- Chunk terrain data as binary files
- All ant data, upgrade states, transport infrastructure saved
- Settings saved separately (PlayerPrefs or dedicated file)

---

## Research Notes: Patterns Stolen from Idle Games

### From Cookie Clicker
- Workers produce FPS (food per second) → watching counter go up IS the game

### From Gnorp Apologue
- Simple entity AI → entities do ONE thing well
- Visual spectacle from quantity → hundreds of ants doing simple things looks amazing

### From WorldBox
- Chunk-based world → only simulate/render what's visible
- Named entities → player attachment

### From Dome Keeper
- Manual carry → automation feels EARNED

### From Dwarf Fortress / Kingdoms and Castles
- Worker allocation creates meaningful decisions
- Tunnel/layout design is a player SKILL bottleneck

---

## Sound Design Direction (Future)
- Digging: crunchy, satisfying bites (AudioSource + AudioClip pool)
- Food pickup: light "pop" or "pling"
- Depositing food: satisfying "chunk"
- Worker hatching: organic crack/pop
- Zoom out: ambient hum via AudioMixer snapshots
- All managed through Unity's AudioMixer for volume control per category

---

## Build Order (Step by Step)

**BUILD STRATEGY: Vanilla Mode first.** After proving terrain works (Steps 1-5),
build the complete Vanilla Mode ant farm screensaver before any Normal Mode systems.

### Step 1: Terrain + Camera
- Chunk-based destructible 2D terrain (Texture2D per chunk, SetPixels32/Apply)
- Procedural noise (Unity.Mathematics or FastNoiseLite)
- Distance-based color gradient
- Camera follow + zoom (Cinemachine or custom)
- Chunk loading/unloading
- Save/load terrain chunks to disk

### Step 2: Player Ant + Movement
- Queen ant with WASD movement (Input System)
- Wall climbing (raycast-based surface detection)
- Gravity (Rigidbody2D or custom)
- Basic collision with terrain

### Step 3: Digging
- Click to dig in mouse direction
- Dig cooldown between bites
- Multiple bites per block
- Pixel debris particles (Particle System)
- Terrain modification (modify Texture2D, update chunk)
- Hold-duration bite size

### Step 4: Food + Collection
- Procedural food placement
- Food always visible through dirt
- Food exposed when surrounding dirt dug away → pops out
- Walk over food to pick up, stacks on ant body
- Carry capacity limit + food physics (Physics2D.Raycast downward)

### Step 5: Food Pile + Deposit
- Starting chamber with food pile
- Warm glow gradient deposit zone
- Walk to pile to deposit
- Food counter UI (TextMeshProUGUI with suffix notation)
- Pile grows visually

### Step 6: Upgrade Menu + First Upgrades
- Evolve menu (uGUI Canvas overlay)
- Auto Mining, Scaling Dig Strength (0/50)
- Dig Range / Speed / Radius (pick 2 of 3, 0/10 each)
- Food Magnet + Carry Capacity + Player Speed
- Place Dirt

### Step 7: Dig Methods
- Gun / Laser / Butt Acid / Explosion (pick 1 of 4)
- Distinct visuals, projectiles, AOE for each

### Step 8: Worker Ants + Naming
- Unlock Workers upgrade
- Egg hatching (spend food → choose Miner or Hauler, permanent)
- Miner AI + Hauler AI
- Customize screen (click ant → name, color, hat)
- Achievement ant: Greg

### Step 9: Miner Upgrades
- Scaling Miner Strength (0/50)
- Miner Dig Range / Speed / Radius (pick 2 of 3)
- Miner Dig Method (pick 1 of 4)
- Ant Haul Capacity (0/10), Ant Move Speed (0/10)

### Step 10: Transport Tier 1
- Lift / Minecart / Platform / Zip Line (pick 1 of 4, free to place)
- Loading stations

### Step 11: Transport Tier 2
- Aerial Tramway / Conveyor Belt (pick 1 of 2, food only)

### Step 12: Player Traversal
- Mega Speed / Grapple Hook / Jetpack / Jump+Dash (pick 1 of 4)

### Step 13: Mid-Game Automation Trio
- Auto Worker, Architect Ant, Auto Evolve

### Step 14: Hauling Efficiency Fork
- Ant Cannon / Food Singularity / Relay Chains (pick 1 of 3)
- Auto Conveyor

### Step 15: Endgame Transport
- Teleporters / Pneumatic Tubes (pick 1 of 2)

### Step 16: Hats + Achievements
- Hats spawn randomly in new terrain layers
- Achievement ants
- Hat collection / cosmetics

### Step 17: Over the Rainbow + Cheat Menu
- Rainbow food at extreme distances
- Rainbow food tab with power fantasy unlocks
- Dig Power cross-colony persistence

### Step 18: Polish
- Sound design (AudioMixer + AudioSource pooling)
- Particle effects (Particle System / VFX Graph)
- Performance optimization pass (Profiler, Job System, Burst)
- Full save system verification
- Dev menu testing

---

## Open Questions

1. **Hatching cost curve:** Exact formula for egg cost scaling. Determined through playtesting.
2. **Upgrade costs/balance:** All numbers need playtesting. Dev menu enables rapid iteration.
3. **Pixel terrain implementation:** Texture2D per chunk vs ComputeShader vs hybrid. Needs prototyping.
4. **Grapple hook range:** Needs playtesting.
5. **Dig method balance:** Needs playtesting.
6. **Ant Cannon tuning:** Range, trajectory physics. Needs prototyping.
7. **Rainbow food rarity:** How often, how many per unlock. Needs playtesting.

---

## Dev Menu (Testing Tool)

**Required for development.** Can't playtest a multi-hour idle game by playing hundreds of hours.

- **Give food** / **Give rainbow food**
- **Hatch N workers** (instant, free, choose role)
- **Unlock all upgrades** / unlock specific upgrade
- **Set distance** (teleport queen)
- **Speed multiplier** (2x/5x/10x via `Time.timeScale`)
- **Reset colony**
- **Toggle debug overlays** (Gizmos or debug Canvas for pathfinding, flow fields, worker targets)

Access via F12 or backtick. Wrap in `#if UNITY_EDITOR || DEVELOPMENT_BUILD` to strip from release.

---

## Technical Research Needed

### 1. Pixel Terrain in Unity (CRITICAL)
- **What:** Pixel-granular destructible terrain via Texture2D per chunk
- **Unity approach:** `Texture2D.SetPixels32()` + `Apply()` per chunk. ComputeShader for GPU-side modification.
- **Performance:** Only update dirty chunks. Minimize `Apply()` calls (batch modifications).
- **Alternative:** RenderTexture + ComputeShader for fully GPU-side terrain.

### 2. Procedural Terrain Generation
- **What:** Noise for dirt, food cluster placement, rock formations
- **Unity approach:** `Unity.Mathematics.noise` or FastNoiseLite package
- **Key question:** How to make food placement feel designed, not random?

### 3. Ant Pathfinding at Scale
- **What:** Hundreds/thousands of ants navigating destructible terrain
- **Unity approach:** Flow fields via Job System + Burst Compiler. NativeArray for data. Staggered updates.
- **Key question:** How to efficiently recompute flow fields when terrain changes?

### 4. Chunk System + LOD
- **What:** Loading/unloading terrain chunks, multi-resolution for zoom
- **Unity approach:** Custom chunk manager, multi-resolution Texture2D cache
- **Key question:** How many resolution levels? Smooth LOD transitions?

### 5. Food Physics
- **What:** Lightweight falling when support removed
- **Unity approach:** Event-driven on dig, `Physics2D.Raycast()` downward to find floor

### 6. Transport Infrastructure
- **What:** How transport works in pixel terrain
- **Unity approach:** Snap to tile grid underlying pixel terrain

### 7. Idle Game Economy Math
- **What:** Cost curves, scaling formulas
- **Research:** Cookie Clicker, Idle Miner Tycoon progression curves

### 8. Auto-Buy Systems
- **What:** Auto Worker and Auto Evolve
- **Key question:** Priority when multiple affordable?

### 9. Performance Optimization (CROSS-CUTTING)
- **Target:** 500+ ants + pixel terrain + transport + food physics at 60fps
- **Unity tools:** Profiler, Frame Debugger, Job System, Burst Compiler, SRP Batcher
- **Nuclear option:** DOTS/ECS migration for ant simulation
- **Key budget:** CPU (AI/pathfinding via Jobs), GPU (terrain rendering via batching), Memory (chunk storage)
