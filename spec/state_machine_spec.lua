local StateMachine = require("src.systems.state_machine")
local Logger = require("src.logger")

describe("StateMachine", function()
    local sm

    setup(function()
        Logger.disable()
    end)

    teardown(function()
        Logger.enable()
    end)

    before_each(function()
        sm = StateMachine.new()
    end)

    describe("new()", function()
        it("should create state machine with empty stack", function()
            assert.are.same({}, sm.stack)
            assert.are.same({}, sm.states)
        end)

        it("should return nil for getState on empty stack", function()
            assert.is_nil(sm:getState())
        end)
    end)

    describe("addState()", function()
        it("should add state correctly", function()
            sm:addState("menu", {})
            assert.is_not_nil(sm.states["menu"])
        end)

        it("should add state with all callbacks", function()
            local callbacks = {
                enter = function() end,
                exit = function() end,
                update = function() end,
                draw = function() end,
                pause = function() end,
                resume = function() end
            }
            sm:addState("playing", callbacks)
            assert.are.equal(callbacks, sm.states["playing"])
        end)

        it("should add state with partial callbacks", function()
            local callbacks = {
                enter = function() end,
                update = function() end
            }
            sm:addState("menu", callbacks)
            assert.is_not_nil(sm.states["menu"].enter)
            assert.is_not_nil(sm.states["menu"].update)
            assert.is_nil(sm.states["menu"].exit)
        end)
    end)

    describe("setState()", function()
        it("should set state and call enter", function()
            local enterCalled = false
            sm:addState("menu", {
                enter = function() enterCalled = true end
            })

            sm:setState("menu")

            assert.is_true(enterCalled)
            assert.are.equal("menu", sm:getState())
        end)

        it("should call exit of old state and enter of new state", function()
            local sequence = {}
            sm:addState("menu", {
                enter = function() table.insert(sequence, "menu:enter") end,
                exit = function() table.insert(sequence, "menu:exit") end
            })
            sm:addState("playing", {
                enter = function() table.insert(sequence, "playing:enter") end
            })

            sm:setState("menu")
            sm:setState("playing")

            assert.are.same({ "menu:enter", "menu:exit", "playing:enter" }, sequence)
        end)

        it("should pass params to enter", function()
            local receivedParams
            sm:addState("menu", {
                enter = function(params) receivedParams = params end
            })

            sm:setState("menu", { level = 1 })

            assert.are.same({ level = 1 }, receivedParams)
        end)

        it("should pass params to exit", function()
            local receivedParams
            sm:addState("menu", {
                exit = function(params) receivedParams = params end
            })
            sm:addState("playing", {})

            sm:setState("menu")
            sm:setState("playing", { score = 100 })

            assert.are.same({ score = 100 }, receivedParams)
        end)

        it("should clear stack when called", function()
            sm:addState("menu", {})
            sm:addState("playing", {})
            sm:addState("pause", {})

            sm:setState("menu")
            sm:pushState("playing")
            sm:pushState("pause")
            assert.are.equal(3, #sm.stack)

            sm:setState("menu")
            assert.are.equal(1, #sm.stack)
        end)

        it("should not crash with unregistered state name", function()
            sm:addState("menu", {})
            sm:setState("menu")

            -- This should not crash and should not change state
            sm:setState("nonexistent")

            assert.are.equal("menu", sm:getState())
        end)
    end)

    describe("pushState()", function()
        it("should push state and call enter", function()
            local enterCalled = false
            sm:addState("menu", {})
            sm:addState("pause", {
                enter = function() enterCalled = true end
            })

            sm:setState("menu")
            sm:pushState("pause")

            assert.is_true(enterCalled)
            assert.are.equal("pause", sm:getState())
        end)

        it("should call pause of previous state", function()
            local pauseCalled = false
            sm:addState("playing", {
                pause = function() pauseCalled = true end
            })
            sm:addState("pause", {})

            sm:setState("playing")
            sm:pushState("pause")

            assert.is_true(pauseCalled)
        end)

        it("should pass params to enter", function()
            local receivedParams
            sm:addState("menu", {})
            sm:addState("dialog", {
                enter = function(params) receivedParams = params end
            })

            sm:setState("menu")
            sm:pushState("dialog", { message = "Hello" })

            assert.are.same({ message = "Hello" }, receivedParams)
        end)

        it("should grow stack correctly", function()
            sm:addState("a", {})
            sm:addState("b", {})
            sm:addState("c", {})

            sm:setState("a")
            assert.are.equal(1, #sm.stack)

            sm:pushState("b")
            assert.are.equal(2, #sm.stack)

            sm:pushState("c")
            assert.are.equal(3, #sm.stack)
        end)

        it("should not crash with unregistered state name", function()
            sm:addState("menu", {})
            sm:setState("menu")

            sm:pushState("nonexistent")

            assert.are.equal("menu", sm:getState())
            assert.are.equal(1, #sm.stack)
        end)
    end)

    describe("popState()", function()
        it("should remove state and call exit", function()
            local exitCalled = false
            sm:addState("menu", {})
            sm:addState("pause", {
                exit = function() exitCalled = true end
            })

            sm:setState("menu")
            sm:pushState("pause")
            sm:popState()

            assert.is_true(exitCalled)
            assert.are.equal("menu", sm:getState())
        end)

        it("should call resume of underlying state", function()
            local resumeCalled = false
            sm:addState("playing", {
                resume = function() resumeCalled = true end
            })
            sm:addState("pause", {})

            sm:setState("playing")
            sm:pushState("pause")
            sm:popState()

            assert.is_true(resumeCalled)
        end)

        it("should pass params to exit and resume", function()
            local exitParams, resumeParams
            sm:addState("playing", {
                resume = function(params) resumeParams = params end
            })
            sm:addState("pause", {
                exit = function(params) exitParams = params end
            })

            sm:setState("playing")
            sm:pushState("pause")
            sm:popState({ resumed = true })

            assert.are.same({ resumed = true }, exitParams)
            assert.are.same({ resumed = true }, resumeParams)
        end)

        it("should not crash on empty stack", function()
            -- Should not crash
            sm:popState()
            assert.is_nil(sm:getState())
        end)

        it("should return correct state after pop", function()
            sm:addState("a", {})
            sm:addState("b", {})
            sm:addState("c", {})

            sm:setState("a")
            sm:pushState("b")
            sm:pushState("c")

            assert.are.equal("c", sm:getState())
            sm:popState()
            assert.are.equal("b", sm:getState())
            sm:popState()
            assert.are.equal("a", sm:getState())
        end)
    end)

    describe("update()", function()
        it("should call update only on current state (top)", function()
            local aUpdated, bUpdated = false, false
            sm:addState("a", {
                update = function() aUpdated = true end
            })
            sm:addState("b", {
                update = function() bUpdated = true end
            })

            sm:setState("a")
            sm:pushState("b")
            sm:update(0.016)

            assert.is_false(aUpdated)
            assert.is_true(bUpdated)
        end)

        it("should not crash if state has no update", function()
            sm:addState("menu", {})
            sm:setState("menu")

            -- Should not crash
            sm:update(0.016)
        end)

        it("should not crash if stack is empty", function()
            -- Should not crash
            sm:update(0.016)
        end)
    end)

    describe("draw()", function()
        it("should call draw on all states in stack (bottom to top)", function()
            local drawOrder = {}
            sm:addState("a", {
                draw = function() table.insert(drawOrder, "a") end
            })
            sm:addState("b", {
                draw = function() table.insert(drawOrder, "b") end
            })
            sm:addState("c", {
                draw = function() table.insert(drawOrder, "c") end
            })

            sm:setState("a")
            sm:pushState("b")
            sm:pushState("c")
            sm:draw()

            assert.are.same({ "a", "b", "c" }, drawOrder)
        end)

        it("should not crash if state has no draw", function()
            sm:addState("menu", {})
            sm:setState("menu")

            -- Should not crash
            sm:draw()
        end)

        it("should not crash if stack is empty", function()
            -- Should not crash
            sm:draw()
        end)
    end)

    describe("integration", function()
        it("should handle complete flow: setState -> pushState -> popState", function()
            local sequence = {}

            sm:addState("playing", {
                enter = function() table.insert(sequence, "playing:enter") end,
                exit = function() table.insert(sequence, "playing:exit") end,
                pause = function() table.insert(sequence, "playing:pause") end,
                resume = function() table.insert(sequence, "playing:resume") end
            })
            sm:addState("pause", {
                enter = function() table.insert(sequence, "pause:enter") end,
                exit = function() table.insert(sequence, "pause:exit") end
            })

            sm:setState("playing")
            sm:pushState("pause")
            sm:popState()

            assert.are.same({
                "playing:enter",
                "playing:pause",
                "pause:enter",
                "pause:exit",
                "playing:resume"
            }, sequence)

            assert.are.equal("playing", sm:getState())
        end)
    end)
end)
