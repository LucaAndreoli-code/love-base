---@class MathUtils
local MathUtils = {}

---Returns the distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function MathUtils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

---Returns the squared distance between two points (faster, no sqrt)
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function MathUtils.distanceSquared(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return dx * dx + dy * dy
end

---Returns the length of a vector
---@param x number
---@param y number
---@return number
function MathUtils.length(x, y)
    return math.sqrt(x * x + y * y)
end

---Returns a normalized vector (length 1). Returns (0, 0) if input length is 0
---@param x number
---@param y number
---@return number vx
---@return number vy
function MathUtils.normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len == 0 then
        return 0, 0
    end
    return x / len, y / len
end

---Returns the angle in radians from point 1 to point 2
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function MathUtils.angle(x1, y1, x2, y2)
    return math.atan2(y2 - y1, x2 - x1)
end

---Returns velocity components from angle and speed
---@param angle number Angle in radians
---@param speed number
---@return number vx
---@return number vy
function MathUtils.direction(angle, speed)
    return math.cos(angle) * speed, math.sin(angle) * speed
end

---Linear interpolation between two values
---@param a number Start value
---@param b number End value
---@param t number Interpolation factor (0-1)
---@return number
function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

---Clamps a value between min and max
---@param value number
---@param min number
---@param max number
---@return number
function MathUtils.clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

return MathUtils
