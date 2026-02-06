# Project Discovery

> Game design document captured during bootstrap conversation.

---

## Vision

| Field | Answer |
|-------|--------|
| **Pitch** | Creature collection RPG with real-time tactical 3v3 combat and elemental synergies |
| **References** | Plays like Pokémon meets Dragon Age (pause-and-play combat) |
| **Hook** | No RNG misses, no PP/energy management — pure tactical decisions with team synergy bonuses |
| **Art direction** | GBA-era pixel art (Pokémon Emerald style), vibrant colors, chiptune aesthetic |
| **Audio direction** | Chiptune/retro soundtrack and SFX |

---

## Core Loop

| Field | Answer |
|-------|--------|
| **Core verb** | Collect creatures, build synergistic teams, battle tactically |
| **Perspective** | Top-down 2D with smooth 8-directional movement (Emerald visuals, free movement) |
| **30-second loop** | Explore → encounter trainer/wild creature → real-time 3v3 battle with pause → victory/capture → manage team |
| **Failure mode** | All 6 party creatures faint → return to nearest heal point, lose some currency |
| **Progression** | XP/levels unlock new moves from creature's 9-move pool, capture new creatures, beat trainers |
| **Session length** | Variable — works for 30-60 min or multi-hour sessions |
| **Multiplayer** | Single-player first, architected for potential PvP later |

---

## Combat System

### Battle Format
- **3v3 trainer battles** — 3 creatures active per side from party of 6
- **3v3 wild encounters** — target creature + 2 helpers (from previously seen creatures)
- **Real-time with pause** — action bars fill based on Speed, spacebar pauses for decisions
- **Cannot flee trainer battles** — must win or lose

### Action System
- Each creature has 3 active moves (selected from 9 learned moves)
- Action bar fills based on Speed stat
- When bar reaches 100%, selected move auto-fires
- Player can change move selection and targets anytime (paused or unpaused)

### Elements & Archetypes
| Element | Archetype | Role |
|---------|-----------|------|
| Fire | DPS | High Attack stats, damage-focused moves |
| Water | Support | Healing and buff moves, balanced stats |
| Earth | Tank | High HP/Defense, protective moves |
| Air | Controller | Debuffs, crowd control, speed manipulation |

- Archetypes created by BOTH base stats AND move effects
- Damage calculation: Attack vs Defense — NO element-based modifiers
- Soft counters come from tactical matchups, not damage multipliers

### Synergy System
- **30 total synergies** based on active creature elements
- **20 triple synergies** (3 creatures on field)
- **10 double synergies** (2 creatures remaining after one faints)
- Synergies provide stat bonuses, special triggers, or passive effects

### Combat UI
- Player creatures on left (top/middle/bottom), enemies on right
- Health bars (color-coded by fullness), action bars visible for all
- Player can see: own moves, own targets, enemy HP/action bars
- Player cannot see: enemy moves, enemy targets
- Target indicators show who each player creature is targeting
- Smart targeting: heals can't target enemies, damage can't target allies

---

## Wild Encounter System

### Overview
Wild encounters use the same 3v3 battle system as trainer battles, but with a scanning phase before combat and a capture phase after victory.

### 1. Discovery
- Shaking bushes appear in the world indicating wild creatures
- Bush continues shaking until player engages or leaves the area

### 2. Scanning
- Press button to pull out scanner (cursor becomes magnifying glass)
- Hover over bush to start **sonar ping rhythm minigame** (~5-7 sec)
- Rarity affects scan difficulty/time
- **Fallback:** If sonar ping feels bad, use shrinking circle (Pokemon GO/OSU style)

**Scan Results:**
- Previously caught species → Shows creature identity
- Never caught → Shows "???" (must battle to discover)

**Scan Bonus:**
- If scanned: First flee attempt does NOT reset action bars
- If not scanned: All flee attempts reset action bars

**After Scanning:**
- Choose to **Engage** (walk into bush) or **Ignore**
- Ignoring keeps bush shaking — can rescan or engage later

### 3. Combat (3v3)
- **Target:** The creature you scanned/engaged
- **Helpers:** 2 creatures pulled from species you've seen before
- Helper rules:
  - Zone-locked (beach creatures with beach creatures, etc.)
  - Anti-repetition logic (no creature appears if seen in last 3 encounters)
  - Cannot be 3 of the same species
- Full tactical battle, same as trainer fights

