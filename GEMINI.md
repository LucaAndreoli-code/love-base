# GEMINI.md

Operational guide for Gemini. Contains project architecture, conventions, and development status.

## Commands

```bash
love .                        # Run (INFO logging)
love . --debug                # Debug mode (DEBUG logging + hot reload + F1 overlay)
busted                        # Run all tests
busted spec/entity_spec.lua   # Run single test file
```

---

## Architecture: Init Aggregator Pattern

> **THIS IS THE CORE ARCHITECTURAL RULE. BREAKING IT BREAKS THE ENTIRE CODEBASE ORGANIZATION.**

### The Rule

Every directory has an `init.lua` that aggregates its submodules. There is ONE entry point: `src/init.lua` returns `Game`.

### Access Paths

```
Game.logger          -- Logging system
Game.debug           -- Debug overlay
Game.constants       -- Configuration values
  .colors            -- UI and debug colors
  .gameplay          -- Screen size, speeds
Game.scenes          -- Game states
Game.systems         -- Core systems
  .entity            -- Base entity class
  .entityManager     -- Entity lifecycle and queries
  .stateMachine      -- State management
  .inputHandler      -- Input abstraction and rebinding
Game.ui              -- UI components
  .button            -- Clickable button
Game.utils           -- Helper functions
  .math              -- Distance, lerp, clamp, etc.
  .collision         -- Collision detection
```

### WRONG vs RIGHT

**WRONG** - Direct require to submodules:
```lua
local Colors = require("src.constants.colors")      -- NO!
local Entity = require("src.systems.entity")        -- NO!
local CollisionUtils = require("src.utils.collision") -- NO!
```

**RIGHT** - Always through Game:
```lua
local Game = require("src.init")

function something()
    local Colors = Game.constants.colors
    local entity = Game.systems.entity.new({...})
    local hit = Game.utils.collision.circleCircle(a, b)
end
```

### Why This Pattern?

- **Single entry point** - All code accesses modules through `Game`
- **Easy refactoring** - Rename a file, update only its init.lua
- **Clear hierarchy** - Dependencies are explicit and traceable
- **No circular dependencies** - The aggregator pattern prevents them

### Timing

Modules are populated during `Game.load()`. Access them inside functions (at runtime) to guarantee they're loaded:

```lua
local Game = require("src.init")

-- WRONG: accessed at require time, Game.constants may be nil
local Colors = Game.constants.colors

-- RIGHT: accessed at runtime, Game.load() has already run
function draw()
    local Colors = Game.constants.colors
    love.graphics.setColor(Colors.button.normal)
end
```

### Allowed Exceptions

| Exception | Reason |
|-----------|--------|
| `main.lua` requires `src.init` | Entry point |
| `init.lua` files require their submodules | That's their purpose |
| `Logger` can be required directly | Used everywhere, including init files |

---

## Architecture Principles

- **LOVE is low-level** - Provides rendering, input, audio, game loop. No built-in structure for game objects.
- **Systems are organizational** - Entity, EntityManager, StateMachine are patterns for code organization, not LOVE extensions.
- **Composition over inheritance** - Behaviors as utility functions, not rigid class hierarchies.
- **Events = broadcast** ("something happened, whoever cares reacts"), **References = direct** ("you, do this").
- **Center-based coordinates** - Entity x, y is always center. Rectangles in CollisionUtils use center, not top-left.
- **Tags for identity** - Entities use tags (`table<string, boolean>`) for identification and querying, not class hierarchies.

---

## Conventions

### Naming

| Type | Convention | Example |
|------|------------|---------|
| Files | `snake_case` | `entity_manager.lua` |
| Variables/Functions | `camelCase` | `entityManager`, `getByTag()` |
| Classes/Modules | `PascalCase` | `Entity`, `StateMachine` |

### Constants

Never hardcode values. Always use `Game.constants`:

```lua
-- WRONG
local speed = 300

-- RIGHT
local speed = Game.constants.gameplay.player.speed
```

### Type Annotations

Use LuaLS annotations for all systems:

```lua
---@class Entity
---@field x number
---@field y number
---@field alive boolean
---@field tags table<string, boolean>
```

### Documentation

All systems in `src/` should have documentation in `docs/`. Exceptions: logger, debug, init files.

---

## Key Files

| File | Purpose |
|------|---------|
| `main.lua` | Minimal entry point |
| `src/init.lua` | Master loader, returns Game object |
| `src/logger.lua` | 4-level logging (DEBUG/INFO/WARNING/ERROR) |
| `src/debug.lua` | Debug overlay (F1, only with --debug) |
| `conf.lua` | LOVE configuration (1280x720) |
| `src/systems/entity.lua` | Base entity class with drawDebug() |
| `src/systems/entity_manager.lua` | Entity lifecycle and tag queries |
| `src/systems/state_machine.lua` | Stack-based state management |
| `src/systems/input_handler.lua` | Input abstraction, rebinding, buffering |
| `src/utils/math.lua` | Math utilities |
| `src/utils/collision.lua` | Collision detection |
| `src/ui/button.lua` | Clickable button component |
| `src/constants/colors.lua` | UI and debug colors |
| `src/constants/gameplay.lua` | Screen size, gameplay values |

---

## Systems Reference

### Entity

Base class for all game objects.

**Fields:** `x`, `y`, `vx`, `vy`, `rotation`, `radius`, `alive`, `tags`

