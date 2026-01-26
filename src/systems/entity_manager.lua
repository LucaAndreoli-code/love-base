local Logger = require("src.logger")

---@class EntityManager
---@field entities table[]
---@field byTag table<string, table<Entity, boolean>>
local EntityManager = {}
EntityManager.__index = EntityManager

-- Empty table singleton for getByTag on non-existent tags
local EMPTY_TABLE = {}

---Creates a new EntityManager
---@return EntityManager
function EntityManager.new()
    local self = setmetatable({}, EntityManager)
    self.entities = {}
    self.byTag = {}
    Logger.debug("EntityManager created", "EntityManager")
    return self
end

---Adds an entity to the manager
---@param entity Entity
function EntityManager:add(entity)
    table.insert(self.entities, entity)

    -- Populate byTag cache
    for tag, _ in pairs(entity.tags) do
        if not self.byTag[tag] then
            self.byTag[tag] = {}
        end
        self.byTag[tag][entity] = true
    end

    Logger.debug(string.format("Entity added (total: %d)", #self.entities), "EntityManager")
end

---Removes an entity from the manager
---@param entity Entity
function EntityManager:remove(entity)
    -- Remove from entities list
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            break
        end
    end

    -- Remove from all byTag caches
    for _, tagTable in pairs(self.byTag) do
        tagTable[entity] = nil
    end

    Logger.debug(string.format("Entity removed (total: %d)", #self.entities), "EntityManager")
end

---Returns all entities with a specific tag
---@param tag string
---@return table<Entity, boolean>
function EntityManager:getByTag(tag)
    return self.byTag[tag] or EMPTY_TABLE
end

---Refreshes the tag cache for an entity after tag modifications
---@param entity Entity
function EntityManager:refreshTags(entity)
    -- Remove entity from all tag caches
    for _, tagTable in pairs(self.byTag) do
        tagTable[entity] = nil
    end

    -- Re-add with current tags
    for tag, _ in pairs(entity.tags) do
        if not self.byTag[tag] then
            self.byTag[tag] = {}
        end
        self.byTag[tag][entity] = true
    end
end

---Returns all entities
---@return table[]
function EntityManager:getAll()
    return self.entities
end

---Updates all alive entities
---@param dt number Delta time
function EntityManager:update(dt)
    for _, entity in ipairs(self.entities) do
        if entity.alive then
            entity:update(dt)
        end
    end
end

---Draws all alive entities
function EntityManager:draw()
    for _, entity in ipairs(self.entities) do
        if entity.alive then
            entity:draw()
        end
    end
end

---Removes all dead entities from the manager
function EntityManager:cleanup()
    local removed = 0
    local i = 1

    while i <= #self.entities do
        local entity = self.entities[i]
        if not entity.alive then
            -- Remove from byTag caches
            for _, tagTable in pairs(self.byTag) do
                tagTable[entity] = nil
            end
            table.remove(self.entities, i)
            removed = removed + 1
        else
            i = i + 1
        end
    end

    if removed > 0 then
        Logger.debug(string.format("Cleanup: removed %d dead entities", removed), "EntityManager")
    end
end

---Clears all entities from the manager
function EntityManager:clear()
    self.entities = {}
    self.byTag = {}
    Logger.debug("All entities cleared", "EntityManager")
end

---Returns the count of alive entities
---@return number
function EntityManager:count()
    local count = 0
    for _, entity in ipairs(self.entities) do
        if entity.alive then
            count = count + 1
        end
    end
    return count
end

return EntityManager
