class_name AntColonyUI
## Shared constants for all ant colony UI test scenes.

# --- Viewport ---
const VIEWPORT_W := 640.0
const VIEWPORT_H := 360.0

# --- Colors ---
const BG_DARK := Color(0.12, 0.08, 0.05, 1.0)
const TEXT_CREAM := Color(0.95, 0.9, 0.8, 1.0)
const TEXT_DARK := Color(0.2, 0.15, 0.1, 1.0)
const ACCENT_TAN := Color(0.76, 0.6, 0.42, 1.0)
const ACCENT_ORANGE := Color(0.95, 0.6, 0.15, 1.0)
const FOOD_ORANGE := Color(1.0, 0.65, 0.15, 1.0)
const RAINBOW_TINT := Color(0.9, 0.5, 1.0, 0.3)
const NODE_AVAILABLE := Color(1.0, 1.0, 1.0, 1.0)
const NODE_PURCHASED := Color(0.6, 0.85, 0.4, 1.0)
const NODE_LOCKED := Color(0.5, 0.5, 0.5, 0.6)
const NODE_HOVERED := Color(1.0, 0.95, 0.7, 1.0)
const OVERLAY_DIM := Color(0.0, 0.0, 0.0, 0.6)
const BTN_HOVER := Color(1.2, 1.1, 1.0, 1.0)
const BTN_PRESSED := Color(0.8, 0.75, 0.7, 1.0)
const SAVE_GREEN := Color(0.4, 0.85, 0.4, 1.0)
const CANCEL_RED := Color(0.9, 0.35, 0.3, 1.0)

# --- Font Sizes ---
const FONT_TITLE := 14
const FONT_HEADER := 10
const FONT_BODY := 8
const FONT_SMALL := 6

# --- Asset Paths (Kenney Brown Fantasy Theme) ---
const KENNEY_LARGE := "res://assets/sprites/ui/kenney/large/"
const KENNEY_SMALL := "res://assets/sprites/ui/kenney/small/"

# Large tiles (32x32)
const PANEL_MASTER := KENNEY_LARGE + "tile_0018.png"
const PANEL_CREAM := KENNEY_LARGE + "tile_0000.png"
const PANEL_BROWN := KENNEY_LARGE + "tile_0004.png"
const PANEL_CREAM_ALT := KENNEY_LARGE + "tile_0013.png"
const PANEL_DARK := KENNEY_LARGE + "tile_0017.png"
const PANEL_GRID := KENNEY_LARGE + "tile_0026.png"
const PANEL_ROUNDED := KENNEY_LARGE + "tile_0030.png"
const CIRCLE_RING := KENNEY_LARGE + "tile_0039.png"
const CIRCLE_FILLED := KENNEY_LARGE + "tile_0040.png"
const BANNER_LEFT := KENNEY_LARGE + "tile_0043.png"
const BANNER_MID := KENNEY_LARGE + "tile_0044.png"
const BANNER_RIGHT := KENNEY_LARGE + "tile_0045.png"
const CIRCLE_RING_SM := KENNEY_LARGE + "tile_0052.png"
const BANNER_WIDE := KENNEY_LARGE + "tile_0056.png"
const BTN_ACCENT := KENNEY_LARGE + "tile_0060.png"
const HEX_OUTLINE := KENNEY_LARGE + "tile_0065.png"

# Small tiles (16x16)
const SMALL_CIRCLE := KENNEY_SMALL + "tile_0023.png"
const SMALL_RING := KENNEY_SMALL + "tile_0046.png"
const SMALL_X_RED := KENNEY_SMALL + "tile_0093.png"
const SMALL_BAR := KENNEY_SMALL + "tile_0115.png"

# --- Scene Paths ---
const SCENE_BASE := "res://scenes/prototypes/ant_colony/ui/"
const LAUNCHER := SCENE_BASE + "ui_test_launcher.tscn"
const MAIN_MENU := SCENE_BASE + "main_menu/main_menu_test.tscn"
const MODE_SELECT := SCENE_BASE + "mode_select/mode_select_test.tscn"
const SETTINGS := SCENE_BASE + "settings/settings_test.tscn"
const HUD := SCENE_BASE + "hud/hud_test.tscn"
const EVOLVE_MENU := SCENE_BASE + "evolve_menu/evolve_menu_test.tscn"
const RAINBOW_MENU := SCENE_BASE + "rainbow_menu/rainbow_menu_test.tscn"
const PAUSE_MENU := SCENE_BASE + "pause_menu/pause_menu_test.tscn"
const WORKER_OVERLAY := SCENE_BASE + "worker_overlay/worker_overlay_test.tscn"
const ANT_NAMING := SCENE_BASE + "ant_naming/ant_naming_test.tscn"
const BUILD_MENU := SCENE_BASE + "build_menu/build_menu_test.tscn"