### 4. Fleeing
| Creature Difficulty | Base Flee % | Per Attempt | Guaranteed By |
|--------------------|-------------|-------------|---------------|
| Easiest (common, low level) | 80% | +20% | 2nd attempt |
| Mid-range | 50% | +20% | 4th attempt |
| Hardest (legendary, rare) | 20% | +20% | 5th attempt |

**Flee Rules:**
- Flee attempt resets all action bars to 0 (unless first attempt after scanning)
- Cannot attempt flee again until one of YOUR creatures performs an action
- Successful flee → Creature gone, bush despawns

### 5. Victory → Capture Prompt
- After winning, prompted: "Do you want to capture?" Yes/No
- **No:** Creature runs off, encounter ends
- **Yes:** Enter capture minigame

### 6. Capture Minigame
**Direction Combo** — Creature sprite moves with the arrows (wrestling/chasing feel)

| Difficulty | Directions | Speed | Rounds |
|------------|------------|-------|--------|
| Easiest (common, low level) | 4 | Slow | 1 |
| Mid-range | 4-5 | Medium | 2-4 |
| Hardest (legendary, rare) | 5 | Fast | 5 |

**Rules:**
- Complete all rounds to capture
- **3 mistakes allowed** across all rounds (not consecutive)
- 3 mistakes → Capture fails, creature flees, bush despawns

**Fallback:** If direction combo doesn't feel good, use shrinking circle timing

### 7. Failure States
- **Lose battle** (all 6 faint) → Respawn at Medical Center
- **Fail capture** (3 mistakes) → Creature gone, bush despawns
- **Flee successfully** → Creature gone, bush despawns

---

## Creature Roster

### Distribution — 104 Families, 200 Forms

| Category | Families | Forms Each | Total Forms | Per Element |
|----------|----------|------------|-------------|-------------|
| Legendary | 4 | 1 | 4 | 1 |
| Starters | 4 | 3 | 12 | 1 (3 forms) |
| Endgame | 4 | 1 | 4 | 1 |
| Fossils | 4 | 1 | 4 | 1 |
| Two-stage | 88 | 2 | 176 | 22 (44 forms) |
| **Total** | **104** | | **200** | **50 forms each** |

### Move System
- **120 total moves** — 30 per element
- Each creature learns **9 moves** from its element's 30-move pool
- **3 active moves** equipped for battle at a time
- Move descriptions must be very detailed (exact effects, conditions, values)

### Move Learn Levels
Each species picks levels within the allowed range:

| Move | Baseline | Range |
|------|----------|-------|
| 1 | 1 | 1 (fixed) |
| 2 | 5 | 5 (fixed) |
| 3 | 10 | 10 (fixed) |
| 4 | 17 | 16-18 |
| 5 | 23 | 21-25 |
| 6 | 30 | 28-32 |
| 7 | 37 | 35-39 |
| 8 | 43 | 42-44 |
| 9 | 50 | 50 (fixed) |

- Moves 1-3 are fixed (everyone gets 3 moves by level 10)
- Moves 4-8 vary per species (tighter ranges at edges, ±2 in middle)
- Move 9 is always level 50 (capstone)

### Move Data Structure
- Target type: single_enemy, all_enemies, single_ally, all_allies, self
- Effect type: damage, heal, buff, debuff, status
- No element field on moves — creature's element determines available moves

---

## Stat & Balance System

### Core Rules
| Rule | Value |
|------|-------|
| Base Stat Total (BST) | **250** (same for ALL creatures) |
| Base stat minimum | **30** |
| Base stat maximum | **100** |
| Stats | HP, Attack, Defense, Speed |
| Evolution | **Purely cosmetic** — toggle appearance freely, no stat change |
| Rarity | Does **NOT** affect stats (only encounter rate) |
| Passives | **None** |
| Element | Determines **move pool only**, NOT stats |
| Attack stat | Powers **damage AND healing** |
| Defense stat | Powers **shields** (and reduces damage taken) |

### Stat Scaling Formulas
| Stat | Formula | At Level 50 |
|------|---------|-------------|
| HP | Base × Level ÷ 5 | Base × 10 |
| Attack | Base × Level ÷ 10 | Base × 5 |
| Defense | Base × Level ÷ 10 | Base × 5 |
| Speed | Base × Level ÷ 10 | Base × 5 |

### Stat Ranges at Level 50
| Stat | Minimum | Maximum |
|------|---------|---------|
| HP | 300 | 1000 |
| Attack | 150 | 500 |
| Defense | 150 | 500 |
| Speed | 150 | 500 |

