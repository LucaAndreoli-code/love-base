# State Machine

Stack-based state machine for managing game states. Supports layered states for overlay patterns (e.g., game running with pause menu on top).

## Key Concepts

### States and Callbacks

A state is a named configuration with optional callbacks that respond to lifecycle events. States must be registered before use.

### Stack-Based Design

States are managed on a stack, enabling layered rendering:
- **Top of stack**: Current active state (receives `update`)
- **Entire stack**: All states render bottom-to-top (layering)

```
Stack:      [playing] [pause]
                ↑         ↑
              bottom     top (current)

draw() renders: playing first, then pause on top
update() calls: only pause (top)
```

### setState vs pushState/popState

| Method | Behavior |
|--------|----------|
| `setState(name)` | Clears stack, sets single state (navigation) |
| `pushState(name)` | Adds state on top (overlay) |
| `popState()` | Removes top state, resumes previous |

Use `setState` for navigation (menu → playing → gameover).
Use `pushState`/`popState` for overlays (pause, dialogs, inventory).

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `states` | table<string, StateCallbacks> | Registered state definitions |
| `stack` | string[] | Active state stack (bottom to top) |

## Callbacks

All callbacks are optional. Define only what you need.

| Callback | Signature | When Called |
|----------|-----------|-------------|
| `enter` | `(params?: table)` | State becomes active (setState, pushState) |
| `exit` | `(params?: table)` | State is removed (setState, popState) |
| `update` | `(dt: number)` | Every frame, only for top state |
| `draw` | `()` | Every frame, for ALL states (bottom to top) |
| `pause` | `()` | Another state is pushed on top |
| `resume` | `(params?: table)` | Returns to top after popState |

## Methods

### StateMachine.new()

Creates a new state machine.

```lua
StateMachine.new() -> StateMachine
```

---

### StateMachine:addState(name, callbacks)

Registers a state with its callbacks.

```lua
sm:addState(name, callbacks) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Unique state identifier |
| `callbacks` | StateCallbacks | Table of callback functions |

---

### StateMachine:setState(name, params)

Clears the stack and sets a new state.

```lua
sm:setState(name, params?) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | State to activate |
| `params` | table? | Passed to `exit` and `enter` |

---

### StateMachine:pushState(name, params)

Pushes a new state onto the stack.

```lua
sm:pushState(name, params?) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | State to push |
| `params` | table? | Passed to `enter` |

---

### StateMachine:popState(params)

Removes the current state from the stack.

```lua
sm:popState(params?) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `params` | table? | Passed to `exit` and `resume` |

---

### StateMachine:getState()

Returns the current state name.

```lua
sm:getState() -> string|nil
```

---

### StateMachine:update(dt)

Updates the current (top) state.

```lua
sm:update(dt) -> nil
```

---

### StateMachine:draw()

Draws all states bottom to top.

```lua
sm:draw() -> nil
```

## Examples

### Basic setup with menu and playing

```lua
local StateMachine = require("src.systems.state_machine")

local sm = StateMachine.new()

sm:addState("menu", {
    enter = function()
        -- Load menu assets
    end,
    update = function(dt)
        if love.keyboard.isDown("return") then
            sm:setState("playing")
        end
    end,
    draw = function()
        love.graphics.print("Press ENTER to play", 100, 100)
    end
})

sm:addState("playing", {
    enter = function()
        -- Start game
        score = 0
    end,
    update = function(dt)
        -- Game logic
    end,
    draw = function()
        -- Render game
    end
})

sm:setState("menu")
```

### Passing data between states

```lua
sm:addState("playing", {
    update = function(dt)
        if playerDied then
            -- Pass score to gameover state
            sm:setState("gameover", { finalScore = score })
        end
    end
})

sm:addState("gameover", {
    enter = function(params)
        displayScore = params and params.finalScore or 0
    end,
    draw = function()
        love.graphics.print("Game Over! Score: " .. displayScore, 100, 100)
    end
})
```

### Pause system with push/pop

```lua
sm:addState("playing", {
    enter = function()
        gameTimer = 0
    end,
    update = function(dt)
        gameTimer = gameTimer + dt
        -- Game logic...

        if love.keyboard.isDown("escape") then
            sm:pushState("pause")
        end
    end,
    pause = function()
        -- Optionally pause audio, timers, etc.
    end,
    resume = function()
        -- Resume audio, timers, etc.
    end,
    draw = function()
        -- Draw game world
        drawGameWorld()
    end
})

sm:addState("pause", {
    update = function(dt)
        if love.keyboard.isDown("escape") then
            sm:popState()
        end
    end,
    draw = function()
        -- Semi-transparent overlay
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("PAUSED - Press ESC to resume", 100, 100)
    end
})
```

### Layered draw (game + pause overlay)

```lua
function love.update(dt)
    sm:update(dt)  -- Only updates top state
end

function love.draw()
    sm:draw()  -- Draws ALL states: playing first, then pause on top
end

-- Result: Game world visible with pause overlay on top
```

## Common Patterns

### Game State Flow

```
menu → playing → gameover
         ↑          |
         └──────────┘ (restart)
```

```lua
-- In gameover state
sm:addState("gameover", {
    update = function(dt)
        if love.keyboard.isDown("r") then
            sm:setState("playing")  -- Restart
        elseif love.keyboard.isDown("m") then
            sm:setState("menu")  -- Back to menu
        end
    end
})
```

### Pause System

```
playing ←→ pause (push/pop)
```

```lua
-- Push pause over playing (game still renders underneath)
sm:pushState("pause")

-- Pop to return to playing
sm:popState()
```

### Dialog/Inventory Overlay

```lua
sm:addState("inventory", {
    enter = function()
        -- Pause game time but keep rendering
    end,
    update = function(dt)
        -- Handle inventory input
        if closeRequested then
            sm:popState()
        end
    end,
    draw = function()
        drawInventoryUI()
    end
})

-- In playing state
if love.keyboard.isDown("i") then
    sm:pushState("inventory")
end
```

## Logging

State machine integrates with `src/logger.lua`. All logs use DEBUG level with source `"StateMachine"`.

| Method | Log Message |
|--------|-------------|
| `new()` | `"StateMachine created"` |
| `addState()` | `"State added: name"` |
| `setState()` | `"State changed: old -> new"` or `"State set: name"` |
| `pushState()` | `"State pushed: name (stack size: N)"` |
| `popState()` | `"State popped: name (stack size: N)"` |

**Error handling:**

| Situation | Log Level | Message |
|-----------|-----------|---------|
| setState/pushState with unknown name | ERROR | `"State not found: name"` |
| popState on empty stack | WARNING | `"Cannot pop: stack empty"` |
