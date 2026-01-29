# Input Handler

Abstraction layer for input management. Maps actions to keyboard keys and gamepad buttons, providing a unified interface for game controls. Supports runtime rebinding, input buffering, and automatic device switching.

## Module Structure

The InputHandler is split into multiple files under `src/systems/input_handler/`:

| File | Purpose |
|------|---------|
| `init.lua` | Aggregator, returns InputHandler class |
| `handler.lua` | Main class: constructor, update, rebind |
| `defaults.lua` | Default bindings and axes configuration |
| `utils.lua` | Utility functions: deepCopy, mergeBindings, parseGamepadBinding |
| `queries.lua` | State queries: isHeld, isPressed, isReleased, wasPressedWithin |
| `axis.lua` | Axis handling: getAxis, applyDeadzone |
| `callbacks.lua` | LÖVE callback handlers: onKeyPressed, onGamepadPressed, etc. |

## Key Concepts

### Action-Based Input

Instead of checking raw keys (`love.keyboard.isDown("space")`), you check named actions (`input:isHeld("jump")`). This decouples game logic from specific input devices.

```lua
-- BAD: Hard-coded keys
if love.keyboard.isDown("space") then
    player:jump()
end

-- GOOD: Action-based
if input:isPressed("jump") then
    player:jump()
end
```

### Input States

Each action has three states, tracked per-frame:

| State | Method | Description |
|-------|--------|-------------|
| **Held** | `isHeld(action)` | True while button/key is down |
| **Pressed** | `isPressed(action)` | True only on the frame the input starts |
| **Released** | `isReleased(action)` | True only on the frame the input ends |

```
Frame:    1    2    3    4    5    6    7
Key:      _    ████████████████████    _
Held:          ✓    ✓    ✓    ✓    ✓
Pressed:       ✓
Released:                              ✓
```

### Device Detection

The system automatically detects which device is active based on the last input received. Only one device is active at a time.

```lua
input:getActiveDevice()  -- Returns "keyboard" or "gamepad"
```

### Input Buffering

Actions track the timestamp of their last press. This enables input buffering for responsive controls:

```lua
-- Accept jump input if pressed within last 100ms
if input:wasPressedWithin("jump", 0.1) and player.isGrounded then
    player:jump()
end
```

### Axes

Axes combine directional actions into a continuous value from -1 to 1:

- **Keyboard**: Returns -1, 0, or 1 (discrete)
- **Gamepad**: Returns -1 to 1 (analog, with deadzone applied)

```lua
local moveX = input:getAxis("horizontal")  -- -1 to 1
player.vx = moveX * player.speed
```

## Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `bindings` | table | (see defaults) | Action to key/button mappings |
| `activeDevice` | string | "keyboard" | Currently active input device |
| `deadzone` | number | 0.2 | Stick deadzone threshold (0-1) |
| `actionStates` | table | {} | Current state of each action |
| `lastPressTime` | table | {} | Timestamp of last press per action |
| `eventQueue` | table | {} | Buffered input events for current frame |

## Bindings Structure

```lua
bindings = {
    jump = {
        keyboard = "space",
        gamepad = "a"          -- Button name
    },
    left = {
        keyboard = "a",
        gamepad = "leftx-"     -- Axis with direction
    },
    dash = {
        keyboard = { "k", "lshift" },  -- Multiple keys (OR)
        gamepad = "rightshoulder"
    }
}
```

### Gamepad Binding Syntax

| Syntax | Meaning |
|--------|---------|
| `"a"`, `"b"`, `"x"`, `"y"` | Face buttons |
| `"start"`, `"back"` | Menu buttons |
| `"leftshoulder"`, `"rightshoulder"` | Bumpers |
| `"leftx-"`, `"leftx+"` | Left stick X axis (negative/positive) |
| `"lefty-"`, `"lefty+"` | Left stick Y axis |
| `"rightx-"`, `"rightx+"` | Right stick X axis |
| `"righty-"`, `"righty+"` | Right stick Y axis |
| `"triggerleft"`, `"triggerright"` | Triggers (treated as buttons) |

## Default Bindings

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| `jump` | `space` | `a` |
| `left` | `a` | `leftx-` |
| `right` | `d` | `leftx+` |
| `up` | `w` | `lefty-` |
| `down` | `s` | `lefty+` |
| `attack` | `j` | `x` |
| `dash` | `k`, `lshift` | `rightshoulder` |
| `pause` | `escape` | `start` |

### Default Axes

| Axis | Negative Action | Positive Action |
|------|-----------------|-----------------|
| `horizontal` | `left` | `right` |
| `vertical` | `up` | `down` |

## Methods

### InputHandler.new(config)

Creates a new InputHandler instance.

```lua
InputHandler.new(config?) -> InputHandler
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `config` | table? | Optional configuration |
| `config.bindings` | table? | Custom bindings (merged with defaults) |
| `config.deadzone` | number? | Stick deadzone (default: 0.2) |

**Returns:** `InputHandler` - New input handler instance

---

### InputHandler:update()

Processes input events and updates action states. Must be called every frame at the start of `love.update`.

```lua
input:update() -> nil
```

**Returns:** `nil`

---

### InputHandler:isHeld(action)

Returns true if the action is currently held down.

```lua
input:isHeld(action) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | Action name |

