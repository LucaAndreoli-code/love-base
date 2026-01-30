# GEMINI.md

> Operational guide for Gemini. Contains project context, conventions, and status.

## Commands
```bash
love .           # Run (INFO logging)
love . --debug   # Debug (DEBUG logging + hot reload + debugger)
busted           # Run all tests
```

## Conventions
- **LÖVE is low-level**: provides rendering, input, audio, game loop. No built-in structure for game objects.
- **Systems are organizational**: Entity, EntityManager, Timer, StateMachine are patterns for code organization, not LÖVE extensions.
- **Composition over inheritance**: Behaviors as utility functions, not rigid class hierarchies.
- **Events = broadcast** ("something happened, whoever cares reacts"), 
- **References = direct** ("you, do this").
- **Center-based coordinates**: Entity x, y is always center. Rectangles in CollisionUtils use center, not top-left.
- **Tags for identity**: Entities use tags (table<string, boolean>) for identification and querying, not class hierarchies.
- **Init Aggregator Pattern**: All systems are initialized in `src/init.lua` using `System.new()` + metatable.
- **Mixin Pattern**: All systems use mixin pattern for code organization.
- **Modular Structure**: All systems are split into multiple files for better organization.
- **Type Annotations**: use LuaLS annotations for all systems.
- **Comments**: (if needed) write comments in english
- **Documentation**: All systems should be documented under the folder `docs/`
- **Naming**: `snake_case` for files, `camelCase` for variables/functions, `PascalCase` for classes/modules
- **Constants**: never hardcode values, always use `Game.constants.x`
- **UI Components**: factory pattern with `Component.new()` + metatable
- **Comments**: (if needed) write comments in english
- **Logger**: Use
- **Type Annotations**: use LuaLS annotations for all systems:
```lua
---@class Entity
---@field alive boolean
---@field tags table<string, boolean>
```

## Systems Reference

All `.lua` files (other than logger, debug, lurker.lua and generic init aggregator pattern files) should be documented under the folder `docs/`

### Entity
Base class for all game objects. Fields: x, y, vx, vy, rotation, radius, alive, tags.
Methods: new(config), update(dt), draw(), destroy(), addTag(tag), removeTag(tag), hasTag(tag) (see docs/systems/entity.md for more info)

### EntityManager
Manages entity lifecycle and queries. Uses tag cache for O(1) lookups.
Methods: new(), add(entity), remove(entity), getByTag(tag), refreshTags(entity), getAll(), update(dt), draw(), cleanup(), clear(), count() (see docs/systems/entity_manager.md for more info)

### StateMachine
Game state management with stack for layered states (pause over playing).
Callbacks: enter(params), exit(params), update(dt), draw(), pause(), resume(params)
Methods: new(), addState(name, callbacks), setState(name, params), pushState(name, params), popState(params), getState(), update(dt), draw() (see docs/systems/state_machine.md for more info)

### MathUtils
Pure functions: distance, distanceSquared, length, normalize, angle, direction, lerp, clamp (see docs/systems/math_utils.md for more info)

### CollisionUtils
Pure functions: circleCircle, rectRect, circleRect, pointCircle, pointRect
Note: Rectangles use center coordinates (x, y = center, not top-left) (see docs/systems/collision_utils.md for more info)

### InputHandler
Unified input system with action mapping, contexts, and rebinding. (see docs/systems/input_handler.md for more info)