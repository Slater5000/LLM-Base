# Creature Evolution Battle Simulator — System Design

> Procedural creature generation for a HoMM2-style auto-battle game.
> Press a button → get a unique creature. Breed them. Evolve them. Battle them.

---

## Vision

A system where every creature is procedurally generated from a tiny genome (~200 bytes). Different body plans (quadruped, serpentine, insectoid, centaur, blob, biped), modular parts (heads, limbs, tails, wings), Dead Cells-quality pixel art shading, and procedural walk cycles that adapt to any limb configuration. Eventually: genetics, breeding, trait inheritance, and evolutionary pressure through combat.

---

## Architecture Overview

```
Seed (int64)
  │
  ▼
CreatureGenerator ──► CreatureGenome (Resource, ~200 bytes, serializable)
  │                        │
  │                        ├─ body_plan (enum)
  │                        ├─ spine_segments (count, radii, spacing)
  │                        ├─ limb_slots (type, bone_lengths, segment_index)
  │                        ├─ head_type + head_params
  │                        ├─ tail_segments, tail_taper
  │                        └─ palette_seed
  │
  ▼
CPGWalkComputer ──► Walk Frames (Array[Dictionary] of named Vector2 positions)
  │
  ▼
CreatureFrameBaker ──► ImageTexture (atlas strip, 8 frames)
  │                        uses PartDrawers (draw functions per part type)
  │                        uses CreaturePixelUtils (circles, lines, shading)
  │                        uses CreaturePalette (hue-shifted 5-color ramps)
  │
  ▼
CreatureDisplay (Node2D) ──► Sprite2D (region_rect animation)
                             + VerletTail (_draw() overlay for physics tails)
```

**Key principle: Data and presentation are completely separate.** The genome is pure data. The baker reads the genome and produces pixels. The display node reads the atlas and animates. Each layer has zero knowledge of the others' internals.

---

## Critical Architectural Decisions

### 1. Atlas Baking (not live drawing)

**Why:** GDScript `Image.set_pixel` is too slow for 20 creatures redrawing every frame. The existing spider_monkey_bake.gd proves atlas baking handles 20+ creatures at 60fps. Rain World redraws every frame, but it uses C++ — we can't.

**Approach:** Bake creature frames to an atlas strip at generation time. Only re-bake when the creature structurally changes (mutation, equipment). Physics-driven elements (tails, tentacles) use a lightweight `_draw()` overlay on top of the baked body.

**Two rendering layers per creature:**
1. **Baked atlas** (Sprite2D + region_rect) — body, head, limbs in walk poses
2. **Live overlay** (`_draw()`) — Verlet-driven tail, reaction effects

**Performance:** ~50ms per creature bake (one-time). 20 creatures = ~1s at spawn. Fine for battle setup. Per-frame cost: ~0.08ms per creature (region_rect flip + optional Verlet tail).

### 2. Spine Model

Every creature is a chain of circular nodes. The chain count, radii, and spacing define the body silhouette. The body plan determines the chain shape.

| Body Plan | Segments | Spine Shape | Required Limbs |
|-----------|----------|-------------|----------------|
| Quadruped | 4 | Horizontal | 2 leg pairs |
| Biped | 3 | Upright | 1 leg pair, 1 arm pair |
| Serpentine | 6-8 | S-curve | None (body-wave locomotion) |
| Centaur | 5 | L-shaped | 2 leg pairs + 1 arm pair |
| Insectoid | 3 | Segmented | 3 leg pairs |
| Blob | 2-3 | Round/squat | None (pseudopod/ooze) |

Each spine node stores: position, radius, color ramp index. Neighboring radii differ by max 30% for smooth tapering. Templates constrain segment count ranges and size curves per body plan.

### 3. Parts = Draw Functions (not textures)

Parts are **parameterized drawing functions** in a shared `PartDrawers` utility. Each function takes: Image, pixel position, size, color ramp, and type-specific parameters.

