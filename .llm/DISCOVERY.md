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
| **Progression** | XP/levels unlock new moves from creature's 15-move pool, capture new creatures, beat trainers |
| **Session length** | Variable — works for 30-60 min or multi-hour sessions |
| **Multiplayer** | Single-player first, architected for potential PvP later |

---

## Combat System

### Battle Format
- **3v3 trainer battles** — 3 creatures active per side from party of 6
- **1v1 wild encounters** — single creature battles for capture
- **Real-time with pause** — action bars fill based on Speed, spacebar pauses for decisions

### Action System
- Each creature has 3 active moves (selected from 15 learned moves)
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

## Creature Roster

### Distribution — 56 Families, 100 Forms

| Category | Families | Forms Each | Total Forms | Per Element |
|----------|----------|------------|-------------|-------------|
| Legendary | 4 | 1 | 4 | 1 |
| Starters | 4 | 3 | 12 | 1 (3 forms) |
| Endgame | 12 | 1 | 12 | 3 |
| Two-stage | 36 | 2 | 72 | 9 (18 forms) |
| **Total** | **56** | | **100** | **25 forms each** |

### Move System
- **120 total moves** — 30 per element
- Each creature learns **15 moves** from its element's 30-move pool
- **3 active moves** equipped for battle at a time
- Move descriptions must be very detailed (exact effects, conditions, values)

### Move Data Structure
- Target type: single_enemy, all_enemies, single_ally, all_allies, self
- Effect type: damage, heal, buff, debuff, status
- No element field on moves — creature's element determines available moves

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
9. **Party Screen** — View creatures, stats, moves, swap positions (opens from radial menu)
10. **Starter Selection** — Professor gives starter, first creature added to party

### PENDING:
11. Options Screen (volume sliders, fullscreen toggle)
12. Combat Systems (3v3 battles, action bars, pause, synergies)
13. Wild Encounters & Capture
14. Trainer AI
15. Audio & Final Polish

---

## Incremental Build Plan

Systems in gameplay order:

1. **Tilemap & Movement** — smooth 8-directional, collisions, camera
2. **Dialogue & NPC Interaction** — talk to NPCs, examine objects, get starter
3. **Creature Data Architecture** — Resources for creatures and moves
4. **Team Management Menus** — pause menu, party view, move swapping
5. **Combat Systems** — 3v3 battles, action bars, pause, synergies
6. **Wild Encounters & Capture** — 1v1 battles, capture minigame
7. **Trainer AI** — enemy decision-making
8. **Visuals & Polish** — animations, sprites, transitions
9. **Audio** — music manager, SFX
10. **Feedback & Polish** — juice, tutorials, balance

**Quality checks every increment:**
- Project runs in Godot — no errors
- Test feature manually with placeholder data
- Save/load preserves game state
