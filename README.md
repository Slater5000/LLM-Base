# Creature RPG

Creature collection RPG with real-time tactical 3v3 combat and elemental synergies. Built with Godot 4.6.

## Quick Start

1. Open this folder in **Godot 4.6**
2. Press **F5** (or the Play button) to run
3. The console should print: "Creature RPG - Foundation loaded successfully"

## Game Overview

- **Genre:** Creature collection RPG (Pokémon meets Dragon Age)
- **Combat:** Real-time 3v3 battles with pause-and-play tactical decisions
- **Elements:** Fire (DPS), Water (Support), Earth (Tank), Air (Controller)
- **Hook:** No RNG misses, no PP management — pure tactical team building with synergy bonuses

See `.llm/DISCOVERY.md` for full design documentation.

## Project Structure

```
project/
├── autoloads/          # Global state managers (when implemented)
├── data/               # Resource definitions (creatures, moves, synergies)
├── scenes/             # Game scenes (world, combat, UI)
├── .llm/               # Design docs and AI instructions
│   ├── DISCOVERY.md    # Game design document
│   ├── DECISIONS.md    # Technical decisions
│   ├── PRINCIPLES.md   # Development guidelines
│   └── PATTERNS.md     # Reference implementations
├── main.tscn           # Entry scene
├── main.gd             # Entry script
└── project.godot       # Godot project config
```

## Development

### Running the Game
- Press **F5** in Godot editor to run
- Press **F6** to run current scene

### Linting (optional)
Install gdtoolkit for GDScript linting:
```bash
pip install gdtoolkit
gdlint .
```

### Input Map
| Action | Keys |
|--------|------|
| Move | WASD / Arrow Keys |
| Interact | E / Enter |
| Pause Menu | Escape |
| Pause Combat | Spacebar |

## Tech Stack

- **Engine:** Godot 4.6
- **Language:** GDScript (typed)
- **Renderer:** Compatibility (for pixel art)
- **Resolution:** 640x360 viewport, 2x window scale

See `.llm/DECISIONS.md` for full technical decisions.

## Auto-Persona System

The AI automatically adopts specialized expertise based on context:

| Domain | Focus |
|--------|-------|
| **@architect** | Structure, performance, technical decisions |
| **@gameplay** | Core loop, fun, balance, progression |
| **@ui** | Interface, input, feedback, accessibility |
| **@systems** | Individual game systems, data design |
| **@network** | Multiplayer, synchronization |
| **@quality** | Testing, debugging, stability |

## Archived Files

Web/TypeScript files from the original template are preserved in `.web-archive/` in case they're needed for tooling later.
