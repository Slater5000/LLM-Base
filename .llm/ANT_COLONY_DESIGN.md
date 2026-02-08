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

---

## The World

### Starting State
- Entire screen is **solid brown dirt**
- Center of screen: a small **half-circle chamber** (flat bottom, curved top)
- Inside the chamber: **the Queen Ant** (player) — noticeably larger than worker ants introduced later
- **Food pile** in center of chamber — starts with ~5 orange food bits
- Food pile has a **red circle radius indicator** on the floor showing its collection zone
- The floor under the food pile and starting chamber is **indestructible**
- Tunnel background is **black** (or dark — TBD). Empty space = black. Dirt = brown. Clean contrast.

### Terrain System
- **Procedurally generated** using noise functions (Perlin/Simplex)
- Food (orange circles) embedded in dirt, distributed throughout:
  - Individual scattered pieces (common)
  - Small clusters of 3-8 (uncommon)
  - Large veins of 10-20+ (rare, like Minecraft ore veins)
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

### Distance-Based Gradient System (No Hard Layers)

Instead of discrete concentric layers with hard borders, terrain difficulty and food types are based on **distance from the starting chamber** with smooth gradient transitions.

**How it works:**
- `distance_from_origin` determines everything: dirt hardness, dirt color, food tier probabilities
- Colors blend smoothly — brown gradually shifts to tan, then darker, etc.
- Food tiers have **probability curves** — further out = rarer food more common, common food less common
- No visible borders between "zones" — just gradual transitions
- **Milestone distances** exist where new food types first appear (discovery moments: "ooh what's THAT color?")

**Distance Scaling:**

| Distance | Dirt Color Shift | Dig Difficulty | Dominant Food | New Food Introduced |
|----------|-----------------|----------------|---------------|-------------------|
| 0-200 | Brown | 1x (1-2 bites) | Orange (1) | — |
| 200-500 | Brown → Tan | 2-3x | Orange + Yellow (5x) | Yellow |
| 500-1000 | Tan → Dark Brown | 4-6x | Yellow + Red (25x) | Red |
| 1000-2000 | Dark Brown → Clay Grey | 8-12x | Red + Blue (100x) | Blue |
| 2000-4000 | Grey → Dark Grey/Stone | 16-24x | Blue + Purple (500x) | Purple |
| 4000-8000 | Stone → Slate | 32-48x | Purple + Green (2,500x) | Green |
| 8000-16000 | Slate → Obsidian | 64-96x | Green + White (10,000x) | White |
| 16000+ | Obsidian + Crystal Veins | 128x+ (exponential) | White + Rainbow | Rainbow (endgame currency) |

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

### Controls
- **WASD** — Movement (left, right, up, down)
- **Mouse Click (Left)** — Dig in aimed direction
- **Hold Mouse Click** — Auto-mine (continuous digging at cooldown rate)
- **Mouse position** — Aim direction for digging
- **Scroll Wheel** — Zoom in/out
- **Tab / E** — Open upgrade menu
- **Q** — Place dirt (reverse dig, build ramps/bridges) — requires Dirt Placement upgrade
- **1-3 / Mouse Wheel Click** — Toggle bite size (small / medium / large)

### Movement Rules
- **Wall climbing** — Ants stick to any surface (floor, walls, ceiling)
- **No jumping at start** — unlockable via Jump Boots upgrade
- **Traversal solution** — Place dirt to create climbable surfaces / ramps / bridges (requires upgrade)
- **Gravity** — Ants fall if not touching a surface (unless Jetpack upgrade)
- Movement speed upgradeable

### Digging
- Click in a direction → Queen bites/digs a chunk of dirt in that direction
- **Dig has a cooldown** between bites (prevents auto-clicker cheese). Upgrades reduce cooldown.
- **Hold click = auto-mine** — continuously digs at cooldown rate, no spam clicking
- Dirt takes **multiple bites** to remove (based on distance-difficulty vs dig power)
- Visual: chomping animation, dirt particles fly off
- **Bite size toggle:** switch between small (precise), medium, large (endgame AOE)
  - Small: 1-2 tile radius. Precise tunneling, detail work
  - Medium: 3-4 tile radius. Standard mining
  - Large: 6+ tile radius. Blast mining (unlocked late)
- **Dig speed** = cooldown reduction (starts slow, upgradeable)
- **Critical strike chance** — random instant-break on a block (satisfying proc)
- When all dirt around a food piece is removed, the food pops out and can be collected
- **Endgame upgrades:** Super Mandibles (one-bite anything), Mega Bite (massive AOE) — power fantasy

