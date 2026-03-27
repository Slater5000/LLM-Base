# Procedural Creature Generation Research

Deep research compilation for building a procedural creature/monster generator system.
Focus: Godot 4, pixel-art aesthetic, drawing circles/lines procedurally (no pre-made spritesheets).

---

## 1. Procedural Creature Generation: Core Architecture

### The Spine-Based Approach (Industry Standard)

The dominant pattern across all implementations is a **spine-first** architecture:

1. Generate a spline curve (the "spine") using control points
2. Place body volumes (circles/metaballs) along the spine
3. Attach limbs at body volume positions
4. Layer cosmetic rendering on top

**Data Structures (from Pudgy Pals / Frothzon tutorials):**

```
Spine:
  control_points: Array[Vector2]  # 3-4 points, defines curvature
  metaballs: Array[BodySegment]   # 6-12 segments along spline

BodySegment:
  position: Vector2
  radius: float                   # varies for organic tapering
  color: Color

BodyPart:
  parent: BodyPart                # hierarchical chain
  position: Vector2
  radius: float
  angle: float                    # relative to parent
  distance: float                 # from parent
  direction: float                # rotation

Creature:
  spine: Spine
  limbs: Array[Limb]              # pairs, mirrored
  head: Head
  appendages: Array[Appendage]    # tail, wings, antennae
```

**Spine Generation Algorithm (De Casteljau / Bezier):**
- Pick 3-4 random control points
- Interpolate using De Casteljau's algorithm to create smooth curve
- Place N segments (8 is common) at even intervals along spline
- Randomize radius per segment, with smooth transitions between neighbors
- Smaller segments placed closer together for continuity

**Limb Attachment Algorithm:**
1. Divide torso segments into "buckets" (front half, back half)
2. Distribute limb pairs uniformly across buckets
3. Apply random offset within each bucket
4. Generate from back-to-front (legs first, then arms/wings)
5. Mirror limbs by negating x-values

### Biggest Implementation Challenges
- Making random creatures look "valid" -- most random params produce garbage
- Smooth weight blending at limb-torso junctions
- Fat creatures cause torso shearing with naive bone weights

