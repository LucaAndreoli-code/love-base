local InputAction = require("src.systems.input_handler.input_action")

describe("InputAction", function()
    describe("new", function()
        it("creates action with name", function()
            local action = InputAction.new({ name = "jump" })
            assert.equals("jump", action.name)
        end)

        it("creates action with keyboard binding", function()
            local action = InputAction.new({
                name = "jump",
                keyboard = "space"
            })
            assert.equals("space", action.keyboard)
        end)

        it("creates action with mouse binding", function()
            local action = InputAction.new({
                name = "shoot",
                mouse = 1
            })
            assert.equals(1, action.mouse)
        end)

        it("creates action with gamepad button", function()
            local action = InputAction.new({
                name = "jump",
                gamepadButton = "a"
            })
            assert.equals("a", action.gamepadButton)
        end)

        it("creates action with gamepad axis", function()
            local action = InputAction.new({
                name = "move_right",
                gamepadAxis = "leftx",
                axisDirection = 1,
                axisThreshold = 0.3,
            })
            assert.equals("leftx", action.gamepadAxis)
            assert.equals(1, action.axisDirection)
            assert.equals(0.3, action.axisThreshold)
        end)

        it("defaults axisThreshold to 0.5", function()
            local action = InputAction.new({
                name = "move",
                gamepadAxis = "leftx",
            })
            assert.equals(0.5, action.axisThreshold)
        end)
    end)

    describe("clone", function()
        it("creates independent copy", function()
            local original = InputAction.new({
                name = "jump",
                keyboard = "space"
            })
            local cloned = original:clone()

            cloned.keyboard = "w"

            assert.equals("space", original.keyboard)
            assert.equals("w", cloned.keyboard)
        end)

        it("copies all fields", function()
            local original = InputAction.new({
                name = "move",
                keyboard = "d",
                gamepadAxis = "leftx",
                axisDirection = 1,
                axisThreshold = 0.3,
            })
            local cloned = original:clone()

            assert.equals(original.name, cloned.name)
            assert.equals(original.keyboard, cloned.keyboard)
            assert.equals(original.gamepadAxis, cloned.gamepadAxis)
            assert.equals(original.axisDirection, cloned.axisDirection)
            assert.equals(original.axisThreshold, cloned.axisThreshold)
        end)
    end)

    describe("hasBinding", function()
        it("returns false for empty action", function()
            local action = InputAction.new({ name = "empty" })
            assert.is_false(action:hasBinding())
        end)

        it("returns true with keyboard", function()
            local action = InputAction.new({ name = "a", keyboard = "x" })
            assert.is_true(action:hasBinding())
        end)

        it("returns true with mouse", function()
            local action = InputAction.new({ name = "a", mouse = 1 })
            assert.is_true(action:hasBinding())
        end)

        it("returns true with gamepad", function()
            local action = InputAction.new({ name = "a", gamepadButton = "a" })
            assert.is_true(action:hasBinding())
        end)
    end)

    describe("serialize/deserialize", function()
        it("roundtrips correctly", function()
            local original = InputAction.new({
                name = "test",
                keyboard = "q",
                mouse = 2,
                gamepadButton = "b",
                axisThreshold = 0.7,
            })

            local data = original:serialize()
            local restored = InputAction.deserialize(data)

            assert.equals(original.name, restored.name)
            assert.equals(original.keyboard, restored.keyboard)
            assert.equals(original.mouse, restored.mouse)
            assert.equals(original.gamepadButton, restored.gamepadButton)
            assert.equals(original.axisThreshold, restored.axisThreshold)
        end)
    end)
end)
