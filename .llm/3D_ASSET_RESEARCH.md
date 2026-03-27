# 3D Asset Generation Research

> **Goal:** Find viable methods for Claude to create 3D game assets without a human artist.
> Started: March 2026

---

## Context

Claude can create decent 2D sprites via programmatic MultiMesh (proven in Ant Farm — ant bodies, mushrooms, etc). The question is whether any 3D asset creation method works well enough to unlock 3D game development.

## Test Subject

**Low-poly stylized goblin** — complex enough to be a real test (head, body, arms, legs, ears, nose). If a method can produce a character, it can produce anything simpler (vehicles, props, environments).

---

## Test Results

### Test 1: Raw .obj File (Hand-Written Vertices)
- **Date:** 2026-03-18
- **File:** `test/3d_tests/test1_goblin.obj`
- **Method:** Write vertex coordinates and face indices as raw text
- **Result:** PARTIAL SUCCESS
  - Recognizable humanoid silhouette
  - Head, ears, nose, belly all read correctly
  - Goblin proportions (big head, squat body, pointy ears) came through
- **Issues:**
  - Arms/legs paper-thin (flat quads, not volumetric)
  - Gaps between body parts (not properly connected)
  - No color/material in viewer (mtl didn't load)
  - Very labor-intensive per vertex
- **Verdict:** Proves I can reason about 3D space. Too tedious for production. Move to tools with actual modeling operations.
- **Screenshot:** User confirmed recognizable goblin shape

### Test 2: Blender Python Script (multiple iterations)
- **Date:** 2026-03-18
- **Files:** `test/3d_tests/test2_goblin_blender.py` through `test2f_goblin_anim.py`
- **Method:** Python script using Blender's API — primitives, modifiers, materials
- **Result:** SUCCESS (model), PARTIAL SUCCESS (animation)
- **Sub-tests:**
  - **2a (separate pieces):** Good shapes but visible seams between parts
  - **2b (voxel remesh merge):** BEST result — smooth unified green goblin, good proportions. Ears, nose, brow ridge all readable. User said "much better"
  - **2c (auto-weights rig):** Arms deformed badly with auto-weights on remeshed topology
  - **2d (segmented/bone-parented):** Floating parts, looked worse. User: "def getting worse"
  - **2e (hybrid):** Legs splayed, regression. User: "def going backward still"
  - **2f (2b mesh + armature):** Walk cycle animation WORKS. Arms/legs move. ~10 FPS in Blender viewport (subsurf overhead), would run full speed in engine.
- **Key technique:** Primitives (spheres, cones, cylinders) → join all → voxel remesh (0.018 voxel size) → subsurf level 1. Eyes/mouth/cloth kept separate for materials.
- **Blender 5.x issues:** `Action.fcurves` API changed, `bpy.ops.object.select_all` fails from Scripting tab context. Workarounds: try/except for fcurves, use `bpy.data` level ops instead of `bpy.ops.object.select_all`.
- **Verdict:** Viable for indie game assets. Model quality = good. Animation = functional but rigging on remeshed topology is fragile. Best workflow: model in Blender Python, animate with simple bone rotations (not auto-weights).

### Test 3: CSG Composition (Godot)
- **Date:** 2026-03-18
- **Files:** `test/3d_tests/test3_goblin_csg.gd` + `.tscn`
- **Method:** @tool GDScript building CSG primitives (spheres, cylinders, cones) in the editor
- **Result:** PARTIAL SUCCESS (model OK, animation janky)
- **What worked:**
  - Correct goblin silhouette with proper proportions
  - Materials/colors applied per-shape (skin, eyes, mouth, cloth)
  - No external tool needed — pure Godot scene
  - Each part is a selectable node (easy to tweak in editor)
  - Pivot-based animation using Node3D parents + AnimationPlayer
- **Issues:**
  - No remesh/smoothing — visible seams between overlapping shapes (arms look like sausages stuck to body)
  - Fine detail limited (face features are blobby)
  - Animation: limbs rotate rigidly at pivots, no skin deformation
  - Face details don't move with body unless parented correctly
  - CSG recomputes union every frame during animation (perf concern at scale)
- **Verdict:** Good for prototyping and static level geometry. Could pass for a low-fi idle game aesthetic. Not viable for polished 3D characters. Way below Blender Python quality.

### Test 4: Unity Procedural Mesh (Unity 6.3 LTS)
- **Date:** 2026-03-18
- **Files:** `C:\Projects\Firstpass\Unity3DTest\Assets\Scripts\ProceduralGoblin.cs` + `GoblinSceneSetup.cs` + `OrbitCamera.cs`
- **Method:** C# Mesh API — generate sphere/capsule/ellipsoid meshes from vertices+triangles, merge with CombineMeshes, animate via Transform rotation on pivot GameObjects
- **Result:** PARTIAL SUCCESS (better than CSG, worse than Blender/SDF)
- **What worked:**
  - Recognizable goblin with correct proportions
  - Segmented arms (shoulder → upper arm → elbow → forearm → hand → fingers) and legs (hip → thigh → knee → shin → foot)
  - Real 3D scene object with proper lighting, shadows, materials
  - CombineMeshes merges multiple primitives into single draw call per body group
  - Animation works (pivot-based rotation, body bob/sway)
  - Orbit camera with mouse drag + scroll zoom
  - ExecuteInEditMode — builds in editor without hitting Play
  - Standard Material on all parts — integrates with Unity's lighting pipeline
- **Issues:**
  - Visible seams between overlapping primitives (no voxel remesh equivalent in Unity)
  - Arms still look "stuck on" — same problem as Godot CSG
  - Initially facing wrong direction (Unity left-handed coords, camera was behind goblin)
  - Goblin was sunk into ground (foot positions below y=0)
  - No smooth blending — CombineMeshes just concatenates vertex buffers
  - More boilerplate than Blender Python (manual vertex generation for every primitive type)
- **Verdict:** Proves Unity's Mesh API works for procedural generation, but without a remesh/smoothing step the visual quality is below Blender Python. Main advantage: assets exist as native Unity objects (collision, physics, LOD all work). Would be viable for geometric/low-poly art styles where seams are acceptable.

### Test 5: SDF Shader (Godot)
- **Date:** 2026-03-18
- **Files:** `test/3d_tests/test5_goblin_sdf.gdshader` + `.gd` + `.tscn`
- **Method:** canvas_item shader with full raymarching — SDF primitives (spheres, ellipsoids, capsules) combined via smooth unions, rendered per-pixel
- **Result:** SUCCESS (best visual quality), UNIQUE TRADEOFFS
- **What worked:**
  - Smoothest model of all tests — organic blending between all body parts (smooth union math)
  - Proper segmented skeleton: upper/lower arm with elbow, upper/lower leg with knee, tapered capsule limbs
  - Full walk cycle with secondary motion: body bob, sway, lean, head lag, elbow/knee bending
  - Multi-material support (skin, dark skin, eyes, pupils, mouth, cloth) via material IDs
  - Soft shadows, rim lighting, specular highlights — best lighting of any test
  - Mouse-drag camera orbit (click and drag to rotate around goblin)
  - Instant iteration — change a number, see the result immediately
- **Issues:**
  - Renders as 2D overlay (canvas_item shader on ColorRect) — not a 3D scene object
  - Can't interact with other 3D objects, no collision, no physics
  - GPU-intensive: every pixel runs the full raymarching loop (100 steps × map evaluation)
  - Godot shader gotcha: can't redefine built-in `PI` as local variable (causes silent compile failure → "version is null" spam)
  - Godot shader gotcha: no `return` in `fragment()` — must use if/else flow
  - Arms still slightly fused to body despite reduced smooth union radius
- **Best use cases:**
  - Rapid character design prototyping (proportions, silhouette, animation timing)
  - Boss encounters / special characters (single SDF per screen is fine)
  - Title screens, cutscenes, magic effects
  - Procedural creatures that morph at runtime
- **Verdict:** Best visual quality of all tests. Not a general-purpose game asset pipeline (can't export mesh), but excellent as a design tool and viable for specific game uses. Ideal workflow: design in SDF → translate proportions to Blender Python for mesh export.

---

## Key Findings (updated as tests complete)

- **Raw vertex placement:** I CAN do it, but worst workflow. Proof of concept only.
- **Blender Python:** BEST production method. Voxel remesh = smooth organic models. Animation works. Export to any engine.
- **CSG (Godot):** Prototyping and static geometry only. Visible seams, janky animation.
- **Unity Procedural Mesh:** Works but no remesh = visible seams. Native engine objects (collision, physics). Good for geometric styles.
- **SDF Shader:** Best visual quality but not exportable as mesh. Ideal as design tool / rapid prototyping. Also viable for specific in-game uses (bosses, effects, procedural creatures).

---

## Final Ranking

| Rank | Method | Visual Quality | Animation | Engine Integration | Best For |
|------|--------|---------------|-----------|-------------------|----------|
| 1 | **Blender Python** | Great (voxel remesh) | Good (armature) | Any (.glb export) | Production assets |
| 2 | **SDF Shader** | Best (smooth math) | Best (pure math) | Limited (2D overlay) | Design tool, special FX |
| 3 | **Unity Procedural** | OK (seams visible) | OK (pivot-based) | Native Unity | Geometric art styles |
| 4 | **CSG (Godot)** | OK (seams visible) | Janky | Native Godot | Level prototyping |
| 5 | **Raw .obj** | Poor | None | Universal import | Never use this |

---

## Recommended Pipeline

```
 DESIGN                    BUILD                      SHIP
 ──────                    ─────                      ────
 SDF shader (Godot)   →   Blender Python script  →   .glb to any engine
 - Proportions             - Same coordinates         - Unity, Unreal, Godot
 - Silhouette              - Voxel remesh             - Native materials
 - Animation timing        - Armature + keyframes     - Physics/collision
 - Color palette           - Materials                - LOD support
 - Iterate in seconds      - Run script = new mesh    - Production ready
```

### For Different Asset Types:
- **Characters/NPCs:** SDF sketch → Blender Python → .glb (full pipeline)
- **Vehicles/Props:** Blender Python directly (geometric, no SDF sketch needed)
- **Environments:** Blender Python modular kit → snap together in engine
- **Special FX / Bosses:** SDF shader could BE the final asset (in Godot)
- **Procedural creatures:** SDF shader at runtime (morph params, no mesh needed)

---

## Implications for Game Development

**3D games are viable.** The Blender Python pipeline produces good enough assets for indie/stylized 3D games.

- Asset pipeline: Claude writes Blender script → run → export .glb → import to any engine
- Iteration: tweak script params, re-run, instant new version
- Style consistency: same script patterns = same art style across all assets
- Animation: Blender Python creates armatures + keyframe animations
- Levels: modular kit approach (one script → 15-20 snap-together pieces)
- The geometric/low-poly aesthetic (Superhot, TABS, Human Fall Flat) is very achievable
- Organic characters work with voxel remesh trick (proven in Test 2b)
