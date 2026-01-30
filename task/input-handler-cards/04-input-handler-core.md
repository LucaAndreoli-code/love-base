# Card 04: InputHandler Core

> Struttura base del sistema centrale di input.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_handler.lua`

## Descrizione

InputHandler è il sistema centrale che orchestra tutto. Questa card definisce la struttura base e il costruttore. Le card successive aggiungono i metodi.

## Struttura

```lua
---@class InputHandler
---@field contexts table<string, InputContext>      -- tutti i contesti registrati
---@field activeContexts table<string, boolean>     -- contesti attualmente attivi
---@field states table<string, InputState>          -- stato per ogni azione
---@field _rawInputs table<string, boolean>         -- input grezzi catturati da callback
---@field _activeGamepad love.Joystick|nil          -- gamepad attivo
---@field mouse InputHandlerMouse                   -- stato mouse
---@field settings InputHandlerSettings             -- configurazione

---@class InputHandlerMouse
---@field x number
---@field y number
---@field dx number                    -- delta dall'ultimo frame
---@field dy number
---@field scroll { x: number, y: number }
---@field drag { active: boolean, startX: number, startY: number, button: number|nil }

---@class InputHandlerSettings
---@field axisThreshold number         -- soglia default per axis (0.5)
---@field dragThreshold number         -- pixel minimi per iniziare drag (5)

local InputHandler = {}
InputHandler.__index = InputHandler
```

## Interfaccia Base

```lua
--- Crea nuovo InputHandler
---@param settings? InputHandlerSettings
---@return InputHandler
function InputHandler.new(settings)
    local self = setmetatable({}, InputHandler)
    
    self.contexts = {}
    self.activeContexts = {}
    self.states = {}
    self._rawInputs = {}
    self._activeGamepad = nil
    
    self.mouse = {
        x = 0,
        y = 0,
        dx = 0,
        dy = 0,
        scroll = { x = 0, y = 0 },
        drag = { active = false, startX = 0, startY = 0, button = nil },
    }
    
    self.settings = {
        axisThreshold = (settings and settings.axisThreshold) or 0.5,
        dragThreshold = (settings and settings.dragThreshold) or 5,
    }
    
    -- Detect gamepad on creation
    self:_detectGamepad()
    
    return self
end

--- Rileva gamepad connesso
---@private
function InputHandler:_detectGamepad()
    local joysticks = love.joystick.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isGamepad() then
            self._activeGamepad = joystick
            return
        end
    end
end

--- Callback per gamepad connesso (chiamare da love.joystickadded)
---@param joystick love.Joystick
function InputHandler:joystickAdded(joystick)
    if not self._activeGamepad and joystick:isGamepad() then
        self._activeGamepad = joystick
    end
end

--- Callback per gamepad disconnesso (chiamare da love.joystickremoved)
---@param joystick love.Joystick
function InputHandler:joystickRemoved(joystick)
    if self._activeGamepad == joystick then
        self._activeGamepad = nil
        self:_detectGamepad()  -- cerca un altro
    end
end

return InputHandler
```

## Storage degli Stati

Gli `InputState` vengono creati per ogni azione quando il contesto viene attivato:

```lua
-- Interno: crea stati per tutte le azioni di un contesto
function InputHandler:_createStatesForContext(contextName)
    local context = self.contexts[contextName]
    if not context then return end
    
    for actionName, _ in pairs(context:getActions()) do
        if not self.states[actionName] then
            self.states[actionName] = InputState.new()
        end
    end
end
```

## Raw Inputs

`_rawInputs` è una tabella che memorizza gli input "grezzi" catturati dai callback LÖVE:

```lua
_rawInputs = {
    ["key:space"] = true,      -- keyboard
    ["key:w"] = true,
    ["mouse:1"] = true,         -- mouse button
    ["mouse:wheel:up"] = true,  -- mouse wheel (one frame)
    ["pad:a"] = true,           -- gamepad button
    ["axis:leftx"] = 0.8,       -- gamepad axis (valore, non boolean)
}
```

Questa separazione permette di:
1. Catturare input nei callback (asincroni)
2. Processarli in `update()` (sincrono, una volta per frame)

## Note Implementative

- `activeContexts` è una table con chiavi boolean, non un array, per O(1) lookup
- Gli stati sono condivisi tra contesti: se "jump" esiste in più contesti, usa lo stesso `InputState`
- `_rawInputs` viene parzialmente pulito ogni frame (mouse wheel, etc.)

## Test Cases (Struttura)

```lua
describe("InputHandler Core", function()
    it("creates with default settings", function()
        local handler = InputHandler.new()
        assert.equals(0.5, handler.settings.axisThreshold)
        assert.equals(5, handler.settings.dragThreshold)
    end)
    
    it("creates with custom settings", function()
        local handler = InputHandler.new({ axisThreshold = 0.3 })
        assert.equals(0.3, handler.settings.axisThreshold)
    end)
    
    it("initializes mouse state", function()
        local handler = InputHandler.new()
        assert.equals(0, handler.mouse.x)
        assert.is_false(handler.mouse.drag.active)
    end)
    
    it("starts with no active contexts", function()
        local handler = InputHandler.new()
        assert.equals(0, #handler.activeContexts)
    end)
end)
```

## Dipendenze
- `InputState` (Card 02)
- `InputContext` (Card 03)
- `InputAction` (Card 01)

## Prossima Card
→ Card 05: InputHandler Context Management
