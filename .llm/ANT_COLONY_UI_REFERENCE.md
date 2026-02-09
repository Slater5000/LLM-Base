# Ant Colony UI Reference

> **For use by Claude Code in a NEW repo.** This documents every UI test scene
> built in the reference project at `c:\Projects\Firstpass\LLM-Base`.
> Read this first, then read individual source files as needed.

---

## How To Use This Doc

The new Claude Code session can **read any file** from the reference project using
absolute paths. This doc gives you the overview; source files give you exact code.

```
Reference project root: c:\Projects\Firstpass\LLM-Base
UI scenes root:         c:\Projects\Firstpass\LLM-Base\scenes\prototypes\ant_colony\ui\
Design doc:             c:\Projects\Firstpass\LLM-Base\.llm\ANT_COLONY_DESIGN.md
```

---

## Assets To Copy

```
assets/sprites/ui/kenney/large/    182 tiles, 32x32 each (tile_0000.png - tile_0090.png + .import)
assets/sprites/ui/kenney/small/    322 tiles, 16x16 each (tile_0000.png - tile_0160.png + .import)
assets/sprites/ui/kenney/License.txt
assets/fonts/BoldPixels.ttf        Pixel font used everywhere
assets/fonts/default_theme.tres    Project-wide default theme (BoldPixels, size 16)
```

---

## Viewport & Project Settings

- **Resolution:** 640x360 (pixel art)
- **Stretch mode:** canvas_items
- **Window scale:** configurable 2x/3x/4x
- **All text is ALL CAPS** throughout every menu

---

## Shared Constants (`ui_constants.gd`)

**Path:** `scenes/prototypes/ant_colony/ui/shared/ui_constants.gd` (73 lines)
**Class name:** `AntColonyUI` (static constants accessed as `AntColonyUI.CONSTANT_NAME`)

### Colors
| Constant | Value | Use |
|----------|-------|-----|
| `BG_DARK` | `Color(0.12, 0.08, 0.05)` | Background for every scene |
| `TEXT_CREAM` | `Color(0.95, 0.9, 0.8)` | Light text on dark backgrounds |
| `TEXT_DARK` | `Color(0.2, 0.15, 0.1)` | Dark text on panels |
| `ACCENT_TAN` | `Color(0.76, 0.6, 0.42)` | Subtle accent (version labels) |
| `ACCENT_ORANGE` | `Color(0.95, 0.6, 0.15)` | Headers, costs, highlights |
| `FOOD_ORANGE` | `Color(1.0, 0.65, 0.15)` | Food icon, selected items |
| `RAINBOW_TINT` | `Color(0.9, 0.5, 1.0, 0.3)` | Rainbow menu tint |
| `NODE_AVAILABLE` | `Color(1, 1, 1, 1)` | Skill tree: available |
| `NODE_PURCHASED` | `Color(0.6, 0.85, 0.4)` | Skill tree: bought / toggled on |
| `NODE_LOCKED` | `Color(0.5, 0.5, 0.5, 0.6)` | Skill tree: locked |
| `NODE_HOVERED` | `Color(1.0, 0.95, 0.7)` | Skill tree: hover |
| `OVERLAY_DIM` | `Color(0, 0, 0, 0.6)` | Modal overlay background |
| `BTN_HOVER` | `Color(1.2, 1.1, 1.0)` | Button hover modulate |
| `BTN_PRESSED` | `Color(0.8, 0.75, 0.7)` | Button pressed modulate |
| `SAVE_GREEN` | `Color(0.4, 0.85, 0.4)` | Save/confirm buttons |
| `CANCEL_RED` | `Color(0.9, 0.35, 0.3)` | Cancel/delete buttons |

### Font Sizes (constants in `ui_constants.gd`)
| Constant | Value | Use |
|----------|-------|-----|
| `FONT_TITLE` | 14 | Scene titles (Node2D draw menus) |
| `FONT_HEADER` | 10 | Section headers (Node2D draw menus) |
| `FONT_BODY` | 8 | Body text (Node2D draw menus) |
| `FONT_SMALL` | 6 | Back buttons, version labels |

