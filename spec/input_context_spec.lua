local InputContext = require("src.systems.input_handler.input_context")
local InputAction = require("src.systems.input_handler.input_action")

describe("InputContext", function()
    describe("new", function()
        it("creates empty context with name", function()
            local ctx = InputContext.new("gameplay")

            assert.equals("gameplay", ctx.name)
            assert.equals(0, ctx:count())
        end)
    end)

    describe("addAction", function()
        it("adds action", function()
            local ctx = InputContext.new("test")
            local action = InputAction.new({ name = "jump", keyboard = "space" })

            ctx:addAction(action)

            assert.equals(1, ctx:count())
            assert.is_true(ctx:hasAction("jump"))
        end)

        it("overwrites existing action with same name", function()
            local ctx = InputContext.new("test")

            ctx:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
            ctx:addAction(InputAction.new({ name = "jump", keyboard = "w" }))

            assert.equals(1, ctx:count())
            assert.equals("w", ctx:getAction("jump").keyboard)
        end)
    end)

    describe("removeAction", function()
        it("removes existing action", function()
            local ctx = InputContext.new("test")
            ctx:addAction(InputAction.new({ name = "jump", keyboard = "space" }))

            local removed = ctx:removeAction("jump")

            assert.is_true(removed)
            assert.is_false(ctx:hasAction("jump"))
            assert.equals(0, ctx:count())
        end)

        it("returns false for non-existent action", function()
            local ctx = InputContext.new("test")

            local removed = ctx:removeAction("nonexistent")

            assert.is_false(removed)
        end)
    end)

    describe("getAction", function()
        it("returns action by name", function()
            local ctx = InputContext.new("test")
            local action = InputAction.new({ name = "jump", keyboard = "space" })
            ctx:addAction(action)

            local retrieved = ctx:getAction("jump")

            assert.equals(action, retrieved)
        end)

        it("returns nil for non-existent", function()
            local ctx = InputContext.new("test")

            assert.is_nil(ctx:getAction("nonexistent"))
        end)
    end)

    describe("getActions", function()
        it("returns all actions", function()
            local ctx = InputContext.new("test")
            ctx:addAction(InputAction.new({ name = "a", keyboard = "a" }))
            ctx:addAction(InputAction.new({ name = "b", keyboard = "b" }))

            local actions = ctx:getActions()

            assert.is_not_nil(actions.a)
            assert.is_not_nil(actions.b)
        end)
    end)
end)