### Sources
- [Pudgy Pals (GitHub)](https://github.com/nmagarino/Pudgy-Pals-Procedural-Creature-Generator)
- [Frothzon Tutorial (itch.io)](https://frothzon.itch.io/procedural-creature-generation)
- [Bournemouth MSc Thesis](https://nccastaff.bournemouth.ac.uk/jmacey/MastersProject/MSc22/01/ProceduralCreatureGenerationandAnimationforGames.pdf)

---

## 2. Spore Creature Creator: Technical Deep Dive

### The Metaball Body System

Spore uses **implicit surfaces (metaballs)** -- mathematical functions that merge smoothly when close together. Key details from Chris Hecker's writeup:

- Uses a **4th-order polynomial** in squared distance (not standard 2nd order) for smoother lighting
- Only **spherical metaballs** (no ellipsoids) for evaluation speed -- editor responsiveness was critical
- Metaballs distributed along spine and limbs via mathematical spacing
- Bone weights generated procedurally based on which body parts created which metaballs

**Unexpected Feature:** Webbing between limbs was a BUG from using one unified implicit surface. Players loved it for bat wings etc., so it shipped.

### Body Part Attachment: Rigblocks

Complex parts (hands, mouths, spikes) use **rigblocks** -- hand-crafted meshes with predefined degrees of freedom (scale, stretch, rotate within constraints). This hybrid approach (metaballs for body + rigblocks for details) balanced freedom with quality.

### Animation: Channel-Based Retargeting

The breakthrough was animating creatures the system had never seen before:

- Animations split into **channels** (arms, feet, torso)
- **Queries** select body parts: "highest arm pair", "all left feet"
- Artists keyframe poses; system generalizes via instructions:
  - "ground relative" = all feet hit ground simultaneously regardless of leg length
  - "scale by limb length" = longer limbs make bigger motions
- **Gait system** groups legs by length, selects appropriate walk cycle
- **Jiggles** = physics-based secondary motion for non-animated parts

### Texture Pipeline

- Auto UV unwrapping in ~10ms (ugly but functional, 36000x faster than artist work)
- Particle-based painting: particles crawl across mesh surface painting textures
- Three layers: base coat, main pattern, detail layer
- Multi-channel writes: diffuse, specular, gloss, emissive, bump simultaneously

### Key Lessons
- Spherical-only metaballs sacrificed variety for speed (worth it for editor feel)
- Fat creature torsos shear -- bone weight problem never fully solved
- The system NEVER assumes creature structure -- always queries for parts
- File sizes stayed tiny, enabling creature sharing (critical design goal)

### Sources
- [How the Spore Creature Creator Works (Rempton Games)](https://remptongames.com/2022/08/07/how-the-spore-creature-creator-works/)
- [Chris Hecker's Liner Notes for Spore](https://chrishecker.com/My_Liner_Notes_for_Spore)
- [GDC Vault: Rainworld Animation Process](https://www.gdcvault.com/play/1023475/Animation-Bootcamp-Rainworld-Animation)

---

## 3. Procedural Pixel Art Creature Generators

### Existing Tools & Techniques

**Lospec Procedural Pixel Art Generator:**
- Draw a base sprite with limited color palette
- Lower pixel generation probability to create randomized variations
- Works best with small, simple sprites (8x8 to 16x16)
- Good for mass-producing enemy variants, not complex creatures

**CryPixels:**
- Custom generation grids with pre-defined options
- Procedural grid brushes for building templates
- Full control over generation pipeline

**Frothzon's GameMaker Approach (most relevant to our use case):**

The rendering uses **surface-based drawing**:
1. Create a small surface (e.g., 150x50 pixels) once
2. For each pair of connected body parts, draw interpolated circles:
   - `lerp()` position from parent to child
   - `lerp()` radius from parent to child
   - `merge_color()` for color gradients
3. Draw filled circles at each interpolated point
4. Convert surface to sprite

This is exactly the approach we'd use in Godot with `draw_circle()` calls.

### Runevision's Advanced System (3D but principles apply)

- 503 low-level parameters (bone alignments, skin thickness)
- 106 high-level parameters (bulkiness, proportions)
- Key insight: "any random values for parameters should always create valid creatures"
- Uses **gradient descent** with silhouette matching to fit creatures to references
- Biggest challenge: ensuring random generation produces acceptable results

### Gotchas
- Pixel art at small scales (16x16) limits detail dramatically
- Color palette consistency matters more than shape detail
- Mirror symmetry is nearly mandatory for creatures to read as "alive"
- Pre-baking to Image/texture is essential for performance (don't redraw every frame)

### Sources
- [Lospec Procedural Pixel Art Generator](https://lospec.com/procedural-pixel-art-generator/)
- [Runevision Blog: Procedural Creature Progress](https://blog.runevision.com/2025/01/procedural-creature-progress-2021-2024.html)
- [CryPixels](https://crypixels.com/)

---

## 4. Modular 2D Character Generation (Mix-and-Match)

### The Layer System

The standard indie approach breaks characters into **ordered layers**:

1. **Back arm/hand** (behind body)
2. **Legs**
3. **Body/torso**
4. **Head**
5. **Front arm/hand**
6. **Accessories** (glasses, hats, scarves)

Each layer is a separate sprite with a consistent **anchor point** (usually center-bottom of the part's attachment zone).

### Color Masking for Part Mixing

When mixing parts from different sources, colors clash. Solution: **color masks**.

- Draw parts in grayscale with a palette index texture
- At runtime, remap palette indices to actual colors
- Godot approach: use a shader with a palette texture uniform
- This lets any head work with any body regardless of original coloring

### Attachment Point System

Each part defines **socket positions** where other parts connect:

```
BodyPartDef:
  texture: Texture2D
  sockets: Dictionary  # "head_attach": Vector2(8, 0), "arm_l": Vector2(0, 4)
  z_order: int
  palette_mask: Texture2D  # optional, for recoloring
```

The assembler reads socket positions and snaps parts together.

### For Procedural Generation (Our Case)

Instead of pre-made sprites, we'd procedurally DRAW each part:
- Define part templates as drawing instructions (circles, lines, arcs)
- Parameterize: size, color, segment count, spikiness, etc.
- Each "gene" controls a drawing parameter
- Assemble parts using the same socket/attachment system

### Sources
- [GameDev.net: 2D Modular Asset Tips](https://www.gamedev.net/forums/topic/685614-2d-modular-assets-creation-tips/)
- [GameFromScratch: Dynamically Equipped Characters](https://gamefromscratch.com/creating-dynamically-equipped-characters-in-2d-and-3d-games/)
- [RGS_Dev: Free Modular Characters](https://rgsdev.itch.io/free-cc0-modular-animated-vector-characters-2d)

---

## 5. Open Source Creature Generators (Code Review)

### Pudgy Pals (WebGL, JavaScript) -- BEST REFERENCE

**Architecture:**
- Spine class: De Casteljau spline with 4 control points, 8 metaballs
- Creature class: manages spine + limbs + head + appendages
- Rendering: SDF raymarching (GPU shader)

**Limb Generation:**
```
1. Pick random limb pair count (1-4)
2. Distribute uniformly across torso metaballs
3. Random offset within distribution bucket
4. For each limb:
   a. Random joint count
   b. Spherical positional offsets between joints
   c. Legs: constrain final joint to ground plane (y=0)
   d. Mirror by negating x-values
5. Connect joints with capped cylinders matching radii
6. Add hand/foot SDF at terminal joints
```

**Texturing:** Triplanar mapping with 2 grayscale textures, 4 random colors. Surface normal dot product blends textures (upward-facing surfaces get different treatment).

### Creature Creator (Unity, C#) -- daniellochner

- Full Spore-like editor in Unity
- Spine-based body with draggable control points
- Body parts snap to spine segments
- Procedural animation built in
- Has multiplayer support
- Source: https://github.com/daniellochner/creature

### Terasology Creature Generator (Java)

- Voxel-based approach (different paradigm)
- L-system inspired body generation
- Less relevant to 2D pixel art but interesting for mutation systems

### Sources
- [Pudgy Pals (GitHub)](https://github.com/nmagarino/Pudgy-Pals-Procedural-Creature-Generator)
- [Creature Creator (GitHub)](https://github.com/daniellochner/creature)
- [PCG Resource List](https://github.com/kchapelier/procedural-generation)

---

## 6. Procedural Animation: Verlet Chain Physics

### Core Algorithm (Position-Based Verlet Integration)

This is the foundation for tails, tentacles, hair, and floppy limbs.

**Step 1: Simulate**
```
for each node:
  velocity = node.position - node.old_position
  node.old_position = node.position
  node.position += velocity + acceleration * dt * dt
```

**Step 2: Constrain (iterate N times for stiffness)**
```
for each pair of connected nodes:
  delta = node_b.position - node_a.position
  current_dist = delta.length()
  diff = (target_dist - current_dist) / current_dist
  node_a.position -= delta * 0.5 * diff
  node_b.position += delta * 0.5 * diff
```

**Step 3: Pin first node to parent**
```
chain[0].position = parent_body.position
```

**Data Structures:**
```
VerletNode:
  position: Vector2
  old_position: Vector2  # velocity is implicit!

VerletChain:
  nodes: Array[VerletNode]
  target_distances: Array[float]  # rest length per segment
  iterations: int  # 3-8 typical, more = stiffer
  gravity: Vector2
```

### Key Performance Tips
- **Fixed timestep** is critical for stability
- More iterations = stiffer, but O(N * iterations) per frame
- For stiff chains, use "hard constraints": solve top-to-bottom, move one node fully instead of splitting 50/50
- Cache transform data, avoid re-querying physics engine
- Interpolate between physics steps for smooth rendering

### Godot 4 Implementation Notes
- Don't use RigidBody2D chains -- too expensive, too unstable
- Implement in `_physics_process()` with custom Verlet
- Draw with `draw_line()` and `draw_circle()` in `_draw()`
- For pixel art: snap positions to integer coordinates before drawing

### Sources
- [Verlet Rope in Games (toqoz.fyi)](https://toqoz.fyi/game-rope.html)
- [Godot Verlet Chain Tutorial](https://steemit.com/utopian-io/@sp33dy/tutorial-godot-engine-v3-gdscript-verlet-chain-v0-01)
- [Roblox Verlet Integration Guide](https://devforum.roblox.com/t/the-beauty-of-verlet-integration-2d-ragdolls/1467651)

---

## 7. Rain World's Procedural Animation System

### Architecture: Physics Layer + Cosmetic Layer

Rain World's creatures use a **two-layer** system:

**Physics Layer:**
- Slugcat = **two spherical chunks locked at fixed distance**
- These chunks handle collision, gravity, movement
- Simple rigid body physics only

**Cosmetic Layer:**
- Limbs, tail, head details drawn ON TOP of physics chunks
- Position calculated procedurally based on:
  - Physics chunk positions/velocities
  - Player input state
  - Terrain context
- NO pre-baked keyframe animations
- NO traditional animation state machine

### How Creatures Are Defined

Quote from Joar (creature designer): "I never really set out to do procedural animation. I was posed with the problem of making the slugcat's limbs move, and since code is how you make things move in a computer game, that's what I did."

Each creature is defined as:
- A set of **freely moving pieces** (physics bodies)
- **Interconnections** between pieces (distance constraints, springs)
- **Rendering rules** for how to draw the soft body around the physics

The AI determines WHERE creatures should move; the procedural animation determines HOW they move to get there.

### For Our Use Case (Pixel Art Creatures)

Rain World's approach maps perfectly to our needs:
1. **Physics body** = 2-4 Verlet nodes for the creature's core
2. **Distance constraints** keep nodes together
3. **Limbs** = IK chains targeting ground/walls, drawn as pixel lines
4. **Body rendering** = draw circles at each node, interpolate between them
5. **Tail/tentacles** = Verlet chains hanging off the last node

### Key Insight
The seamless integration of AI + animation is what makes Rain World creatures feel alive. The locomotion AI IS the animation system -- they're not separate concerns.

### Sources
- [Unity Blog: Procedural Design in Rain World](https://unity.com/blog/exploring-procedural-design-rain-world)
- [Recreating Rain World's Animation (Medium)](https://medium.com/@merxon22/recreating-rainworlds-2d-procedural-animation-part-1-4d882f947e9f)
- [GDC 2016: Rain World Animation Bootcamp](https://www.gdcvault.com/play/1023475/Animation-Bootcamp-Rainworld-Animation)
- [Rain World Devlog Archive](https://candlesign.github.io/Rain-World-Devlog/Full%20devlog)

---

## 8. Inverse Kinematics for 2D Creature Legs

### Two-Bone IK (Simplest, Most Common for Legs)

Uses the **Law of Cosines** to analytically solve joint angles.

**Given:**
- `a` = upper leg length (hip to knee)
- `b` = lower leg length (knee to foot)
- `c` = distance from hip to target foot position

**Solve:**
```
# Elbow/knee angle
cos_angle_knee = (a*a + b*b - c*c) / (2*a*b)
angle_knee = acos(clamp(cos_angle_knee, -1, 1))

# Hip angle
cos_angle_hip = (a*a + c*c - b*b) / (2*a*c)
angle_hip = acos(clamp(cos_angle_hip, -1, 1))

# Add angle from hip to target
angle_to_target = atan2(target.y - hip.y, target.x - hip.x)
hip_rotation = angle_to_target - angle_hip  # or + for other solution
```

**Two solutions exist** (knee bends left or right). Pick based on creature design.

**Performance:** "Exceptionally efficient, can run on hundreds of characters simultaneously."

### Foot Placement Algorithm (from Weaverdev tutorial)

```
1. Define "home position" for each foot (relative to body center)
2. Each frame, compute world-space home position
3. If current foot position is too far from home:
   a. Trigger step coroutine
   b. Animate foot along quadratic Bezier arc:
      - start = current foot pos
      - apex = midpoint + upward offset
      - end = home position + overshoot
   c. Duration: 0.1-0.2 seconds typical
4. CRITICAL: Only allow diagonal pairs to step simultaneously
   (front-left + back-right, OR front-right + back-left)
```

**Bezier Arc for Foot Movement:**
```
var mid = (start + end) / 2.0 + Vector2.UP * step_height
var t = elapsed / duration  # 0 to 1, apply easing

# Quadratic Bezier
var a = start.lerp(mid, t)
var b = mid.lerp(end, t)
foot_pos = a.lerp(b, t)
```

### For Pixel Art Creatures

- Draw legs as 2-3 pixel-wide lines between hip, knee, foot
- Use `draw_line()` with the IK-solved joint positions
- Foot = small circle or rectangle at ground contact
- Snap to pixel grid for clean look
- At small scales (16-32px creatures), single-bone legs may suffice

### Key Gotchas
- Clamp target distance to `a + b - epsilon` to prevent over-extension jitter
- When hip-knee-foot align (straight line), add tiny offset to prevent NaN
- Foot rotation during lift phase matters for realism (curl toes up)
- Step timing needs to sync with movement speed

### Sources
- [Alan Zucconi: IK in 2D](https://www.alanzucconi.com/2018/05/02/ik-2d-1/)
- [Little Polygon: Two-Bone IK](https://blog.littlepolygon.com/posts/twobone/)
- [Weaverdev: Procedural Animation Tutorial](https://weaverdev.io/projects/proc-anim-tutorial/)
- [Godot Forum: IK in 2D](https://forum.godotengine.org/t/need-help-in-making-procedural-animation-using-inverse-kinematics-in-a-2d-project/68890)

---

## 9. 2D Metaball Rendering for Organic Shapes

### The Texture Threshold Technique (BEST for Godot pixel art)

From John Wigg's approach, specifically designed for Godot:

**Concept:**
Instead of computing implicit surface math, use texture blending + threshold shader.

**Step 1:** Create a radial gradient texture (white center fading to transparent edge)

**Step 2:** Render multiple gradient sprites to a SubViewport with black background. Where sprites overlap, alpha values ADD together.

**Step 3:** Apply threshold shader to the viewport texture:
```glsl
shader_type canvas_item;
uniform sampler2D gradient;

void fragment() {
    float brightness = texture(TEXTURE, UV).r;
    COLOR = texture(gradient, vec2(brightness, 0.0));
}
```

Pixels above threshold = solid. Below = invisible. The merging happens automatically where gradients overlap.

**Step 4:** Use a tiny gradient texture (5 pixels wide) imported WITHOUT filtering for pixel-art sharp edges.

### Why This Is Perfect for Creature Bodies

- Each body segment = one gradient sprite in the SubViewport
- Segments automatically merge into smooth blobs when close
- Moving segments apart causes them to separate organically
- Size controlled by sprite scale OR alpha modulation
- VERY cheap: no marching squares, no raymarching, just texture blending

### Performance Considerations
- SubViewport rendering has overhead but is manageable
- Use smallest SubViewport that contains the creature
- Update only when creature moves (flag-based dirty checking)
- For many creatures: consider rendering body to Image once, use as cached texture

### Alternative: Marching Squares
- Divide space into grid cells
- Evaluate scalar field at each corner
- Look up which edges are crossed (16 cases in 2D)
- Draw line segments along crossed edges
- More expensive, more precise, less pixel-art friendly

### Gotchas
- SubViewport size must be large enough to contain all metaballs
- The gradient texture controls the "sharpness" of the merge
- Godot's SubViewport has frame delay issues -- may need `render_target_update_mode = ALWAYS`
- For pixel art: snap gradient sprite positions to integer coordinates

### Sources
- [John Wigg: 2D Metaballs](https://john-wigg.dev/2DMetaballs/)
- [GameDev.net: Exploring Metaballs in 2D](https://www.gamedev.net/tutorials/programming/graphics/exploring-metaballs-and-isosurfaces-in-2d-r2556/)
- [Wikipedia: Metaballs](https://en.wikipedia.org/wiki/Metaballs)

---

## 10. Genetic Algorithm Creature Evolution

### Chromosome Representation

Each creature's genome is encoded as an array of values (floats or ints):

```
Genome:
  # Body shape genes
  spine_length: float          # 0.0-1.0
  segment_count: int           # 4-12
  segment_radii: Array[float]  # per-segment size
  body_color_h: float          # hue
  body_color_s: float          # saturation

  # Limb genes
  limb_pair_count: int         # 0-4
  limb_positions: Array[float] # where on spine (0.0-1.0)
  limb_lengths: Array[float]   # per limb
  limb_joint_count: Array[int] # joints per limb

  # Head genes
  head_type: int               # index into head variations
  head_size: float
  eye_count: int
  eye_size: float

  # Appendage genes
  has_tail: bool
  tail_length: float
  has_wings: bool
  wing_span: float
```

### Breeding (Crossover)

**Method 1: Uniform Crossover**
```
for each gene in genome:
  child.gene = randf() < 0.5 ? parent_a.gene : parent_b.gene
```

**Method 2: Single-Point Crossover**
```
crossover_point = randi() % genome.length
child.genes = parent_a.genes[0:crossover_point] + parent_b.genes[crossover_point:]
```

**Method 3: Blended (best for continuous values)**
```
for each float gene:
  t = randf()  # or randf_range(-0.1, 1.1) for extrapolation
  child.gene = lerp(parent_a.gene, parent_b.gene, t)
```

### Mutation

```
mutation_rate = 0.05  # 5% chance per gene
for each gene in child.genome:
  if randf() < mutation_rate:
    if gene is float:
      gene += randf_range(-0.2, 0.2)  # small perturbation
      gene = clamp(gene, 0.0, 1.0)
    elif gene is int:
      gene += randi_range(-1, 1)
      gene = clamp(gene, min_val, max_val)
    elif gene is bool:
      gene = !gene
```

### Fitness Function (for player-driven evolution)

In a game context, fitness can be:
- **Player selection** (pick favorites, breed them) -- simplest
- **Combat performance** (kill/death ratio)
- **Survival time** in an environment
- **Speed/agility** in races

**Validity check is critical:**
```
func is_valid(creature: Creature) -> bool:
  if creature.segment_count < 3: return false
  if creature.limb_pair_count == 0 and not creature.has_wings: return false
  if creature.head_size < 0.1: return false
  return true
```

### Dominance System (from Gamasutra article)

Each creature carries TWO chromosomes (one from each parent). A dominance flag per gene determines which expresses:

```
Gene:
  left_value: float   # from parent A
  right_value: float   # from parent B
  dominant: int        # 0 = left expressed, 1 = right expressed

func expressed_value() -> float:
  return left_value if dominant == 0 else right_value
```

This creates **recessive traits** -- a mutation can hide for generations then suddenly appear when both parents carry it. Great for gameplay surprise.

### Key Lessons
- Mutation rate tuning is THE most important parameter
- Too high (>20%): children look nothing like parents, feels random
- Too low (<1%): evolution stalls, takes too many generations
- 3-10% is the sweet spot for visible-but-gradual evolution
- Always validate offspring before presenting to player
- Dominance/recessive system adds depth but complexity

### Sources
- [Gamasutra: Genetic Algorithms in Games](https://www.gamedeveloper.com/design/genetic-algorithms-in-games-part-1-)
- [Karl Sims: Evolving Virtual Creatures (SIGGRAPH 1994)](https://www.karlsims.com/papers/siggraph94.pdf)
- [Evolution Simulator (itch.io)](https://orenong.itch.io/evolution-sim)
- [Vilmonic: Genetics Evolution Sandbox](https://bludgeonsoft.org/)

---

## Synthesis: Recommended Architecture for Godot 4 Pixel Art

### The Hybrid Approach

Combining the best techniques from all research:

**Body:** Metaball-style rendering via SubViewport + threshold shader (Section 9)
- Each body segment is a radial gradient sprite
- Segments merge organically when close
- Snap to pixel grid for pixel-art aesthetic

**Spine:** Verlet chain for the body core (Section 6)
- 4-8 nodes connected by distance constraints
- Gives organic wobble and physics response
- First node follows AI/player input, rest follows via constraints

**Limbs:** Two-bone IK with procedural stepping (Section 8)
- `draw_line()` from hip to knee to foot
- Foot placement via raycasting to ground
- Diagonal stepping pairs for natural gait
- At pixel scale, single-segment legs may suffice

**Tail/Tentacles:** Pure Verlet chains (Section 6)
- Hang off last spine node
- Drawn as connected circles/lines
- No IK needed, just physics follow

**Head:** Attached to first spine node
- Drawn as larger circle + eye circles
- Can track targets with simple angle interpolation

**Genetics:** Array-of-floats genome (Section 10)
- Each float maps to a body parameter
- Crossover + mutation for breeding
- Dominance system for recessive traits
- Validity check before spawning

### Rendering Pipeline

```
1. Update Verlet physics (spine + tails)
2. Solve IK for legs
3. Update foot stepping logic
4. Render to SubViewport:
   a. Clear to black
   b. Draw gradient circles at each body node position
   c. Draw gradient circles at each limb joint
5. Apply threshold shader to SubViewport output
6. Draw result to screen at creature position
7. Draw eyes, mouth, details on top
```

### Performance Budget (estimated for 50 creatures)
- Verlet physics: ~0.5ms (50 creatures x 8 nodes x 5 iterations)
- IK solving: ~0.1ms (50 creatures x 4 legs)
- SubViewport rendering: THIS IS THE BOTTLENECK
  - Option A: One shared SubViewport, draw all creatures (complex)
  - Option B: Cache creature sprites, only re-render on change
  - Option C: Skip metaballs, just draw overlapping circles directly

### Simplest Viable Version (Recommended Start)

Skip metaballs entirely for v1:
1. Spine = array of Vector2 positions updated via Verlet
2. Draw overlapping circles at each spine position (largest in middle)
3. Draw legs as 2-segment lines with IK
4. Draw eyes on the front circle
5. All rendering via `_draw()` calls, no SubViewport needed
6. Cache to Image when creature isn't moving

This gets 80% of the visual result with 20% of the complexity.