**IMPORTANT:** Most UI scenes override font_size to **16** on all labels and buttons.
The smaller constants above are only used in `evolve_tree_draw.gd` (the Node2D `_draw()` version).

### Kenney Tile Constants (tiles actually used)
```
# Large tiles (32x32) — paths relative to res://assets/sprites/ui/kenney/large/
PANEL_MASTER     = tile_0018   # Warm brown panel (legacy, not used in theme)
PANEL_CREAM      = tile_0000   # Lighter cream panel
PANEL_BROWN      = tile_0004   # Darker brown
PANEL_CREAM_ALT  = tile_0013
PANEL_DARK       = tile_0017   # Dark panel (ant preview frame)
PANEL_GRID       = tile_0026
PANEL_ROUNDED    = tile_0030   # *** PRIMARY PANEL TEXTURE *** (theme + all menus)
CIRCLE_RING      = tile_0039   # Evolve tree: available node (draw version)
CIRCLE_FILLED    = tile_0040   # Evolve tree: purchased node (draw version)
BANNER_LEFT      = tile_0043   # Banner system left cap
BANNER_MID       = tile_0044   # Banner system middle (stretch/tile)
BANNER_RIGHT     = tile_0045   # Banner system right cap
CIRCLE_RING_SM   = tile_0052
BANNER_WIDE      = tile_0056
BTN_ACCENT       = tile_0060
HEX_OUTLINE      = tile_0065

# Small tiles (16x16) — paths relative to res://assets/sprites/ui/kenney/small/
SMALL_CIRCLE     = tile_0023   # HUD food icon
SMALL_RING       = tile_0046
SMALL_X_RED      = tile_0093   # Delete/trash buttons
SMALL_BAR        = tile_0115
```

### Scene Paths
```
LAUNCHER       = ui_test_launcher.tscn
MAIN_MENU      = main_menu/main_menu_test.tscn
MODE_SELECT    = mode_select/mode_select_test.tscn
SETTINGS       = settings/settings_test.tscn
HUD            = hud/hud_test.tscn
EVOLVE_MENU    = evolve_menu/evolve_menu_test.tscn
RAINBOW_MENU   = rainbow_menu/rainbow_menu_test.tscn
PAUSE_MENU     = pause_menu/pause_menu_test.tscn
WORKER_OVERLAY = worker_overlay/worker_overlay_test.tscn
ANT_NAMING     = ant_naming/ant_naming_test.tscn
BUILD_MENU     = build_menu/build_menu_test.tscn
```

---

## Theme (`ant_colony_theme.tres`)

**Path:** `scenes/prototypes/ant_colony/ui/shared/ant_colony_theme.tres` (165 lines)
**Base texture:** `tile_0030.png` (PANEL_ROUNDED) for ALL styled controls
**Nine-patch margins:** 14px all sides (texture_margin_left/top/right/bottom = 14.0)

### Global Text Style
- **Font color:** Black `(0, 0, 0, 1)` for Label, Button, LineEdit
- **Font outline:** White `(1, 1, 1, 1)` for Label, Button, LineEdit
- **Outline size:** 2 for Label, Button, LineEdit

### Button Styles
| State | Modulate | Font Color |
|-------|----------|------------|
| Normal | (none) | Black |
| Hover | `(1.15, 1.1, 1.05)` | Black |
| Pressed | `(0.85, 0.8, 0.75)` | Black |
| Disabled | `(0.6, 0.55, 0.5, 0.7)` | `(0.5, 0.45, 0.4, 0.6)` |
| Focus | `(1.1, 1.05, 0.95)` | (inherits) |

Content margins: 4/2/4/2 (left/top/right/bottom)

### HSlider Styles
- **Track:** flat `(0.15, 0.1, 0.07)`, 1px border `(0.4, 0.3, 0.2)`, 2px corners
- **Grabber area:** flat `(0.5, 0.35, 0.2)`, 1px border `(0.4, 0.3, 0.2)`, 2px corners
- **Grabber highlight:** flat `(0.6, 0.42, 0.25)`, 1px border `(0.5, 0.38, 0.25)`

### LineEdit
- Same tile_0030 nine-patch, content margins: 6/2/6/2
- Focus state: modulate `(1.1, 1.05, 1.0)`

