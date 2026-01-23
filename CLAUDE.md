# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Love2D game template using a modular "init aggregator" pattern for clean namespace organization. Built for LÖVE 11.5.

## Commands

```bash
# Run the game (INFO level logging)
love .

# Run with debug mode (DEBUG logging + hot reload via lick.lua + VS Code debugger)
love . --debug
```

For building distributable packages, use [love-build](https://github.com/ellraiser/love-build) with the `build.lua` configuration.

## Architecture

### Init Aggregator Pattern

Each module directory has an `init.lua` that aggregates and exposes submodules. The master loader at `src/init.lua` provides a single entry point:

```lua
local Game = require("src.init")
Game.constants  -- centralized config values
Game.scenes     -- game scenes
Game.systems    -- core systems (state machine, input, assets)
Game.ui         -- reusable UI components
Game.utils      -- helper functions
```

### Key Files

- `main.lua` - Minimal entry point, delegates to `src/init.lua`
- `src/init.lua` - Master loader with `load()`, `update(dt)`, `draw()`, `keypressed(key)`
- `src/logger.lua` - 4-level logging (DEBUG, INFO, WARNING, ERROR) with ANSI colors
- `src/debug.lua` - Debug overlay (FPS, toggle with F1), only active with `--debug` flag
- `conf.lua` - LÖVE configuration (1280x720 window)
- `build.lua` - love-build configuration for Windows/macOS/Linux

### Hot Reload (Debug Mode)

When running with `--debug`, `libs/lick/lick.lua` enables live code reloading. Errors display on screen. The entry point `main.lua` is reloaded when any `.lua` file changes.

### Logger Usage

```lua
local Logger = require("src.logger")
Logger.debug("message", "source")   -- only with --debug
Logger.info("message", "source")
Logger.warning("message", "source")
Logger.error("message", "source")
```

### Scene Interface

Scenes in `src/scenes/` follow this interface:

```lua
function Scene:enter() end
function Scene:exit() end
function Scene:update(dt) end
function Scene:draw() end
function Scene:keypressed(key) end
```

### Module Guidelines

- `constants/` - Config values (colors, dimensions, speeds)
- `systems/` - Core architecture (state machine, input handler, asset manager)
- `scenes/` - Game states (menu, game, pause, gameover)
- `ui/` - Reusable components across scenes
- `utils/` - Generic helpers (math, string, table functions)
- `entities/` - Add when you have 3+ game object types with similar logic
