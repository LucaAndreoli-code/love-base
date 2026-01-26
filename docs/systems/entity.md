# Entity

Base class for all game objects. Provides position, velocity, lifecycle management, and a tagging system for entity identification and filtering.

## Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `x` | number | 0 | X position |
| `y` | number | 0 | Y position |
| `vx` | number | 0 | X velocity (pixels/second) |
| `vy` | number | 0 | Y velocity (pixels/second) |
| `rotation` | number | 0 | Rotation in radians |
| `radius` | number | 0 | Collision radius |
| `alive` | boolean | true | Lifecycle state |
| `tags` | table<string, boolean> | {} | Tags for identification |

## Methods

### Entity.new(config)

Creates a new Entity instance.

```lua
Entity.new(config?) -> Entity
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `config` | table? | Optional configuration table |
| `config.x` | number? | Initial X position |
| `config.y` | number? | Initial Y position |
| `config.vx` | number? | Initial X velocity |
| `config.vy` | number? | Initial Y velocity |
| `config.rotation` | number? | Initial rotation |
| `config.radius` | number? | Collision radius |
| `config.tags` | string[]? | Array of tag strings |

**Returns:** `Entity` - New entity instance

---

### Entity:update(dt)

Updates entity position based on velocity.

```lua
Entity:update(dt) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `dt` | number | Delta time in seconds |

**Returns:** `nil`

---

### Entity:draw()

Empty draw method for subclass override.

```lua
Entity:draw() -> nil
```

**Returns:** `nil`

---

### Entity:destroy()

Marks the entity as dead by setting `alive = false`.

```lua
Entity:destroy() -> nil
```

**Returns:** `nil`

---

### Entity:addTag(tag)

Adds a tag to the entity.

```lua
Entity:addTag(tag) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `tag` | string | Tag to add |

**Returns:** `nil`

---

### Entity:removeTag(tag)

Removes a tag from the entity.

```lua
Entity:removeTag(tag) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `tag` | string | Tag to remove |

**Returns:** `nil`

---

### Entity:hasTag(tag)

Checks if the entity has a specific tag.

```lua
Entity:hasTag(tag) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `tag` | string | Tag to check |

**Returns:** `boolean` - `true` if tag exists, `false` otherwise

## Examples

### Creation with defaults

```lua
local Entity = require("src.systems.entity")

local entity = Entity.new()
-- x=0, y=0, vx=0, vy=0, rotation=0, radius=0, alive=true, tags={}
```

### Creation with config

```lua
local player = Entity.new({
    x = 640,
    y = 360,
    vx = 100,
    vy = 0,
    rotation = 0,
    radius = 16
})
```

### Creation with tags

```lua
local enemy = Entity.new({
    x = 100,
    y = 100,
    radius = 12,
    tags = { "enemy", "collidable", "shootable" }
})
```

### Update loop

```lua
function love.update(dt)
    for _, entity in ipairs(entities) do
        if entity.alive then
            entity:update(dt)
        end
    end
end
```

### Tag management

```lua
local entity = Entity.new()

-- Add tags
entity:addTag("player")
entity:addTag("collidable")

-- Check tags
if entity:hasTag("player") then
    -- Handle player-specific logic
end

-- Remove tag
entity:removeTag("collidable")
```

### Override draw in subclass

```lua
local Entity = require("src.systems.entity")

local Player = {}
Player.__index = Player
setmetatable(Player, { __index = Entity })

function Player.new(x, y)
    local self = Entity.new({
        x = x,
        y = y,
        radius = 16,
        tags = { "player" }
    })
    setmetatable(self, Player)
    return self
end

function Player:draw()
    love.graphics.circle("fill", self.x, self.y, self.radius)
end
```

## Logging

Entity integrates with `src/logger.lua`. All logs use DEBUG level with source `"Entity"`.

| Method | Log Message |
|--------|-------------|
| `new()` | `"Entity created at (x, y)"` or `"Entity created at (x, y) with tags: tag1, tag2"` |
| `destroy()` | `"Entity destroyed"` |
| `addTag(tag)` | `"Tag added: tag"` |
| `removeTag(tag)` | `"Tag removed: tag"` |

To see Entity logs, run with `--debug` flag or set log level to DEBUG.