### PanelContainer
- Same tile_0030 nine-patch, content margins: 6/4/6/4

---

## Banner System

Three-part banner for panel titles, used across almost every menu.

### Programmatic Pattern (settings, evolve, build, rainbow)
```gdscript
# Standard banner width = 157px
var bx: float = (panel_w - 157.0) / 2.0

# Left cap — tile_0043, STRETCH_SCALE
bl.position = Vector2(bx, -1.0)
bl.size = Vector2(32, 32)

# Middle — tile_0044, STRETCH_TILE
mid.position = Vector2(bx + 30.0, -1.0)
mid.size = Vector2(97, 32)

# Right cap — tile_0045, STRETCH_SCALE
br.position = Vector2(bx + 125.44, -1.07)
br.size = Vector2(32, 32)

# Label — centered over banner, black text, white outline
lbl.position = Vector2(bx, 1.0)
lbl.size = Vector2(157.0, 32.0)
lbl.font_size = 16
lbl.font_color = Color.BLACK
lbl.font_outline_color = Color.WHITE
```

### Wide Banner Variant (rainbow menu: BANNER_W = 220px)
Same pattern but `mid_w = BANNER_W - 62.0` and label width = BANNER_W.

### Scene-Defined Pattern (mode_select, pause, worker_overlay)
In .tscn files, the banner uses nested TextureRects under a BannerLeft parent with
multiple BannerMid segments. Same visual result, different structure. Uses
`stretch_mode = 4` (KEEP_ASPECT_COVERED).

### Banner Titles Used
| Menu | Banner Title |
|------|-------------|
| Main Menu | `ANT COLONY` |
| Mode Select (Normal) | `NORMAL MODE` |
| Mode Select (Vanilla) | `VANILLA MODE` |
| Mode Select (Load Overlay) | `LOAD COLONY` |
| Mode Select (Legacy Overlay) | `LEGACY COLONIES` |
| Pause Menu | `PAUSED` |
| Worker Overlay | `ALLOCATE` |
| Ant Naming (Customize) | `CUSTOMIZE` |
| Settings | `SETTINGS` |
| Evolve Menu | `EVOLVE` |
| Rainbow Menu | `OVER THE RAINBOW` |
| Build Menu | `BUILD` |

---

## Common Patterns Across All Menus

1. **Back button:** `< Back` at (8, 8), size 50x16, font_size 6
2. **Background:** BG_DARK `(0.12, 0.08, 0.05)` ColorRect, full-rect anchors
3. **Theme:** All root Controls reference `ant_colony_theme.tres`
4. **Panel texture:** `PANEL_ROUNDED` (tile_0030), patch_margin 14px all sides
5. **Text style:** Black text, white outline (from theme), ALL CAPS
6. **Font size override:** `.add_theme_font_size_override("font_size", 16)`
7. **Navigation:** `get_tree().change_scene_to_file(AntColonyUI.SCENE_PATH)`
8. **mouse_filter:** MOUSE_FILTER_IGNORE on decorative elements, MOUSE_FILTER_STOP on interactive

---

## Menu Descriptions (11 Menus)

### 1. Test Launcher
**Source:** `ui_test_launcher.gd` (30 lines) + `.tscn` (53 lines)
**Pattern:** Scene-defined VBoxContainer + programmatic Button creation in `_ready()`
**Layout:** BG_DARK, centered VBoxContainer (separation 6), 10 buttons (font_size 16) linking to each test scene.

---

### 2. Main Menu
**Source:** `main_menu_test.gd` (11 lines) + `.tscn` (145 lines)
**Pattern:** Fully scene-defined (.tscn does all layout, .gd just wires back button)
**Layout:**
- BG_DARK background
- Banner "ANT COLONY" positioned at y=60
- 3 centered buttons: `START GAME`, `OPTIONS`, `QUIT` (160x32, VBoxContainer separation 12)
- Version label "V0.1.0" bottom-right corner, ACCENT_TAN color, font_size 6

---

### 3. Mode Select
**Source:** `mode_select_test.gd` (123 lines) + `.tscn` (928 lines)
**Pattern:** Scene-defined panels + overlays, GDScript wires signals and toggles visibility
**Complexity:** Most complex .tscn file

