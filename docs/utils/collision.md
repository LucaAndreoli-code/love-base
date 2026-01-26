# Collision Utils

Utility functions for collision detection. All functions are pure (no side effects, no state, no logging), return boolean, and perform no allocations.

## Important: Coordinate System

**For all rectangles, `x` and `y` represent the CENTER, not the top-left corner.**

This design choice ensures consistency with the Entity system where `x, y` always represents the center position. When working with collision detection:

```
Rectangle with x=100, y=100, width=50, height=30:

     75                125
      |                 |
  85 -+----------------+- 85
      |                |
      |    (100,100)   |    <- center
      |        •       |
      |                |
 115 -+----------------+- 115
      |                 |
```

## Functions

### CollisionUtils.circleCircle(a, b)

Checks collision between two circles.

```lua
CollisionUtils.circleCircle(a, b) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `a` | table | First circle |
| `a.x` | number | X position (center) |
| `a.y` | number | Y position (center) |
| `a.radius` | number | Circle radius |
| `b` | table | Second circle (same fields as `a`) |

**Returns:** `boolean` - `true` if circles overlap or touch

---

### CollisionUtils.rectRect(a, b)

Checks collision between two rectangles.

```lua
CollisionUtils.rectRect(a, b) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `a` | table | First rectangle |
| `a.x` | number | X position (center) |
| `a.y` | number | Y position (center) |
| `a.width` | number | Rectangle width |
| `a.height` | number | Rectangle height |
| `b` | table | Second rectangle (same fields as `a`) |

**Returns:** `boolean` - `true` if rectangles overlap or touch

---

### CollisionUtils.circleRect(circle, rect)

Checks collision between a circle and a rectangle.

```lua
CollisionUtils.circleRect(circle, rect) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `circle` | table | Circle with `x`, `y`, `radius` |
| `rect` | table | Rectangle with `x`, `y` (center), `width`, `height` |

**Returns:** `boolean` - `true` if circle and rectangle overlap or touch

---

### CollisionUtils.pointCircle(px, py, circle)

Checks if a point is inside or on a circle.

```lua
CollisionUtils.pointCircle(px, py, circle) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `px` | number | Point X coordinate |
| `py` | number | Point Y coordinate |
| `circle` | table | Circle with `x`, `y`, `radius` |

**Returns:** `boolean` - `true` if point is inside or on circle edge

---

### CollisionUtils.pointRect(px, py, rect)

Checks if a point is inside or on a rectangle.

```lua
CollisionUtils.pointRect(px, py, rect) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `px` | number | Point X coordinate |
| `py` | number | Point Y coordinate |
| `rect` | table | Rectangle with `x`, `y` (center), `width`, `height` |

**Returns:** `boolean` - `true` if point is inside or on rectangle edge

## Practical Examples

### Bullet-enemy collision (circleCircle)

```lua
local function checkBulletHits(bullets, enemies)
    for bullet, _ in pairs(bullets) do
        for enemy, _ in pairs(enemies) do
            if CollisionUtils.circleCircle(bullet, enemy) then
                bullet:destroy()
                enemy:destroy()
            end
        end
    end
end
```

### Player-wall collision (circleRect)

```lua
local function checkWallCollision(player, walls)
    for _, wall in ipairs(walls) do
        if CollisionUtils.circleRect(player, wall) then
            -- Push player out of wall
            return true
        end
    end
    return false
end
```

### Mouse click on entity (pointCircle)

```lua
function love.mousepressed(x, y, button)
    if button == 1 then
        local enemies = manager:getByTag("enemy")
        for enemy, _ in pairs(enemies) do
            if CollisionUtils.pointCircle(x, y, enemy) then
                enemy:destroy()
                break
            end
        end
    end
end
```

### Mouse click on UI button (pointRect)

```lua
local button = {
    x = 640,  -- center
    y = 360,
    width = 200,
    height = 50
}

function love.mousepressed(x, y, btn)
    if btn == 1 and CollisionUtils.pointRect(x, y, button) then
        onButtonClick()
    end
end
```

## Integration with EntityManager

```lua
function love.update(dt)
    manager:update(dt)

    -- Collision: bullets vs enemies
    local bullets = manager:getByTag("bullet")
    local enemies = manager:getByTag("enemy")

    for bullet, _ in pairs(bullets) do
        if bullet.alive then
            for enemy, _ in pairs(enemies) do
                if enemy.alive and CollisionUtils.circleCircle(bullet, enemy) then
                    bullet:destroy()
                    enemy:destroy()
                    score = score + 100
                end
            end
        end
    end

    -- Collision: player vs pickups
    local player = manager:getByTag("player")
    local pickups = manager:getByTag("pickup")

    for p, _ in pairs(player) do
        for pickup, _ in pairs(pickups) do
            if pickup.alive and CollisionUtils.circleCircle(p, pickup) then
                pickup:destroy()
                applyPickupEffect(pickup)
            end
        end
    end

    manager:cleanup()
end
```

## Performance Notes

| Function | Complexity | Notes |
|----------|------------|-------|
| `circleCircle()` | O(1) | Uses squared distance (no sqrt) |
| `rectRect()` | O(1) | Simple AABB comparison |
| `circleRect()` | O(1) | Finds closest point, then distance check |
| `pointCircle()` | O(1) | Squared distance check |
| `pointRect()` | O(1) | Simple bounds check |

**Scaling considerations:**

For N bullets vs M enemies, collision check is O(N × M). This is acceptable for small numbers (< 100 entities), but for larger games consider:

- **Spatial partitioning**: Grid-based or quadtree to reduce checks
- **Broad phase**: Quick AABB check before detailed collision
- **Early exit**: Check `alive` before expensive calculations

```lua
-- Example: early exit pattern
for bullet, _ in pairs(bullets) do
    if not bullet.alive then goto continue_bullet end

    for enemy, _ in pairs(enemies) do
        if not enemy.alive then goto continue_enemy end

        if CollisionUtils.circleCircle(bullet, enemy) then
            bullet:destroy()
            enemy:destroy()
            break
        end

        ::continue_enemy::
    end

    ::continue_bullet::
end
```

Future improvement: implement spatial hash grid for O(N) collision detection.
