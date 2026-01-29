local Logger = require("src.logger")

-- Mock state (must be accessible to mock functions)
local mockTime = 0
local keysDown = {}

-- Store original LÖVE table
local originalLove = _G.love

-- Create mock love table BEFORE requiring InputHandler
-- Use _G to ensure it's truly global
_G.love = {
    timer = {
        getTime = function()
            return mockTime
        end
    },
    keyboard = {
        isDown = function(key)
            return keysDown[key] == true
        end
    },
    joystick = {
        getJoysticks = function()
            return {}
        end
    }
}

-- Now require InputHandler with mock love in place
local InputHandler = require("src.systems.input_handler")

describe("InputHandler", function()
    setup(function()
        Logger.disable()
    end)

    teardown(function()
        Logger.enable()
        _G.love = originalLove
    end)

    -- Reset mock state before each test
    before_each(function()
        mockTime = 0
        keysDown = {}
    end)

    describe("new()", function()
        it("should create InputHandler with default bindings", function()
            local input = InputHandler.new()

            assert.is_not_nil(input)
            assert.is_not_nil(input.bindings)
            assert.is_not_nil(input.bindings.jump)
            assert.are.equal("space", input.bindings.jump.keyboard)
            assert.are.equal("a", input.bindings.jump.gamepad)
        end)

        it("should have all default actions", function()
            local input = InputHandler.new()

            assert.is_not_nil(input.bindings.jump)
            assert.is_not_nil(input.bindings.left)
            assert.is_not_nil(input.bindings.right)
            assert.is_not_nil(input.bindings.up)
            assert.is_not_nil(input.bindings.down)
            assert.is_not_nil(input.bindings.attack)
            assert.is_not_nil(input.bindings.dash)
            assert.is_not_nil(input.bindings.pause)
        end)

        it("should create InputHandler with custom bindings merged with defaults", function()
            local input = InputHandler.new({
                bindings = {
                    shoot = {
                        keyboard = "x",
                        gamepad = "b"
                    }
                }
            })

            -- Custom binding exists
            assert.is_not_nil(input.bindings.shoot)
            assert.are.equal("x", input.bindings.shoot.keyboard)

            -- Default bindings still exist
            assert.is_not_nil(input.bindings.jump)
            assert.are.equal("space", input.bindings.jump.keyboard)
        end)

        it("should use custom deadzone when provided", function()
            local input = InputHandler.new({ deadzone = 0.3 })

            assert.are.equal(0.3, input.deadzone)
        end)

        it("should use default deadzone of 0.2", function()
            local input = InputHandler.new()

            assert.are.equal(0.2, input.deadzone)
        end)

        it("should initialize state for all actions", function()
            local input = InputHandler.new()

            for action in pairs(input.bindings) do
                assert.is_not_nil(input.state[action])
                assert.is_false(input.state[action].pressed)
                assert.is_false(input.state[action].released)
                assert.are.equal(0, input.state[action].lastPressedAt)
            end
        end)
    end)

    describe("isHeld()", function()
        it("should return false if key is not pressed", function()
            local input = InputHandler.new()
            input:update()

            keysDown = {}

            assert.is_false(input:isHeld("jump"))
        end)

        it("should return true if key is pressed", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { space = true }

            assert.is_true(input:isHeld("jump"))
        end)

        it("should return true if any of multiple keys is pressed", function()
            local input = InputHandler.new()
            input:update()

            -- dash has bindings: { "k", "lshift" }
            keysDown = { lshift = true }

            assert.is_true(input:isHeld("dash"))
        end)

        it("should return false for unknown action", function()
            local input = InputHandler.new()
            input:update()

            assert.is_false(input:isHeld("unknownAction"))
        end)
    end)

    describe("isPressed()", function()
        it("should return false before any input", function()
            local input = InputHandler.new()
            input:update()

            assert.is_false(input:isPressed("jump"))
        end)

        it("should return true after _onKeyPressed and update", function()
            local input = InputHandler.new()
            input:_onKeyPressed("space")
            input:update()

            assert.is_true(input:isPressed("jump"))
        end)

        it("should return false on the next frame after press", function()
            local input = InputHandler.new()

            -- Frame 1: press
            input:_onKeyPressed("space")
            input:update()
            assert.is_true(input:isPressed("jump"))

            -- Frame 2: no new input
            input:update()
            assert.is_false(input:isPressed("jump"))
        end)

        it("should return false for unknown action", function()
            local input = InputHandler.new()
            input:_onKeyPressed("space")
            input:update()

            assert.is_false(input:isPressed("unknownAction"))
        end)

        it("should handle multiple presses correctly", function()
            local input = InputHandler.new()

            -- Press jump
            input:_onKeyPressed("space")
            input:update()
            assert.is_true(input:isPressed("jump"))

            -- Next frame, press attack
            input:_onKeyPressed("j")
            input:update()
            assert.is_false(input:isPressed("jump"))
            assert.is_true(input:isPressed("attack"))
        end)
    end)

    describe("isReleased()", function()
        it("should return false before any input", function()
            local input = InputHandler.new()
            input:update()

            assert.is_false(input:isReleased("jump"))
        end)

        it("should return true after _onKeyReleased and update", function()
            local input = InputHandler.new()
            input:_onKeyReleased("space")
            input:update()

            assert.is_true(input:isReleased("jump"))
        end)

        it("should return false on the next frame after release", function()
            local input = InputHandler.new()

            -- Frame 1: release
            input:_onKeyReleased("space")
            input:update()
            assert.is_true(input:isReleased("jump"))

            -- Frame 2: no new input
            input:update()
            assert.is_false(input:isReleased("jump"))
        end)
    end)

    describe("wasPressedWithin()", function()
        it("should return true if pressed recently", function()
            local input = InputHandler.new()

            mockTime = 1.0
            input:_onKeyPressed("space")
            input:update()

            -- Check immediately (0 seconds later)
            mockTime = 1.0
            assert.is_true(input:wasPressedWithin("jump", 0.1))
        end)

        it("should return true if pressed within time window", function()
            local input = InputHandler.new()

            mockTime = 1.0
            input:_onKeyPressed("space")
            input:update()

            -- Check 50ms later
            mockTime = 1.05
            assert.is_true(input:wasPressedWithin("jump", 0.1))
        end)

        it("should return false if pressed too long ago", function()
            local input = InputHandler.new()

            mockTime = 1.0
            input:_onKeyPressed("space")
            input:update()

            -- Check 200ms later (window is 100ms)
            mockTime = 1.2
            assert.is_false(input:wasPressedWithin("jump", 0.1))
        end)

        it("should return false if never pressed", function()
            local input = InputHandler.new()
            input:update()

            mockTime = 100.0 -- Any time
            assert.is_false(input:wasPressedWithin("jump", 0.1))
        end)

        it("should return false for unknown action", function()
            local input = InputHandler.new()
            input:update()

            assert.is_false(input:wasPressedWithin("unknownAction", 0.1))
        end)
    end)

    describe("getAxis()", function()
        it("should return 0 without any input", function()
            local input = InputHandler.new()
            input:update()

            keysDown = {}

            assert.are.equal(0, input:getAxis("horizontal"))
            assert.are.equal(0, input:getAxis("vertical"))
        end)

        it("should return -1 when left is held", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { a = true }

            assert.are.equal(-1, input:getAxis("horizontal"))
        end)

        it("should return 1 when right is held", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { d = true }

            assert.are.equal(1, input:getAxis("horizontal"))
        end)

        it("should return 0 when both left and right are held", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { a = true, d = true }

            assert.are.equal(0, input:getAxis("horizontal"))
        end)

        it("should return -1 when up is held (vertical)", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { w = true }

            assert.are.equal(-1, input:getAxis("vertical"))
        end)

        it("should return 1 when down is held (vertical)", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { s = true }

            assert.are.equal(1, input:getAxis("vertical"))
        end)

        it("should return 0 for unknown axis", function()
            local input = InputHandler.new()
            input:update()

            assert.are.equal(0, input:getAxis("unknownAxis"))
        end)
    end)

    describe("rebind()", function()
        it("should change keyboard binding for existing action", function()
            local input = InputHandler.new()

            input:rebind("jump", "keyboard", "up")

            assert.are.equal("up", input.bindings.jump.keyboard)
        end)

        it("should change gamepad binding for existing action", function()
            local input = InputHandler.new()

            input:rebind("jump", "gamepad", "b")

            assert.are.equal("b", input.bindings.jump.gamepad)
        end)

        it("should create new action if it doesn't exist", function()
            local input = InputHandler.new()

            input:rebind("customAction", "keyboard", "q")

            assert.is_not_nil(input.bindings.customAction)
            assert.are.equal("q", input.bindings.customAction.keyboard)
            assert.is_not_nil(input.state.customAction)
        end)

        it("should allow multiple keys as array", function()
            local input = InputHandler.new()

            input:rebind("jump", "keyboard", { "space", "up" })

            assert.are.same({ "space", "up" }, input.bindings.jump.keyboard)
        end)

        it("should work with isPressed after rebind", function()
            local input = InputHandler.new()

            -- Rebind jump to "x"
            input:rebind("jump", "keyboard", "x")

            -- Press new key
            input:_onKeyPressed("x")
            input:update()

            assert.is_true(input:isPressed("jump"))
        end)

        it("should not respond to old key after rebind", function()
            local input = InputHandler.new()

            -- Rebind jump from "space" to "x"
            input:rebind("jump", "keyboard", "x")

            -- Press old key
            input:_onKeyPressed("space")
            input:update()

            assert.is_false(input:isPressed("jump"))
        end)
    end)

    describe("getBindings()", function()
        it("should return the bindings table", function()
            local input = InputHandler.new()

            local bindings = input:getBindings()

            assert.is_not_nil(bindings)
            assert.is_not_nil(bindings.jump)
            assert.are.equal("space", bindings.jump.keyboard)
        end)
    end)

    describe("getActiveDevice()", function()
        it("should return keyboard by default", function()
            local input = InputHandler.new()

            assert.are.equal("keyboard", input:getActiveDevice())
        end)

        it("should switch to keyboard on key press", function()
            local input = InputHandler.new()
            input.activeDevice = "gamepad"

            input:_onKeyPressed("space")

            assert.are.equal("keyboard", input:getActiveDevice())
        end)

        it("should switch to gamepad on gamepad press", function()
            local input = InputHandler.new()

            input:_onGamepadPressed({}, "a")

            assert.are.equal("gamepad", input:getActiveDevice())
        end)
    end)

    describe("setDeadzone()", function()
        it("should set deadzone value", function()
            local input = InputHandler.new()

            input:setDeadzone(0.3)

            assert.are.equal(0.3, input.deadzone)
        end)

        it("should clamp deadzone to 0-1 range", function()
            local input = InputHandler.new()

            input:setDeadzone(-0.5)
            assert.are.equal(0, input.deadzone)

            input:setDeadzone(1.5)
            assert.are.equal(1, input.deadzone)
        end)
    end)

    describe("applyDeadzone()", function()
        it("should return 0 for values within deadzone", function()
            local input = InputHandler.new({ deadzone = 0.2 })

            assert.are.equal(0, input:applyDeadzone(0.1))
            assert.are.equal(0, input:applyDeadzone(-0.1))
            assert.are.equal(0, input:applyDeadzone(0.19))
        end)

        it("should return normalized value outside deadzone", function()
            local input = InputHandler.new({ deadzone = 0.2 })

            -- At full tilt (1.0), should return 1.0
            assert.are.equal(1, input:applyDeadzone(1.0))

            -- At -1.0, should return -1.0
            assert.are.equal(-1, input:applyDeadzone(-1.0))
        end)

        it("should rescale values correctly", function()
            local input = InputHandler.new({ deadzone = 0.2 })

            -- At 0.6 (midpoint between 0.2 and 1.0), should return 0.5
            local result = input:applyDeadzone(0.6)
            assert.is_true(math.abs(result - 0.5) < 0.001)
        end)
    end)

    describe("update()", function()
        it("should clear event queue after processing", function()
            local input = InputHandler.new()

            input:_onKeyPressed("space")
            assert.are.equal(1, #input.eventQueue)

            input:update()
            assert.are.equal(0, #input.eventQueue)
        end)

        it("should reset pressed/released flags each frame", function()
            local input = InputHandler.new()

            input:_onKeyPressed("space")
            input:update()

            -- pressed is true on first frame
            assert.is_true(input.state.jump.pressed)

            -- pressed is false on second frame
            input:update()
            assert.is_false(input.state.jump.pressed)
        end)

        it("should record lastPressedAt timestamp", function()
            local input = InputHandler.new()

            mockTime = 5.0
            input:_onKeyPressed("space")
            input:update()

            assert.are.equal(5.0, input.state.jump.lastPressedAt)
        end)
    end)

    describe("multiple keys binding (dash)", function()
        it("should trigger pressed for first key", function()
            local input = InputHandler.new()

            input:_onKeyPressed("k")
            input:update()

            assert.is_true(input:isPressed("dash"))
        end)

        it("should trigger pressed for second key", function()
            local input = InputHandler.new()

            input:_onKeyPressed("lshift")
            input:update()

            assert.is_true(input:isPressed("dash"))
        end)

        it("should trigger isHeld for either key", function()
            local input = InputHandler.new()
            input:update()

            keysDown = { k = true }
            assert.is_true(input:isHeld("dash"))

            keysDown = { lshift = true }
            assert.is_true(input:isHeld("dash"))

            keysDown = { k = true, lshift = true }
            assert.is_true(input:isHeld("dash"))
        end)
    end)
end)