### Carrying
- Touch exposed food → it attaches to top of Queen's body
- **Carry capacity** starts at 3-5 pieces
- Food visually stacks on the ant
- Must return to food pile to deposit
- **Upgradeable progression:**
  - More carry slots (Bigger Backpack tiers)
  - Food compression (each carried piece worth more)
  - Void storage (food auto-deposits on pickup, no return trips — endgame)

---

## Food System

### Food as Primary Currency
- **Orange food** (base tier) — the standard unit
- Higher-tier food from further out is worth exponentially more
- All food converts to a single currency number at the food pile
- Food pile visually grows as you deposit more (small pile → medium mound → large hill → overflowing)
- **No storage cap.** Unlimited. Let the number grow forever.

### Rainbow Food — Endgame Currency (SEPARATE)
- **Rainbow food is NOT just "better food"** — it is its own separate currency
- Found only at extreme distances (16000+)
- Has its own upgrade menu / section (not mixed with regular food upgrades)
- Used for endgame-only special upgrades
- Cannot be converted to regular food or vice versa
- Extremely rare — finding one is an event

### Food Pile
- Located in the starting chamber
- **Red circle radius** — shows collection zone
- Workers automatically deposit food here when they enter the radius
- Radius is upgradeable (larger = workers deposit from further away)
- Indestructible floor — can never lose your pile

### Food Bank / Vault
- Unlockable upgrade: stored food generates **passive interest**
- Small percentage per minute (0.1% → 0.5% → 1% with upgrades)
- **Only runs while the game is open** — no offline progression
- Creates "your money makes money" loop while you're actively playing

### Food Tiers (Visual + Value)

| Tier | Name | Color | Value | Distance Found | Shape |
|------|------|-------|-------|----------------|-------|
| 1 | Crumbs | Orange | 1 | 0+ | Small circle |
| 2 | Honey | Yellow | 5 | 200+ | Slightly larger circle |
| 3 | Meat | Red | 25 | 500+ | Oval |
| 4 | Fungi | Blue | 100 | 1000+ | Circle with spots |
| 5 | Crystal | Purple | 500 | 2000+ | Diamond shape |
| 6 | Nectar | Green | 2,500 | 4000+ | Droplet |
| 7 | Pearl | White | 10,000 | 8000+ | Glowing circle |
| — | **Rainbow** | Rainbow shimmer | **Endgame currency** | 16000+ | Pulsing star |

### Ant Egg Colors
Real ant eggs are **white/cream/translucent**. So:
- **Ant eggs: White/cream** (when we show hatching visuals)
- **Food: Orange** (strong contrast against brown dirt AND white eggs)

### Food Visibility — 3-Stage Detection System

Food embedded in dirt is **NOT visible by default.** You can't see through dirt. Food only becomes visible as you get close to it.

**Stage 1: Hidden (default)**
- Food in undug dirt looks exactly like dirt. No visual indication whatsoever.
- You have to dig to find it. Random discovery creates exploration dopamine.

**Stage 2: Hint Glow (detection radius)**
- When the queen or a miner gets within a **detection radius** of hidden food, the food block emits a **dim periodic glow** through the dirt.
- Like a faint pulse — "something is nearby." Direction is ambiguous; you know food is CLOSE but not exactly where.
- Detection radius starts small (~3-5 tiles), upgradeable.
- Creates an upgrade path: "I want to see food from further away" → buy detection range upgrades.

**Stage 3: Fully Revealed (very close)**
- When within ~1-2 tiles, food is fully visible through the dirt — bright color, clear shape.
- At this point you know exactly where to dig.

**Upgrades that improve detection:**
- Mining tab could include "Food Sense I-III" → increase detection radius
- Endgame: "Omniscience" → all food visible always (removes the system entirely as a power fantasy)

**Why this works:**
- Creates genuine exploration — you don't know what's ahead until you get close
- Natural upgrade path that feels meaningful
- Early game feels like real discovery; late game feels like omniscient oversight
- Miners pushing the frontier also push the detection boundary — they reveal food as they dig

---

## Upgrade System

### Structure: Category Tabs
Open with **Tab/E** at any time (pauses or overlays). Tabs across the top, each with its own upgrade list. Spend **food currency** to unlock nodes. Some nodes have prerequisites.

**Rainbow Food upgrades** are a separate section/tab — only visible once rainbow food has been found.

**Transport infrastructure is FREE to place once unlocked.** You spend food to unlock the UPGRADE (e.g., "Minecart System"), then you can place unlimited track/carts for free. No per-piece cost. Building the network is the fun part, not the tax.

