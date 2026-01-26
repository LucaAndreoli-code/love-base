---@class CollisionUtils
local CollisionUtils = {}

---Checks collision between two circles
---@param a {x: number, y: number, radius: number}
---@param b {x: number, y: number, radius: number}
---@return boolean
function CollisionUtils.circleCircle(a, b)
    local dx = b.x - a.x
    local dy = b.y - a.y
    local distSq = dx * dx + dy * dy
    local radiusSum = a.radius + b.radius
    return distSq <= radiusSum * radiusSum
end

---Checks collision between two rectangles (x, y is center)
---@param a {x: number, y: number, width: number, height: number}
---@param b {x: number, y: number, width: number, height: number}
---@return boolean
function CollisionUtils.rectRect(a, b)
    local aHalfW = a.width / 2
    local aHalfH = a.height / 2
    local bHalfW = b.width / 2
    local bHalfH = b.height / 2

    local aLeft = a.x - aHalfW
    local aRight = a.x + aHalfW
    local aTop = a.y - aHalfH
    local aBottom = a.y + aHalfH

    local bLeft = b.x - bHalfW
    local bRight = b.x + bHalfW
    local bTop = b.y - bHalfH
    local bBottom = b.y + bHalfH

    return aLeft <= bRight and aRight >= bLeft and aTop <= bBottom and aBottom >= bTop
end

---Checks collision between a circle and a rectangle (rect x, y is center)
---@param circle {x: number, y: number, radius: number}
---@param rect {x: number, y: number, width: number, height: number}
---@return boolean
function CollisionUtils.circleRect(circle, rect)
    local halfW = rect.width / 2
    local halfH = rect.height / 2

    local rectLeft = rect.x - halfW
    local rectRight = rect.x + halfW
    local rectTop = rect.y - halfH
    local rectBottom = rect.y + halfH

    -- Find closest point on rectangle to circle center
    local closestX = math.max(rectLeft, math.min(circle.x, rectRight))
    local closestY = math.max(rectTop, math.min(circle.y, rectBottom))

    -- Check if closest point is within circle radius
    local dx = circle.x - closestX
    local dy = circle.y - closestY
    local distSq = dx * dx + dy * dy

    return distSq <= circle.radius * circle.radius
end

---Checks if a point is inside a circle
---@param px number Point X coordinate
---@param py number Point Y coordinate
---@param circle {x: number, y: number, radius: number}
---@return boolean
function CollisionUtils.pointCircle(px, py, circle)
    local dx = px - circle.x
    local dy = py - circle.y
    local distSq = dx * dx + dy * dy
    return distSq <= circle.radius * circle.radius
end

---Checks if a point is inside a rectangle (rect x, y is center)
---@param px number Point X coordinate
---@param py number Point Y coordinate
---@param rect {x: number, y: number, width: number, height: number}
---@return boolean
function CollisionUtils.pointRect(px, py, rect)
    local halfW = rect.width / 2
    local halfH = rect.height / 2

    return px >= rect.x - halfW and px <= rect.x + halfW and
           py >= rect.y - halfH and py <= rect.y + halfH
end

return CollisionUtils