**Layout:**
- Two side-by-side NinePatchRect panels in HBoxContainer (center-anchored)
  - Each panel: 270x280, tile_0030, patch_margin 14, separation 20 between them
- **Normal panel:** Banner "NORMAL MODE", ColonyInfo label (multi-line stats), PLAY button with DeleteX TextureButton (SMALL_X_RED), LEGACY COLONIES button (hidden, 0.5 alpha)
- **Vanilla panel:** Banner "VANILLA MODE", ColonyInfo, PLAY + DeleteX, LOAD COLONY button

**Three overlay systems (children of root, initially hidden):**
1. **LoadOverlay:** dim (0,0,0,0.6), centered panel 480x260, banner "LOAD COLONY"
   - NewGameSlot: green bg `(0.45, 0.7, 0.4, 0.3)`, text "+ NEW GAME"
   - 3 save slots: tan bg `(0.85, 0.78, 0.65, 0.3)`, 48px height, NameLabel + StatsLabel + TrashBtn
   - `< Back` close button
2. **LegacyOverlay:** same structure, banner "LEGACY COLONIES", 2 legacy slots
3. **ConfirmOverlay:** dim (0,0,0,0.5), small panel 180x90
   - Text: "DELETE THIS\nCOLONY?"
   - YES button (red modulate 0.9,0.35,0.3) + NO button in HBoxContainer

**Test toggle:** ToggleStateBtn (top-right, 0.4 alpha) switches has_save/no_save states
**GDScript:** Wires all button signals, toggles overlay visibility, updates panel content

---

### 4. Pause Menu
**Source:** `pause_menu_test.gd` (11 lines) + `.tscn` (163 lines)
**Pattern:** Fully scene-defined
**Layout:**
- BG_DARK + dim overlay `(0, 0, 0, 0.6)`
- Centered panel 200x160, tile_0030, patch_margin 14
- Banner "PAUSED"
- VBoxContainer (separation 10): `RESUME`, `SETTINGS`, `MAIN MENU` buttons (height 26)

---

### 5. Worker Overlay (Allocate)
**Source:** `worker_overlay_test.gd` (46 lines) + `.tscn` (167 lines)
**Pattern:** Scene-defined modal with programmatic slider logic
**Layout:**
- Dim overlay `(0, 0, 0, 0.4)`
- Centered panel 220x150, tile_0030, patch_margin 14
- Banner "ALLOCATE"
- Content: MinersLabel "MINERS: 0", HaulersLabel "HAULERS: 0", RatioSlider (HSlider, 0-8 range), OK button
- **GDScript:** Slider value = miner count, haulers = TOTAL_WORKERS (8) minus miners

---

### 6. Ant Naming / Customize
**Source:** `ant_naming_test.gd` (411 lines) + `.tscn` (159 lines)
**Pattern:** Scene provides structure, GDScript builds ALL content programmatically
**This is a FULL customization screen, not just naming.**

**Scene (.tscn) provides:**
- BG_DARK, overlay `(0, 0, 0, 0.4)`
- Panel 260x340, tile_0030, patch_margin 14
- Content VBoxContainer (separation 3)
- Banner "CUSTOMIZE"
- Two test buttons: QueenToggle, UnlockToggle

**GDScript builds in `_build_ui()`:**
1. **Name input:** LineEdit, placeholder "GREG" (rainbow cycling color via `_process()`), font_size 16
2. **Ant preview:** NinePatchRect frame (PANEL_DARK), Control with `_draw()` signal
   - Draws 3-oval ant body (abdomen + thorax + head) with legs, antennae, eye
   - Queen mode: 1.3x scale, gold crown (3 zigzag lines)
   - Color changes with palette selection
3. **Color palette:** "ANT COLOR" header, 8-column GridContainer, 24 swatches (3 rows x 8)
   - Each swatch: Button with StyleBoxFlat (bg=color, border=darkened, 2px corners)
   - Locked by default, "LOCKED" label shown. Toggle with UnlockToggle button
4. **Hat collection (queen only):** "HAT COLLECTION" header, 5-column GridContainer
   - 10 hats: Hard Hat, Top Hat, Crown, Propeller, Wizard, Party Hat, Viking, Flower, Astronaut, Pirate
   - Each hat: colored Button with tooltip_text