**Returns:** `boolean` - True if held

---

### InputHandler:isPressed(action)

Returns true only on the frame the action was pressed.

```lua
input:isPressed(action) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | Action name |

**Returns:** `boolean` - True if just pressed this frame

---

### InputHandler:isReleased(action)

Returns true only on the frame the action was released.

```lua
input:isReleased(action) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | Action name |

**Returns:** `boolean` - True if just released this frame

---

### InputHandler:wasPressedWithin(action, seconds)

Returns true if the action was pressed within the specified time window.

```lua
input:wasPressedWithin(action, seconds) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | Action name |
| `seconds` | number | Time window in seconds |

**Returns:** `boolean` - True if pressed within window

---

### InputHandler:getAxis(axisName)

Returns the axis value from -1 to 1.

```lua
input:getAxis(axisName) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `axisName` | string | Axis name ("horizontal", "vertical") |

**Returns:** `number` - Value from -1 to 1

---

### InputHandler:rebind(action, deviceType, newKey)

Changes the binding for an action.

```lua
input:rebind(action, deviceType, newKey) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `action` | string | Action to rebind |
| `deviceType` | string | "keyboard" or "gamepad" |
| `newKey` | string or string[] | New key/button binding |

**Returns:** `nil`

---

### InputHandler:getBindings()

Returns the current bindings table.

```lua
input:getBindings() -> table
```

**Returns:** `table` - Current bindings

---

### InputHandler:getActiveDevice()

Returns the currently active input device.

```lua
input:getActiveDevice() -> string
```

**Returns:** `string` - "keyboard" or "gamepad"

---

### InputHandler:setDeadzone(value)

Sets the analog stick deadzone.

```lua
input:setDeadzone(value) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | number | Deadzone threshold (0-1) |

**Returns:** `nil`

## Examples

### Basic Setup

```lua
local Game = require("src.init")

local input

function love.load()
    Game.load()
    input = Game.systems.inputHandler.new()
end

function love.update(dt)
    input:update()

    if input:isPressed("jump") then
        player:jump()
    end

    local moveX = input:getAxis("horizontal")
    player.vx = moveX * player.speed
end

-- Required: Forward LÖVE callbacks to InputHandler
function love.keypressed(key)
    input:keypressed(key)
end

function love.keyreleased(key)
    input:keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    input:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    input:gamepadreleased(joystick, button)
end
```

### Custom Bindings

```lua
local input = Game.systems.inputHandler.new({
    bindings = {
        shoot = {
            keyboard = "space",
            gamepad = "righttrigger"
        },
        reload = {
            keyboard = "r",
            gamepad = "x"
        }
    },
    deadzone = 0.15
})
```

### Input Buffering for Responsive Jumps

```lua
function Player:update(dt)
    -- Buffer jump input - accept if pressed in last 100ms
    if input:wasPressedWithin("jump", 0.1) then
        if self.isGrounded then
            self:jump()
        end
    end
end
```

### Runtime Rebinding

```lua
-- In options menu
function rebindAction(action)
    waitingForInput = true
    actionToRebind = action
end

function love.keypressed(key)
    if waitingForInput then
        input:rebind(actionToRebind, "keyboard", key)
        waitingForInput = false
    else
        input:keypressed(key)
    end
end
```

### Device-Specific UI

```lua
function drawControls()
    local device = input:getActiveDevice()

    if device == "keyboard" then
        love.graphics.print("Press SPACE to jump", 100, 100)
    else
        love.graphics.print("Press A to jump", 100, 100)
    end
end
```

### Dash with Cooldown

```lua
function Player:update(dt)
    self.dashCooldown = math.max(0, self.dashCooldown - dt)

    if input:isPressed("dash") and self.dashCooldown <= 0 then
        self:dash()
        self.dashCooldown = 1.0
    end
end
```

### Movement with Analog Support

```lua
function Player:update(dt)
    local moveX = input:getAxis("horizontal")
    local moveY = input:getAxis("vertical")

    -- Normalize diagonal movement
    local len = math.sqrt(moveX * moveX + moveY * moveY)
    if len > 1 then
        moveX = moveX / len
        moveY = moveY / len
    end

    self.vx = moveX * self.speed
    self.vy = moveY * self.speed
end
```

## Implementation Notes

### LÖVE Input System

LÖVE provides two ways to check input:

1. **Polling** (`love.keyboard.isDown(key)`) - Check state at any time
2. **Callbacks** (`love.keypressed(key)`) - Event-driven, called once per press

InputHandler uses both:
- **Polling** for `isHeld()` - checks `love.keyboard.isDown()` directly
- **Callbacks** for `isPressed()`/`isReleased()` - buffers events in a queue

### Event Queue Pattern

