local Logger = require("src.logger")
local Game = require("src.init")

---@class Entity
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field rotation number
---@field radius number
---@field alive boolean
---@field tags table<string, boolean>
local Entity = {}
Entity.__index = Entity

---Creates a new Entity
---@param config? {x?: number, y?: number, vx?: number, vy?: number, rotation?: number, radius?: number, tags?: string[]}
---@return Entity
function Entity.new(config)
    config = config or {}

    local self = setmetatable({}, Entity)

    self.x = config.x or 0
    self.y = config.y or 0
    self.vx = config.vx or 0
    self.vy = config.vy or 0
    self.rotation = config.rotation or 0
    self.radius = config.radius or 0
    self.alive = true
    self.tags = {}

    -- Initialize tags from config array
    if config.tags then
        for _, tag in ipairs(config.tags) do
            self.tags[tag] = true
        end
    end

    -- Log creation
    local tagList = {}
    for tag, _ in pairs(self.tags) do
        table.insert(tagList, tag)
    end

    if #tagList > 0 then
        Logger.debug(string.format("Entity created at (%.2f, %.2f) with tags: %s", self.x, self.y, table.concat(tagList, ", ")), "Entity")
    else
        Logger.debug(string.format("Entity created at (%.2f, %.2f)", self.x, self.y), "Entity")
    end

    return self
end

---Updates the entity position based on velocity
---@param dt number Delta time
function Entity:update(dt)
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
end

---Draw method (empty, for override)
function Entity:draw()
    -- Override in subclasses
end

---Draws debug information (hitbox, center, velocity)
function Entity:drawDebug()
    local Colors = Game.constants.colors

    -- Draw hitbox circle
    love.graphics.setColor(Colors.debug.hitbox)
    love.graphics.circle("line", self.x, self.y, self.radius)

    -- Draw center point
    love.graphics.setColor(Colors.debug.center)
    love.graphics.circle("fill", self.x, self.y, 3)

    -- Draw velocity vector
    if self.vx ~= 0 or self.vy ~= 0 then
        love.graphics.setColor(Colors.debug.velocity)
        local scale = 0.5
        love.graphics.line(self.x, self.y, self.x + self.vx * scale, self.y + self.vy * scale)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

---Destroys the entity
function Entity:destroy()
    self.alive = false
    Logger.debug("Entity destroyed", "Entity")
end

---Adds a tag to the entity
---@param tag string
function Entity:addTag(tag)
    self.tags[tag] = true
    Logger.debug("Tag added: " .. tag, "Entity")
end

---Removes a tag from the entity
---@param tag string
function Entity:removeTag(tag)
    self.tags[tag] = nil
    Logger.debug("Tag removed: " .. tag, "Entity")
end

---Checks if the entity has a tag
---@param tag string
---@return boolean
function Entity:hasTag(tag)
    return self.tags[tag] == true
end

return Entity
