# Ant Colony UI Reference (Unity 6)

> **NOTE:** This is the Unity 6 adaptation of the UI reference.
> The original Godot 4.6 version is at `.llm/ANT_COLONY_UI_REFERENCE.md`.
> All visual specs (colors, sizes, layouts) are identical — only engine-specific details differ.

> **For use by Claude Code in a NEW repo.** This documents every UI test scene
> built in the reference project at `c:\Projects\Firstpass\LLM-Base`.
> Read this first, then read individual source files as needed.

---

## How To Use This Doc

The new Claude Code session can **read any file** from the reference project using
absolute paths. This doc gives you the overview; source files give you exact code.
When porting, translate GDScript → C# and Godot UI nodes → Unity uGUI components.

```
Reference project root: c:\Projects\Firstpass\LLM-Base
UI scenes root:         c:\Projects\Firstpass\LLM-Base\scenes\prototypes\ant_colony\ui\
Design doc (Unity):     c:\Projects\Firstpass\LLM-Base\.llm\ANT_COLONY_DESIGN_UNITY.md
Design doc (Godot):     c:\Projects\Firstpass\LLM-Base\.llm\ANT_COLONY_DESIGN.md
```

---

## Godot → Unity UI Node Mapping

| Godot Node | Unity Equivalent | Notes |
|------------|-----------------|-------|
| Control | RectTransform (on any UI GameObject) | Base UI element |
| ColorRect | Image (solid color, no sprite) | Set Image.color, no Source Image |
| NinePatchRect | Image with 9-slice Sprite | Set Sprite borders in Sprite Editor |
| TextureRect | Image or RawImage | Image for sprites, RawImage for textures |
| Label | TextMeshProUGUI | Requires TextMeshPro package |
| Button | Button + Image + TextMeshProUGUI child | Button component on Image GO |
| LineEdit | TMP_InputField | TextMeshPro input field |
| HSlider | Slider | Set direction to Left-To-Right |
| VBoxContainer | VerticalLayoutGroup | On a GameObject with RectTransform |
| HBoxContainer | HorizontalLayoutGroup | On a GameObject with RectTransform |
| GridContainer | GridLayoutGroup | Set cell size + constraint |
| CenterContainer | RectTransform anchored center | Anchor min/max = (0.5, 0.5) |
| MarginContainer | LayoutGroup with padding | Or ContentSizeFitter + padding |
| ScrollContainer | ScrollRect + Viewport + Content | Standard Unity scroll setup |
| PanelContainer | Image + VerticalLayoutGroup | Image for background, LG for children |
| HSeparator | Image (1px height) | LayoutElement with preferredHeight = 1 |
| Node2D _draw() | Custom UI via Graphic subclass or procedural mesh | Or use UI LineRenderer / GL |

---

## Assets To Copy

```
Assets/Sprites/UI/Kenney/Large/    182 tiles, 32x32 each (tile_0000.png - tile_0090.png)
Assets/Sprites/UI/Kenney/Small/    322 tiles, 16x16 each (tile_0000.png - tile_0160.png)
Assets/Sprites/UI/Kenney/License.txt
Assets/Fonts/BoldPixels.ttf        Pixel font — create TMP SDF font asset after import
```

**Unity Import Settings:**
- All tile PNGs: Filter Mode = Point, Compression = None, Sprite Mode = Single
- Large tiles: Pixels Per Unit = 32
- Small tiles: Pixels Per Unit = 16
- 9-slice tiles (e.g., tile_0030): Open Sprite Editor, set Border to 14/14/14/14
- BoldPixels.ttf: Create TMP font asset via Window > TextMeshPro > Font Asset Creator

---

## Viewport & Project Settings

- **Reference Resolution:** 640x360 (pixel art)
- **Canvas Scaler:** Scale With Screen Size, Reference Resolution 640x360
- **Screen Match Mode:** Match Width Or Height (Match = 0.5)
- **Window scale:** configurable 2x/3x/4x (Player Settings or runtime resolution change)
- **All text is ALL CAPS** throughout every menu
- **Pixel Perfect:** Consider using Unity's Pixel Perfect Camera package

