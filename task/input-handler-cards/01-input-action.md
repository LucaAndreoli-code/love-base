# Card 01: InputAction

> Struttura dati per una singola azione mappabile.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_action.lua`

## Descrizione

InputAction rappresenta un'azione di gioco (es: "jump", "shoot") con i suoi binding per ogni tipo di input. È una struttura dati pura, senza logica di stato.

## Interfaccia

```lua
---@class InputAction
---@field name string                    -- identificatore unico ("jump", "shoot")
---@field keyboard string|nil            -- tasto keyboard ("space", "w", "escape")
---@field mouse number|nil               -- bottone mouse (1=left, 2=right, 3=middle)
---@field mouseWheel string|nil          -- "up" | "down" | nil
---@field gamepadButton string|nil       -- bottone gamepad ("a", "b", "start", "rightshoulder")
---@field gamepadAxis string|nil         -- asse gamepad ("leftx", "lefty", "rightx", "righty")
---@field axisDirection number|nil       -- direzione asse: -1 o 1 (per trasformare axis in pressed)
---@field axisThreshold number           -- soglia per axis→pressed (default 0.5)

local InputAction = {}
InputAction.__index = InputAction

--- Crea nuova azione
---@param config table
---@return InputAction
function InputAction.new(config)

--- Clona l'azione (per rebinding senza mutare originale)
---@return InputAction
function InputAction:clone()

--- Verifica se l'azione ha almeno un binding valido
---@return boolean
function InputAction:hasBinding()

--- Ritorna una rappresentazione serializzabile (per save/load)
---@return table
function InputAction:serialize()

--- Crea InputAction da dati serializzati
---@param data table
---@return InputAction
function InputAction.deserialize(data)

return InputAction
```

## Esempio Uso

```lua
local InputAction = require("src.systems.input_action")

local jumpAction = InputAction.new({
    name = "jump",
    keyboard = "space",
    gamepadButton = "a",
})

local moveLeft = InputAction.new({
    name = "move_left",
    keyboard = "a",
    gamepadAxis = "leftx",
    axisDirection = -1,
    axisThreshold = 0.3,
})

-- Per rebinding
local backup = jumpAction:clone()
jumpAction.keyboard = "w"  -- nuovo binding
```

## Campi Opzionali

Tutti i campi tranne `name` sono opzionali. Un'azione può avere:
- Solo keyboard
- Solo mouse
- Solo gamepad
- Qualsiasi combinazione

## Note Implementative

- `axisThreshold` default a 0.5 se non specificato
- `axisDirection` necessario solo per azioni che usano `gamepadAxis`
- `clone()` deve fare deep copy per evitare reference condivise
- `serialize/deserialize` per futuro save/load dei rebinding

## Test Cases

```lua
describe("InputAction", function()
    it("creates action with keyboard binding", function()
        local action = InputAction.new({ name = "test", keyboard = "space" })
        assert.equals("test", action.name)
        assert.equals("space", action.keyboard)
    end)
    
    it("clones without sharing references", function()
        local original = InputAction.new({ name = "test", keyboard = "a" })
        local cloned = original:clone()
        cloned.keyboard = "b"
        assert.equals("a", original.keyboard)
    end)
    
    it("reports hasBinding correctly", function()
        local empty = InputAction.new({ name = "empty" })
        local withKey = InputAction.new({ name = "key", keyboard = "x" })
        assert.is_false(empty:hasBinding())
        assert.is_true(withKey:hasBinding())
    end)
    
    it("serializes and deserializes", function()
        local original = InputAction.new({ name = "test", keyboard = "q", axisThreshold = 0.7 })
        local data = original:serialize()
        local restored = InputAction.deserialize(data)
        assert.equals(original.name, restored.name)
        assert.equals(original.axisThreshold, restored.axisThreshold)
    end)
end)
```

## Dipendenze
- Nessuna

## Prossima Card
→ Card 02: InputState