### Two Upgrade Tiers

The upgrade system has two distinct layers:

**1. Build Choice Nodes (Mutually Exclusive — Pick 2 of 3)**
- Scattered throughout the upgrade tree at key progression points
- Each presents 3 options — you can only pick 2, permanently locking out the 3rd
- These are the **meaningful, gameplay-defining** choices that create your colony's identity
- All 3 options in a node are balanced — no dominant choice
- All percentage-based (not flat additive) so they don't scale with starting worker count
- Worker-count Build Choices only compete against other worker-count choices, placed late in tree
- **This IS the build diversity system.** Different colonies = different builds = reason to prestige.

**2. Standard Upgrades (Available to All Builds)**
- Normal tiered upgrades everyone can buy regardless of build choices
- Includes the **infinite scalers** for endgame grinding: worker speed, dig power, transport efficiency
- These are the "numbers go up" upgrades — less about identity, more about progression
- After you've chosen your build, this is what you keep investing in forever
- Three infinite scaling categories map to the three bottlenecks: **dig speed, transport speed, worker efficiency**

**Progression flow:**
```
EARLY GAME: Buy standard upgrades → encounter first Build Choice → commit to a direction
MID GAME: More standard upgrades + more Build Choices → build identity solidifies
LATE GAME: All Build Choices made → colony has a clear identity
ENDGAME: Infinite scalers → keep pumping the three bottlenecks forever
```

### Tab 1: MINING (Personal Dig Power)

| # | Upgrade | Effect | Notes |
|---|---------|--------|-------|
| 1 | Sharp Mandibles I-V | Reduces dig cooldown (faster bites) | Core progression, many tiers |
| 2 | Wide Bite I-III | +50/100/200% dig radius | Bigger chomp area |
| 3 | Bite Size Toggle | Switch between small/medium/large bite | Precision vs speed |
| 4 | Auto-Mine | Hold click to continuously dig at cooldown rate | QoL, no more click spam |
| 5 | Critical Strike I-III | 5/15/30% chance to instant-break a block | Satisfying random procs |
| 6 | Food Magnet I-III | Exposed food flies to you (range 50/150/infinite) | No more chasing loose food |
| 7 | Fortune I-III | 1 food block yields 2/3/5 food | Yield multiplier |
| 8 | TNT / Explosives | Placeable charges, blast huge areas | Manual but powerful |
| 9 | Mining Range Extension I-III | Dig blocks from further away | Don't need to be touching |
| 10 | Food Sense I-III | Increase food detection radius (see Food Visibility system) | See food through dirt from further away |
| 11 | Super Mandibles | One-bite anything regardless of hardness | Endgame power fantasy |
| 12 | Mega Bite | Massive AOE dig per click | Endgame power fantasy |

### Tab 2: MOVEMENT (Getting Around)

| # | Upgrade | Effect | Notes |
|---|---------|--------|-------|
| 1 | Speed Boots I-V | +20% movement speed per tier | Core mobility |
| 2 | Dirt Placement | Place dirt blocks (build ramps/bridges) | Traversal tool |
| 3 | Jump Boots | Enable jumping across gaps | Unlock basic jumping |
| 4 | Jump-Dash | Jump + forward momentum boost | Extension of Jump Boots |
| 5 | Jump Height I-III | Higher jumps per tier | Vertical mobility |
| 6 | Grappling Hook | Swing across caverns, attach to any surface | Fun traversal, every game needs one |
| 7 | Jetpack | Hover/fly vertically | Full vertical freedom |
| 8 | Elevator Shafts | Build instant vertical travel points | Infrastructure |
| 9 | Minecart Rider | Ride minecart/train rails personally | Fast travel on built tracks |
| 10 | Teleport Waypoints | Set beacons, warp between them | Instant travel |

### Tab 3: STORAGE (Carrying Stuff)

| # | Upgrade | Effect | Notes |
|---|---------|--------|-------|
| 1 | Bigger Backpack I-V | +3/5/10/20/50 carry capacity | Core storage progression |
| 2 | Food Compression I-III | Carried food counts as 2x/5x/10x value | More value per trip |
| 3 | Quick Deposit | Faster deposit animation at pile | QoL speed |
| 4 | Auto-Deposit Radius | Deposit food by walking near pile (radius) | Don't need to touch pile |
| 5 | Void Storage | Food instantly stored on pickup, no carrying | Ultimate storage upgrade |
| 6 | Food Bank I-III | Passive interest on stored food (0.1/0.5/1%) | Money makes money (while game is open) |