---

## Shared Constants (`AntColonyUI.cs`)

**Unity equivalent:** `public static class AntColonyUI` (C# static class, no MonoBehaviour needed)
**Reference:** `scenes/prototypes/ant_colony/ui/shared/ui_constants.gd` (73 lines)

### Colors
| Constant | C# Value | Use |
|----------|----------|-----|
| `BG_DARK` | `new Color(0.12f, 0.08f, 0.05f)` | Background for every scene |
| `TEXT_CREAM` | `new Color(0.95f, 0.9f, 0.8f)` | Light text on dark backgrounds |
| `TEXT_DARK` | `new Color(0.2f, 0.15f, 0.1f)` | Dark text on panels |
| `ACCENT_TAN` | `new Color(0.76f, 0.6f, 0.42f)` | Subtle accent (version labels) |
| `ACCENT_ORANGE` | `new Color(0.95f, 0.6f, 0.15f)` | Headers, costs, highlights |
| `FOOD_ORANGE` | `new Color(1.0f, 0.65f, 0.15f)` | Food icon, selected items |
| `RAINBOW_TINT` | `new Color(0.9f, 0.5f, 1.0f, 0.3f)` | Rainbow menu tint |
| `NODE_AVAILABLE` | `new Color(1f, 1f, 1f, 1f)` | Skill tree: available |
| `NODE_PURCHASED` | `new Color(0.6f, 0.85f, 0.4f)` | Skill tree: bought / toggled on |
| `NODE_LOCKED` | `new Color(0.5f, 0.5f, 0.5f, 0.6f)` | Skill tree: locked |
| `NODE_HOVERED` | `new Color(1.0f, 0.95f, 0.7f)` | Skill tree: hover |
| `OVERLAY_DIM` | `new Color(0f, 0f, 0f, 0.6f)` | Modal overlay background |
| `BTN_HOVER` | `new Color(1.2f, 1.1f, 1.0f)` | Button hover — apply via Image.color |
| `BTN_PRESSED` | `new Color(0.8f, 0.75f, 0.7f)` | Button pressed — apply via Image.color |
| `SAVE_GREEN` | `new Color(0.4f, 0.85f, 0.4f)` | Save/confirm buttons |
| `CANCEL_RED` | `new Color(0.9f, 0.35f, 0.3f)` | Cancel/delete buttons |

**Note on BTN_HOVER:** Unity Color values above 1.0 won't brighten unless using HDR. Use ColorBlock on Button component or manually multiply in script. Alternative: use Color(1f, 0.92f, 0.83f) as the hover tint.

### Font Sizes (constants in `AntColonyUI.cs`)
| Constant | Value | Use |
|----------|-------|-----|
| `FONT_TITLE` | 14 | Scene titles (procedural draw menus) |
| `FONT_HEADER` | 10 | Section headers (procedural draw menus) |
| `FONT_BODY` | 8 | Body text (procedural draw menus) |
| `FONT_SMALL` | 6 | Back buttons, version labels |

**IMPORTANT:** Most UI menus set font size to **16** on all TMP text components.
The smaller constants above are only used in the evolve tree draw version.

### Kenney Tile Constants (tiles actually used)
```csharp
// Large tiles (32x32) — paths relative to Assets/Sprites/UI/Kenney/Large/
public static readonly string PANEL_MASTER     = "tile_0018";   // Warm brown panel (legacy)
public static readonly string PANEL_CREAM      = "tile_0000";   // Lighter cream panel
public static readonly string PANEL_BROWN      = "tile_0004";   // Darker brown
public static readonly string PANEL_CREAM_ALT  = "tile_0013";
public static readonly string PANEL_DARK       = "tile_0017";   // Dark panel (ant preview frame)
public static readonly string PANEL_GRID       = "tile_0026";
public static readonly string PANEL_ROUNDED    = "tile_0030";   // *** PRIMARY PANEL TEXTURE *** (9-slice)
public static readonly string CIRCLE_RING      = "tile_0039";   // Evolve tree: available node
public static readonly string CIRCLE_FILLED    = "tile_0040";   // Evolve tree: purchased node
public static readonly string BANNER_LEFT      = "tile_0043";   // Banner system left cap
public static readonly string BANNER_MID       = "tile_0044";   // Banner system middle (tiled)
public static readonly string BANNER_RIGHT     = "tile_0045";   // Banner system right cap
public static readonly string CIRCLE_RING_SM   = "tile_0052";
public static readonly string BANNER_WIDE      = "tile_0056";
public static readonly string BTN_ACCENT       = "tile_0060";
public static readonly string HEX_OUTLINE      = "tile_0065";

// Small tiles (16x16) — paths relative to Assets/Sprites/UI/Kenney/Small/
public static readonly string SMALL_CIRCLE     = "tile_0023";   // HUD food icon
public static readonly string SMALL_RING       = "tile_0046";
public static readonly string SMALL_X_RED      = "tile_0093";   // Delete/trash buttons
public static readonly string SMALL_BAR        = "tile_0115";
```

### Scene Paths (Unity scene or prefab names)
```csharp
public const string LAUNCHER       = "UITestLauncher";
public const string MAIN_MENU      = "MainMenuTest";
public const string MODE_SELECT    = "ModeSelectTest";
public const string SETTINGS       = "SettingsTest";
public const string HUD            = "HudTest";
public const string EVOLVE_MENU    = "EvolveMenuTest";
public const string RAINBOW_MENU   = "RainbowMenuTest";
public const string PAUSE_MENU     = "PauseMenuTest";
public const string WORKER_OVERLAY = "WorkerOverlayTest";
public const string ANT_NAMING     = "AntNamingTest";
public const string BUILD_MENU     = "BuildMenuTest";
```

---

## Theme (ScriptableObject or Static Config)

**Godot original:** `ant_colony_theme.tres` (165 lines)
**Unity equivalent:** Create a `AntColonyTheme` ScriptableObject or static helper that applies styles.

**Base texture:** `tile_0030.png` (PANEL_ROUNDED) for ALL styled controls
**9-slice borders:** 14px all sides (set in Sprite Editor: Border L/R/T/B = 14)

### Global Text Style (applied via TMP settings)
- **Font color:** Black `new Color(0f, 0f, 0f, 1f)` for all text
- **Font outline:** White `new Color(1f, 1f, 1f, 1f)` for all text
- **Outline width:** ~0.15-0.2 in TMP (equivalent to 2px outline in Godot)
- **Font asset:** BoldPixels SDF

### Button Styles
| State | Image.color / tint | Font Color |
|-------|-------------------|------------|
| Normal | White (1,1,1,1) | Black |
| Highlighted | (1f, 0.92f, 0.83f) | Black |
| Pressed | (0.85f, 0.8f, 0.75f) | Black |
| Disabled | (0.6f, 0.55f, 0.5f, 0.7f) | (0.5f, 0.45f, 0.4f, 0.6f) |
| Selected | (0.92f, 0.88f, 0.8f) | (inherits) |

Apply via Unity Button's `ColorBlock` or manual scripting on pointer events.

Content padding: 4/2/4/2 (left/top/right/bottom) via LayoutGroup padding or ContentSizeFitter.

### Slider Styles
- **Background:** flat `new Color(0.15f, 0.1f, 0.07f)`, Image with rounded sprite
- **Fill Area:** flat `new Color(0.5f, 0.35f, 0.2f)`
- **Handle:** flat `new Color(0.6f, 0.42f, 0.25f)` on highlight

### TMP_InputField
- Background: tile_0030 9-slice Image, padding 6/2/6/2
- Focus: tint to `new Color(1.1f, 1.05f, 1.0f)` (or slightly brighter white)

### PanelContainer equivalent
- Image (tile_0030 9-slice sprite) + VerticalLayoutGroup, padding 6/4/6/4

---

## Banner System

Three-part banner for panel titles, used across almost every menu.

### Unity Implementation
Use a HorizontalLayoutGroup with 3 Image children:

```csharp
// Standard banner width = 157px
// Parent: HorizontalLayoutGroup, childForceExpandWidth = false

// Left cap — tile_0043, preserve aspect
// LayoutElement: preferredWidth = 32, preferredHeight = 32

// Middle — tile_0044, Image Type = Tiled
// LayoutElement: flexibleWidth = 1, preferredHeight = 32
// Image.type = Image.Type.Tiled

// Right cap — tile_0045, preserve aspect
// LayoutElement: preferredWidth = 32, preferredHeight = 32

// Label — overlay TextMeshProUGUI, centered, black text, white outline
// Font size 16, alignment = Center + Middle
```

### Wide Banner Variant (rainbow menu: BANNER_W = 220px)
Same pattern, wider middle section. Parent LayoutElement preferredWidth = 220.

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
2. **Background:** BG_DARK `new Color(0.12f, 0.08f, 0.05f)` Image, stretched to fill Canvas
3. **Theme:** All roots use the shared style config (ScriptableObject or static apply)
4. **Panel texture:** `PANEL_ROUNDED` (tile_0030), 9-slice with 14px borders
5. **Text style:** Black text, white outline (TMP outline settings), ALL CAPS
6. **Font size override:** TMP fontSize = 16 on most text components
7. **Navigation:** `SceneManager.LoadScene(AntColonyUI.SCENE_NAME)`
8. **raycastTarget:** false on decorative Images, true on interactive elements (Button, InputField)

---

## Menu Descriptions (11 Menus)

### 1. Test Launcher
**Godot source:** `ui_test_launcher.gd` (30 lines) + `.tscn` (53 lines)
**Unity port:** Single scene with Canvas, VerticalLayoutGroup, 10 Buttons created in `Start()`
**Layout:** BG_DARK, centered VerticalLayoutGroup (spacing 6), 10 buttons (fontSize 16) loading each test scene.

---

### 2. Main Menu
**Godot source:** `main_menu_test.gd` (11 lines) + `.tscn` (145 lines)
**Unity port:** Prefab-defined (layout in Unity Editor, minimal MonoBehaviour)
**Layout:**
- BG_DARK background Image
- Banner "ANT COLONY" positioned at y=60
- 3 centered buttons: `START GAME`, `OPTIONS`, `QUIT` (160x32, VerticalLayoutGroup spacing 12)
- Version label "V0.1.0" bottom-right corner, ACCENT_TAN color, fontSize 6

---

### 3. Mode Select
**Godot source:** `mode_select_test.gd` (123 lines) + `.tscn` (928 lines)
**Unity port:** Prefab-defined panels + overlays, C# MonoBehaviour wires events and toggles
**Complexity:** Most complex prefab

**Layout:**
- Two side-by-side 9-slice Image panels in HorizontalLayoutGroup (center-anchored)
  - Each panel: 270x280, tile_0030, 9-slice border 14, spacing 20 between them
- **Normal panel:** Banner "NORMAL MODE", ColonyInfo TMP (multi-line stats), PLAY button with DeleteX Image button (SMALL_X_RED), LEGACY COLONIES button (hidden, alpha 0.5)
- **Vanilla panel:** Banner "VANILLA MODE", ColonyInfo, PLAY + DeleteX, LOAD COLONY button

**Three overlay systems (children of root Canvas, initially SetActive(false)):**
1. **LoadOverlay:** dim `new Color(0,0,0,0.6f)`, centered panel 480x260, banner "LOAD COLONY"
   - NewGameSlot: green bg `new Color(0.45f, 0.7f, 0.4f, 0.3f)`, text "+ NEW GAME"
   - 3 save slots: tan bg `new Color(0.85f, 0.78f, 0.65f, 0.3f)`, 48px height, NameLabel + StatsLabel + TrashBtn
   - `< Back` close button
2. **LegacyOverlay:** same structure, banner "LEGACY COLONIES", 2 legacy slots
3. **ConfirmOverlay:** dim `new Color(0,0,0,0.5f)`, small panel 180x90
   - Text: "DELETE THIS\nCOLONY?"
   - YES button (CANCEL_RED tint) + NO button in HorizontalLayoutGroup

**Test toggle:** ToggleStateBtn (top-right, alpha 0.4) switches has_save/no_save states
**C# script:** Wires all Button.onClick events, toggles overlay SetActive, updates panel content

---

### 4. Pause Menu
**Godot source:** `pause_menu_test.gd` (11 lines) + `.tscn` (163 lines)
**Unity port:** Prefab-defined
**Layout:**
- BG_DARK + dim overlay `new Color(0, 0, 0, 0.6f)`
- Centered panel 200x160, tile_0030, 9-slice border 14
- Banner "PAUSED"
- VerticalLayoutGroup (spacing 10): `RESUME`, `SETTINGS`, `MAIN MENU` buttons (height 26)

---

### 5. Worker Overlay (Allocate)
**Godot source:** `worker_overlay_test.gd` (46 lines) + `.tscn` (167 lines)
**Unity port:** Prefab-defined modal with C# slider logic
**Layout:**
- Dim overlay `new Color(0, 0, 0, 0.4f)`
- Centered panel 220x150, tile_0030, 9-slice border 14
- Banner "ALLOCATE"
- Content: MinersLabel "MINERS: 0", HaulersLabel "HAULERS: 0", Slider (0-8 wholeNumbers), OK button
- **C# script:** Slider.onValueChanged updates labels: miners = value, haulers = TOTAL_WORKERS (8) - miners

---

### 6. Ant Naming / Customize
**Godot source:** `ant_naming_test.gd` (411 lines) + `.tscn` (159 lines)
**Unity port:** Prefab provides structure, C# MonoBehaviour builds ALL content in `Start()`
**This is a FULL customization screen, not just naming.**

**Prefab provides:**
- BG_DARK, overlay `new Color(0, 0, 0, 0.4f)`
- Panel 260x340, tile_0030, 9-slice border 14
- Content VerticalLayoutGroup (spacing 3)
- Banner "CUSTOMIZE"
- Two test buttons: QueenToggle, UnlockToggle

**C# builds in `BuildUI()`:**
1. **Name input:** TMP_InputField, placeholder "GREG" (rainbow cycling color via `Update()`), fontSize 16
2. **Ant preview:** 9-slice Image frame (PANEL_DARK), custom UI component that draws ant
   - Draws 3-oval ant body (abdomen + thorax + head) with legs, antennae, eye
   - Queen mode: 1.3x scale, gold crown (3 zigzag lines)
   - Color changes with palette selection
   - Implementation: UI Image layering, or custom Graphic subclass with `OnPopulateMesh()`
3. **Color palette:** "ANT COLOR" header, 8-column GridLayoutGroup, 24 swatches (3 rows x 8)
   - Each swatch: Button with Image (background=color, outline via border sprite)
   - Locked by default, "LOCKED" label shown. Toggle with UnlockToggle button
4. **Hat collection (queen only):** "HAT COLLECTION" header, 5-column GridLayoutGroup
   - 10 hats: Hard Hat, Top Hat, Crown, Propeller, Wizard, Party Hat, Viking, Flower, Astronaut, Pirate
   - Each hat: colored Button with tooltip (via EventTrigger + tooltip prefab)
5. **Give Hat button (worker only):** "GIVE HAT?" button, ACCENT_ORANGE tint, 160x26
   - Click changes to "HAT GIVEN!" and sets interactable = false
6. **Action row:** SAVE (SAVE_GREEN tint, 80x26) + CANCEL (CANCEL_RED tint, 80x26)

**Mode switching:** Queen shows hat grid, hides give-hat. Worker shows give-hat, hides hat grid.

---

### 7. In-Game HUD
**Godot source:** `hud_test.gd` (51 lines) + `.tscn` (112 lines)
**Unity port:** Prefab-defined, C# handles tool cycling + radius
**Layout:**
- Top-right: FoodCount "12,450" + FoodIcon (Image, SMALL_CIRCLE, color FOOD_ORANGE)
- Top-left: "DIST: 1,247" + "M:5 H:3" (miners/haulers count)
- Bottom-left: "TOOL: DIG R:1"
- Bottom-center: Instructions label (test only)
- **C# script:** TAB cycles 4 tools (DIG, PHEROMONE, INSPECT, RALLY), `[` `]` adjust radius 1-5
- Use new Input System for key bindings

---

### 8. Settings
**Godot source:** `settings_test.gd` (586 lines) + `.tscn` (33 lines)
**Unity port:** Minimal prefab (BG + BackButton only), everything built in C# `Start()`
**Layout:**
- Canvas center-anchored panel 380x310, tile_0030, 9-slice border 14
- Banner "SETTINGS"
- Padding (12/40/12/10)
- **6 tabs** in HorizontalLayoutGroup: AUDIO, DISP, GAME, PERF, ACCESS, CTRL
  - Active tab: green text `new Color(0.2f, 0.5f, 0.2f)`, inactive: black
  - Tab buttons: 50x20, fontSize 16
- Separator between tabs and content
- Content area: 160px min height (LayoutElement)
- Bottom row: DEFAULTS (56x24), SAVE (64x24), CANCEL (64x24)

**Tab contents:**
1. **AUDIO:** 4 slider rows: MASTER (100%), MUSIC (80%), SFX (100%), AMBIENT (100%)
2. **DISP:** ScrollRect with: Window Mode (WINDOWED/BORDERLESS/FULLSCREEN), Resolution (1280x720/1920x1080/2560x1440), Max FPS (30/60/120/144/UNLIM), UI Scale (1x-4x), Shake slider, Pheromone slider, Trail Quality (SIMPLE/NORMAL/DETAILED), Ant Detail (DOTS/NORMAL/FULL), Show Ant Names toggle
3. **GAME:** Speed (0.25x/0.5x/1x), Zoom Speed slider, Edge Scrolling toggle, Auto-Save toggle, Save Freq (1m/5m/10m), Numbers (STANDARD/SHORT/SCIENTIFIC), Colony Size (SMALL/MEDIUM/LARGE/UNLIMITED)
4. **PERF:** Quality Preset (LOW/MEDIUM/HIGH), Max Ants slider, Show FPS toggle, FPS Warning toggle
5. **ACCESS:** Colorblind mode (OFF/DEUTAN/PROTAN/TRITAN), High Contrast toggle, Font Size (SMALL/NORMAL/LARGE), Large Cursor toggle
6. **CTRL:** ScrollRect with 7 key bindings: MOVE=WASD, DIG=LCLICK, PLACE=RCLICK, ZOOM=SCROLL, EVOLVE=TAB/E, BUILD=B, PAUSE=ESC
   - Key rebinding via Input System's `InputActionRebindingExtensions`

**Reusable helpers:** `CreateSliderRow()`, `CreateOptionRow()`, `CreateToggleRow()`, `CreateKeyRow()`, `CreateStyledButton()`, `CreateBanner()`

---

### 9. Build Menu
**Godot source:** `build_menu_test.gd` (371 lines) + `.tscn` (33 lines)
**Unity port:** Minimal prefab, fully C# programmatic
**Layout:**
- Blur overlay: Unity post-processing Blur effect or render to RenderTexture + blur shader
- "[ GAME WORLD HERE ]" placeholder label
- 6 transport buttons in circular ring (RING_RADIUS=80, CENTER=320,165)
  - Each button: 80x32 RectTransform with 9-slice Image (PANEL_ROUNDED), centered TMP text
  - Selected: FOOD_ORANGE tint, Hover: BTN_HOVER
  - Position via `anchoredPosition = center + new Vector2(Mathf.Cos(angle), Mathf.Sin(angle)) * radius`
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

**Blur shader (Unity URP ShaderGraph or HLSL):**
```hlsl
// URP blur approach: use a fullscreen render feature with Kawase blur
// or capture screen to RenderTexture and apply Gaussian blur material
// Simpler alternative: just dim the background with a semi-transparent overlay
```

---

### 10. Rainbow Menu
**Godot source:** `rainbow_menu_test.gd` (537 lines) + `.tscn` (33 lines)
**Unity port:** Minimal prefab, fully C# programmatic using uGUI
**BG color:** Purple-tinted dark `new Color(0.15f, 0.08f, 0.12f)` (different from standard BG_DARK)

**Layout:**
- Centered panel 510x310, tile_0030, 9-slice border 14
- Padding (10/36/10/6)
- ScrollRect (horizontal disabled, vertical auto)
- VerticalLayoutGroup (spacing 6)
- Banner "OVER THE RAINBOW" (wide: BANNER_W=220)
- Rainbow count label top-right (cycling color via `Update()`, fontSize 16, TMP outline size ~0.2)

**3 Categories with tiles:**
1. **LOGISTICS** (3 items): HIVE MIND (30), SPEED LIGHT (25), GLOBAL CONV (20)
2. **POWER FANTASY** (5 items): QUANTUM (30), AUTO ATTACK (25), AUTO-PILOT (20), GIANT QUEEN (25), VOID STORAGE (20)
3. **COSMETIC** (6 items): BIG HEAD (10), BIG ANT (10), RAINBOW TRAIL (15), FIRE TRAIL (15), BOOGIE BOMB (10), ANT COLORS (10)

**Tile construction:**
- Each tile: 76x40, 9-slice Image (PANEL_ROUNDED, border 14)
- Text color: rainbow hue `Color.HSVToRGB(index / 16f, 0.7f, 0.95f)` with TMP black outline
- Category headers: centered, ACCENT_ORANGE color, TMP black outline
- Cost label below each tile
- Click toggles: NODE_PURCHASED tint (on) / White (off)
- Hover: NODE_HOVERED tint + tooltip (child Canvas or overlay prefab)
- Tooltip: flips to left side if would overflow right edge (check `Screen.width`)

---

### 11. Evolve Menu (Two Implementations)

#### 11a. Tab-Based (`EvolveMenuTest.cs`) — port of 774-line GDScript
**Unity port:** Minimal prefab, fully C# programmatic

**Layout:**
- Canvas center-anchored panel 460x330, tile_0030, 9-slice border 14
- Padding (12/40/12/8)
- Banner "EVOLVE" (programmatic)
- Rainbow count label top-right (cycling, TMP outline)
- **3 tabs** (HorizontalLayoutGroup, 100x20 each):
  - PLAYER: green `new Color(0.3f, 0.65f, 0.3f)`
  - LOGISTICS: yellow `new Color(0.7f, 0.6f, 0.15f)`
  - COLONY: red `new Color(0.7f, 0.25f, 0.25f)`
- Active tab: tab color text, inactive: black
- Separator, then content area (LayoutElement minHeight 160)

**Skill tiles:**
- Each: 92x40, 9-slice Image (PANEL_ROUNDED, border 14)
- Default tint: `new Color(0.5f, 0.45f, 0.38f, 0.7f)` (dimmed)
- Text: TMP with enableWordWrapping, fontSize 16
- Rainbow tiles: cycling color, TMP outline
- Regular tiles: black text
- Cost label below tile. Progressive skills show "0/50" or "0/10" above cost.
- Fork labels ("PICK 2 OF 3", "PICK 1 OF 4") in red, centered

**Hover:** Tab color tint + tooltip (9-slice Image styled tooltip prefab)
**Click:** Cycles state 0 → 1 → 2 → 0 (tab color → tab color → NODE_LOCKED)

**Skill data:** PLAYER (7 tiers), LOGISTICS (7 tiers), COLONY (6 tiers)
Each tier is a List of skill dictionaries: `{name, desc, cost, state, [prog], [pick], [rainbow]}`
Use C# classes or structs for type safety.

#### 11b. Scrollable Tree (`EvolveTreeDraw.cs`) — port of 490-line GDScript
**Unity port:** Custom Graphic subclass or procedural UI with ScrollRect
- Three parallel prongs from shared trunk: PLAYER ANT (cx=160), LOGISTICS (cx=320), COLONY (cx=480)
- Standard nodes (30px circles) and fork nodes (20px) with branching
- Fork offsets: 2=[-28,28], 3=[-42,0,42], 4=[-56,-19,19,56]
- Labels beside nodes (left tree → right labels, right tree → left labels)
- Scroll wheel pans vertically via ScrollRect. Click cycles node state.
- Tooltip: UI overlay with 9-slice panel + TMP text
- Implementation options: Canvas with positioned Image elements, or custom `Graphic.OnPopulateMesh()`, or world-space Canvas with `GL.Begin()`/`GL.End()` for lines

---

## File Inventory (Unity equivalents — 24 source files)

```
Assets/Scripts/UI/AntColony/
  Shared/
    AntColonyUI.cs              Static constants class
    AntColonyTheme.asset        ScriptableObject (optional)
  UITestLauncher.cs             Entry point MonoBehaviour
  UITestLauncher.unity          Scene file
  MainMenu/
    MainMenuTest.cs             MonoBehaviour (minimal)
    MainMenuTest.prefab         Prefab layout
  ModeSelect/
    ModeSelectTest.cs           MonoBehaviour (signal wiring)
    ModeSelectTest.prefab       Most complex prefab
  PauseMenu/
    PauseMenuTest.cs            MonoBehaviour (minimal)
    PauseMenuTest.prefab        Prefab layout
  WorkerOverlay/
    WorkerOverlayTest.cs        MonoBehaviour (slider logic)
    WorkerOverlayTest.prefab    Prefab layout
  AntNaming/
    AntNamingTest.cs            MonoBehaviour (full customize, ~400 lines)
    AntNamingTest.prefab        Prefab structure
  Hud/
    HudTest.cs                  MonoBehaviour (tool cycling)
    HudTest.prefab              Prefab layout
  Settings/
    SettingsTest.cs             MonoBehaviour (6-tab programmatic, ~580 lines)
    SettingsTest.prefab         Minimal prefab
  BuildMenu/
    BuildMenuTest.cs            MonoBehaviour (hex ring, ~370 lines)
    BuildMenuTest.prefab        Minimal prefab
  RainbowMenu/
    RainbowMenuTest.cs          MonoBehaviour (tile grid, ~530 lines)
    RainbowMenuTest.prefab      Minimal prefab
  EvolveMenu/
    EvolveMenuTest.cs           MonoBehaviour (3-tab skill tree, ~770 lines)
    EvolveMenuTest.prefab       Minimal prefab
    EvolveTreeDraw.cs           Custom Graphic or procedural UI (~490 lines)
```

---

## Two UI Construction Patterns

### Pattern A: Prefab-Defined (main_menu, mode_select, pause, worker_overlay)
- Layout in .prefab file, designed in Unity Editor
- MonoBehaviour is minimal: just wires Button.onClick and toggles SetActive
- Best for: static layouts, visually complex scenes tweaked in editor

### Pattern B: Programmatic (settings, evolve, rainbow, build, ant_naming)
- Minimal .prefab: just root Canvas + BG Image + BackButton
- All UI built in C# `Start()` / `BuildUI()` / `CreateUI()`
- Best for: data-driven layouts, grids, tab systems, dynamic content
- These menus share `CreateBanner()` as a reusable method

### Both Patterns Share:
- AntColonyTheme config on root or applied via static helper
- BG_DARK Image background
- BackButton at (8,8) with fontSize 6
- Navigation via `SceneManager.LoadScene()`
