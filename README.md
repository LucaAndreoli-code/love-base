# Love2D Base Template

Modular game template for LÖVE 11.5 with init aggregator pattern.

## Quick Start

```bash
love .           # Run game
love . --debug   # Debug mode (hot reload + verbose logging)
```

## Project Structure

```
├── docs/              # Docs about element of the template
├── assets/
│   ├── data/          # JSON, Lua tables, presets
│   ├── font/          # Custom fonts
│   ├── icon/          # Game icon
│   ├── sounds/        # Audio files
│   └── sprites/       # Images and spritesheets
├── libs/              # Third-party libraries (lurker, etc.)
├── shaders/           # GLSL shaders
├── src/
│   ├── constants/     # Config values (colors, sizes, speeds)
│   ├── scenes/        # Game states (menu, game, pause)
│   ├── systems/       # Core systems (state machine, input, assets)
│   ├── ui/            # Reusable UI components
│   ├── utils/         # Helper functions
│   ├── init.lua       # Master loader
│   ├── logger.lua     # Logging system
│   └── debug.lua      # Debug overlay
├── main.lua           # Entry point
├── conf.lua           # LÖVE configuration
└── build.lua          # love-build config
```

## Architecture

### Init Aggregator Pattern

Each directory has an `init.lua` that exposes submodules. Single entry point:

```lua
local Game = require("src.init")

Game.logger      -- Logging (DEBUG/INFO/WARNING/ERROR)
Game.debug       -- Debug overlay (F1 to toggle)
Game.constants   -- Centralized config
Game.scenes      -- Game scenes
Game.systems     -- Core systems
Game.ui          -- UI components
Game.utils       -- Helpers
```

### Logger

```lua
Game.logger.debug("msg", "source")    -- Only in --debug mode
Game.logger.info("msg", "source")
Game.logger.warning("msg", "source")
Game.logger.error("msg", "source")
```

## Debug Mode

`--debug` flag enables:
- DEBUG level logging
- Hot reload via lurker.lua
- VS Code debugger support
- FPS overlay (F1)

## Tests

All generic systems in `src/` must have tests in `spec/`. Game-specific code tested manually.

Framework: busted (installed via LuaRocks)

## Build

Uses [love-build](https://github.com/ellraiser/love-build) for distribution packages.

## VS Code Setup

`.vscode/settings.json` configuration:
```json
{
  "Lua.runtime.version": "LuaJIT",
  "Lua.workspace.library": [
    "${3rd}/love2d/library"
  ],
  "Lua.diagnostics.globals": [
    "love"
  ]
}
```

`.vscode/launch.json` configuration:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "lua-local",
            "request": "launch",
            "name": "Run LÖVE",
            "program": {
                "command": "love"
            },
            "args": ["."]
        },
        {
            "type": "lua-local",
            "request": "launch",
            "name": "Debug LÖVE",
            "program": {
                "command": "love"
            },
            "args": [".", "--debug"]
        }
    ]
}
```

Required extensions:
- **Lua** (sumneko) — Language server
- **Local Lua Debugger** (tomblind) — Debugging