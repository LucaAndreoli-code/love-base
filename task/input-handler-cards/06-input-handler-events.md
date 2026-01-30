# Card 06: InputHandler Event Capture

> Metodi che catturano gli eventi LÖVE e li traducono in raw inputs.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_handler.lua` (estensione Card 04-05)

## Descrizione

Questi metodi vengono chiamati dai callback LÖVE in `main.lua`. Catturano gli input grezzi e li memorizzano in `_rawInputs` per essere processati in `update()`.

## Interfaccia

```lua
--- Keyboard
---@param key string
---@param scancode string
---@param isrepeat boolean
function InputHandler:keypressed(key, scancode, isrepeat)

---@param key string
---@param scancode string
function InputHandler:keyreleased(key, scancode)

--- Mouse buttons
---@param x number
---@param y number
---@param button number
---@param istouch boolean
function InputHandler:mousepressed(x, y, button, istouch)

---@param x number
---@param y number
---@param button number
---@param istouch boolean
function InputHandler:mousereleased(x, y, button, istouch)

--- Mouse movement
---@param x number
---@param y number
---@param dx number
---@param dy number
function InputHandler:mousemoved(x, y, dx, dy)

--- Mouse wheel
---@param x number
---@param y number
function InputHandler:wheelmoved(x, y)

--- Gamepad buttons
---@param joystick love.Joystick
---@param button string
function InputHandler:gamepadpressed(joystick, button)

---@param joystick love.Joystick
---@param button string
function InputHandler:gamepadreleased(joystick, button)

--- Gamepad axis (chiamato continuamente, non solo su cambio)
---@param joystick love.Joystick
---@param axis string
---@param value number
function InputHandler:gamepadaxis(joystick, axis, value)
```

## Implementazione

```lua
--------------------------------------------------
-- Keyboard
--------------------------------------------------

function InputHandler:keypressed(key, scancode, isrepeat)
    if isrepeat then return end  -- ignora auto-repeat
    self._rawInputs["key:" .. key] = true
end

function InputHandler:keyreleased(key, scancode)
    self._rawInputs["key:" .. key] = false
end

--------------------------------------------------
-- Mouse Buttons
--------------------------------------------------

function InputHandler:mousepressed(x, y, button, istouch)
    self._rawInputs["mouse:" .. button] = true
    
    -- Start drag tracking
    self.mouse.drag.button = button
    self.mouse.drag.startX = x
    self.mouse.drag.startY = y
    self.mouse.drag.active = false  -- diventa true quando supera threshold
end

function InputHandler:mousereleased(x, y, button, istouch)
    self._rawInputs["mouse:" .. button] = false
    
    -- End drag if it was this button
    if self.mouse.drag.button == button then
        self.mouse.drag.active = false
        self.mouse.drag.button = nil
    end
end

--------------------------------------------------
-- Mouse Movement
--------------------------------------------------

function InputHandler:mousemoved(x, y, dx, dy)
    self.mouse.x = x
    self.mouse.y = y
    self.mouse.dx = dx
    self.mouse.dy = dy
    
    -- Check drag threshold
    if self.mouse.drag.button and not self.mouse.drag.active then
        local distX = math.abs(x - self.mouse.drag.startX)
        local distY = math.abs(y - self.mouse.drag.startY)
        if distX > self.settings.dragThreshold or distY > self.settings.dragThreshold then
            self.mouse.drag.active = true
        end
    end
end

--------------------------------------------------
-- Mouse Wheel
--------------------------------------------------

function InputHandler:wheelmoved(x, y)
    self.mouse.scroll.x = x
    self.mouse.scroll.y = y
    
    -- Wheel come azione (per un frame)
    if y > 0 then
        self._rawInputs["mouse:wheel:up"] = true
    elseif y < 0 then
        self._rawInputs["mouse:wheel:down"] = true
    end
    if x > 0 then
        self._rawInputs["mouse:wheel:right"] = true
    elseif x < 0 then
        self._rawInputs["mouse:wheel:left"] = true
    end
end

--------------------------------------------------
-- Gamepad
--------------------------------------------------

