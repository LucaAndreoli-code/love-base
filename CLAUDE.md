# CLAUDE.md

> Operational guide for Claude Code. Contains project context, conventions, and status.

## Commands

```bash
love .           # Run (INFO logging)
love . --debug   # Debug (DEBUG logging + hot reload + debugger)
busted           # Run all tests
busted spec/entity_spec.lua  # Run single test
```

## Architecture

**Init Aggregator Pattern**: each directory has an `init.lua` that aggregates submodules. Single entry point: `src/init.lua` → `Game`.

```
Game.logger, Game.debug, Game.constants, Game.scenes, Game.systems, Game.ui, Game.utils
```

## Key Files

| File | Purpose |
|------|---------|
| `main.lua` | Minimal entry point |
| `src/init.lua` | Master loader |
| `src/logger.lua` | 4-level logging |
| `src/debug.lua` | Debug overlay (F1) |
| `conf.lua` | LÖVE config (1280x720) |

## Architecture Principles

- **LÖVE is low-level**: provides rendering, input, audio, game loop. No built-in structure for game objects.
- **Systems are organizational**: Entity, EntityManager, Timer, StateMachine are patterns for code organization, not LÖVE extensions.
- **Composition over inheritance**: Behaviors as utility functions, not rigid class hierarchies.
- **Events = broadcast** ("something happened, whoever cares reacts"), **References = direct** ("you, do this").

## Conventions

- **Naming**: `snake_case` for files, `camelCase` for variables/functions, `PascalCase` for classes/modules
- **Constants**: never hardcode values, always use `Game.constants.x`
- **UI Components**: factory pattern with `Component.new()` + metatable
- **Comments**: (if needed) write comments in english
- **Type Annotations**: use LuaLS annotations for all systems:
```lua
---@class Entity
---@field alive boolean
---@field tags table<string, boolean>
```

### Docs

All `.lua` files (other than logger, debug, lurker.lua and generica init aggregator pattern files) should be documented under the folder `docs/`

## Testing

All generic systems in `src/` must have tests in `spec/`. Game-specific code tested manually.

Framework: busted (installed via LuaRocks)

## Project Status

### Implemented ✅
- Init aggregator pattern
- Logger (4 levels, ANSI colors)
- Debug overlay (FPS, F1 toggle)
- Hot reload (lurker.lua)
- Base project structure
- Entity + Test

### TODO 🚧
1. [X] Setup busted (test framework)
2. [X] Entity + test
3. [ ] Entity Manager + test
4. [ ] Math Utils + test
5. [ ] Behaviors + test
6. [ ] Collision Utils + test
7. [ ] Timer + test
8. [ ] State Machine + test
9. [ ] Update init aggregators
10. [ ] Integration test

After completing these, build Asteroids as the first game using the template.

## Development Log

### 2025-01-26
- 

### 2025-01-24
- Restructured README.md and CLAUDE.md
- Defined TODO list of systems to implement

### 2025-01-22
- Implemented init aggregator pattern architecture

---

*Update this file when making important architectural decisions.*