local Entity = require("src.systems.entity")
local Logger = require("src.logger")

describe("Entity", function()
    -- Disable logging during tests
    setup(function()
        Logger.disable()
    end)

    teardown(function()
        Logger.enable()
    end)

    describe("new()", function()
        it("should create entity with default values", function()
            local entity = Entity.new()

            assert.are.equal(0, entity.x)
            assert.are.equal(0, entity.y)
            assert.are.equal(0, entity.vx)
            assert.are.equal(0, entity.vy)
            assert.are.equal(0, entity.rotation)
            assert.are.equal(0, entity.radius)
            assert.is_true(entity.alive)
            assert.are.same({}, entity.tags)
        end)

        it("should create entity with config values", function()
            local entity = Entity.new({
                x = 100,
                y = 200,
                vx = 10,
                vy = -5,
                rotation = 1.5,
                radius = 20
            })

            assert.are.equal(100, entity.x)
            assert.are.equal(200, entity.y)
            assert.are.equal(10, entity.vx)
            assert.are.equal(-5, entity.vy)
            assert.are.equal(1.5, entity.rotation)
            assert.are.equal(20, entity.radius)
            assert.is_true(entity.alive)
        end)

        it("should initialize tags from config array", function()
            local entity = Entity.new({
                tags = { "player", "collidable" }
            })

            assert.is_true(entity.tags["player"])
            assert.is_true(entity.tags["collidable"])
            assert.is_true(entity:hasTag("player"))
            assert.is_true(entity:hasTag("collidable"))
        end)
    end)

    describe("update()", function()
        it("should move entity based on velocity", function()
            local entity = Entity.new({
                x = 0,
                y = 0,
                vx = 100,
                vy = 50
            })

            entity:update(0.5)

            assert.are.equal(50, entity.x)
            assert.are.equal(25, entity.y)
        end)

        it("should not move entity with zero velocity", function()
            local entity = Entity.new({
                x = 100,
                y = 200,
                vx = 0,
                vy = 0
            })

            entity:update(1.0)

            assert.are.equal(100, entity.x)
            assert.are.equal(200, entity.y)
        end)
    end)

    describe("destroy()", function()
        it("should set alive to false", function()
            local entity = Entity.new()

            assert.is_true(entity.alive)

            entity:destroy()

            assert.is_false(entity.alive)
        end)
    end)

    describe("tags", function()
        it("addTag() should add a tag", function()
            local entity = Entity.new()

            entity:addTag("enemy")

            assert.is_true(entity.tags["enemy"])
        end)

        it("removeTag() should remove a tag", function()
            local entity = Entity.new({
                tags = { "player" }
            })

            assert.is_true(entity:hasTag("player"))

            entity:removeTag("player")

            assert.is_nil(entity.tags["player"])
            assert.is_false(entity:hasTag("player"))
        end)

        it("hasTag() should return true for existing tag", function()
            local entity = Entity.new()
            entity:addTag("bullet")

            assert.is_true(entity:hasTag("bullet"))
        end)

        it("hasTag() should return false for non-existing tag", function()
            local entity = Entity.new()

            assert.is_false(entity:hasTag("nonexistent"))
        end)
    end)
end)
