local InputState = require("src.systems.input_handler.input_state")

describe("InputState", function()
    describe("new", function()
        it("starts in idle state", function()
            local state = InputState.new()

            assert.is_false(state.down)
            assert.is_false(state.pressed)
            assert.is_false(state.released)
            assert.equals(0, state.downDuration)
        end)
    end)

    describe("update", function()
        it("detects press on first down frame", function()
            local state = InputState.new()

            state:update(true, 0.016)

            assert.is_true(state.pressed)
            assert.is_true(state.down)
            assert.is_false(state.released)
        end)

        it("clears pressed after first frame", function()
            local state = InputState.new()

            state:update(true, 0.016) -- press
            state:update(true, 0.016) -- hold

            assert.is_false(state.pressed)
            assert.is_true(state.down)
        end)

        it("detects release", function()
            local state = InputState.new()

            state:update(true, 0.016)  -- press
            state:update(false, 0.016) -- release

            assert.is_false(state.down)
            assert.is_false(state.pressed)
            assert.is_true(state.released)
        end)

        it("clears released after frame", function()
            local state = InputState.new()

            state:update(true, 0.016)  -- press
            state:update(false, 0.016) -- release
            state:update(false, 0.016) -- idle

            assert.is_false(state.released)
        end)

        it("tracks duration while held", function()
            local state = InputState.new()

            state:update(true, 0.1)
            state:update(true, 0.1)
            state:update(true, 0.1)

            assert.near(0.3, state.downDuration, 0.001)
        end)

        it("resets duration on release", function()
            local state = InputState.new()

            state:update(true, 0.1)
            state:update(true, 0.1)
            state:update(false, 0.1)

            assert.equals(0, state.downDuration)
        end)
    end)

    describe("clear", function()
        it("resets all state", function()
            local state = InputState.new()

            state:update(true, 0.1)
            state:update(true, 0.1)
            state:clear()

            assert.is_false(state.down)
            assert.is_false(state.pressed)
            assert.is_false(state.released)
            assert.equals(0, state.downDuration)
        end)
    end)
end)