Examples:
- `draw_head_spider(img, pos, radius, ramp, {eye_count: 4, mandible_length: 1.2})`
- `draw_leg_insect(img, hip, knee, foot, ramp, {thickness: 2, band_count: 3})`
- `draw_tail_scorpion(img, points, ramp, {stinger_size: 0.8})`

The genome's `head_type`, `limb_type`, etc. are integer indices that map to these functions. The genome stores *what* to draw; the part drawer knows *how* to draw it.

### 4. Walk Cycle: CPG + Two-Bone IK

**CPG (Central Pattern Generator):** Coupled oscillators compute which legs are in swing vs stance at each frame. Phase biases define gait type:
- Quadruped trot: `[0, PI, PI, 0]` (diagonal pairs)
- Insectoid tripod: `[0, PI, 0, PI, 0, PI]` (alternating)
- Biped walk: `[0, PI]` (alternating)

**Two-Bone IK:** Analytical law-of-cosines solver computes knee position given hip and foot target. ~15 lines of math, runs on hundreds of creatures.

**Foot targets from phase:** `foot.x = rest + amplitude * cos(phase)`, `foot.y = ground - abs(sin(phase)) * step_height`

Serpentine and blob body plans don't use CPG/IK — they have dedicated animation functions (sine-wave propagation, radial pulsing).

### 5. Rendering Pipeline

Every pixel drawn uses the existing `_fill_circle` / `_draw_line_px` primitives wrapped in Dead Cells shading helpers:

1. **`_shaded_circle`**: 5 concentric layers — outline (darkest, largest) → shadow → base (offset toward light) → highlight (smaller, more offset) → rim (specular pop). Light from top-left.
2. **`_shaded_line`**: 3 layers — outline (thick+1) → base fill → highlight on light side.
3. **`_make_ramp`**: Generates 5-color array from a base color. Shadows shift hue +0.06 (cooler), highlights shift -0.06 (warmer).
4. **`_dim_ramp`**: Multiplies all colors by factor (0.55 for far-side depth cue).
5. **All positions snap to pixel grid.** Consistent outline thickness across all parts.

---

## Phased Implementation Plan

### Phase 0: Extract Shared Rendering Utilities
**Difficulty:** Easy | **Effort:** ~2 hours

Extract pixel helpers and shading from `spider_monkey_bake.gd` into reusable utilities.

**New files:**
- `creature_pixel_utils.gd` — static class with `fill_circle`, `draw_line_px`, `shaded_circle`, `shaded_line`, `make_ramp`, `dim_ramp`, light direction constants
- `creature_palette.gd` — Resource class for per-creature color generation. `create_from_seed(seed)` → named ramps (body, belly, limb, eye, accent)

**Validation:** Refactor `spider_monkey_bake.gd` to use the new utilities. Battle scene must still work identically.

---

### Phase 1: Genome and Body Plan Data
**Difficulty:** Moderate | **Effort:** ~1 day

Define creature data without drawing anything.

**New files:**
- `creature_genome.gd` — `CreatureGenome extends Resource`. Properties: seed, body_plan, spine_segment_count, spine_segment_radii, limb_slots, head_type, head_params, tail_segments, palette_seed, tex_size, ppu. Serializable via `to_dict()` / `from_dict()`.
- `body_plan_templates.gd` — Static constraint data per body plan. Segment count ranges, size curves, required/optional limb slots, compatibility lists.
- `creature_generator.gd` — `generate(seed) → CreatureGenome`. Seeds an RNG, picks body plan, rolls constrained parameters, validates, returns genome.

**Validation:** Generate 100 random genomes, verify all pass `is_valid()`. Print stats (limb counts, segment counts, body plan distribution).

---

### Phase 2: Walk Cycle Computer and Frame Baker
**Difficulty:** Complex | **Effort:** ~2-3 days

This is the core — generalizing the spider_monkey_bake pattern for any genome.