5. **Give Hat button (worker only):** "GIVE HAT?" button, ACCENT_ORANGE modulate, 160x26
   - Click changes to "HAT GIVEN!" and disables
6. **Action row:** SAVE (SAVE_GREEN modulate, 80x26) + CANCEL (CANCEL_RED modulate, 80x26)

**Mode switching:** Queen shows hat grid, hides give-hat. Worker shows give-hat, hides hat grid.

---

### 7. In-Game HUD
**Source:** `hud_test.gd` (51 lines) + `.tscn` (112 lines)
**Pattern:** Fully scene-defined, GDScript handles tool cycling + radius
**Layout:**
- Top-right: FoodCount "12,450" + FoodIcon (TextureRect, SMALL_CIRCLE, modulate FOOD_ORANGE)
- Top-left: "DIST: 1,247" + "M:5 H:3" (miners/haulers count)
- Bottom-left: "TOOL: DIG R:1"
- Bottom-center: Instructions label (test only)
- **GDScript:** TAB cycles 4 tools (DIG, PHEROMONE, INSPECT, RALLY), `[` `]` adjust radius 1-5

---

### 8. Settings
**Source:** `settings_test.gd` (586 lines) + `.tscn` (33 lines)
**Pattern:** Minimal .tscn (BG + BackButton only), everything built programmatically
**Layout:**
- CenterContainer with panel 380x310, tile_0030, patch_margin 14
- Banner "SETTINGS"
- MarginContainer (12/40/12/10)
- **6 tabs** in HBoxContainer: AUDIO, DISP, GAME, PERF, ACCESS, CTRL
  - Active tab: green text `(0.2, 0.5, 0.2)`, inactive: black
  - Tab buttons: 50x20, font_size 16
- HSeparator between tabs and content
- Content area: 160px min height
- Bottom row: DEFAULTS (56x24), SAVE (64x24), CANCEL (64x24)

**Tab contents:**
1. **AUDIO:** 4 slider rows: MASTER (100%), MUSIC (80%), SFX (100%), AMBIENT (100%)
2. **DISP:** ScrollContainer with: Window Mode (WINDOWED/BORDERLESS/FULLSCREEN), Resolution (1280x720/1920x1080/2560x1440), Max FPS (30/60/120/144/UNLIM), UI Scale (1x-4x), Shake slider, Pheromone slider, Trail Quality (SIMPLE/NORMAL/DETAILED), Ant Detail (DOTS/NORMAL/FULL), Show Ant Names checkbox
3. **GAME:** Speed (0.25x/0.5x/1x), Zoom Speed slider, Edge Scrolling checkbox, Auto-Save checkbox, Save Freq (1m/5m/10m), Numbers (STANDARD/SHORT/SCIENTIFIC), Colony Size (SMALL/MEDIUM/LARGE/UNLIMITED)
4. **PERF:** Quality Preset (LOW/MEDIUM/HIGH), Max Ants slider, Show FPS checkbox, FPS Warning checkbox
5. **ACCESS:** Colorblind mode (OFF/DEUTAN/PROTAN/TRITAN), High Contrast checkbox, Font Size (SMALL/NORMAL/LARGE), Large Cursor checkbox
6. **CTRL:** ScrollContainer with 7 key bindings: MOVE=WASD, DIG=LCLICK, PLACE=RCLICK, ZOOM=SCROLL, EVOLVE=TAB/E, BUILD=B, PAUSE=ESC

**Reusable helpers:** `_create_slider_row()`, `_create_option_row()`, `_create_checkbox_row()`, `_create_key_row()`, `_create_styled_button()`, `_create_banner()`

---

### 9. Build Menu
**Source:** `build_menu_test.gd` (371 lines) + `.tscn` (33 lines)
**Pattern:** Minimal .tscn, fully programmatic
**Layout:**
- Blur overlay (ColorRect with screen texture shader, lod 2.5) shown when items unlocked
- "[ GAME WORLD HERE ]" placeholder label
- 6 transport buttons in circular ring (RING_RADIUS=80, CENTER=320,165)
  - Each button: 80x32 Control with NinePatchRect (PANEL_ROUNDED), centered label
  - Selected: FOOD_ORANGE modulate, Hover: BTN_HOVER