### Move Formulas
```
Damage = (Attacker's Attack ÷ Defender's Defense) × Move Power
Healing = (Healer's Attack ÷ 150) × Heal Power
Shield  = (User's Defense ÷ 150) × Shield Power
```

### Buff/Debuff Effects
- Buffs apply to **next action** (not time-based)
- Debuffs can be time-based (e.g., slow for 5 seconds) or next-action
- Flat percentage effects: +30% / -30% typical

### Move Power Range
- **Minimum power:** 50
- **Maximum power:** 200

| Tier | Power | Notes |
|------|-------|-------|
| Weak | 50-80 | Basic attacks, early moves |
| Medium | 100-150 | Standard moves |
| Strong | 175-200 | Powerful moves, capstones |

### Element Move Diversity
All elements have access to all move types, but with different power levels:

| Element | Best At | Okay At | Weak At |
|---------|---------|---------|---------|
| Fire | Damage | Debuffs | Heals, Shields |
| Water | Heals | Damage | Shields, Debuffs |
| Earth | Shields | Damage | Heals, Debuffs |
| Air | Debuffs | Damage, Heals | Shields |

**Note:** Stats vary independently of element. A high-Atk Earth creature deals good damage despite Earth having weaker damage moves.

### Balance Target
- Max attacker vs max tank with strongest move = **~5 hits to kill**
- Glass cannon vs glass cannon = **~2 hits to kill**
- Tank vs tank = **~7 hits to kill**

---

## Legendary Creatures

### Lore
The four legendaries were **constructed** by an unknown force. The Earth legendary (a gorilla) fell from space as a meteorite — the first solid matter. It contained the other three: Liquid (Water), Gas (Air), Energy (Fire). Over eons they broke free and spread life across the world. All four share mysterious carved glyphs in an unknowable language.

### Legendary Stats (250 BST, same as everyone)
| Legendary | HP | Atk | Def | Spd | Base | Level 50 Stats |
|-----------|-----|-----|-----|-----|------|----------------|
| Earth Gorilla | 80 | 50 | 80 | 40 | 250 | 800 HP, 250 Atk, 400 Def, 200 Spd |
| Water Jellyfish | 70 | 70 | 55 | 55 | 250 | 700 HP, 350 Atk, 275 Def, 275 Spd |
| Air Octopus | 55 | 55 | 60 | 80 | 250 | 550 HP, 275 Atk, 300 Def, 400 Spd |
| Fire Cat | 50 | 85 | 45 | 70 | 250 | 500 HP, 425 Atk, 225 Def, 350 Spd |

### Legendary Visual Concepts
| Legendary | Element | Visual Concept |
|-----------|---------|----------------|
| Earth Gorilla | Earth | **Meteorite skeleton** — gorilla skeletal frame made of ancient space-stone, carved glyphs on bones, crystal growth in joints |
| Water Jellyfish | Water | **Angelic jellyfish** — ethereal, translucent, halo or wing-like fins, glyphs ripple through body |
| Air Octopus | Air | **Wind elemental** — made of visible wind/cloud, 8 tentacles are air currents, floats and manipulates |
| Fire Cat | Fire | **Two-headed lightning cat** — made of crackling electricity, twin heads, twin tails, moves in flashes |

### Legendary Uniqueness
- **Same BST as regular creatures** (250)
- **One signature move each** — unique move only they can learn
- No special passives, no stat advantages
- Special because of lore, rarity, and signature move

### Legendary Names & Files
| File | Name | Element |
|------|------|---------|
| legendary_earth_gorilla.tres | Primordius | Earth |
| legendary_water_jellyfish.tres | Luminara | Water |
| legendary_air_octopus.tres | Zephyrus | Air |
| legendary_fire_cat.tres | Voltaris | Fire |

---

## Shiny Creatures

### Concept
Every creature species has a **Shiny variant** — an ultra-rare color palette swap, similar to Shiny Pokémon. Shinies are purely cosmetic status symbols with no stat advantages.

### Shiny Rules
| Rule | Value |
|------|-------|
| Encounter rate | **1/4096** (same as modern Pokémon) |
| Stat difference | **None** — identical to normal |
| Move difference | **None** — same move pool |
| Visual indicator | Alternate color palette + sparkle effect on encounter |
| Dex tracking | Separate shiny sprite in creature dex |

