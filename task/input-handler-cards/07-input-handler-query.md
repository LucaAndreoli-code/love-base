# Card 07: InputHandler Query API

> Update loop e API di query per il gameplay code.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/systems/input_handler/input_handler.lua` (estensione Card 04-06)

## Descrizione

Il cuore del sistema: `update()` processa i raw inputs e aggiorna gli stati, poi l'API di query permette al gameplay di controllare lo stato delle azioni.

## Interfaccia

```lua
--------------------------------------------------
-- Update Methods
--------------------------------------------------

--- Chiamato ogni frame in love.update(dt)
---@param dt number
function InputHandler:update(dt)

--- Chiamato a fine frame per reset (opzionale, vedi note)
function InputHandler:lateUpdate()

--------------------------------------------------
-- Action Query
--------------------------------------------------

--- L'azione è premuta (include primo frame)
---@param actionName string
---@return boolean
function InputHandler:isDown(actionName)

--- L'azione è stata appena premuta (solo primo frame)
---@param actionName string
---@return boolean
function InputHandler:isPressed(actionName)

--- L'azione è stata appena rilasciata (solo primo frame)
---@param actionName string
---@return boolean
function InputHandler:isReleased(actionName)

--- Quanto tempo l'azione è stata tenuta premuta
---@param actionName string
---@return number  -- secondi, 0 se non premuta
function InputHandler:getHoldDuration(actionName)

--------------------------------------------------
-- Axis Query (per movimento analogico)
--------------------------------------------------

--- Valore asse per un'azione axis-based
---@param actionName string
---@return number  -- -1 to 1, 0 se non trovato
function InputHandler:getAxis(actionName)

--------------------------------------------------
-- Mouse Query
--------------------------------------------------

---@return number, number  -- x, y
function InputHandler:getMousePosition()

---@return number, number  -- scroll x, y (questo frame)
function InputHandler:getMouseScroll()

---@return boolean
function InputHandler:isDragging()

---@return number, number  -- dx, dy da inizio drag
function InputHandler:getDragDelta()

---@return number, number  -- start x, y del drag
function InputHandler:getDragStart()

---@return number, number  -- delta movimento questo frame
function InputHandler:getMouseDelta()
```

## Implementazione Update

```lua
function InputHandler:update(dt)
    -- Aggiorna posizione mouse (anche senza movimento)
    self.mouse.x, self.mouse.y = love.mouse.getPosition()
    
    -- Processa ogni azione nei contesti attivi
    for contextName, active in pairs(self.activeContexts) do
        if active then
            local context = self.contexts[contextName]
            if context then
                for actionName, action in pairs(context:getActions()) do
                    local isDown = self:_isActionDown(action)
                    
                    -- Crea stato se non esiste
                    if not self.states[actionName] then
                        self.states[actionName] = InputState.new()
                    end
                    
                    self.states[actionName]:update(isDown, dt)
                end
            end
        end
    end
end

--- Controlla se un'azione è attualmente down basandosi sui raw inputs
---@private
---@param action InputAction
---@return boolean
function InputHandler:_isActionDown(action)
    -- Keyboard
    if action.keyboard then
        if self._rawInputs["key:" .. action.keyboard] then
            return true
        end
    end
    
    -- Mouse button
    if action.mouse then
        if self._rawInputs["mouse:" .. action.mouse] then
            return true
        end
    end
    
    -- Mouse wheel (trattato come press istantaneo)
    if action.mouseWheel then
        if self._rawInputs["mouse:wheel:" .. action.mouseWheel] then
            return true
        end
    end
    
    -- Gamepad button
    if action.gamepadButton then
        if self._rawInputs["pad:" .. action.gamepadButton] then
            return true
        end
    end
    
    -- Gamepad axis (con threshold e direzione)
    if action.gamepadAxis then
        local axisValue = self._rawInputs["axis:" .. action.gamepadAxis] or 0
        local threshold = action.axisThreshold or self.settings.axisThreshold
        local direction = action.axisDirection or 1
        
        if direction > 0 then
            return axisValue > threshold
        else
            return axisValue < -threshold
        end
    end
    
    return false
end

function InputHandler:lateUpdate()
    -- Reset mouse delta (accumulato durante frame)
    self.mouse.dx = 0
    self.mouse.dy = 0
    
    -- Reset scroll (è un evento one-shot)
    self.mouse.scroll.x = 0
    self.mouse.scroll.y = 0
    
    -- Reset wheel raw inputs
    self._rawInputs["mouse:wheel:up"] = nil
    self._rawInputs["mouse:wheel:down"] = nil
    self._rawInputs["mouse:wheel:left"] = nil
    self._rawInputs["mouse:wheel:right"] = nil
end
```

## Implementazione Query

```lua
--------------------------------------------------
-- Action Query
--------------------------------------------------

function InputHandler:isDown(actionName)
    local state = self.states[actionName]
    return state and state.down or false
end

function InputHandler:isPressed(actionName)
    local state = self.states[actionName]
    return state and state.pressed or false
end

function InputHandler:isReleased(actionName)
    local state = self.states[actionName]
    return state and state.released or false
end

function InputHandler:getHoldDuration(actionName)
    local state = self.states[actionName]
    return state and state.downDuration or 0
end

--------------------------------------------------
-- Axis Query
--------------------------------------------------