- Tooltip below ring showing hovered item description
- Placement hint: "CLICK START, THEN END POSITION. ESC TO CANCEL."
- Unlock count display + instructions at bottom
- Banner "BUILD" (programmatic, standard 157px width)

**6 Transport types:**
| ID | Label | Description |
|----|-------|-------------|
| lift | LIFT | VERTICAL LIFT -- FAST UP/DOWN FOR DEEP MINING |
| tramway | TRAMWAY | AERIAL CABLE BETWEEN PYLONS -- CROSSES GAPS |
| minecart | MINECART | HORIZONTAL RAIL -- FAST LEFT/RIGHT HAULING |
| conveyor | CONVEYOR | SURFACE BELT -- FOLLOWS FLOOR, WALL, CEILING |
| zipline | ZIP LINE | DIAGONAL SHORTCUT -- FAST DOWN, SLOW UP |
| teleport | TELEPORT | INSTANT WARP BETWEEN TWO PADS -- 1 PAIR ONLY |

**Test feature:** Number keys 1-6 toggle unlock count, ESC deselects

**Blur shader:**
```glsl
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 5.0) = 2.5;
void fragment() {
    COLOR = textureLod(screen_tex, SCREEN_UV, blur_lod);
    COLOR.a = 1.0;
}
```

---

### 10. Rainbow Menu
**Source:** `rainbow_menu_test.gd` (537 lines) + `.tscn` (33 lines)
**Pattern:** Minimal .tscn, fully programmatic using Control nodes (NOT Node2D _draw)
**BG color:** Purple-tinted dark `(0.15, 0.08, 0.12)` (different from standard BG_DARK)

**Layout:**
- Centered panel 510x310, tile_0030, patch_margin 14
- MarginContainer (10/36/10/6)
- ScrollContainer (horizontal disabled, vertical auto)
- VBoxContainer (separation 6)
- Banner "OVER THE RAINBOW" (wide: BANNER_W=220)
- Rainbow count label top-right (cycling color via `_process()`, font_size 16, black outline size 4)

**3 Categories with tiles:**
1. **LOGISTICS** (3 items): HIVE MIND (30), SPEED LIGHT (25), GLOBAL CONV (20)
2. **POWER FANTASY** (5 items): QUANTUM (30), AUTO ATTACK (25), AUTO-PILOT (20), GIANT QUEEN (25), VOID STORAGE (20)
3. **COSMETIC** (6 items): BIG HEAD (10), BIG ANT (10), RAINBOW TRAIL (15), FIRE TRAIL (15), BOOGIE BOMB (10), ANT COLORS (10)

**Tile construction:**
- Each tile: 76x40, NinePatchRect (PANEL_ROUNDED, patch_margin 14)
- Text color: rainbow hue `Color.from_hsv(index / 16.0, 0.7, 0.95)` with black outline (size 3)
- Category headers: centered, ACCENT_ORANGE color, black outline (size 3)
- Cost label below each tile
- Click toggles: NODE_PURCHASED (on) / WHITE (off)
- Hover: NODE_HOVERED modulate + tooltip (PanelContainer)
- Tooltip: flips to left side if would overflow right edge

---

### 11. Evolve Menu (Two Implementations)

#### 11a. Tab-Based (`evolve_menu_test.gd`) -- 774 lines
**Source:** `evolve_menu_test.gd` + `.tscn` (33 lines)
**Pattern:** Minimal .tscn, fully programmatic

**Layout:**
- CenterContainer with panel 460x330, tile_0030, patch_margin 14
- MarginContainer (12/40/12/8)
- Banner "EVOLVE" (programmatic)
- Rainbow count label top-right (cycling, black outline size 4)
- **3 tabs** (HBoxContainer, 100x20 each):
  - PLAYER: green `(0.3, 0.65, 0.3)`
  - LOGISTICS: yellow `(0.7, 0.6, 0.15)`
  - COLONY: red `(0.7, 0.25, 0.25)`
- Active tab: tab color text, inactive: black
- HSeparator, then content area (160px min height)

