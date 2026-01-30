-- Mock love module for testing
_G.love = {
    joystick = {
        getJoysticks = function() return {} end
    },
    mouse = {
        getPosition = function() return 0, 0 end
    },
    graphics = {
        print = function() end
    }
}

local InputModule = require("src.systems.input_handler.init")
local InputHandler = InputModule.InputHandler
local InputContext = InputModule.InputContext
local InputAction = InputModule.InputAction

describe("InputHandler", function()
    -- Helper: creates handler with test context
    local function createTestHandler()
        local handler = InputHandler.new()

        local ctx = InputContext.new("test")
        ctx:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
        ctx:addAction(InputAction.new({ name = "shoot", keyboard = "x", mouse = 1 }))
        ctx:addAction(InputAction.new({
            name = "move_right",
            keyboard = "d",
            gamepadAxis = "leftx",
            axisDirection = 1,
        }))

        handler:addContext(ctx)
        handler:setContext("test")

        return handler
    end

    -------------------------------------------------
    -- Core
    -------------------------------------------------

    describe("new", function()
        it("creates with default settings", function()
            local handler = InputHandler.new()

            assert.equals(0.5, handler.settings.axisThreshold)
            assert.equals(5, handler.settings.dragThreshold)
        end)

        it("creates with custom settings", function()
            local handler = InputHandler.new({ axisThreshold = 0.3 })

            assert.equals(0.3, handler.settings.axisThreshold)
        end)
    end)

    -------------------------------------------------
    -- Context Management
    -------------------------------------------------

    describe("context management", function()
        it("sets context exclusively", function()
            local handler = createTestHandler()

            local ctx2 = InputContext.new("menu")
            handler:addContext(ctx2)

            handler:setContext("test")
            handler:setContext("menu")

            assert.is_true(handler:isContextActive("menu"))
            assert.is_false(handler:isContextActive("test"))
        end)

        it("pushes context additively", function()
            local handler = createTestHandler()

            local ctx2 = InputContext.new("pause")
            handler:addContext(ctx2)

            handler:setContext("test")
            handler:pushContext("pause")

            assert.is_true(handler:isContextActive("test"))
            assert.is_true(handler:isContextActive("pause"))
        end)

        it("pops context", function()
            local handler = createTestHandler()

            local ctx2 = InputContext.new("pause")
            handler:addContext(ctx2)

            handler:setContext("test")
            handler:pushContext("pause")
            handler:popContext("pause")

            assert.is_true(handler:isContextActive("test"))
            assert.is_false(handler:isContextActive("pause"))
        end)

        it("clears all contexts", function()
            local handler = createTestHandler()
            handler:clearContexts()

            assert.equals(0, #handler:getActiveContexts())
        end)
    end)

    -------------------------------------------------
    -- Event Capture
    -------------------------------------------------

    describe("event capture", function()
        it("captures keyboard press", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)

            assert.is_true(handler._rawInputs["key:space"])
        end)

        it("ignores keyboard repeat", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", true)

            assert.is_nil(handler._rawInputs["key:space"])
        end)

        it("captures keyboard release", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)
            handler:keyreleased("space", "space")

            assert.is_false(handler._rawInputs["key:space"])
        end)

        it("captures mouse position", function()
            local handler = createTestHandler()

            handler:mousemoved(100, 200, 5, 10)

            assert.equals(100, handler.mouse.x)
            assert.equals(200, handler.mouse.y)
        end)

        it("captures mouse scroll", function()
            local handler = createTestHandler()

            handler:wheelmoved(0, 1)

            assert.equals(1, handler.mouse.scroll.y)
            assert.is_true(handler._rawInputs["mouse:wheel:up"])
        end)
    end)

    -------------------------------------------------
    -- Query API
    -------------------------------------------------

    describe("query", function()
        it("returns false when not pressed", function()
            local handler = createTestHandler()
            handler:update(0.016)

            assert.is_false(handler:isDown("jump"))
            assert.is_false(handler:isPressed("jump"))
        end)

        it("returns true when key pressed", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)
            handler:update(0.016)

            assert.is_true(handler:isDown("jump"))
            assert.is_true(handler:isPressed("jump"))
        end)

        it("pressed is true only first frame", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)
            handler:update(0.016)

            assert.is_true(handler:isPressed("jump"))

            handler:update(0.016)

            assert.is_true(handler:isDown("jump"))
            assert.is_false(handler:isPressed("jump"))
        end)

        it("detects release", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)
            handler:update(0.016)
            handler:keyreleased("space", "space")
            handler:update(0.016)

            assert.is_false(handler:isDown("jump"))
            assert.is_true(handler:isReleased("jump"))
        end)

        it("tracks hold duration", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)
            handler:update(0.1)
            handler:update(0.1)
            handler:update(0.1)

            assert.near(0.3, handler:getHoldDuration("jump"), 0.001)
        end)

        it("returns false for action not in active context", function()
            local handler = createTestHandler()

            handler:keypressed("space", "space", false)
            handler:clearContexts()
            handler:update(0.016)

            assert.is_false(handler:isDown("jump"))
        end)

        it("handles multiple inputs for same action", function()
            local handler = createTestHandler()

            -- shoot has both keyboard and mouse
            handler:mousepressed(100, 100, 1, false)
            handler:update(0.016)

            assert.is_true(handler:isPressed("shoot"))
        end)
    end)

    -------------------------------------------------
    -- Mouse
    -------------------------------------------------

    describe("mouse", function()
        it("tracks position", function()
            local handler = createTestHandler()

            handler:mousemoved(150, 250, 0, 0)

            local x, y = handler:getMousePosition()
            assert.equals(150, x)
            assert.equals(250, y)
        end)

        it("tracks drag", function()
            local handler = createTestHandler()
            handler.settings.dragThreshold = 5

            handler:mousepressed(50, 50, 1, false)
            handler:mousemoved(60, 50, 10, 0) -- > threshold

            assert.is_true(handler:isDragging())

            local dx, dy = handler:getDragDelta()
            assert.equals(10, dx)
            assert.equals(0, dy)
        end)

        it("ends drag on release", function()
            local handler = createTestHandler()

            handler:mousepressed(50, 50, 1, false)
            handler:mousemoved(100, 50, 50, 0)
            handler:mousereleased(100, 50, 1, false)

            assert.is_false(handler:isDragging())
        end)
    end)

    -------------------------------------------------
    -- Rebinding
    -------------------------------------------------

    describe("rebinding", function()
        it("sets binding directly", function()
            local handler = createTestHandler()

            local success = handler:setBinding("jump", "keyboard", "w")

            assert.is_true(success)
            assert.equals("w", handler:getBinding("jump", "keyboard"))
        end)

        it("enters rebind mode", function()
            local handler = createTestHandler()

            handler:startRebind("jump", "keyboard")

            assert.is_true(handler:isRebinding())
        end)

        it("captures key during rebind", function()
            local handler = createTestHandler()
            local captured = nil

            handler:startRebind("jump", "keyboard", function(success, key)
                captured = key
            end)

            handler:keypressed("w", "w", false)

            assert.equals("w", captured)
            assert.is_false(handler:isRebinding())
            assert.equals("w", handler:getBinding("jump", "keyboard"))
        end)

        it("cancels rebind with escape", function()
            local handler = createTestHandler()
            local cancelled = false

            handler:startRebind("jump", "keyboard", function(success)
                cancelled = not success
            end)

            handler:keypressed("escape", "escape", false)

            assert.is_true(cancelled)
            assert.is_false(handler:isRebinding())
        end)

        it("exports and imports bindings", function()
            local handler = createTestHandler()
            handler:setBinding("jump", "keyboard", "w")

            local data = handler:exportBindings()

            handler:setBinding("jump", "keyboard", "q")
            handler:importBindings(data)

            assert.equals("w", handler:getBinding("jump", "keyboard"))
        end)
    end)

    -------------------------------------------------
    -- Late Update
    -------------------------------------------------

    describe("lateUpdate", function()
        it("resets mouse scroll", function()
            local handler = createTestHandler()

            handler:wheelmoved(0, 1)
            handler:lateUpdate()

            local x, y = handler:getMouseScroll()
            assert.equals(0, x)
            assert.equals(0, y)
        end)

        it("clears wheel raw inputs", function()
            local handler = createTestHandler()

            handler:wheelmoved(0, 1)
            handler:lateUpdate()

            assert.is_nil(handler._rawInputs["mouse:wheel:up"])
        end)
    end)
end)
