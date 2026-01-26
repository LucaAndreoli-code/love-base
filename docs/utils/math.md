# Math Utils

Utility functions for common game math operations. All functions are pure (no side effects, no state, no logging) and perform no allocations beyond return values.

## Functions

### Distance

#### MathUtils.distance(x1, y1, x2, y2)

Returns the Euclidean distance between two points.

```lua
MathUtils.distance(x1, y1, x2, y2) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `x1` | number | X coordinate of first point |
| `y1` | number | Y coordinate of first point |
| `x2` | number | X coordinate of second point |
| `y2` | number | Y coordinate of second point |

**Returns:** `number` - Distance between the points

```lua
local dist = MathUtils.distance(0, 0, 3, 4)  -- 5
```

---

#### MathUtils.distanceSquared(x1, y1, x2, y2)

Returns the squared distance between two points. Faster than `distance()` for comparisons.

```lua
MathUtils.distanceSquared(x1, y1, x2, y2) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `x1` | number | X coordinate of first point |
| `y1` | number | Y coordinate of first point |
| `x2` | number | X coordinate of second point |
| `y2` | number | Y coordinate of second point |

**Returns:** `number` - Squared distance between the points

```lua
local distSq = MathUtils.distanceSquared(0, 0, 3, 4)  -- 25
```

---

### Vectors

#### MathUtils.length(x, y)

Returns the length (magnitude) of a vector.

```lua
MathUtils.length(x, y) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | number | X component of vector |
| `y` | number | Y component of vector |

**Returns:** `number` - Length of the vector

```lua
local len = MathUtils.length(3, 4)  -- 5
```

---

#### MathUtils.normalize(x, y)

Returns a normalized vector (length 1) in the same direction. Returns (0, 0) if input is zero vector.

```lua
MathUtils.normalize(x, y) -> number, number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `x` | number | X component of vector |
| `y` | number | Y component of vector |

**Returns:** `number, number` - Normalized vx, vy components

```lua
local vx, vy = MathUtils.normalize(3, 4)  -- 0.6, 0.8
local vx, vy = MathUtils.normalize(0, 0)  -- 0, 0 (safe)
```

---

### Angles and Direction

#### MathUtils.angle(x1, y1, x2, y2)

Returns the angle in radians from point 1 to point 2.

```lua
MathUtils.angle(x1, y1, x2, y2) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `x1` | number | X coordinate of origin point |
| `y1` | number | Y coordinate of origin point |
| `x2` | number | X coordinate of target point |
| `y2` | number | Y coordinate of target point |

**Returns:** `number` - Angle in radians (-π to π)

```lua
local a = MathUtils.angle(0, 0, 10, 0)   -- 0 (right)
local a = MathUtils.angle(0, 0, 0, 10)   -- π/2 (down)
local a = MathUtils.angle(0, 0, -10, 0)  -- π (left)
```

---

#### MathUtils.direction(angle, speed)

Returns velocity components from an angle and speed.

```lua
MathUtils.direction(angle, speed) -> number, number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `angle` | number | Angle in radians |
| `speed` | number | Speed magnitude |

**Returns:** `number, number` - vx, vy velocity components

```lua
local vx, vy = MathUtils.direction(0, 100)           -- 100, 0
local vx, vy = MathUtils.direction(math.pi / 2, 100) -- 0, 100
```

---

### Interpolation and Limits

#### MathUtils.lerp(a, b, t)

Linear interpolation between two values.

```lua
MathUtils.lerp(a, b, t) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `a` | number | Start value |
| `b` | number | End value |
| `t` | number | Interpolation factor (typically 0-1) |

**Returns:** `number` - Interpolated value

```lua
local v = MathUtils.lerp(0, 100, 0)    -- 0
local v = MathUtils.lerp(0, 100, 0.5)  -- 50
local v = MathUtils.lerp(0, 100, 1)    -- 100
```

---

#### MathUtils.clamp(value, min, max)

Clamps a value between min and max bounds.

```lua
MathUtils.clamp(value, min, max) -> number
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | number | Value to clamp |
| `min` | number | Minimum bound |
| `max` | number | Maximum bound |

**Returns:** `number` - Clamped value

```lua
local v = MathUtils.clamp(5, 0, 10)   -- 5 (unchanged)
local v = MathUtils.clamp(-5, 0, 10)  -- 0 (clamped to min)
local v = MathUtils.clamp(15, 0, 10)  -- 10 (clamped to max)
```

## Practical Examples

### Collision detection with distance

```lua
local function checkCollision(entity1, entity2)
    -- Use distanceSquared to avoid sqrt (faster)
    local radiusSum = entity1.radius + entity2.radius
    local distSq = MathUtils.distanceSquared(
        entity1.x, entity1.y,
        entity2.x, entity2.y
    )
    return distSq <= radiusSum * radiusSum
end
```

### Normalize movement direction

```lua
function Player:update(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left") then dx = dx - 1 end
    if love.keyboard.isDown("right") then dx = dx + 1 end
    if love.keyboard.isDown("up") then dy = dy - 1 end
    if love.keyboard.isDown("down") then dy = dy + 1 end

    -- Normalize for consistent diagonal speed
    dx, dy = MathUtils.normalize(dx, dy)

    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
end
```

### Point entity toward target

```lua
function Enemy:update(dt)
    -- Calculate angle to player
    self.rotation = MathUtils.angle(
        self.x, self.y,
        player.x, player.y
    )
end

function Enemy:draw()
    love.graphics.draw(self.sprite, self.x, self.y, self.rotation)
end
```

### Movement from angle and speed

```lua
function Bullet.new(x, y, angle, speed)
    local vx, vy = MathUtils.direction(angle, speed)

    return Entity.new({
        x = x,
        y = y,
        vx = vx,
        vy = vy,
        tags = { "bullet" }
    })
end

-- Shoot toward mouse
local mouseX, mouseY = love.mouse.getPosition()
local angle = MathUtils.angle(player.x, player.y, mouseX, mouseY)
local bullet = Bullet.new(player.x, player.y, angle, 500)
```

### Smooth transition with lerp

```lua
function Camera:update(dt)
    -- Smooth camera follow (ease toward target)
    local smoothing = 5 * dt  -- Adjust for feel
    self.x = MathUtils.lerp(self.x, target.x, smoothing)
    self.y = MathUtils.lerp(self.y, target.y, smoothing)
end

-- Fade in effect
function FadeOverlay:update(dt)
    self.alpha = MathUtils.lerp(self.alpha, 0, 2 * dt)
end
```

### Limit speed with clamp

```lua
function Entity:update(dt)
    -- Apply acceleration
    self.vx = self.vx + self.ax * dt
    self.vy = self.vy + self.ay * dt

    -- Clamp to max speed
    self.vx = MathUtils.clamp(self.vx, -self.maxSpeed, self.maxSpeed)
    self.vy = MathUtils.clamp(self.vy, -self.maxSpeed, self.maxSpeed)

    -- Update position
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end
```

## Performance Notes

| Function | Notes |
|----------|-------|
| `distanceSquared()` | Preferred over `distance()` for comparisons (avoids `sqrt`) |
| `normalize()` | Single `sqrt` call, safe for zero vectors |
| `direction()` | Uses `cos`/`sin`, cache result if angle doesn't change |
| All functions | Pure functions, no allocations, no state |

**Best practices:**
- Use `distanceSquared()` when comparing distances (e.g., collision detection)
- Use `distance()` only when you need the actual distance value
- Cache `direction()` results when angle is constant
- All functions are safe to call every frame with no GC overhead
