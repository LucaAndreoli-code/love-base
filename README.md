# Love2D Base Template

A modular game template for LÖVE 11.5. Includes essential systems for entity management, state machines, collision detection, and UI components. Designed for developers who want a clean starting point without the overhead of a full engine.

## Quick Start

```bash
love .           # Run game
love . --debug   # Debug mode (hot reload, verbose logging, F1 overlay)
```

## Project Structure

```
├── main.lua           # Entry point (minimal, delegates to src/init.lua)
├── conf.lua           # LÖVE configuration (1280x720)
├── src/
│   ├── init.lua       # Master loader (Game object)
│   ├── logger.lua     # 4-level logging (DEBUG/INFO/WARNING/ERROR)
│   ├── debug.lua      # Debug overlay (F1 toggle)
│   ├── constants/     # Configuration values (colors, gameplay)
│   ├── scenes/        # Game states (add your scenes here)
│   ├── systems/       # Core systems (entity, state machine)
│   ├── ui/            # UI components (button)
│   └── utils/         # Helper functions (math, collision)
├── spec/              # Test files (busted framework)
├── docs/              # System documentation
├── assets/
│   ├── sprites/       # Images and spritesheets
│   ├── sounds/        # Audio files
│   ├── font/          # Custom fonts
│   └── data/          # JSON, Lua tables
├── libs/              # Third-party libraries (lurker)
└── shaders/           # GLSL shaders
```

## Available Systems

| System | Access | Description |
|--------|--------|-------------|
| **Entity** | `Game.systems.entity` | Base class for game objects (position, velocity, tags, lifecycle) |
| **EntityManager** | `Game.systems.entityManager` | Entity lifecycle and tag-based queries (O(1) lookup) |
| **StateMachine** | `Game.systems.stateMachine` | Stack-based state management for scenes and overlays |
| **MathUtils** | `Game.utils.math` | Distance, normalize, angle, lerp, clamp |
| **CollisionUtils** | `Game.utils.collision` | Circle, rectangle, and point collision detection |
| **Button** | `Game.ui.button` | Clickable UI component with hover/press states |
| **Logger** | `Game.logger` | Colored console output with log levels |

## Debug Mode

Run with `love . --debug` to enable:

- **DEBUG logging** — Verbose output from all systems
- **Hot reload** — Automatic code refresh on file save (via lurker.lua)
- **VS Code debugger** — Breakpoint support with lldebugger
- **F1 overlay** — FPS counter and entity hitbox visualization

Debug features are disabled in normal mode (`love .`).

## Testing

Tests use the [busted](https://lunarmodules.github.io/busted/) framework.

```bash
busted                        # Run all tests
busted spec/entity_spec.lua   # Run single test file
busted --verbose              # Verbose output
```

Install via LuaRocks: `luarocks install busted`

## Building

Uses [love-build](https://github.com/ellraiser/love-build) for distribution packages.

```bash
love-build . --windows --macos --linux
```

See `build.lua` for configuration options.

## VS Code Setup

### settings.json

```json
{
  "Lua.runtime.version": "LuaJIT",
  "Lua.workspace.library": [
    "${3rd}/love2d/library",
    "${3rd}/busted/library"
  ],
  "Lua.diagnostics.globals": ["love"]
}
```

### launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "lua-local",
      "request": "launch",
      "name": "Run LÖVE",
      "program": { "command": "love" },
      "args": ["."]
    },
    {
      "type": "lua-local",
      "request": "launch",
      "name": "Debug LÖVE",
      "program": { "command": "love" },
      "args": [".", "--debug"]
    }
  ]
}
```

### Required Extensions

- [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) (sumneko) — Language server
- [Local Lua Debugger](https://marketplace.visualstudio.com/items?itemName=tomblind.local-lua-debugger-vscode) (tomblind) — Debugging

---

See `CLAUDE.md` for architecture details and development conventions.
