# CLAUDE.md

> Operational guide for Claude Code. Contains project context, conventions, and status.

## Commands

```bash
love .           # Run (INFO logging)
love . --debug   # Debug (DEBUG logging + hot reload + debugger)
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

## Conventions

- **Naming**: `snake_case` for files, `camelCase` for variables/functions, `PascalCase` for classes/modules
- **Constants**: never hardcode values, always use `Game.constants.x`
- **UI Components**: factory pattern with `Component.new()` + metatable
- **Comments**: (if needed) write comments in english

## Project Status

### Implemented ✅
- Init aggregator pattern
- Logger (4 levels, ANSI colors)
- Debug overlay (FPS, F1 toggle)
- Hot reload (lurker.lua)
- Base project structure

### TODO 🚧
- [ ] Event System (pub/sub)
- [ ] Timer/Tween system
- [ ] Input handler (action mapping, rebinding)
- [ ] State machine (scene transitions)
- [ ] Asset manager (cache, lazy loading)
- [ ] Camera system (follow, shake, bounds)
- [ ] Save/Load system

## Development Log

### 2025-01-24
- Restructured README.md and CLAUDE.md
- Defined TODO list of systems to implement

### 2025-01-22
- Implemented init aggregator pattern architecture

---

*Update this file when making important architectural decisions.*