```lua
-- LÖVE callback (called by engine)
function InputHandler:keypressed(key)
    table.insert(self.eventQueue, { type = "pressed", device = "keyboard", key = key })
    self.activeDevice = "keyboard"
end

-- Called every frame
function InputHandler:update()
    -- Clear previous frame's pressed/released states
    for action, state in pairs(self.actionStates) do
        state.pressed = false
        state.released = false
    end

    -- Process queued events
    for _, event in ipairs(self.eventQueue) do
        local action = self:getActionForKey(event.key, event.device)
        if action then
            if event.type == "pressed" then
                self.actionStates[action].pressed = true
                self.lastPressTime[action] = love.timer.getTime()
            else
                self.actionStates[action].released = true
            end
        end
    end

    -- Clear queue for next frame
    self.eventQueue = {}
end
```

### Gamepad Detection

```lua
function InputHandler:update()
    -- Check for connected gamepads
    local joysticks = love.joystick.getJoysticks()
    self.gamepad = joysticks[1]  -- Use first gamepad

    -- Read gamepad axes if active
    if self.activeDevice == "gamepad" and self.gamepad then
        -- Apply deadzone and update axis values
    end
end
```

### Deadzone Application

```lua
function InputHandler:applyDeadzone(value)
    if math.abs(value) < self.deadzone then
        return 0
    end
    -- Rescale so edge of deadzone = 0, full tilt = 1
    local sign = value > 0 and 1 or -1
    return sign * (math.abs(value) - self.deadzone) / (1 - self.deadzone)
end
```

### Multiple Keys per Action

When an action has multiple keys (like `dash = { "k", "lshift" }`), the action is held if ANY key is down:

```lua
function InputHandler:isHeld(action)
    local keys = self.bindings[action].keyboard
    if type(keys) == "string" then
        keys = { keys }
    end

    for _, key in ipairs(keys) do
        if love.keyboard.isDown(key) then
            return true
        end
    end
    return false
end
```

## Integration with Game

### Access Pattern

```lua
local Game = require("src.init")

function someFunction()
    local InputHandler = Game.systems.inputHandler
    local input = InputHandler.new()
end
```

### Required Callbacks

The InputHandler needs LÖVE callbacks forwarded to it. In `main.lua`:

```lua
local Game = require("src.init")
local input  -- Global or passed around

function love.load()
    Game.load()
    input = Game.systems.inputHandler.new()
end

function love.keypressed(key)
    input:keypressed(key)
end

function love.keyreleased(key)
    input:keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    input:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    input:gamepadreleased(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    input:gamepadaxis(joystick, axis, value)
end
```

## Logging

InputHandler integrates with `src/logger.lua`. All logs use DEBUG level with source `"InputHandler"`.

| Event | Log Message |
|-------|-------------|
| `new()` | `"InputHandler created"` |
| Device switch | `"Active device changed: keyboard -> gamepad"` |
| `rebind()` | `"Rebound action: jump, keyboard = space"` |
| Gamepad connected | `"Gamepad connected: Controller Name"` |
| Gamepad disconnected | `"Gamepad disconnected"` |

## LÖVE Reference

### Keyboard Functions

| Function | Purpose |
|----------|---------|
| `love.keyboard.isDown(key)` | Check if key is held |
| `love.keypressed(key)` | Callback when key pressed |
| `love.keyreleased(key)` | Callback when key released |

### Gamepad Functions

| Function | Purpose |
|----------|---------|
| `love.joystick.getJoysticks()` | Get connected joysticks |
| `joystick:isGamepad()` | Check if joystick is gamepad |
| `joystick:isGamepadDown(button)` | Check if button held |
| `joystick:getGamepadAxis(axis)` | Get axis value (-1 to 1) |
| `love.gamepadpressed(joystick, button)` | Callback when button pressed |
| `love.gamepadreleased(joystick, button)` | Callback when button released |
| `love.gamepadaxis(joystick, axis, value)` | Callback when axis moves |

### Key Names

Common key names for `love.keyboard`:
- Letters: `"a"` to `"z"`
- Numbers: `"0"` to `"9"`
- Arrows: `"up"`, `"down"`, `"left"`, `"right"`
- Modifiers: `"lshift"`, `"rshift"`, `"lctrl"`, `"rctrl"`, `"lalt"`, `"ralt"`
- Special: `"space"`, `"return"`, `"escape"`, `"tab"`, `"backspace"`

### Gamepad Button Names

Standard button names for `joystick:isGamepadDown()`:
- Face: `"a"`, `"b"`, `"x"`, `"y"`
- Bumpers: `"leftshoulder"`, `"rightshoulder"`
- Triggers: `"triggerleft"`, `"triggerright"` (digital)
- Sticks: `"leftstick"`, `"rightstick"` (click)
- Menu: `"start"`, `"back"`, `"guide"`
- D-pad: `"dpup"`, `"dpdown"`, `"dpleft"`, `"dpright"`

### Gamepad Axis Names

Standard axis names for `joystick:getGamepadAxis()`:
- Left stick: `"leftx"`, `"lefty"`
- Right stick: `"rightx"`, `"righty"`
- Triggers: `"triggerleft"`, `"triggerright"` (analog, 0 to 1)