function InputHandler:gamepadpressed(joystick, button)
    -- Solo il gamepad attivo
    if joystick ~= self._activeGamepad then return end
    self._rawInputs["pad:" .. button] = true
end

function InputHandler:gamepadreleased(joystick, button)
    if joystick ~= self._activeGamepad then return end
    self._rawInputs["pad:" .. button] = false
end

function InputHandler:gamepadaxis(joystick, axis, value)
    if joystick ~= self._activeGamepad then return end
    -- Memorizza il valore raw, verrà processato in update
    self._rawInputs["axis:" .. axis] = value
end
```

## Convenzione Chiavi Raw

| Input Type | Key Format | Esempio |
|------------|-----------|---------|
| Keyboard | `key:{key}` | `key:space`, `key:w` |
| Mouse button | `mouse:{button}` | `mouse:1`, `mouse:2` |
| Mouse wheel | `mouse:wheel:{dir}` | `mouse:wheel:up` |
| Gamepad button | `pad:{button}` | `pad:a`, `pad:start` |
| Gamepad axis | `axis:{axis}` | `axis:leftx`, `axis:lefty` |

## Note su Mouse Wheel

Il mouse wheel in LÖVE è un evento, non uno stato. Viene triggerato una volta per "tick" della rotellina. Per trattarlo come azione:

1. Nel callback, settiamo `_rawInputs["mouse:wheel:up"] = true`
2. In `update()`, processiamo come un'azione normale
3. In `lateUpdate()`, resettiamo a `false`

Questo significa che `isPressed("scroll_up")` è true per UN FRAME quando scrolli.

## Note su Drag

Il drag tracking funziona così:
1. `mousepressed` salva posizione iniziale
2. `mousemoved` controlla se abbiamo superato `dragThreshold`
3. Se sì, `drag.active = true`
4. `mousereleased` resetta tutto

Il gameplay code può usare:
```lua
if inputHandler:isDragging() then
    local dx, dy = inputHandler:getDragDelta()
end
```

## Integration in main.lua

```lua
local Game = require("src.init")
local input

function love.load()
    input = Game.systems.inputHandler.new()
    -- setup contexts...
end

function love.keypressed(key, scancode, isrepeat)
    input:keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    input:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
    input:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    input:mousereleased(x, y, button, istouch)
end

function love.mousemoved(x, y, dx, dy)
    input:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    input:wheelmoved(x, y)
end

function love.gamepadpressed(joystick, button)
    input:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    input:gamepadreleased(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    input:gamepadaxis(joystick, axis, value)
end

function love.joystickadded(joystick)
    input:joystickAdded(joystick)
end

function love.joystickremoved(joystick)
    input:joystickRemoved(joystick)
end
```

## Test Cases

I test per gli eventi sono principalmente integration test perché richiedono di simulare la sequenza callback → update → query. Vedi Card 11 per test completi.

```lua
describe("InputHandler Events", function()
    it("captures keyboard press", function()
        local handler = InputHandler.new()
        handler:keypressed("space", "space", false)
        assert.is_true(handler._rawInputs["key:space"])
    end)
    
    it("ignores keyboard repeat", function()
        local handler = InputHandler.new()
        handler:keypressed("space", "space", true)  -- isrepeat = true
        assert.is_nil(handler._rawInputs["key:space"])
    end)
    
    it("captures mouse position", function()
        local handler = InputHandler.new()
        handler:mousemoved(100, 200, 5, 10)
        assert.equals(100, handler.mouse.x)
        assert.equals(200, handler.mouse.y)
    end)
    
    it("tracks drag start", function()
        local handler = InputHandler.new()
        handler:mousepressed(50, 50, 1, false)
        assert.equals(50, handler.mouse.drag.startX)
        assert.is_false(handler.mouse.drag.active)
    end)
    
    it("activates drag after threshold", function()
        local handler = InputHandler.new()
        handler.settings.dragThreshold = 5
        handler:mousepressed(50, 50, 1, false)
        handler:mousemoved(60, 50, 10, 0)  -- moved 10px, > threshold
        assert.is_true(handler.mouse.drag.active)
    end)
end)
```

## Dipendenze
- Card 04: InputHandler Core
- Card 05: Context Management

## Prossima Card
→ Card 07: InputHandler Query API