### Tab 4: LOGISTICS (Automated Transport)

All infrastructure is **free to place** once unlocked. The upgrade cost IS the gate.

| # | Upgrade | Effect | Notes |
|---|---------|--------|-------|
| 1 | Minecart System | Build tracks, place carts. Batch transport, medium speed. Player can ride. | First real transport. Must be on solid ground. |
| 2 | Train Upgrade | Better minecart — carries more food, moves faster. Same rails. | Direct upgrade to minecart. |
| 3 | Conveyor Belts | Constant passive flow in one direction. Drop food on, it slides to the end. | Set and forget. Surface only. |
| 4 | Aerial Tramway | Cable between two anchor points. Gondola crosses open caverns. | Only transport that works over gaps. |
| 5 | Pneumatic Tubes | Near-instant transport through pipes. Can go through walls. | Expensive but fast. Any direction. |
| 6 | Cargo Drones | Flying units that ferry food to storage. No path needed. | Ignore terrain entirely. |
| 7 | Teleporters | Instant point-to-point for food AND player. | Ultimate transport. |

**Worker interaction with transport:** Workers dump food at **loading stations** (marked points on tracks/belts). The transport system picks it up and delivers to the pile. Workers only need to pathfind to the nearest loading station, not all the way back to the pile. This simplifies their AI significantly.

### Tab 5: COLONY (Worker Ants)

| # | Upgrade | Effect | Notes |
|---|---------|--------|-------|
| 1 | Lay Eggs I-V | Unlock egg hatching. Each egg costs food → choose Miner or Hauler → permanent ant. | Core progression. Choice is permanent. |
| 2 | Worker Speed I-V | All workers move faster per tier | Core mobility stat |
| 3 | Miner Caste | Unlock miner specialization (choose "Miner" when hatching) | Must unlock before you can hatch miners |
| 4 | Miner Strength I-III | Miners can dig through harder terrain per tier | Scale their ability |
| 5 | Hauler Caste | Unlock hauler specialization (3x carry capacity, slightly slower) | Must unlock before you can hatch haulers |
| 6 | Smarter AI I-III | Workers path more efficiently / prioritize higher-value food | Intelligence upgrade, not just speed |
| 7 | Manager AI | Workers auto-optimize behavior. Full idle automation. | Endgame — no babysitting |

### Tab 6: ENDGAME (Rainbow Food Currency)

Only visible once rainbow food has been discovered. **Separate currency, separate upgrades.**

| # | Upgrade | Effect | Notes |
|---|---------|--------|-------|
| 1 | Omniscience | All food visible through dirt at any distance | Removes Food Visibility system — power fantasy |
| 2 | Architect Ant | Unlock colony room system — dig specific shapes for bonus chambers | Gameplay-defining endgame feature |
| 3 | Ant Customization | Change individual ant colors, patterns, accessories | Cosmetic — Rainbow Greg is the dream |
| 4 | Colony Themes | Unlock background themes (space, crystal, underwater, ice, lava) | Cosmetic — carries across colonies |
| 5 | Time Warp | 2x simulation speed toggle | QoL — makes late-game grinding faster |
| 6+ | TBD | Additional endgame upgrades designed as needed | Design expands once core game works |

**Endgame infinite scalers (food currency, not rainbow):**
These live in the standard upgrade tabs but have no cap. After all Build Choices are made, these are what you keep buying:
- **Dig Power ∞** — infinite tiers of dig speed/strength (Mining tab)
- **Transport Speed ∞** — infinite tiers of transport throughput (Logistics tab)
- **Worker Efficiency ∞** — infinite tiers of worker speed/carry (Colony tab)

These three map directly to the three bottlenecks. Endgame = choose your build, then pump the bottlenecks forever.

### Upgrade Cost Scaling
Idle game standard: each upgrade tier costs ~3-5x the previous. Creates natural plateaus where the player needs to push further out to afford the next upgrade. Exact values need balance tuning.

---

## Worker Ants

### Basics
- Hatched by spending food (Lay Eggs upgrade)
- **All ants are permanent** — once hatched, they exist forever in your colony
- Much smaller than the Queen (~0.5x her size)
- Same basic ant shape but simpler (less detail at distance)
- **Autonomous** — they do their jobs without player input

### Worker Roles — Permanent Commitment

**When you hatch an ant, you choose: Miner or Hauler. That choice is permanent. No swapping.**

