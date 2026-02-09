# GDScript Lessons Learned

Hard-won lessons from development. Consult this when writing GDScript to avoid repeat mistakes.

---

## Type System Gotchas

- **Dictionary values return Variant** — need explicit casts (`float()`, `as Node2D`, `: Vector2`)
- **Untyped Array iterations also return Variant** — same casting needed
- **`Array[String]` params reject plain `Array`** — use untyped `Array` when callers may pass either
- **Node-typed vars return Variant from methods** — must use `var x: String =` not `var x :=`
- **spatial_grid.query_radius() returns Variant** — must use `var x: Array =` not `var x :=`

## Scene & Node Patterns

- **`set_script()` before `add_child()`** so `_ready()` fires with correct script
- **Physics state changes during signal callbacks need `call_deferred()`**
- **CanvasLayer + PROCESS_MODE_ALWAYS** for UI that works during pause
- **CanvasLayer for screen-fixed elements** — HUD, perf tracker need own CanvasLayer

## Performance & Timing

- **Engine.time_scale affects ALL nodes** — use `delta / maxf(Engine.time_scale, 0.001)` for real-time
- **Direction-aware bounce checks** — only reverse when moving TOWARD wall (prevents oscillation)
- **RefCounted for utility classes** — SpatialGrid extends RefCounted, just `.new()`

## GDScript Syntax

- **PackedVector2Array can't be const** — use `var _name` instead
- **gdlint class-definitions-order** — consts first, then public vars, then private vars (`_prefixed`)

## File Size Warnings

- **passive_weapon_manager.gd at ~1992 lines** — very close to 2000 line limit, be careful adding to it