### Visual Design
- Each species needs a **shiny palette** (alternate colors)
- Shiny creatures sparkle/glitter when first appearing
- Small star icon in party/battle UI to indicate shiny status
- Shiny sprite shown in dex only after catching shiny version

### Implementation Notes
- `CreatureInstance` needs `is_shiny: bool` flag
- Species resource needs `shiny_texture` or palette swap shader
- Shiny roll happens at encounter spawn (not capture)
- Breeding/eggs can have shiny odds modifiers (future)

---

## Starter Moves (16 Created)

| Element | Moves |
|---------|-------|
| Fire | Ember (70 AoE), Flame Strike (150), Ignite (+30% buff), Warm Glow (60 heal) |
| Water | Hydro Pulse (100), Healing Wave (150), Refreshing Mist (80 AoE heal), Bubble Shield (80) |
| Earth | Rock Slam (100), Stone Wall (150 self-shield), Fortify (100 ally-shield), Dust Recovery (60 self-heal) |
| Air | Gust (100), Gale Force (-30% spd debuff), Weaken (-30% atk debuff), Breeze (80 heal) |

---

## First Playable

The smallest thing that's playable:

- [x] **Player can:** Move through a test area with tiles and obstacles
- [x] **Player can:** Enter buildings (doors) and travel between areas (map edges)
- [x] **Player can:** Talk to an NPC (professor) — dialogue system complete, starter receiving pending
- [x] **Player can:** Open radial menu (F key), navigate with WASD/mouse, save game
- [ ] **Player can:** View party, see creature stats and moves (menu opens, screen not built yet)
- [ ] **Player can:** Enter a trainer battle (3v3), use the pause system, win or lose
- [ ] **Challenge is:** Defeat a trainer using the real-time combat system
- [ ] **Success means:** Victory screen, XP gained
- [ ] **Failure means:** Return to heal point

---

## Implementation Status

### COMPLETED:
1. **Phase 1: Bootstrap** — Project setup, Godot 4.6 configured, documentation filled
2. **Movement System** — Smooth 8-directional, CharacterBody2D, collision, camera follow
3. **Scene Transition System** — SceneManager autoload, doors (E to enter), map edges (auto-trigger), fade effects, spawn points
4. **Dialogue & NPC Interaction** — DialogueManager autoload, Interactable base class, NPC scenes, typewriter effect, Professor in Route 1
5. **Visual Polish (ColorRect)** — 3/4 view house with shadows/depth, layered trees, detailed player/NPC sprites, grass/flower details, forest borders, y-sorting
6. **Creature Data Architecture** — CreatureSpecies resource, MoveData resource, CreatureInstance runtime class
7. **Save/Load System** — GameState autoload, JSON save to user://save.json, settings (volume, fullscreen), story flags, party persistence
8. **Radial Menu** — Hexagonal button ring centered on player (F to toggle), WASD/mouse navigation, Save/Options/Exit working, Party/Bag/Dex placeholders

### NEXT UP:
9. ~~**First Creature + Moves**~~ — ✓ Created 4 legendaries + 16 moves (4 per element)
10. **Starter Selection** — Professor gives starter, creature added to party
11. **Party Screen** — View creatures, stats, moves, swap positions

### PENDING:
12. **1v1 Combat (MVP)** — Action bars, pause, damage, targeting, win/lose (single creature per side)
13. **Wild Encounters (1v1)** — Scanning, engage, battle, capture minigame
14. **Scale to 3v3** — Multiple creatures, synergies, helpers, party management in battle
15. Options Screen (volume sliders, fullscreen toggle)
16. Trainer AI
17. Audio & Final Polish

---

## Incremental Build Plan

Systems in gameplay order:

1. **Tilemap & Movement** — smooth 8-directional, collisions, camera
2. **Dialogue & NPC Interaction** — talk to NPCs, examine objects, get starter
3. **Creature Data Architecture** — Resources for creatures and moves
4. **Team Management Menus** — pause menu, party view, move swapping
5. **Combat Systems** — 3v3 battles, action bars, pause, synergies
6. **Wild Encounters & Capture** — 3v3 battles (target + helpers), scanning, capture minigame
7. **Trainer AI** — enemy decision-making
8. **Visuals & Polish** — animations, sprites, transitions
9. **Audio** — music manager, SFX
10. **Feedback & Polish** — juice, tutorials, balance

**Quality checks every increment:**
- Project runs in Godot — no errors
- Test feature manually with placeholder data
- Save/load preserves game state
