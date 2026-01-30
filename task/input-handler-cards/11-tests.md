# Card 11: Tests

> Test suite completa per il sistema Input Handler.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## Files
- `spec/input_action_spec.lua`
- `spec/input_state_spec.lua`
- `spec/input_context_spec.lua`
- `spec/input_handler_spec.lua`

## Struttura Test

Ogni modulo ha il proprio file spec. I test sono organizzati per funzionalità.

---

## `spec/input_action_spec.lua`

```lua
local InputAction = require("src.systems.input_action")

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
```

---

## `spec/input_state_spec.lua`

```lua
local InputState = require("src.systems.input_state")

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
            
            state:update(true, 0.016)  -- press
            state:update(true, 0.016)  -- hold
            
            assert.is_false(state.pressed)
            assert.is_true(state.down)
        end)
        
        it("detects release", function()
            local state = InputState.new()
            
            state:update(true, 0.016)   -- press
            state:update(false, 0.016)  -- release
            
            assert.is_false(state.down)
            assert.is_false(state.pressed)
            assert.is_true(state.released)
        end)
        
        it("clears released after frame", function()
            local state = InputState.new()
            
            state:update(true, 0.016)   -- press
            state:update(false, 0.016)  -- release
            state:update(false, 0.016)  -- idle
            
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
```

---

## `spec/input_context_spec.lua`

```lua
local InputContext = require("src.systems.input_context")
local InputAction = require("src.systems.input_action")

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
```

---

## `spec/input_handler_spec.lua`

```lua
local InputHandler = require("src.systems.input_handler")
local InputContext = require("src.systems.input_context")
local InputAction = require("src.systems.input_action")

describe("InputHandler", function()
    
    -- Helper: crea handler con contesto test
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
            
            -- shoot ha sia keyboard che mouse
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
            handler:mousemoved(60, 50, 10, 0)  -- > threshold
            
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
```

---

## Running Tests

```bash
# Run all input tests
busted spec/input_*_spec.lua

# Run single file
busted spec/input_handler_spec.lua

# Run with verbose output
busted spec/input_handler_spec.lua --verbose
```

## Dipendenze
- Tutte le Card implementative (01-10)
- busted framework

## Prossima Card
→ Card 12: Documentation
