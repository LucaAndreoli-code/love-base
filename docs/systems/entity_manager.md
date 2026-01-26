# EntityManager

Central manager for all game entities. Handles entity lifecycle, provides efficient tag-based queries, and orchestrates update/draw calls.

**Responsibilities:**
- Store and track all entities
- Maintain tag-based cache for O(1) queries
- Call update/draw on alive entities
- Clean up dead entities

## Fields

| Field | Type | Description |
|-------|------|-------------|
| `entities` | table[] | List of all managed entities |
| `byTag` | table<string, table<Entity, boolean>> | Cache for fast tag-based lookups |

## Methods

### EntityManager.new()

Creates a new EntityManager instance.

```lua
EntityManager.new() -> EntityManager
```

**Returns:** `EntityManager` - New manager instance with empty collections

---

### EntityManager:add(entity)

Adds an entity to the manager and populates the tag cache.

```lua
EntityManager:add(entity) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `entity` | Entity | Entity to add |

**Returns:** `nil`

---

### EntityManager:remove(entity)

Removes an entity from the manager and cleans up tag cache.

```lua
EntityManager:remove(entity) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `entity` | Entity | Entity to remove |

**Returns:** `nil`

---

### EntityManager:getByTag(tag)

Returns all entities with a specific tag.

```lua
EntityManager:getByTag(tag) -> table<Entity, boolean>
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `tag` | string | Tag to query |

**Returns:** `table<Entity, boolean>` - Set of entities (entity as key, true as value)

---

### EntityManager:refreshTags(entity)

Updates the tag cache for an entity after its tags have been modified.

```lua
EntityManager:refreshTags(entity) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `entity` | Entity | Entity whose tags changed |

**Returns:** `nil`

---

### EntityManager:getAll()

Returns all entities (alive and dead).

```lua
EntityManager:getAll() -> table[]
```

**Returns:** `table[]` - Array of all entities

---

### EntityManager:update(dt)

Calls `update(dt)` on all alive entities.

```lua
EntityManager:update(dt) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `dt` | number | Delta time in seconds |

**Returns:** `nil`

---

### EntityManager:draw()

Calls `draw()` on all alive entities.

```lua
EntityManager:draw() -> nil
```

**Returns:** `nil`

---

### EntityManager:cleanup()

Removes all dead entities (alive = false) from the manager and tag cache.

```lua
EntityManager:cleanup() -> nil
```

**Returns:** `nil`

---

### EntityManager:clear()

Removes all entities and resets the tag cache.

```lua
EntityManager:clear() -> nil
```

**Returns:** `nil`

---

### EntityManager:count()

Returns the count of alive entities.

```lua
EntityManager:count() -> number
```

**Returns:** `number` - Number of entities with `alive = true`

## Examples

### Creating a manager

```lua
local EntityManager = require("src.systems.entity_manager")

local manager = EntityManager.new()
```

### Adding entities

```lua
local Entity = require("src.systems.entity")

local player = Entity.new({
    x = 400, y = 300,
    tags = { "player", "collidable" }
})

local enemy = Entity.new({
    x = 100, y = 100,
    tags = { "enemy", "collidable" }
})

manager:add(player)
manager:add(enemy)
```

### Query by tag and iterate

```lua
-- getByTag returns a set (entity = true), iterate with pairs
local collidables = manager:getByTag("collidable")

for entity, _ in pairs(collidables) do
    -- Process collidable entity
end

-- Check if player exists in enemies (won't find it)
local enemies = manager:getByTag("enemy")
for entity, _ in pairs(enemies) do
    print(entity.x, entity.y)
end
```

### Refresh tags after modification

```lua
local entity = Entity.new({ tags = { "neutral" } })
manager:add(entity)

-- Later, entity becomes an enemy
entity:removeTag("neutral")
entity:addTag("enemy")
entity:addTag("collidable")

-- IMPORTANT: update the cache
manager:refreshTags(entity)

-- Now entity appears in getByTag("enemy")
```

### Typical game loop

```lua
function love.update(dt)
    -- Update all alive entities
    manager:update(dt)

    -- Collision detection between bullets and enemies
    local bullets = manager:getByTag("bullet")
    local enemies = manager:getByTag("enemy")

    for bullet, _ in pairs(bullets) do
        for enemy, _ in pairs(enemies) do
            if checkCollision(bullet, enemy) then
                bullet:destroy()
                enemy:destroy()
            end
        end
    end

    -- Remove dead entities at end of frame
    manager:cleanup()
end

function love.draw()
    manager:draw()
end
```

### Clear for scene change

```lua
function changeScene(newScene)
    -- Remove all entities from current scene
    manager:clear()

    -- Load new scene entities
    loadScene(newScene)
end
```

## Performance Notes

| Operation | Complexity | Notes |
|-----------|------------|-------|
| `getByTag()` | O(1) | Returns cached table, no allocation |
| `add()` | O(t) | Where t = number of tags on entity |
| `remove()` | O(n + t) | n = total entities, t = total tag types |
| `refreshTags()` | O(t) | t = total tag types in manager |
| `cleanup()` | O(n * t) | n = entities, t = tag types |
| `count()` | O(n) | Iterates all entities |

**Important:**
- `getByTag()` returns a shared singleton empty table for non-existent tags (zero allocation)
- `refreshTags()` must be called manually after modifying entity tags via `addTag()`/`removeTag()`
- `cleanup()` is not called automatically in `update()` - call it explicitly at end of frame
- Dead entities still exist in `entities` until `cleanup()` is called

## Logging

EntityManager integrates with `src/logger.lua`. All logs use DEBUG level with source `"EntityManager"`.

| Method | Log Message |
|--------|-------------|
| `new()` | `"EntityManager created"` |
| `add()` | `"Entity added (total: N)"` |
| `remove()` | `"Entity removed (total: N)"` |
| `cleanup()` | `"Cleanup: removed N dead entities"` (only if N > 0) |
| `clear()` | `"All entities cleared"` |

To see EntityManager logs, run with `--debug` flag or set log level to DEBUG.
