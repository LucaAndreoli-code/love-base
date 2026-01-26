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

**Systems access:**
```
Game.systems.entity
Game.systems.entityManager
Game.systems.stateMachine
```

**Utils access:**
```
Game.utils.math
Game.utils.collision
```

## Key Files

| File | Purpose |
|------|---------|
| `main.lua` | Minimal entry point |
| `src/init.lua` | Master loader |
| `src/logger.lua` | 4-level logging |
| `src/debug.lua` | Debug overlay (F1) |
| `conf.lua` | LÖVE config (1280x720) |
| `src/systems/entity.lua` | Base entity class (position, velocity, tags, lifecycle) |
| `src/systems/entity_manager.lua` | Entity management and queries by tag |
| `src/systems/state_machine.lua` | Game states with stack support for pause |
| `src/utils/math.lua` | Math utilities (distance, normalize, angle, lerp, clamp) |
| `src/utils/collision.lua` | Collision detection (circle, rect, point) |

## Architecture Principles

- **LÖVE is low-level**: provides rendering, input, audio, game loop. No built-in structure for game objects.
- **Systems are organizational**: Entity, EntityManager, Timer, StateMachine are patterns for code organization, not LÖVE extensions.
- **Composition over inheritance**: Behaviors as utility functions, not rigid class hierarchies.
- **Events = broadcast** ("something happened, whoever cares reacts"), **References = direct** ("you, do this").
- **Center-based coordinates**: Entity x, y is always center. Rectangles in CollisionUtils use center, not top-left.
- **Tags for identity**: Entities use tags (table<string, boolean>) for identification and querying, not class hierarchies.

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

All `.lua` files (other than logger, debug, lurker.lua and generic init aggregator pattern files) should be documented under the folder `docs/`

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
- Entity + test + docs
- EntityManager + test + docs
- MathUtils + test + docs
- CollisionUtils + test + docs
- StateMachine + test + docs

### TODO 🚧
1. [X] Setup busted (test framework)
2. [X] Entity + test
3. [X] EntityManager + test
4. [X] MathUtils + test
5. ~~[ ] Behaviors + test~~ (Behaviors are game-specific, not template)
6. [X] CollisionUtils + test
7. [X] StateMachine + test
8. ~~[ ] Update init aggregators~~ (Update init aggregators only when i need a specific module)
9. [ ] Integration test

### TODO After (when needed)
- [ ] Timer + test (cooldowns, delays, tweens)
- [ ] Input Handler (rebinding, gamepad)
- [ ] Save/Load system

After completing TODO, build Asteroids as the first game using the template.

## Systems Reference

### Entity
Base class for all game objects. Fields: x, y, vx, vy, rotation, radius, alive, tags.
Methods: new(config), update(dt), draw(), destroy(), addTag(tag), removeTag(tag), hasTag(tag)

### EntityManager
Manages entity lifecycle and queries. Uses tag cache for O(1) lookups.
Methods: new(), add(entity), remove(entity), getByTag(tag), refreshTags(entity), getAll(), update(dt), draw(), cleanup(), clear(), count()

### StateMachine
Game state management with stack for layered states (pause over playing).
Callbacks: enter(params), exit(params), update(dt), draw(), pause(), resume(params)
Methods: new(), addState(name, callbacks), setState(name, params), pushState(name, params), popState(params), getState(), update(dt), draw()

### MathUtils
Pure functions: distance, distanceSquared, length, normalize, angle, direction, lerp, clamp

### CollisionUtils
Pure functions: circleCircle, rectRect, circleRect, pointCircle, pointRect
Note: Rectangles use center coordinates (x, y = center, not top-left)

## Development Log

### 2025-01-26
- Added Entity system (position, velocity, rotation, radius, tags, lifecycle)
- Added EntityManager (add, remove, query by tag with cache, cleanup)
- Added MathUtils (distance, normalize, angle, direction, lerp, clamp)
- Added CollisionUtils (circle/rect/point collisions, center-based coords)
- Added StateMachine (states, stack for pause, params passing)
- All systems have tests in spec/ and docs in docs/
- Decided: Behaviors are game-specific, not template

### 2025-01-24
- Restructured README.md and CLAUDE.md
- Defined TODO list of systems to implement

### 2025-01-22
- Implemented init aggregator pattern architecture

---

*Update this file when making important architectural decisions.*