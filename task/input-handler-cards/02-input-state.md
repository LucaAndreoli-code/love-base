# Card 02: InputState

> Traccia lo stato di un input frame per frame (pressed/held/released).

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_state.lua`

## Descrizione

InputState gestisce la transizione di stato per un singolo input. Permette di distinguere tra:
- **pressed**: primo frame in cui l'input è attivo
- **down**: input attualmente attivo (include pressed)
- **released**: primo frame in cui l'input non è più attivo

## Diagramma Stati

```
        press event
IDLE ──────────────────► PRESSED
  ▲                          │
  │                          │ next frame
  │                          ▼
  │     release event     HELD ◄─────┐
  └──────────────────── RELEASED     │ still down
                            │        │
                            └────────┘
```

## Interfaccia

```lua
---@class InputState
---@field down boolean           -- attualmente premuto
---@field pressed boolean        -- just pressed (solo questo frame)
---@field released boolean       -- just released (solo questo frame)
---@field downDuration number    -- secondi tenuto premuto
---@field _wasDown boolean       -- stato frame precedente (interno)

local InputState = {}
InputState.__index = InputState

--- Crea nuovo stato
---@return InputState
function InputState.new()

--- Aggiorna lo stato basandosi sull'input corrente
---@param isCurrentlyDown boolean  -- l'input è premuto ora?
---@param dt number                -- delta time
function InputState:update(isCurrentlyDown, dt)

--- Reset flags a fine frame (chiamato da InputHandler:lateUpdate)
function InputState:reset()

--- Reset completo (per context switch o altro)
function InputState:clear()

return InputState
```

## Logica Update

```lua
function InputState:update(isCurrentlyDown, dt)
    -- Detect transitions
    self.pressed = isCurrentlyDown and not self._wasDown
    self.released = not isCurrentlyDown and self._wasDown
    
    -- Update down state
    self.down = isCurrentlyDown
    
    -- Track duration
    if self.down then
        self.downDuration = self.downDuration + dt
    else
        self.downDuration = 0
    end
    
    -- Store for next frame
    self._wasDown = isCurrentlyDown
end

function InputState:reset()
    -- NON resettare pressed/released qui!
    -- Vengono resettati naturalmente al prossimo update()
    -- Questo metodo esiste per casi speciali se necessario
end

function InputState:clear()
    self.down = false
    self.pressed = false
    self.released = false
    self.downDuration = 0
    self._wasDown = false
end
```

## Esempio Uso

```lua
local InputState = require("src.systems.input_state")

local jumpState = InputState.new()

-- In update loop
function love.update(dt)
    local spaceDown = love.keyboard.isDown("space")
    jumpState:update(spaceDown, dt)
    
    if jumpState.pressed then
        player:jump()  -- solo primo frame
    end
    
    if jumpState.down then
        -- charging jump?
        chargeAmount = jumpState.downDuration
    end
    
    if jumpState.released then
        player:releaseJump(chargeAmount)
    end
end
```

## Note Implementative

- `pressed` e `released` sono true per UN SOLO FRAME
- `_wasDown` è interno, non deve essere usato dall'esterno
- `downDuration` resetta immediatamente quando rilasci
- `clear()` utile quando cambi contesto e vuoi pulire tutto

## Edge Cases

1. **Input molto veloce**: se premi e rilasci nello stesso frame (impossibile in pratica), sia `pressed` che `released` sarebbero true. Va bene così.

2. **Frame skip**: se il gioco lagga e salta frame, l'input viene comunque catturato dai callback LÖVE, quindi nessuna perdita.

3. **Focus perso**: se la finestra perde focus, LÖVE genera `keyreleased` automaticamente.

## Test Cases

```lua
describe("InputState", function()
    it("starts in idle state", function()
        local state = InputState.new()
        assert.is_false(state.down)
        assert.is_false(state.pressed)
        assert.is_false(state.released)
        assert.equals(0, state.downDuration)
    end)
    
    it("detects pressed on first down frame", function()
        local state = InputState.new()
        state:update(true, 0.016)
        assert.is_true(state.pressed)
        assert.is_true(state.down)
        assert.is_false(state.released)
    end)
    
    it("clears pressed on subsequent frames", function()
        local state = InputState.new()
        state:update(true, 0.016)  -- press
        state:update(true, 0.016)  -- hold
        assert.is_false(state.pressed)
        assert.is_true(state.down)
    end)
    
    it("detects released", function()
        local state = InputState.new()
        state:update(true, 0.016)   -- press
        state:update(false, 0.016)  -- release
        assert.is_false(state.down)
        assert.is_true(state.released)
    end)
    
    it("tracks down duration", function()
        local state = InputState.new()
        state:update(true, 0.1)
        state:update(true, 0.1)
        state:update(true, 0.1)
        assert.near(0.3, state.downDuration, 0.001)
    end)
    
    it("resets duration on release", function()
        local state = InputState.new()
        state:update(true, 0.1)
        state:update(false, 0.1)
        assert.equals(0, state.downDuration)
    end)
    
    it("clears all state", function()
        local state = InputState.new()
        state:update(true, 0.1)
        state:clear()
        assert.is_false(state.down)
        assert.is_false(state.pressed)
        assert.equals(0, state.downDuration)
    end)
end)
```

## Dipendenze
- Nessuna

## Prossima Card
→ Card 03: InputContext