function InputHandler:getAxis(actionName)
    -- Cerca l'azione nei contesti attivi
    for contextName, active in pairs(self.activeContexts) do
        if active then
            local context = self.contexts[contextName]
            if context then
                local action = context:getAction(actionName)
                if action and action.gamepadAxis then
                    return self._rawInputs["axis:" .. action.gamepadAxis] or 0
                end
            end
        end
    end
    return 0
end

--------------------------------------------------
-- Mouse Query
--------------------------------------------------

function InputHandler:getMousePosition()
    return self.mouse.x, self.mouse.y
end

function InputHandler:getMouseScroll()
    return self.mouse.scroll.x, self.mouse.scroll.y
end

function InputHandler:isDragging()
    return self.mouse.drag.active
end

function InputHandler:getDragDelta()
    if not self.mouse.drag.active then
        return 0, 0
    end
    return self.mouse.x - self.mouse.drag.startX, 
           self.mouse.y - self.mouse.drag.startY
end

function InputHandler:getDragStart()
    return self.mouse.drag.startX, self.mouse.drag.startY
end

function InputHandler:getMouseDelta()
    return self.mouse.dx, self.mouse.dy
end
```

## Note su lateUpdate

`lateUpdate()` è opzionale ma consigliato. Pulisce:
- Mouse delta (altrimenti accumula)
- Mouse scroll (evento one-shot)
- Wheel raw inputs

**Quando chiamarlo**: a fine `love.update()` o inizio del prossimo frame.

```lua
function love.update(dt)
    input:update(dt)
    
    -- game logic...
    
    input:lateUpdate()  -- pulizia fine frame
end
```

## Azioni Non in Contesto Attivo

Se chiedi `isPressed("jump")` ma nessun contesto attivo ha "jump":
- Ritorna `false`
- Nessun errore, nessun warning

Questo è intenzionale: permette al gameplay code di essere più semplice.

## Esempio Uso Completo

```lua
function love.update(dt)
    input:update(dt)
    
    -- Movimento (digital da keyboard o analogico da gamepad)
    local moveX = 0
    if input:isDown("move_left") then moveX = -1 end
    if input:isDown("move_right") then moveX = 1 end
    
    -- Override con analogico se presente
    local axisX = input:getAxis("move_horizontal")
    if math.abs(axisX) > 0.1 then
        moveX = axisX
    end
    
    player.x = player.x + moveX * speed * dt
    
    -- Salto (solo su press)
    if input:isPressed("jump") then
        player:jump()
    end
    
    -- Charged shot
    if input:isDown("shoot") then
        chargeAmount = input:getHoldDuration("shoot")
        ui:showChargeBar(chargeAmount)
    end
    if input:isReleased("shoot") then
        player:shootCharged(chargeAmount)
    end
    
    -- Mouse aiming
    local mx, my = input:getMousePosition()
    player:aimAt(mx, my)
    
    -- Camera drag
    if input:isDragging() then
        local dx, dy = input:getDragDelta()
        camera:pan(dx, dy)
    end
    
    input:lateUpdate()
end
```

## Test Cases

```lua
describe("InputHandler Query", function()
    local function setupHandler()
        local handler = InputHandler.new()
        
        local ctx = InputContext.new("test")
        ctx:addAction(InputAction.new({ name = "jump", keyboard = "space" }))
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
    
    it("returns false for inactive action", function()
        local handler = setupHandler()
        handler:update(0.016)
        assert.is_false(handler:isDown("jump"))
    end)
    
    it("returns true when key pressed", function()
        local handler = setupHandler()
        handler:keypressed("space", "space", false)
        handler:update(0.016)
        assert.is_true(handler:isDown("jump"))
        assert.is_true(handler:isPressed("jump"))
    end)
    
    it("pressed is true only first frame", function()
        local handler = setupHandler()
        handler:keypressed("space", "space", false)
        handler:update(0.016)
        assert.is_true(handler:isPressed("jump"))
        
        handler:update(0.016)  -- secondo frame, ancora down
        assert.is_true(handler:isDown("jump"))
        assert.is_false(handler:isPressed("jump"))  -- non più pressed
    end)
    
    it("detects release", function()
        local handler = setupHandler()
        handler:keypressed("space", "space", false)
        handler:update(0.016)
        handler:keyreleased("space", "space")
        handler:update(0.016)
        
        assert.is_false(handler:isDown("jump"))
        assert.is_true(handler:isReleased("jump"))
    end)
    
    it("tracks hold duration", function()
        local handler = setupHandler()
        handler:keypressed("space", "space", false)
        handler:update(0.1)
        handler:update(0.1)
        handler:update(0.1)
        
        assert.near(0.3, handler:getHoldDuration("jump"), 0.001)
    end)
    
    it("returns false for action not in active context", function()
        local handler = setupHandler()
        handler:keypressed("space", "space", false)
        handler:clearContexts()  -- no active context
        handler:update(0.016)
        
        assert.is_false(handler:isDown("jump"))
    end)
    
    it("returns axis value", function()
        local handler = setupHandler()
        handler:gamepadaxis(handler._activeGamepad, "leftx", 0.8)
        handler:update(0.016)
        
        assert.near(0.8, handler:getAxis("move_right"), 0.01)
    end)
end)
```

## Dipendenze
- Card 04: InputHandler Core
- Card 05: Context Management
- Card 06: Event Capture
- Card 02: InputState

## Prossima Card
→ Card 08: InputHandler Rebinding