**Methods:**
- `new(config)` - Create entity with optional config table
- `update(dt)` - Update position based on velocity
- `draw()` - Empty, override in subclasses
- `drawDebug()` - Draw hitbox, center point, velocity vector
- `destroy()` - Set alive = false
- `addTag(tag)`, `removeTag(tag)`, `hasTag(tag)` - Tag management

### EntityManager

Manages entity lifecycle and queries. Uses tag cache for O(1) lookups.

**Methods:**
- `new()` - Create manager
- `add(entity)`, `remove(entity)` - Add/remove entities
- `getByTag(tag)` - Get all entities with tag (returns table)
- `refreshTags(entity)` - Update tag cache after tag changes
- `getAll()` - Get all entities
- `update(dt)`, `draw()`, `drawDebug()` - Update/render all entities
- `cleanup()` - Remove dead entities
- `clear()` - Remove all entities
- `count()` - Count alive entities

### StateMachine

Stack-based state management for scenes and overlays.

**Callbacks:** `enter(params)`, `exit(params)`, `update(dt)`, `draw()`, `pause()`, `resume(params)`

**Methods:**
- `new()` - Create state machine
- `addState(name, callbacks)` - Register a state
- `setState(name, params)` - Clear stack, set single state
- `pushState(name, params)` - Push overlay state
- `popState(params)` - Remove top state
- `getState()` - Get current state name
- `update(dt)` - Update top state only
- `draw()` - Draw ALL states bottom-to-top

### MathUtils

Pure functions, no side effects.

- `distance(x1, y1, x2, y2)` - Distance between points
- `distanceSquared(x1, y1, x2, y2)` - Squared distance (faster)
- `length(x, y)` - Vector length
- `normalize(x, y)` - Unit vector (returns x, y)
- `angle(x1, y1, x2, y2)` - Angle between points
- `direction(angle)` - Unit vector from angle (returns x, y)
- `lerp(a, b, t)` - Linear interpolation
- `clamp(value, min, max)` - Clamp value to range

### CollisionUtils

Pure functions, no side effects. **All rectangles use CENTER coordinates.**

- `circleCircle(a, b)` - Circle vs circle
- `rectRect(a, b)` - Rectangle vs rectangle
- `circleRect(circle, rect)` - Circle vs rectangle
- `pointCircle(px, py, circle)` - Point vs circle
- `pointRect(px, py, rect)` - Point vs rectangle

### InputHandler

Abstracts input from keyboard/gamepad into actions. Tracks press timing for buffering.

**Methods:**
- `new(config)` - Create handler with optional custom bindings
- `update()` - Process input events (call every frame)
- `isHeld(action)` - True while action is held
- `isPressed(action)` - True only on press frame
- `isReleased(action)` - True only on release frame
- `wasPressedWithin(action, seconds)` - True if pressed within time window
- `getAxis(axisName)` - Returns -1 to 1 for horizontal/vertical
- `rebind(action, deviceType, key)` - Change binding at runtime
- `getBindings()` - Get current bindings table
- `getActiveDevice()` - Returns "keyboard" or "gamepad"

### Button (UI)

Clickable button with hover/press states. Mouse only (keyboard navigation planned with InputHandler).

**Config:** `x`, `y`, `width`, `height`, `text`, `onClick`

**Methods:**
- `new(config)` - Create button
- `update(dt)` - Update hover/press state, trigger onClick
- `draw()` - Render button
- `isHovered()`, `isPressed()` - Query state
- `containsPoint(px, py)` - Hit test

---

## Testing

Framework: [busted](https://lunarmodules.github.io/busted/) (install via LuaRocks)

- All generic systems in `src/` must have tests in `spec/`
- Game-specific code tested manually
- Currently: 162 tests passing

---

## Project Status

### Implemented

- Init aggregator pattern (enforced)
- Logger (4 levels, ANSI colors)
- Debug overlay (FPS, F1 toggle, hitbox visualization)
- Hot reload (lurker.lua)
- Entity + EntityManager + tests + docs
- StateMachine + tests + docs
- MathUtils + CollisionUtils + tests + docs
- Button UI component + docs
- InputHandler + tests + docs

### TODO

- [ ] Timer system (cooldowns, delays, tweens)
- [ ] Save/Load system

---

## Development Log

### 2026-01-29
- Added InputHandler system (action mapping, rebinding, press/release/held states, input buffering, gamepad support)
- 162 tests passing

### 2026-01-28
- Enforced init aggregator pattern across all modules
- Added Button UI component (src/ui/button.lua + docs)
- Added Entity:drawDebug() and EntityManager:drawDebug() for hitbox visualization
- Added debug colors to Game.constants.colors
- Debug overlay (F1) now requires --debug flag
- Created and removed integration test scenes (menu, game, pause)
- 111 tests passing

### 2025-01-26
- Added Entity system (position, velocity, rotation, radius, tags, lifecycle)
- Added EntityManager (add, remove, query by tag with cache, cleanup)
- Added MathUtils (distance, normalize, angle, direction, lerp, clamp)
- Added CollisionUtils (circle/rect/point collisions, center-based coords)
- Added StateMachine (states, stack for pause, params passing)
- All systems have tests and docs

### 2025-01-24
- Restructured README.md and CLAUDE.md
- Defined TODO list of systems to implement

### 2025-01-22
- Implemented init aggregator pattern architecture

---

*Update this file when making architectural decisions.*
