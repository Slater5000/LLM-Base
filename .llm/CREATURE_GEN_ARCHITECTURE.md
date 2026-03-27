# Procedural Creature Generation: Software Architecture Research

> Research compiled March 2026. Focused on CODE ARCHITECTURE, not visual techniques.

---

## Table of Contents
1. [Creature Genome Data Structure](#1-creature-genome-data-structure)
2. [Attachment Point / Socket System](#2-attachment-point--socket-system)
3. [Body Plan System](#3-body-plan-system)
4. [Procedural Gait Generation (CPG)](#4-procedural-gait-generation-cpg)
5. [Constraint-Based Animation (2D)](#5-constraint-based-animation-2d)
6. [Godot-Specific Procedural Animation](#6-godot-specific-procedural-animation)
7. [Creature Part Library Design](#7-creature-part-library-design)
8. [Verlet Physics for Creature Bodies](#8-verlet-physics-for-creature-bodies)
9. [Color Palette Generation](#9-color-palette-generation)
10. [Architecture Synthesis: Recommended Approach](#10-architecture-synthesis-recommended-approach)

---

## 1. Creature Genome Data Structure

### How Games Encode Creatures as Data

**Spore's approach (the gold standard):**
Each creature is represented as a tiny "DNA" payload (~2 KB). The game client acts as a "womb" that interprets the DNA and generates megabytes of mesh, texture, and animation data at runtime. This is a seed-to-phenotype pipeline.

**Genetic Algorithm Encoding (Gamasutra/Game Developer):**
- Genome = ordered array of chromosomes
- Chromosome = array of 15 data points (each data point = 4 characters)
- Diploid system: two full chromosome sets per creature (one from each parent)
- Dominance flags: binary array indicating which allele is expressed
- Mutation: `floor(total_points * mutation_rate)` random point changes

**Seed-Based Encoding (Runtime PCG systems):**
- 64-bit unsigned integer = complete creature specification
- Deterministic PRNG seeded from this integer
- Pipeline: `Seed -> RNG -> Skeleton Params -> Mesh Deformation -> Texture Gen`
- 18+ quintillion unique creatures from a single u64

### Practical Data Structure (pseudocode)

```
CreatureGenome:
    seed: u64                          # Deterministic regeneration
    body_plan: BodyPlanType            # Enum: SERPENTINE, BIPED, QUADRUPED, etc.
    spine_segments: int                # 2-8 segments
    segment_radii: float[]             # Thickness per segment
    segment_colors: ColorGene[]        # Per-segment color data

    limb_slots: LimbSlot[]             # Where limbs CAN attach
    attached_limbs: AttachedLimb[]     # What IS attached

    traits: Dictionary<String, float>  # speed, health, weight, etc.
    abilities: String[]                # fly, swim, bite, etc.

LimbSlot:
    segment_index: int                 # Which spine segment
    offset_angle: float                # Radial position around segment
    allowed_types: LimbType[]          # What can go here

AttachedLimb:
    slot_id: int
    part_id: String                    # Reference into part library
    scale: Vector2
    mirror: bool                       # Auto-mirror to opposite side
    bone_count: int                    # For IK chain length
    sub_parts: AttachedLimb[]          # Recursive: fingers, claws, etc.
```

### Key Insight
The genome should encode PARAMETERS, not geometry. The geometry is derived at runtime from parameters. This keeps creature data tiny (serializable, networkable) while producing rich visual variety.

---

## 2. Attachment Point / Socket System

### How Socket Systems Work in Practice

**Impossible Creatures / Gamasutra approach (3D mesh seaming):**
- "Vertex Tags" = spatial markers placed at connection edges in the editor
- Tags collect all vertices within a defined radius
- When two parts connect, guest vertices are transported to host vertex positions
- Normals are copied from host to guest for seamless shading
- Scale adjustment includes normal flipping when mirrored: `normals[i].x *= -1`

**For 2D (our use case), this simplifies dramatically:**
- Sockets = named Vector2 positions + rotation on each part sprite
- Each part defines its "attach_in" point (where it connects TO parent)
- Each part defines "attach_out" points (where children connect TO it)
- Connection = align child's attach_in to parent's attach_out, inherit rotation

### 2D Socket Data Structure

```
PartDefinition:
    id: String
    sprite: Texture2D
    attach_in: Vector2               # Connection point TO parent (local coords)
    attach_out: AttachPoint[]         # Connection points FOR children
    z_order_offset: int              # Layer sorting relative to parent
    allowed_child_types: String[]    # What can attach here
    flip_mode: enum { NONE, MIRROR_X, MIRROR_Y }

AttachPoint:
    local_position: Vector2
    local_rotation: float
    slot_type: String                # "leg", "arm", "head", "tail", etc.
    max_children: int
```

### Connection Algorithm (2D)

```
func attach_part(parent_point: AttachPoint, child: PartDefinition):
    child_node.position = parent_point.local_position
    child_node.rotation = parent_point.local_rotation
    child_node.position -= child.attach_in  # Offset so attach_in aligns
    # If mirrored, flip sprite and negate x-offset
```

---

## 3. Body Plan System

### How Games Define Body Layouts

**Hierarchical Spine Model (used by Spore, Creature Creator):**
1. Start with a spine = chain of segments with variable count and thickness
2. Each segment has radial attachment slots
3. Limbs attach to specific segments
4. Creature type emerges from: segment count + limb placement + limb types

**Body Plan as Template:**

```
BodyPlan:
    name: String                          # "quadruped", "serpent", "spider"
    min_segments: int
    max_segments: int
    segment_size_curve: Curve             # How size varies along spine
    required_slots: SlotRequirement[]     # Minimum limb requirements
    optional_slots: SlotRequirement[]

SlotRequirement:
    segment_range: Vector2i              # Which segments (e.g., front 1/3)
    slot_type: String                    # "leg", "arm", "wing"
    count: int                           # How many (per side)
    symmetry: bool                       # Auto-mirror

# Example body plans:
BIPED:     segments=3-4, legs@bottom(2), arms@mid(2), head@top(1)
QUADRUPED: segments=4-6, legs@front(2)+back(2), head@front(1), tail@back(1)
SERPENT:   segments=6-12, no legs, head@front(1)
SPIDER:    segments=2-3, legs@front(6-8), head@front(1)
CENTIPEDE: segments=8-20, legs@each(2), head@front(1)
```

**Constraint System for Believability:**
- Legs must not overlap (minimum angular spacing)
- Weight must appear balanced (center of mass over support polygon)
- Limb size should scale with body segment size
- No Man's Sky uses tag-based validation: legs have "legs" tag, flying creatures require "wings" tag

### The Hardest Problem: Limb Placement

From research on No Man's Sky and academic work:
- Legs are directly tied to movement animation, making placement critical
- Balance constraint: project center of mass and verify it falls within the convex hull of foot positions
- Overlap constraint: minimum angular distance between adjacent limbs on same segment
- Aesthetic constraint: bilateral symmetry is almost always desired (mirror mode)

---

## 4. Procedural Gait Generation (CPG)

### Central Pattern Generator Algorithm

CPGs are the biologically-inspired standard for procedural locomotion. Each leg gets an oscillator; oscillators are coupled with phase offsets to produce coordinated gaits.

**Core Equations (per oscillator i):**

```
Phase:     d_theta_i/dt = 2*PI*freq_i + SUM_j(r_j * w_ij * sin(theta_j - theta_i - phi_ij))
Amplitude: d_r_i/dt     = alpha_i * (R_i - r_i)
```

Where:
- `theta_i` = current phase of leg i
- `freq_i` = intrinsic frequency (step rate in Hz)
- `w_ij` = coupling weight between legs i and j
- `phi_ij` = phase bias (THE KEY PARAMETER for gait type)
- `r_i` = current amplitude, `R_i` = target amplitude
- `alpha_i` = convergence speed

**Phase Biases Define Gait Type:**

For a quadruped (4 legs: FL, FR, BL, BR):

```
WALK:    phi = [0, PI/2, PI/2, PI]       # Sequential: FL, BL, FR, BR
TROT:    phi = [0, PI, PI, 0]            # Diagonal pairs in sync
GALLOP:  phi = [0, 0, PI, PI]            # Front pair, then back pair
```

For a hexapod (6 legs), tripod gait:
```
Phase bias matrix (phi_ij):
    [0, PI, 0, PI, 0, PI]     # Alternating legs in anti-phase
    [PI, 0, PI, 0, PI, 0]
    ...
```

**GDScript Implementation Sketch:**

```gdscript
class CPGNetwork:
    var phases: PackedFloat32Array       # theta per leg
    var amplitudes: PackedFloat32Array   # r per leg
    var intrinsic_freq: float = 2.0      # Hz
    var target_amp: float = 1.0
    var coupling_weights: Array[Array]   # w_ij matrix
    var phase_biases: Array[Array]       # phi_ij matrix
    var convergence: float = 20.0

    func step(dt: float):
        var new_phases = phases.duplicate()
        for i in phases.size():
            var coupling = 0.0
            for j in phases.size():
                if i != j:
                    coupling += amplitudes[j] * coupling_weights[i][j] * \
                        sin(phases[j] - phases[i] - phase_biases[i][j])
            new_phases[i] += (TAU * intrinsic_freq + coupling) * dt
            amplitudes[i] += convergence * (target_amp - amplitudes[i]) * dt
        phases = new_phases

    func get_leg_phase(leg_index: int) -> float:
        return fmod(phases[leg_index], TAU)

    func is_stance(leg_index: int) -> bool:
        # Stance = foot on ground (phase 0 to PI)
        return get_leg_phase(leg_index) < PI
```

**Converting Phase to Foot Position:**

```
foot_target.x = rest_position.x + amplitude * cos(phase)  # Forward/back
foot_target.y = rest_position.y - abs(sin(phase)) * step_height  # Up arc during swing
```

### Performance
- O(n^2) per step where n = leg count (coupling calculation)
- For creatures with <= 20 legs, this is negligible
- Run at fixed timestep (e.g., 60 Hz), not per-frame

---

## 5. Constraint-Based Animation (2D)

### Spring and Distance Constraints for Creature Bodies

**Distance Constraint (the fundamental building block):**

```
func solve_distance_constraint(p1: Vector2, p2: Vector2, rest_length: float) -> Array:
    var delta = p2 - p1
    var current_length = delta.length()
    var diff = (current_length - rest_length) / current_length
    var correction = delta * 0.5 * diff
    return [p1 + correction, p2 - correction]  # Move each point halfway
```

**Spring Constraint (softer, used for secondary motion):**

```
func spring_force(p1: Vector2, p2: Vector2, rest_length: float, stiffness: float) -> Vector2:
    var delta = p2 - p1
    var stretch = delta.length() - rest_length
    return delta.normalized() * stretch * stiffness
```

**For creature bodies, use a hybrid:**
- Hard distance constraints for the spine (maintains structure)
- Spring constraints for rotation/orientation (allows wobble)
- Pin constraints for feet during stance phase (keeps them planted)

**Practical Pattern for 2D Creature Spine:**

```
class SpineConstraints:
    var points: PackedVector2Array    # Spine joint positions
    var rest_lengths: PackedFloat32Array
    var iterations: int = 4          # More = stiffer

    func solve():
        for _iter in iterations:
            # Pin head to desired position
            points[0] = head_target

            # Solve each link
            for i in range(points.size() - 1):
                var result = solve_distance_constraint(
                    points[i], points[i+1], rest_lengths[i])
                if i > 0:  # Don't move pinned head
                    points[i] = result[0]
                points[i+1] = result[1]
```

**Box2D reference:** Joint springs use stiffness expressed in Hertz (cycles/second), so spring reaction speed is independent of body mass. This is a good API design pattern.

---

## 6. Godot-Specific Procedural Animation

### IK in Godot 4.6

**New built-in 3D IK system (4.6):**
- `TwoBoneIK3D` - analytical two-bone solver
- `FABRIK3D` - iterative chain solver
- `CCDIK3D` - cyclic coordinate descent
- `SplineIK3D` - spline-following chains
- `SpringBoneSimulator3D` - physics-based secondary motion
- Deterministic mode available (important for networking)

**For 2D, no built-in IK.** Options:
1. Implement Two-Bone IK analytically (best for creature legs)
2. Use Twisted IK 2 addon (FABRIK + CCDIK for Bone2D)
3. Roll your own with the math below

### Two-Bone IK for 2D Legs (the practical choice)

```gdscript
## Two-bone IK solver for 2D creature legs
## Given: shoulder position, upper/lower bone lengths, target position
## Returns: elbow position

func solve_two_bone_ik_2d(
    shoulder: Vector2, target: Vector2,
    upper_length: float, lower_length: float,
    elbow_direction: float = 1.0  # 1.0 = bend right, -1.0 = bend left
) -> Vector2:
    var to_target = target - shoulder
    var dist = to_target.length()

    # Clamp to reachable range
    dist = clampf(dist, abs(upper_length - lower_length) + 0.01,
                  (upper_length + lower_length) * 0.99)

    # Law of cosines: find angle at shoulder
    var cos_angle = (upper_length*upper_length + dist*dist - lower_length*lower_length) / \
                    (2.0 * upper_length * dist)
    cos_angle = clampf(cos_angle, -1.0, 1.0)
    var angle = acos(cos_angle)

    # Direction to target + elbow offset
    var base_angle = to_target.angle()
    var elbow_angle = base_angle + angle * elbow_direction

    return shoulder + Vector2.from_angle(elbow_angle) * upper_length
```

### Procedural Walk Cycle in Godot 4 (Spider Example)

From a working Godot 4.5 implementation:

**Architecture:**
1. Marker2D/Marker3D nodes act as IK targets (one per foot)
2. Script moves markers, IK solver moves bones
3. Each leg has a RayCast for ground detection ("step sensor")

**Step Logic:**
```
1. Calculate "future position" = raycast hit + velocity * look_ahead_time
2. If distance(current_target, future_position) > step_threshold:
   -> Start step animation (lerp current -> future over step_duration)
3. Only allow N legs to step simultaneously (diagonal pairs for stability)
```

**Leg Grouping for Balance:**
- Group legs into diagonal pairs (or tripod sets for 6-legged)
- Only one group moves at a time
- Body height = average of all foot Y positions
- Body rotation = derived from terrain normal at foot positions

### Godot Node Hierarchy for a Procedural Creature

```
CreatureRoot (CharacterBody2D)
  +-- SpineChain (Node2D)  [custom Verlet/constraint solver]
  |   +-- Segment0 (Sprite2D)
  |   +-- Segment1 (Sprite2D)
  |   +-- ...
  +-- LegManager (Node2D)
  |   +-- LegIK_L0 (Node2D)  [custom IK script]
  |   |   +-- UpperLeg (Sprite2D)
  |   |   +-- LowerLeg (Sprite2D)
  |   |   +-- FootTarget (Marker2D)
  |   |   +-- StepSensor (RayCast2D)
  |   +-- LegIK_R0 (Node2D)
  |   +-- ...
  +-- HeadAttach (Node2D)
  +-- TailChain (Node2D)  [Verlet rope]
```

---

## 7. Creature Part Library Design

### How to Define a Library of Swappable Parts

**XML/Resource-Based Registry (industry standard):**
Parts are defined as data files, not hardcoded. The game loads all parts at startup and indexes them.

**Godot Resource Pattern:**

```gdscript
# creature_part.gd
class_name CreaturePart extends Resource

@export var id: StringName
@export var display_name: String
@export var part_type: PartType  # HEAD, TORSO, LEG, ARM, TAIL, WING, etc.
@export var sprite: Texture2D
@export var sprite_frames: SpriteFrames  # If animated

# Attachment geometry
@export var attach_in: Vector2           # Where this connects to parent
@export var attach_in_rotation: float
@export var attach_out_points: Array[AttachPointData]

# Gameplay stats
@export var stat_modifiers: Dictionary   # {"speed": 1.2, "health": -5}
@export var granted_abilities: Array[StringName]
@export var weight: float

# Visual properties
@export var color_regions: Array[Rect2]  # Areas that accept palette coloring
@export var z_order: int
@export var default_scale: Vector2 = Vector2.ONE

# Constraints
@export var min_scale: Vector2 = Vector2(0.5, 0.5)
@export var max_scale: Vector2 = Vector2(2.0, 2.0)
@export var compatible_body_plans: Array[StringName]

enum PartType { HEAD, TORSO, LEG, ARM, TAIL, WING, HORN, FIN, EYE, MOUTH }
```

**Part Registry (Autoload):**

```gdscript
# part_registry.gd - Autoload
class_name PartRegistry extends Node

var _parts: Dictionary = {}  # id -> CreaturePart

func _ready():
    _load_all_parts("res://data/creature_parts/")

func _load_all_parts(path: String):
    var dir = DirAccess.open(path)
    for file in dir.get_files():
        if file.ends_with(".tres"):
            var part = load(path + file) as CreaturePart
            _parts[part.id] = part

func get_part(id: StringName) -> CreaturePart:
    return _parts.get(id)

func get_parts_of_type(type: CreaturePart.PartType) -> Array[CreaturePart]:
    return _parts.values().filter(func(p): return p.part_type == type)

func get_compatible_parts(body_plan: StringName, slot_type: String) -> Array[CreaturePart]:
    return _parts.values().filter(func(p):
        return p.compatible_body_plans.has(body_plan) and \
               str(p.part_type).to_lower() == slot_type)
```

**Exception Lists (from Impossible Creatures approach):**
- Some parts don't work together -- maintain an incompatibility list
- Can be encoded as: `incompatible_with: Array[StringName]` on each part
- Or as a separate compatibility matrix resource

---

## 8. Verlet Physics for Creature Bodies

### Verlet Integration for Spines, Tails, Tentacles

**Why Verlet over RigidBody2D:**
- Verlet is position-based (no velocity accumulation errors)
- Much cheaper than RigidBody chains for visual-only physics
- Easy to pin/constrain specific points
- Perfect for creature spines that follow the head

**Complete GDScript Verlet Chain:**

```gdscript
class_name VerletChain extends Node2D

@export var segment_count: int = 8
@export var segment_length: float = 16.0
@export var gravity: float = 0.6
@export var damping: float = 0.98       # Velocity retention (0-1)
@export var constraint_iterations: int = 4
@export var pin_first: bool = true       # Pin head to parent

var points: PackedVector2Array
var old_points: PackedVector2Array

func _ready():
    points.resize(segment_count)
    old_points.resize(segment_count)
    for i in segment_count:
        points[i] = Vector2(0, i * segment_length)
        old_points[i] = points[i]

func _physics_process(delta: float):
    _integrate()
    _apply_constraints()
    queue_redraw()

func _integrate():
    for i in points.size():
        if pin_first and i == 0:
            points[0] = to_local(get_parent().global_position)
            continue
        var velocity = (points[i] - old_points[i]) * damping
        old_points[i] = points[i]
        points[i] += velocity
        points[i].y += gravity

func _apply_constraints():
    for _iter in constraint_iterations:
        for i in range(points.size() - 1):
            var delta = points[i + 1] - points[i]
            var dist = delta.length()
            if dist < 0.001:
                continue
            var diff = (dist - segment_length) / dist
            var correction = delta * 0.5 * diff
            if not (pin_first and i == 0):
                points[i] += correction
            points[i + 1] -= correction

func _draw():
    for i in range(points.size() - 1):
        draw_line(points[i], points[i + 1], Color.WHITE, 3.0)
```

**Adapting for Creature Spine:**
- Pin point 0 to creature's head/root position
- Each point becomes a spine segment with a sprite attached
- Segment radius can vary (use `draw_circle` or scale sprites)
- Add angular constraints to prevent the spine from folding on itself

**Available Godot Addons:**
- `Verlet Rope 4` (C#/.NET only) - Catmull-Rom spline tessellation, collision support
- `GDNative-Ropesim` - C++ GDExtension for fast verlet ropes
- Both require adaptation for creature use (designed for ropes/cables)

**Performance Notes:**
- Pure GDScript verlet: fine for ~50 segments per creature, ~10 creatures
- For more, move to C# or GDExtension
- Collision (O(n) static, O(n*m) dynamic) is the bottleneck, skip if not needed
- Use `VisibleOnScreenNotifier2D` to skip offscreen creatures

---

## 9. Color Palette Generation

### Algorithms for Cohesive Creature Palettes

**Best approach: HSV-based variations from a base color.**

Work in HSV (Hue-Saturation-Value) space, NOT RGB. HSV gives intuitive control:
- Hue shift = different color feeling
- Saturation shift = more/less vivid
- Value shift = lighter/darker

**Algorithm 1: Analogous Palette (best for creatures)**

```gdscript
func generate_creature_palette(base_hue: float, count: int = 5) -> Array[Color]:
    var palette: Array[Color] = []
    var sat = randf_range(0.4, 0.8)
    var val = randf_range(0.5, 0.9)

    # Primary color
    palette.append(Color.from_hsv(base_hue, sat, val))

    # Analogous colors (nearby on color wheel)
    for i in range(1, count):
        var hue_offset = randf_range(-0.08, 0.08)  # ~30 degrees max
        var sat_offset = randf_range(-0.15, 0.15)
        var val_offset = randf_range(-0.2, 0.2)
        palette.append(Color.from_hsv(
            fmod(base_hue + hue_offset + 1.0, 1.0),
            clampf(sat + sat_offset, 0.2, 1.0),
            clampf(val + val_offset, 0.3, 1.0)
        ))
    return palette
```

**Algorithm 2: Complementary Accent**

```gdscript
func generate_with_accent(base_hue: float) -> Dictionary:
    var body_color = Color.from_hsv(base_hue, 0.6, 0.7)
    var accent_color = Color.from_hsv(fmod(base_hue + 0.5, 1.0), 0.8, 0.9)  # Complement
    var dark_color = Color.from_hsv(base_hue, 0.5, 0.3)   # Shadows/outlines
    var light_color = Color.from_hsv(base_hue, 0.2, 0.95)  # Highlights/belly
    return {
        "body": body_color,
        "accent": accent_color,
        "dark": dark_color,
        "light": light_color
    }
```

**Algorithm 3: Photon-Aware Blending (avoids dark muddy colors)**

When blending two colors, blend the SQUARES of RGB channels:
```
new_r = sqrt((1-w) * base_r^2 + w * random_r^2)
new_g = sqrt((1-w) * base_g^2 + w * random_g^2)
new_b = sqrt((1-w) * base_b^2 + w * random_b^2)
```
This prevents the perceptual darkening that linear RGB blending causes.

**Material-Specific Color Ramps:**
Different creature materials need different color constraints:
- Skin/scales: warm hues, medium saturation
- Chitin/shell: cool hues, high saturation, high value
- Fur: low saturation, wide value range
- Eyes: high saturation, high value (accent color)

**Applying to Sprites:**
Use shader uniforms or `modulate` + color regions:
```gdscript
# Per-region palette application
sprite.material.set_shader_parameter("body_color", palette.body)
sprite.material.set_shader_parameter("accent_color", palette.accent)
```

Or use a palette swap shader that replaces specific source colors with palette colors.

---

## 10. Architecture Synthesis: Recommended Approach

### Putting It All Together for Godot 4 2D

**Layer 1: Data (Resources)**
```
res://data/creature_parts/    # .tres files (CreaturePart resources)
res://data/body_plans/        # .tres files (BodyPlan resources)
res://data/color_palettes/    # .tres files (PaletteTemplate resources)
```

**Layer 2: Registry (Autoloads)**
```
PartRegistry      # Indexes all parts, provides query API
BodyPlanRegistry  # Indexes body plans
```

**Layer 3: Generation (Scripts)**
```
CreatureGenerator     # Takes genome/seed -> produces CreatureData
CreatureAssembler     # Takes CreatureData -> builds scene tree
PaletteGenerator      # Takes seed + body plan -> produces color palette
```

**Layer 4: Runtime (Nodes)**
```
CreatureBody          # Root node, owns spine + limb manager
SpineController       # Verlet chain for body segments
LimbController        # Per-limb IK solver + step logic
CPGLocomotion         # Oscillator network for gait
TailController        # Verlet chain for tails/tentacles
```

**Data Flow:**
```
Seed/Genome
    |
    v
CreatureGenerator (pure data, no nodes)
    |
    v
CreatureData (serializable, networkable, ~200 bytes)
    |
    v
CreatureAssembler (creates scene tree)
    |
    v
[SpineController] <-> [CPGLocomotion] <-> [LimbControllers]
         |                                        |
    Verlet physics                    Two-Bone IK + step logic
```

**Key Architecture Decisions:**
1. Separate DATA from PRESENTATION completely
2. CreatureData must be serializable (for save/load and potential networking)
3. Parts are Resources, not scenes (lighter, faster to query)
4. IK solvers are custom code, not Godot's built-in (2D has no built-in IK)
5. Verlet spine runs in `_physics_process` at fixed timestep
6. CPG locomotion runs at fixed timestep, drives IK targets
7. Color palette is generated once at creature creation, stored in CreatureData

### Performance Budget (estimated)

| System | Per Creature | 10 Creatures |
|--------|-------------|--------------|
| Verlet spine (8 segments, 4 iterations) | ~0.02ms | ~0.2ms |
| CPG locomotion (4 legs) | ~0.005ms | ~0.05ms |
| Two-Bone IK (4 legs) | ~0.01ms | ~0.1ms |
| Step logic + raycasts (4 legs) | ~0.05ms | ~0.5ms |
| Sprite rendering (body + parts) | ~0.1ms | ~1.0ms |
| **Total** | **~0.2ms** | **~2ms** |

Well within budget for 60fps (16.6ms frame budget).

---

## Sources

### Creature Genome & Encoding
- [Genetic Algorithms in Games (Part 1) - Game Developer](https://www.gamedeveloper.com/design/genetic-algorithms-in-games-part-1-)
- [Runtime Procedural Character Generation - DEV Community](https://dev.to/goals/runtime-procedural-character-generation-161d)
- [Spore PCG - Carnegie Mellon ETC Press](https://press.etc.cmu.edu/articles/spores-playable-procedural-content-generation)

### Attachment Points & Mesh Seaming
- [Combining Meshes into Seamless Procedural Characters - Game Developer](https://www.gamedeveloper.com/programming/your-problems-are-not-always-what-they-seam-combining-different-meshes-into-seamless-procedural-characters)
- [Modular Character System - ITEM42](https://www.item42.com/modular-character-system)
- [daniellochner/creature-creator - GitHub](https://github.com/daniellochner/Creature-Creator)

### Body Plans & Creature Structure
- [Procedural Creature Generation Tutorial #1 - frothzon (itch.io)](https://frothzon.itch.io/procedural-creature-generation)
- [Coherent Creature Design - MNENAD](https://www.mnenad.com/creature-design/)

### Gait Generation (CPG)
- [CPG System for Procedural Quadruped Locomotion - Springer](https://link.springer.com/article/10.1007/s11042-019-7641-1)
- [Controlling Locomotion with CPGs - NeuroMechFly](https://neuromechfly.org/tutorials/cpg_controller.html)
- [Gait Algorithm Study - RobotShop Community](https://community.robotshop.com/forum/t/gait-algorithm-study/17784)

### Constraint Animation & IK
- [Two-Bone IK - Little Polygon Blog](https://blog.littlepolygon.com/posts/twobone/)
- [Inverse Kinematics in 2D - Alan Zucconi](https://www.alanzucconi.com/2018/05/02/ik-2d-1/)
- [IK-Driven Procedural Spider in Godot 4.5 - 80.lv](https://80.lv/articles/ik-driven-procedural-spider-locomotion-in-godot-4-5)
- [Inverse Kinematics Returns to Godot 4.6 - Godot Engine](https://godotengine.org/article/inverse-kinematics-returns-to-godot-4-6/)

### Godot IK & Procedural Animation
- [Twisted IK 2 - TwistedTwigleg (itch.io)](https://twistedtwigleg.itch.io/twistedik2)
- [2D Runtime IK for Godot - Ephemeralen (itch.io)](https://ephemeralen.itch.io/2d-ik-node)
- [Godot Forum: Procedural Animation with IK in 2D](https://forum.godotengine.org/t/need-help-in-making-procedural-animation-using-inverse-kinematics-in-a-2d-project/68890)

### Verlet Physics / Rope Chains
- [Verlet Rope 4 for Godot - GitHub](https://github.com/Tshmofen/verlet-rope-4)
- [RigidBody Rope in Godot - Steemit Tutorial](https://steemit.com/utopian-io/@sp33dy/tutorial-godot-engine-v3-gdscript-rigidbody-rope)
- [Verlet Chain in Godot GDScript - Hive Tutorial](https://hive.blog/utopian-io/@sp33dy/tutorial-godot-engine-v3-gdscript-verlet-chain-v0-01)
- [Godot Forum: Rope with RigidBody2D](https://forum.godotengine.org/t/rope-implementation-using-rigidbody2d-solved/130433)

### Color Palette Generation
- [Procedural Color Variations - Sighack](https://sighack.com/post/procedural-color-algorithms-color-variations)
- [How to Choose Colours Procedurally - Dev.Mag](http://devmag.org.za/2012/07/29/how-to-choose-colours-procedurally-algorithms/)