This is a one-time purchase decision, not ongoing micromanagement. Overinvested in miners? Buy more haulers. The bottleneck naturally shifts, and you address it by buying more of what you need. You never open a "reassign workers" menu. Buy it and move on.

**Before caste unlock:** All hatched ants are basic gatherers (pick up exposed food, carry to pile, can't dig).

**Unassigned workers can be assigned later.** When you unlock Miner Caste or Hauler Caste, any existing unassigned basic gatherers can be promoted via a **slider UI**: "Assign your unassigned workers" → drag slider to split between Miners and Haulers → confirm. Assignment is still permanent — you're just deferred on the choice until the role exists. New workers hatched AFTER caste unlock choose at hatch time as before.

**Two specialized roles (unlockable):**

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

### Stage 4: Minecarts + Trains (1-2 hours)
- Place tracks in your main tunnels (free after unlock)
- Carts/trains automatically ferry food along rails
- Workers dump food at loading stations instead of walking all the way back
- **VISUAL PAYOFF** — watching little trains zip through your tunnels

### Stage 5: Conveyor Belts + Tramways (2-4 hours)
- Passive transport — food just flows along belts
- Tramways cross open caverns on cables
- Workers dump food on belts/tramways, transport carries it to pile
- Player designs transport networks

### Stage 6: Tubes + Drones (4-8 hours)
- Pneumatic tubes through walls — near-instant
- Drones fly food directly — ignore terrain
- Workers + drones + belts all working together

### Stage 7: Teleporters + Full Automation (8+ hours)
- Instant food transport between any two points
- Manager AI auto-balances worker roles
- Workers dig and haul autonomously
- **The colony runs itself — true idle gameplay**
- Player's role is strategic: where to expand, which upgrades to buy

---

## Named Ants System

### Manual Naming (Free from Start)
- **No upgrade needed.** The moment you hatch your first ant, you can name it.
- Click on any ant → rename dialog → type a name → save
- Remove a name by clearing the text field and saving (blank = no name)
- Name as many ants as you want. Remove names whenever you want.
- Named ants get a **subtle glow** + name tag above their head
- **Can give a named ant your hat** (double-click → "Give this ant your hat?" yes/no)
- Named ants wearing hats have the hat visually on their head
- **No stat buffs.** Pure attachment and cosmetics.
- Greg is canonically the first named ant. Always.

### Future: Ant Color Customization (Endgame)
- Unlock ability to change an individual ant's color
- Rainbow Greg is the endgame dream

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
- **One hidden hat buried per distance milestone** (roughly every new food tier zone)
- Hats are buried in the dirt — look like a tiny colored pixel/shape until dug out
- When dug out: satisfying reveal animation, popup notification
- **5-10+ hats minimum**, potentially more added over time

### Equipping
- Queen ant can wear one hat at a time
- Hat appears on the ant's head, visible at close zoom
- **Can give your hat to a named ant** (they wear it instead)
- Purely cosmetic — no stat effects
- Hat menu accessible from pause/upgrade screen

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
The upgrade tree contains **mutually exclusive "Build Choice" nodes** — pick 2 of 3 options. You physically cannot have all upgrades in one colony. Each colony is a unique "build."

This means:
- Each colony has a distinct identity (mining-focused, hauling-focused, balanced, etc.)
- Experienced players want to try different combinations
- No single "optimal" build — all branches balanced, just different playstyles
- Achievements tied to specific builds encourage completionism

See **Upgrade System → Build Choice Nodes** for the full breakdown.

### Meta-Reward: +1 Starting Worker Per Colony Founded
Each time you found a new colony, you start with +1 basic worker ant (unassigned gatherer).

- **Colony 1:** 0 bonus workers (baseline)
- **Colony 5:** 4 bonus workers
- **Colony 10:** 9 bonus workers
- **Colony 50:** 49 bonus workers

**How it works:**
1. Start a new colony → bonus workers appear as basic gatherers in the starting chamber
2. They pick up exposed food (basic gatherer behavior) immediately
3. When you unlock Miner Caste or Hauler Caste, a **slider UI** appears: "Assign your unassigned workers"
4. Drag the slider to split them between Miners and Haulers → confirm → they activate
5. Assignment is permanent (same rule as all worker commitment)

**Why starting workers:**
- Thematic — it's an ant game, the reward is more ants
- Natural diminishing returns — queen's dig speed is the bottleneck early, not hauler count
- Integer values, no decimal weirdness
- Doesn't interact with the build system (percentage-based upgrades scale the same regardless of worker count)

**Balance safeguard:** Worker-count upgrades only compete with OTHER worker-count upgrades in Build Choice nodes, and are placed late in the tree. By the time you reach them, the starting worker bonus is a drop in the bucket.

### Cosmetic Prestige Rewards
- **Colony Themes:** Background replacements (black void → space, crystal cavern, underwater, ice, lava)
- **Ant Themes:** Visual skins on all ants (golden ants, ghost ants, robot ants, leaf-cutter style)
- **Build Completion Achievements:** "Complete the game as a pure-miner build" → unlocks unique cosmetic
- All cosmetics carry across colonies (permanent collection)
- Mix and match: colony theme + ant theme, both per-colony choice

### What Does NOT Carry Over
- No upgrade progress
- No food
- No worker count (except the +1 per colony bonus)
- No map knowledge
- No transport infrastructure
- Literally nothing except: cosmetics unlocked + colony count (for starting workers)

---

## Design Decisions Log

Decisions made during brainstorming, preserved for reference:

| Decision | Reasoning |
|----------|-----------|
| No storage cap | Boring, punishing. Let the number grow. |
| No offline progression | Game only runs when open. Simpler, more honest. |
| No random tunnel events | Golden cookie mechanic = forced screen watching = psycho behavior. None of the events make you engage with gameplay or are balanced early vs late. CUT. |
| No enemies/hazards/combat | Pure mining/idle. No damage, no death, no soldier ants. Maybe future expansion. |
| No pheromone trail system | Worker AI should be smart by default (go to closest untargeted thing). Don't need player-drawn paths. |
| Transport is free to place | Once you unlock minecarts, place unlimited track for free. The upgrade IS the cost. |
| Dig has cooldown (not click speed) | Prevents auto-clicker cheese. Upgrades reduce cooldown. |
| Distance gradient, not hard layers | Smooth color/difficulty transitions. No shape problem (circles vs rectangles). Milestone discoveries at certain distances. |
| Rainbow food = separate currency | Not "better food." Own upgrade tab. Endgame only. |
| Naming ants is free from start | No upgrade gate on naming. Cosmetic, costs nothing, who wouldn't name their first ant? |
| Foreman/Hive Mind CUT | Redundant with speed + AI upgrades. Speed makes them faster. Manager makes them smarter. Don't need "buff aura" middlemen. |
| Miner stacking cap (5 per block) | Visual/balance solution. Multiple miners on same dirt = faster but capped. Excess miners target next block. |
| Worker march formation | Same-direction ants = single file. Opposite direction = pass through each other. Adorable and functional. |
| Permanent worker commitment | Buy a miner, it's a miner forever. Buy a hauler, it's a hauler forever. No reassignment menu, no swapping. Rebalance by buying MORE of what you need. Every decision is a one-time purchase, not ongoing maintenance. |
| Miner spread logic | Miners prefer dirt blocks with fewer miners on them. Automatic dispersal, no player micromanagement. |
| Miners expand the frontier | Miners dig NEW tunnels on their own, not just assist at the player's dig face. They push the explored boundary, trigger zoom-out, and drive late-game expansion. No manual checkpoint gates. |
| No player-assigned dig zones | Workers are fully automatic. Maybe a priority zone system later, but default is smart AI. |
| Miner stacking visual | Vertical pile in tunnels — one on top of the other. No "fan around" (it's 2D, only left/right/up/down in a tunnel). Each ant visually offset so you can count them. |
| Food visibility 3-stage system | Food hidden in dirt by default. Stage 1: invisible. Stage 2: dim hint glow within detection radius. Stage 3: fully visible very close. Creates upgrade path (Food Sense I-III) and exploration incentive. |
| Indestructible rocks | Varying sizes scattered in terrain. Can't dig through — must dig around. Pure logistics obstacles, no damage/death/hazards. Adds interesting tunnel routing decisions. |
| Build diversity prestige | Mutually exclusive upgrade branches (pick 2 of 3). Can't have all upgrades in one colony. Each colony is a unique "build." Reason to start new colonies = try different combinations. |
| Old colonies fully playable | Starting a new colony doesn't delete old ones. Old colonies are full save slots you can return to and keep playing at any time. Not museums — fully interactive. |
| No legacy stat bonuses | No faster dig, no starting upgrades, no carried movement buffs between colonies. Clean slate every time. Only meta-reward is +1 starting worker per colony + cosmetics. |
| +1 starting worker per colony | Prestige meta-reward: each colony founded gives +1 basic gatherer at start of next colony. Natural diminishing returns (queen dig speed is the bottleneck). Assigned via slider when castes unlock. |
| Scout Ants CUT | Considered as colony tab upgrade and endgame feature. Cut entirely — miners expand frontier, detection radius handles food finding. Scout ants are redundant. |
| Colony twist hazards CUT | No underwater, volcanic, crystal colony variants with unique hazards. No death, no damage, no bullshit. Indestructible rocks provide logistics interest without any threat mechanics. |
| Game speed as meta-reward CUT | 3x+ simulation speed would cause performance issues (3x pathfinding, 3x physics). Also less thematic than starting workers. |
| Two upgrade tiers | Build Choice nodes (pick 2 of 3, gameplay-defining, percentage-based) + Standard upgrades (available to all, includes infinite scalers). Build choices create identity; standard upgrades create progression. |
| Percentage-based Build Choices | All Build Choice upgrades are percentage-based (not flat additive). Prevents starting worker count from warping which branch is "best." Worker-count choices only compete with other worker-count choices, placed late in tree. |
| Endgame = infinite scaling on 3 bottlenecks | After all Build Choices made, endgame is pumping three infinite scalers: dig speed, transport speed, worker efficiency. How you REACH endgame is the build; what you DO at endgame is the same for everyone. |
| Unassigned workers can be assigned | Workers hatched before caste unlock are basic gatherers. When castes unlock, slider UI lets you assign them to Miner or Hauler. Still permanent once assigned. |
| Build completion achievements | Achievements tied to completing the game with specific builds. Encourages trying all combinations. Each achievement unlocks a cosmetic reward. |
| Colony themes = background OR ant skins | Two cosmetic layers: background themes (replace black void) and ant themes (visual skins on all ants). Unlocked via achievements, mix and match per colony. |
| Camera: free pan + zoom | Player can freely zoom in/out and pan across discovered areas. Not locked to queen. See your full colony from above. |
| No worker cap | No hard limit on worker count. Performance is the natural cap. Add a limit later if performance demands it. |
| No tutorial | Controls should be self-explanatory. No guided tutorial, no popup tips. Learn by doing. |
| Tunnel background: black | Black void for empty space. Simple, clean contrast against brown dirt. Revisit if needed. |
| Dev menu required | Can't playtest a multi-hour idle game without shortcuts. Need give-food, hatch-workers, unlock-upgrades, teleport, speed-multiplier, etc. F12 or backtick, stripped from release. |
| Balance through playtesting | Upgrade costs, hatching curves, and all numbers determined through actual play, not spreadsheet theory. Dev menu enables rapid iteration. |

---

## Visual Design

### Terrain
- **Brown dirt** — base, procedural noise texture. NOT flat color — subtle variation using noise.
- **Gradient color shifts** based on distance from origin (see Distance Scaling table)
- **Food** is always bright and visible against the dirt — strong contrast
- **Tunnels** are black/dark void — the negative space IS the player's creation

### Ants
- Geometric: ovals + lines
- Queen: 3 ovals, 6 legs (Line2D), 2 antennae, slightly larger. Crown/glow + equippable hat.
- Workers: 2-3 ovals, simplified legs (maybe just 4), smaller. Miners have bigger mandibles, haulers have bigger abdomen.
- Named ants: subtle glow + name tag + optional hat
- Achievement ants: unique color/glow, fixed name tag
- At distance (zoomed out): just colored dots with direction indicators.

### Food
- Bright colored circles (see Food Tiers table)
- When carried: stacked on ant's back, slightly bouncing with movement
- Food pile: heap of circles, grows visually with amount stored

### Infrastructure
- **Minecart tracks:** two parallel lines with cross-ties
- **Minecarts/Trains:** rectangles on the tracks with food circles inside
- **Conveyor belts:** animated dashed lines showing direction
- **Aerial tramways:** pylons with thin wire, gondola hanging from wire
- **Pneumatic tubes:** semi-transparent tubes, food shoots through them
- **Cargo drones:** tiny flying shapes with food attached
- **Teleporters:** two glowing rings (entry/exit) with particle effects
- **Loading stations:** small marked points on transport lines where workers dump food

### UI
- **Food counter** — top of screen, shows current food amount (with suffix notation for big numbers)
- **Rainbow food counter** — separate, only visible once found
- **Distance indicator** — furthest distance reached from origin
- **Worker count** — how many active workers, by role
- **Minimap** (when zoomed in) — shows full colony overview in corner
- **Upgrade menu** — tabbed overlay

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
- Critical strike dig: extra crunchy, louder
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

### Step 1: Terrain + Camera
- Chunk-based destructible 2D terrain
- Procedural noise-based dirt generation with food embedded
- Distance-based color gradient
- Camera follow + zoom in/out
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
- Dirt particles on dig
- Terrain modification (remove tiles from chunks)
- Bite size (start with one size, toggle comes later)

### Step 4: Food + Collection
- Procedural food placement embedded in terrain
- Food exposed when surrounding dirt dug away → pops out
- Walk over food to pick up
- Food stacks on ant body
- Carry capacity limit

### Step 5: Food Pile + Deposit
- Starting chamber with food pile
- Red radius indicator
- Walk to pile to deposit
- Food counter UI (with suffix notation)
- Pile grows visually

### Step 6: Basic Upgrades
- Upgrade menu (Tab/E to open)
- First upgrades: dig speed (cooldown reduction), bite radius, carry capacity
- Food as currency

### Step 7: Dirt Placement
- Q to place dirt (after Dirt Placement upgrade)
- Build ramps, bridges, platforms

### Step 8: Worker Ants + Naming
- Egg hatching (spend food → new permanent ant)
- Basic gatherer AI (find exposed food → pick up → return to pile)
- Worker pathfinding (flow fields)
- Worker visual (smaller ant)
- Naming system (click ant → rename, free from start)
- Achievement ant: Greg spawns on first worker hatched

### Step 9: Worker Castes
- Miner specialization (dig dirt toward food, max 5 per block)
- Hauler specialization (carry more, slightly slower)
- Role allocation decisions
- Ant marching formation (same direction = single file)

### Step 10: More Upgrades
- Fill out upgrade tabs
- Auto-mine toggle
- Critical strike
- Food magnet
- Movement upgrades (speed, jump boots, jump-dash)

### Step 11: Transport Infrastructure
- Minecart system (rails + carts, free to place)
- Train upgrade (better minecart)
- Loading stations (workers dump food here)
- Workers interact with transport

### Step 12: Advanced Movement
- Grappling hook
- Jetpack
- Elevator shafts
- Teleport waypoints

### Step 13: Advanced Transport
- Conveyor belts
- Aerial tramways
- Pneumatic tubes (through walls!)
- Cargo drones
- Teleporters

### Step 14: Smarter Workers
- AI upgrades (better pathing, value prioritization, auto-balance)
- Manager AI (full idle automation)

### Step 15: Hats + Achievements
- Hidden hats in terrain
- Achievement ants (milestone-based special ants)
- Hat giving (queen → named ants)
- Discovery notifications

### Step 16: Rainbow Food + Endgame
- Rainbow food at extreme distances
- Endgame upgrade tab (designed last, based on what the game actually needs)
- Ant color customization?
- Number scaling for late game

### Step 17: Polish
- Sound design
- Particle effects for everything
- Food bank / vault upgrade
- Performance optimization pass
- Full save system verification

---

## Open Questions

1. ~~**Camera**~~ **ANSWERED:** Free pan + zoom across discovered areas. Not locked to queen.
2. ~~**Worker cap**~~ **ANSWERED:** No hard limit. Performance is the cap. Add a limit later if needed.
3. ~~**Tunnel background**~~ **ANSWERED:** Black for now.
4. ~~**Save system**~~ **ANSWERED:** Multiple save slots — each colony is a save slot. Old colonies fully playable.
5. ~~**Tutorial**~~ **ANSWERED:** No tutorial. Controls should be self-explanatory.
6. ~~**Music**~~ **ANSWERED:** User will source later. Not a design question.
7. ~~**Prestige**~~ **ANSWERED:** Build Diversity model. See Prestige System section.
8. ~~**Endgame tab**~~ **PARTIAL:** Core upgrades defined (Omniscience, Architect Ant, etc.) but endgame needs further design alongside the upgrade/build system.
9. **Build Choice nodes:** What are the specific pick-2-of-3 choices? Need to design the exact mutually exclusive branches. **This is the next big design task.**
10. **Hatching cost curve:** Exact formula for egg cost scaling. Will be determined through playtesting, not theory.
11. **Upgrade costs/balance:** All numbers need playtesting. Can't be designed on paper — needs a dev menu to test quickly.

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
- **Toggle food visibility** (see all food, for debugging placement)
- **Speed multiplier** (2x/5x/10x for fast-forwarding idle sections)
- **Reset colony** (fresh start without closing game)
- **Toggle UI overlays** (show pathfinding, flow fields, worker targets)

Access via debug key (F12 or backtick). Stripped from release build.