**Skill tiles:**
- Each: 92x40, NinePatchRect (PANEL_ROUNDED, patch_margin 14)
- Default modulate: `(0.5, 0.45, 0.38, 0.7)` (dimmed)
- Text: autowrap, font_size 16
- Rainbow tiles: cycling color, black outline (size 4)
- Regular tiles: black text
- Cost label below tile. Progressive skills show "0/50" or "0/10" above cost.
- Fork labels ("PICK 2 OF 3", "PICK 1 OF 4") in red, centered

**Hover:** Tab color modulate + tooltip (PanelContainer with PANEL_ROUNDED StyleBoxTexture)
**Click:** Cycles state 0 -> 1 -> 2 -> 0 (tab color -> tab color -> NODE_LOCKED)

**Skill data:** PLAYER (7 tiers), LOGISTICS (7 tiers), COLONY (6 tiers)
Each tier is an Array of skill Dictionaries: `{name, desc, cost, state, [prog], [pick], [rainbow]}`

#### 11b. Scrollable Tree (`evolve_tree_draw.gd`) -- 490 lines
**Pattern:** Node2D with custom `_draw()`, scrollable via mouse wheel
- Three parallel prongs from shared trunk: PLAYER ANT (cx=160), LOGISTICS (cx=320), COLONY (cx=480)
- Standard nodes (30px circles) and fork nodes (20px) with branching
- Fork offsets: 2=[-28,28], 3=[-42,0,42], 4=[-56,-19,19,56]
- Labels beside nodes (left tree -> right labels, right tree -> left labels)
- Scroll wheel pans vertically. Click cycles node state (0 -> 1 -> 2 -> 0).
- Tooltip: draw_rect + draw_string directly
- Uses FONT_TITLE/FONT_HEADER/FONT_BODY sizes from constants

---

## File Inventory (24 files total)

```
scenes/prototypes/ant_colony/ui/
  shared/
    ui_constants.gd              73 lines   class_name AntColonyUI
    ant_colony_theme.tres       165 lines   Theme resource
  ui_test_launcher.gd            30 lines   Entry point
  ui_test_launcher.tscn          53 lines
  main_menu/
    main_menu_test.gd            11 lines
    main_menu_test.tscn         145 lines
  mode_select/
    mode_select_test.gd         123 lines
    mode_select_test.tscn       928 lines   Most complex scene
  pause_menu/
    pause_menu_test.gd           11 lines
    pause_menu_test.tscn        163 lines
  worker_overlay/
    worker_overlay_test.gd       46 lines
    worker_overlay_test.tscn    167 lines
  ant_naming/
    ant_naming_test.gd          411 lines   Full customize screen
    ant_naming_test.tscn        159 lines
  hud/
    hud_test.gd                  51 lines
    hud_test.tscn               112 lines
  settings/
    settings_test.gd            586 lines   6-tab programmatic
    settings_test.tscn           33 lines
  build_menu/
    build_menu_test.gd          371 lines   Hex ring layout
    build_menu_test.tscn         33 lines
  rainbow_menu/
    rainbow_menu_test.gd        537 lines   Tile grid with categories
    rainbow_menu_test.tscn       33 lines
  evolve_menu/
    evolve_menu_test.gd         774 lines   3-tab skill tree
    evolve_menu_test.tscn        33 lines
    evolve_tree_draw.gd         490 lines   Node2D _draw() tree
```

---

## Two UI Construction Patterns

### Pattern A: Scene-Defined (main_menu, mode_select, pause, worker_overlay)
- Layout in .tscn file, designed in Godot editor
- .gd is minimal: just wires signals and toggles visibility
- Best for: static layouts, visually complex scenes the designer tweaks in editor

### Pattern B: Programmatic (settings, evolve, rainbow, build, ant_naming)
- Minimal .tscn: just root Control + BG + BackButton
- All UI built in GDScript `_ready()` / `_build_ui()` / `_create_ui()`
- Best for: data-driven layouts, grids, tab systems, dynamic content
- These menus share `_create_banner()` as a reusable method

### Both Patterns Share:
- ant_colony_theme.tres on root Control
- BG_DARK ColorRect
- BackButton at (8,8) with font_size 6
- Navigation via `get_tree().change_scene_to_file()`