**New files:**
- `cpg_walk_computer.gd` — Takes a genome, produces an array of position dictionaries (one per frame). Internally: CPG oscillators → foot targets → two-bone IK for knee positions → spine bob/sway. Separate code paths for legged creatures (CPG+IK) vs serpentine (sine wave) vs blob (radial pulse).
- `creature_frame_baker.gd` — Takes genome + position frames → atlas ImageTexture. Creates Image, iterates frames calling draw functions in back-to-front order. Same painter's algorithm as the existing `_bake_frame`.
- `part_drawers.gd` — Static draw functions for each part type. Initial set:
  - Heads: round (mammal), spider (multi-eye), beak, flat (reptile)
  - Legs: standard (2-bone), insect (with banding), tentacle
  - Tails: basic (tapered circles), spiky, scorpion
  - Body textures: smooth, furry (dots), armored (plate lines)
  - Eyes drawn per head type with glint (Dead Cells signature)

**Validation:** Generate a creature, bake its atlas, display it with Sprite2D animation. It should walk with a coherent gait matching its body plan.

---

### Phase 3: Runtime Display Node and Test Scene
**Difficulty:** Moderate | **Effort:** ~1 day

**New files:**
- `creature_display.gd` — `CreatureDisplay extends Node2D`. Owns a genome, bakes its atlas on `_ready()`, creates Sprite2D child, animates via region_rect in `_process()`. Methods: `regenerate(genome)`, `set_animation(name)`.
- `verlet_tail.gd` — `VerletTail extends Node2D`. Lightweight Verlet chain for physics tails. 8 segments, distance constraints, gravity, rendered via `_draw()` as tapering circles. Pins first point to parent.
- `creature_gen_v2.tscn` — Test scene. "Generate" button spawns a `CreatureDisplay` with random genome. Shows genome info (body plan, segment count, limb count). Space to regenerate. Multiple creatures on screen to validate performance.

**Validation:** Mash the generate button 50 times. Every creature should look distinct, animate correctly, and not crash. 10+ on screen at 60fps.

---

### Phase 4: Part Variety and Polish
**Difficulty:** Complex | **Effort:** ~3-4 days

Expand the part library for genuine variety.

**Expand `part_drawers.gd`** (split into multiple files if needed):
- More head types: skull, cyclopean (one big eye), insect (compound eyes + antennae), horned
- More limb types: crab claws, bird talons, fin-legs, stubby blob pseudopods
- Wing types: bat membrane, insect (translucent), feathered
- Features: horns, dorsal spines, shell ridges, whiskers, antennae
- Body patterns: spots, stripes, color bands along spine

**Expand `body_plan_templates.gd`:**
- Size classes: tiny (32x32), small (48x48), medium (64x64), large (80x80), titan (112x112)
- More constraint tuning per body plan

**New file: `creature_name_gen.gd`** — Procedural species names from syllable tables. `generate_name(seed) → String`.

**Validation:** Generate 200 creatures, screenshot gallery. Each should read clearly as "a creature" at a glance. No broken silhouettes, no invisible parts.

---

### Phase 5: Genetics and Breeding
**Difficulty:** Complex | **Effort:** ~2-3 days

**New file: `creature_breeder.gd`**
- `breed(parent_a, parent_b, mutation_rate=0.05) → CreatureGenome`
  - Blended crossover for floats (lerp with random t)
  - Uniform crossover for ints/enums (50/50)
  - Mutation: 5% chance per gene of small perturbation
  - Validity check + retry
- `mutate(genome, rate) → CreatureGenome`
- `is_valid(genome) → bool`

**New scene: `breeding_test.tscn`** — Two parent creatures, "Breed" button produces offspring. Visual family tree.

**Validation:** Breed creatures for 10 generations. Offspring should resemble parents but show gradual drift. Mutations should occasionally produce surprising but valid creatures.

---

### Phase 6: Battle Integration
**Difficulty:** Moderate | **Effort:** ~1 day

Refactor `battle_field.gd` to use `CreatureDisplay` instead of `SpiderMonkeyBake`. Each army stack spawns a unique creature. Different body plans per row. Warm/cool palette bias per army.

**Validation:** Full HoMM2 battle scene with 6 unique procedural creatures. Press Space to regenerate all armies with new random creatures.

---

## File Map

