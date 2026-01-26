local EntityManager = require("src.systems.entity_manager")
local Entity = require("src.systems.entity")
local Logger = require("src.logger")

describe("EntityManager", function()
    local manager

    setup(function()
        Logger.disable()
    end)

    teardown(function()
        Logger.enable()
    end)

    before_each(function()
        manager = EntityManager.new()
    end)

    describe("new()", function()
        it("should create empty manager", function()
            assert.are.same({}, manager.entities)
            assert.are.same({}, manager.byTag)
        end)
    end)

    describe("add()", function()
        it("should add entity and populate byTag cache", function()
            local entity = Entity.new({ tags = { "player" } })

            manager:add(entity)

            assert.are.equal(1, #manager.entities)
            assert.are.equal(entity, manager.entities[1])
            assert.is_true(manager.byTag["player"][entity])
        end)

        it("should populate all tag caches for entity with multiple tags", function()
            local entity = Entity.new({ tags = { "enemy", "collidable", "shootable" } })

            manager:add(entity)

            assert.is_true(manager.byTag["enemy"][entity])
            assert.is_true(manager.byTag["collidable"][entity])
            assert.is_true(manager.byTag["shootable"][entity])
        end)
    end)

    describe("remove()", function()
        it("should remove entity and clean byTag cache", function()
            local entity = Entity.new({ tags = { "player", "collidable" } })
            manager:add(entity)

            manager:remove(entity)

            assert.are.equal(0, #manager.entities)
            assert.is_nil(manager.byTag["player"][entity])
            assert.is_nil(manager.byTag["collidable"][entity])
        end)
    end)

    describe("getByTag()", function()
        it("should return entities with that tag", function()
            local player = Entity.new({ tags = { "player" } })
            local enemy1 = Entity.new({ tags = { "enemy" } })
            local enemy2 = Entity.new({ tags = { "enemy" } })

            manager:add(player)
            manager:add(enemy1)
            manager:add(enemy2)

            local enemies = manager:getByTag("enemy")

            assert.is_true(enemies[enemy1])
            assert.is_true(enemies[enemy2])
            assert.is_nil(enemies[player])
        end)

        it("should return empty table for non-existent tag", function()
            local result = manager:getByTag("nonexistent")

            assert.are.same({}, result)
        end)
    end)

    describe("refreshTags()", function()
        it("should update cache after tag modification", function()
            local entity = Entity.new({ tags = { "player" } })
            manager:add(entity)

            assert.is_true(manager.byTag["player"][entity])

            -- Modify tags directly
            entity:removeTag("player")
            entity:addTag("enemy")

            -- Refresh cache
            manager:refreshTags(entity)

            assert.is_nil(manager.byTag["player"][entity])
            assert.is_true(manager.byTag["enemy"][entity])
        end)
    end)

    describe("getAll()", function()
        it("should return all entities", function()
            local e1 = Entity.new()
            local e2 = Entity.new()
            local e3 = Entity.new()

            manager:add(e1)
            manager:add(e2)
            manager:add(e3)

            local all = manager:getAll()

            assert.are.equal(3, #all)
            assert.are.equal(e1, all[1])
            assert.are.equal(e2, all[2])
            assert.are.equal(e3, all[3])
        end)
    end)

    describe("update()", function()
        it("should call update only on alive entities", function()
            local alive1 = Entity.new()
            local alive2 = Entity.new()
            local dead = Entity.new()
            dead:destroy()

            -- Create spies
            local alive1Updated = false
            local alive2Updated = false
            local deadUpdated = false

            alive1.update = function() alive1Updated = true end
            alive2.update = function() alive2Updated = true end
            dead.update = function() deadUpdated = true end

            manager:add(alive1)
            manager:add(alive2)
            manager:add(dead)

            manager:update(0.016)

            assert.is_true(alive1Updated)
            assert.is_true(alive2Updated)
            assert.is_false(deadUpdated)
        end)

        it("should not call update on entities with alive = false", function()
            local entity = Entity.new()
            local updateCalled = false
            entity.update = function() updateCalled = true end
            entity.alive = false

            manager:add(entity)
            manager:update(0.016)

            assert.is_false(updateCalled)
        end)
    end)

    describe("draw()", function()
        it("should call draw only on alive entities", function()
            local alive = Entity.new()
            local dead = Entity.new()
            dead:destroy()

            local aliveDrawn = false
            local deadDrawn = false

            alive.draw = function() aliveDrawn = true end
            dead.draw = function() deadDrawn = true end

            manager:add(alive)
            manager:add(dead)

            manager:draw()

            assert.is_true(aliveDrawn)
            assert.is_false(deadDrawn)
        end)
    end)

    describe("cleanup()", function()
        it("should remove dead entities from entities and cache", function()
            local alive = Entity.new({ tags = { "player" } })
            local dead = Entity.new({ tags = { "enemy" } })
            dead:destroy()

            manager:add(alive)
            manager:add(dead)

            assert.are.equal(2, #manager.entities)

            manager:cleanup()

            assert.are.equal(1, #manager.entities)
            assert.are.equal(alive, manager.entities[1])
            assert.is_nil(manager.byTag["enemy"][dead])
            assert.is_true(manager.byTag["player"][alive])
        end)
    end)

    describe("clear()", function()
        it("should empty everything", function()
            local e1 = Entity.new({ tags = { "a" } })
            local e2 = Entity.new({ tags = { "b" } })

            manager:add(e1)
            manager:add(e2)

            manager:clear()

            assert.are.same({}, manager.entities)
            assert.are.same({}, manager.byTag)
        end)
    end)

    describe("count()", function()
        it("should return correct count of alive entities", function()
            local alive1 = Entity.new()
            local alive2 = Entity.new()
            local dead = Entity.new()
            dead:destroy()

            manager:add(alive1)
            manager:add(alive2)
            manager:add(dead)

            assert.are.equal(2, manager:count())
        end)
    end)
end)
