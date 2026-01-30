# Card 03: InputContext

> Raggruppa un set di azioni che sono attive insieme.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_context.lua`

## Descrizione

InputContext raggruppa azioni correlate che devono essere attive nello stesso momento. Permette di separare logicamente gli input per stato di gioco.

**Esempi di contesti:**
- `gameplay`: move, jump, shoot, pause
- `menu`: confirm, cancel, navigate
- `pause`: unpause, quit_to_menu
- `dialogue`: advance, skip

## Interfaccia

```lua
---@class InputContext
---@field name string
---@field actions table<string, InputAction>  -- actionName → InputAction

local InputContext = {}
InputContext.__index = InputContext

--- Crea nuovo contesto
---@param name string
---@return InputContext
function InputContext.new(name)

--- Aggiunge un'azione al contesto
---@param action InputAction
function InputContext:addAction(action)

--- Rimuove un'azione dal contesto
---@param actionName string
---@return boolean  -- true se rimossa
function InputContext:removeAction(actionName)

--- Verifica se il contesto contiene un'azione
---@param actionName string
---@return boolean
function InputContext:hasAction(actionName)

--- Ottiene un'azione per nome
---@param actionName string
---@return InputAction|nil
function InputContext:getAction(actionName)

--- Ottiene tutte le azioni
---@return table<string, InputAction>
function InputContext:getActions()

--- Conta le azioni nel contesto
---@return number
function InputContext:count()

return InputContext
```

## Esempio Uso

```lua
local InputContext = require("src.systems.input_context")
local InputAction = require("src.systems.input_action")

-- Crea contesto gameplay
local gameplay = InputContext.new("gameplay")

gameplay:addAction(InputAction.new({
    name = "jump",
    keyboard = "space",
    gamepadButton = "a",
}))

gameplay:addAction(InputAction.new({
    name = "shoot",
    keyboard = "x",
    mouse = 1,
    gamepadButton = "rightshoulder",
}))

gameplay:addAction(InputAction.new({
    name = "pause",
    keyboard = "escape",
    gamepadButton = "start",
}))

-- Crea contesto menu
local menu = InputContext.new("menu")

menu:addAction(InputAction.new({
    name = "confirm",
    keyboard = "return",
    gamepadButton = "a",
}))

menu:addAction(InputAction.new({
    name = "cancel",
    keyboard = "escape",
    gamepadButton = "b",
}))

-- Query
if gameplay:hasAction("jump") then
    local jumpAction = gameplay:getAction("jump")
end
```

## Comportamento Azioni Condivise

La stessa azione può esistere in più contesti con binding diversi:

```lua
-- In gameplay: "confirm" non esiste
-- In menu: "confirm" usa return/A
-- In dialogue: "confirm" usa space/A (diverso da menu!)

local menuConfirm = InputAction.new({
    name = "confirm",
    keyboard = "return",
    gamepadButton = "a",
})

local dialogueConfirm = InputAction.new({
    name = "confirm",
    keyboard = "space",  -- diverso!
    gamepadButton = "a",
})

menuContext:addAction(menuConfirm)
dialogueContext:addAction(dialogueConfirm)
```

Quando il contesto cambia, cambia anche quale binding è attivo per quell'azione.

## Note Implementative

- `actions` è una table indexed by name per O(1) lookup
- `addAction` sovrascrive se l'azione esiste già (utile per rebinding)
- Il contesto non gestisce stato (pressed/down/etc), solo struttura

## Test Cases

```lua
describe("InputContext", function()
    local InputAction = require("src.systems.input_action")
    
    it("creates empty context", function()
        local ctx = InputContext.new("test")
        assert.equals("test", ctx.name)
        assert.equals(0, ctx:count())
    end)
    
    it("adds and retrieves actions", function()
        local ctx = InputContext.new("test")
        local action = InputAction.new({ name = "jump", keyboard = "space" })
        
        ctx:addAction(action)
        
        assert.is_true(ctx:hasAction("jump"))
        assert.equals(action, ctx:getAction("jump"))
        assert.equals(1, ctx:count())
    end)
    
    it("removes actions", function()
        local ctx = InputContext.new("test")
        ctx:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
        
        local removed = ctx:removeAction("jump")
        
        assert.is_true(removed)
        assert.is_false(ctx:hasAction("jump"))
        assert.equals(0, ctx:count())
    end)
    
    it("returns false when removing non-existent action", function()
        local ctx = InputContext.new("test")
        assert.is_false(ctx:removeAction("nonexistent"))
    end)
    
    it("overwrites action with same name", function()
        local ctx = InputContext.new("test")
        ctx:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
        ctx:addAction(InputAction.new({ name = "jump", keyboard = "w" }))
        
        assert.equals("w", ctx:getAction("jump").keyboard)
        assert.equals(1, ctx:count())
    end)
    
    it("returns nil for non-existent action", function()
        local ctx = InputContext.new("test")
        assert.is_nil(ctx:getAction("nonexistent"))
    end)
    
    it("returns all actions", function()
        local ctx = InputContext.new("test")
        ctx:addAction(InputAction.new({ name = "a", keyboard = "a" }))
        ctx:addAction(InputAction.new({ name = "b", keyboard = "b" }))
        
        local actions = ctx:getActions()
        assert.is_not_nil(actions.a)
        assert.is_not_nil(actions.b)
    end)
end)
```

## Dipendenze
- `InputAction` (Card 01)

## Prossima Card
→ Card 04: InputHandler Core