```
scenes/prototypes/creature_gen/
  # ── Phase 0: Shared utilities ──
  creature_pixel_utils.gd       # Static drawing primitives + shading helpers
  creature_palette.gd           # Per-creature color ramp generation

  # ── Phase 1: Data layer ──
  creature_genome.gd            # Genome Resource (creature DNA)
  body_plan_templates.gd        # Body plan constraint templates
  creature_generator.gd         # Seed → Genome factory

  # ── Phase 2: Bake pipeline ──
  cpg_walk_computer.gd          # Walk cycle position calculator (CPG + IK)
  creature_frame_baker.gd       # Genome + positions → atlas ImageTexture
  part_drawers.gd               # Draw functions for every part type

  # ── Phase 3: Runtime ──
  creature_display.gd           # Node2D owner: genome + sprite + animation
  verlet_tail.gd                # Physics tail overlay
  creature_gen_v2.tscn          # Test scene with generate button

  # ── Phase 4: Content ──
  creature_name_gen.gd          # Procedural species naming

  # ── Phase 5: Genetics ──
  creature_breeder.gd           # Crossover + mutation

  # ── Existing (reference, eventually deprecated) ──
  spider_monkey_bake.gd         # Reference: production shading pipeline
  creature_drawer.gd            # Reference: first-gen drawing
  ant_creature.gd               # Reference: _draw() rendering path
  battle_field.gd               # Integration target (Phase 6)
```

---

## Performance Budget (20 creatures at 640x360)

| Operation | Per Creature | 20 Creatures | When |
|-----------|-------------|--------------|------|
| Atlas bake | ~50ms | ~1000ms | One-time at spawn |
| Frame advance (region_rect) | ~0.01ms | ~0.2ms | Every frame |
| Verlet tail (8 seg, 4 iter) | ~0.02ms | ~0.4ms | Every frame (if has tail) |
| Sprite2D render | ~0.05ms | ~1.0ms | Every frame (GPU) |
| **Per-frame total** | **~0.08ms** | **~1.6ms** | **Well within 16.6ms** |

Bake cost is amortized: one creature per frame during load, or use `WorkerThreadPool` for background baking.

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Random params produce garbage | High | Body plan templates constrain all rolls. `is_valid()` check + retry loop (max 10). |
| `part_drawers.gd` gets too large | Medium | Split into `part_drawers_heads.gd`, `_limbs.gd`, `_features.gd` at 400+ lines. |
| Serpentine/blob need different animation | Medium | Dedicated animation functions (sine wave, radial pulse) instead of CPG+IK. Implement after quadruped/biped work. |
| GDScript bake too slow for large creatures | Low | Optimize hot loop: batch pixel writes with `PackedByteArray` instead of `set_pixel`. Only needed if titan-size creatures are slow. |
| Walk cycles look stiff | Medium | Add secondary motion: spine flex, head bob delay, arm swing. Same techniques already in spider_monkey_bake.gd. |

---

## Research References

- `.llm/CREATURE_GEN_RESEARCH.md` — Spore, Rain World, Verlet, IK, metaballs, genetic algorithms
- `.llm/CREATURE_GEN_ARCHITECTURE.md` — Genome structures, sockets, CPG gaits, Godot patterns, part libraries
- Pudgy Pals (GitHub): https://github.com/nmagarino/Pudgy-Pals-Procedural-Creature-Generator
- Creature Creator (GitHub): https://github.com/daniellochner/Creature-Creator
- Chris Hecker's Spore Liner Notes: https://chrishecker.com/My_Liner_Notes_for_Spore
- Rain World Procedural Design: https://unity.com/blog/exploring-procedural-design-rain-world
- Frothzon Creature Tutorial: https://frothzon.itch.io/procedural-creature-generation
- 2D Metaballs for Godot: https://john-wigg.dev/2DMetaballs/
- Weaverdev Procedural Animation: https://weaverdev.io/projects/proc-anim-tutorial/
- Alan Zucconi 2D IK: https://www.alanzucconi.com/2018/05/02/ik-2d-1/
