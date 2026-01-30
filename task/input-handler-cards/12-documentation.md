# Card 12: Documentation

> Documentazione completa del sistema Input Handler.

## Stato
- [ ] Implementazione
- [ ] Review

## File
`docs/input_handler.md`

## Contenuto

```markdown
# Input Handler System

Sistema unificato per gestire input da keyboard, mouse e gamepad con supporto per action mapping, context switching e rebinding.

## Quick Start

```lua
local Game = require("src.init")

-- Crea handler
local input = Game.systems.inputHandler.new()

-- Setup da defaults
Game.systems.inputHandler.setupFromDefaults(input, Game.constants.inputDefaults)

-- Imposta contesto
input:setContext("gameplay")

-- In update
function love.update(dt)
    input:update(dt)
    
    if input:isPressed("jump") then
        player:jump()
    end
    
    if input:isDown("shoot") then
        player:charge()
    end
    
    input:lateUpdate()
end
```

## Concetti Chiave

### Actions

Un'azione è un'astrazione sopra gli input fisici:

```lua
-- Definizione
local jumpAction = InputAction.new({
    name = "jump",
    keyboard = "space",      -- tasto keyboard
    gamepadButton = "a",     -- bottone gamepad
})

-- Uso
if input:isPressed("jump") then  -- funziona con space O gamepad A
```

### Contexts

I contesti raggruppano azioni che sono attive insieme:

```lua
-- Gameplay: movimento, azioni, pausa
local gameplay = InputContext.new("gameplay")
gameplay:addAction(jumpAction)
gameplay:addAction(shootAction)
gameplay:addAction(pauseAction)

-- Menu: navigazione, conferma
local menu = InputContext.new("menu")
menu:addAction(confirmAction)
menu:addAction(cancelAction)
```

### Context Switching

```lua
-- Switch esclusivo (menu → gameplay)
input:setContext("gameplay")

-- Layering (gameplay + pause overlay)
input:pushContext("pause")
input:popContext("pause")
```

## API Reference

### InputHandler

#### Creazione

```lua
InputHandler.new(settings?) → InputHandler

-- Settings opzionali:
{
    axisThreshold = 0.5,   -- soglia per axis → boolean
    dragThreshold = 5,     -- pixel per iniziare drag
}
```

#### Context Management

```lua
handler:addContext(context)           -- registra contesto
handler:removeContext(name)           -- rimuove contesto
handler:getContext(name) → context    -- ottiene contesto

handler:setContext(name)              -- attiva SOLO questo
handler:pushContext(name)             -- aggiunge al set attivo
handler:popContext(name)              -- rimuove dal set attivo
handler:isContextActive(name) → bool
handler:getActiveContexts() → string[]
handler:clearContexts()
```

#### Update Loop

```lua
handler:update(dt)      -- chiamare in love.update, PRIMA della game logic
handler:lateUpdate()    -- chiamare a FINE love.update
```

#### Action Query

```lua
handler:isDown(actionName) → bool      -- premuto ora (include primo frame)
handler:isPressed(actionName) → bool   -- appena premuto (solo primo frame)
handler:isReleased(actionName) → bool  -- appena rilasciato (solo primo frame)
handler:getHoldDuration(actionName) → number  -- secondi tenuto premuto
```

#### Axis Query

```lua
handler:getAxis(actionName) → number  -- -1 to 1, per movement analogico
```

#### Mouse Query

```lua
handler:getMousePosition() → x, y
handler:getMouseDelta() → dx, dy
handler:getMouseScroll() → x, y

handler:isDragging() → bool
handler:getDragStart() → x, y
handler:getDragDelta() → dx, dy
```

#### Rebinding

```lua
-- Direct
handler:setBinding(actionName, inputType, value) → success
handler:getBinding(actionName, inputType) → value

-- Interactive
handler:startRebind(actionName, inputType, callback?)
handler:cancelRebind()
handler:isRebinding() → bool

-- Reset
handler:resetBinding(actionName)
handler:resetAllBindings()

-- Serialization
handler:exportBindings() → table
handler:importBindings(data)
handler:saveAsDefault()
```

### InputAction

```lua
InputAction.new(config) → InputAction
action:clone() → InputAction
action:hasBinding() → bool
action:serialize() → table
InputAction.deserialize(data) → InputAction

-- Config fields:
{
    name = "jump",           -- required
    keyboard = "space",      -- optional
    mouse = 1,               -- optional (1=left, 2=right, 3=middle)
    mouseWheel = "up",       -- optional ("up", "down", "left", "right")
    gamepadButton = "a",     -- optional
    gamepadAxis = "leftx",   -- optional
    axisDirection = 1,       -- optional (-1 or 1)
    axisThreshold = 0.5,     -- optional
}
```

### InputContext

```lua
InputContext.new(name) → InputContext
context:addAction(action)
context:removeAction(actionName) → bool
context:hasAction(actionName) → bool
context:getAction(actionName) → action
context:getActions() → table
context:count() → number
```

### InputState

```lua
InputState.new() → InputState
state:update(isCurrentlyDown, dt)
state:clear()

-- Fields:
state.down          -- bool: premuto ora
state.pressed       -- bool: appena premuto
state.released      -- bool: appena rilasciato  
state.downDuration  -- number: secondi premuto
```

## Patterns Comuni

### Movimento 8 direzioni

```lua
local moveX, moveY = 0, 0

if input:isDown("move_left") then moveX = moveX - 1 end
if input:isDown("move_right") then moveX = moveX + 1 end
if input:isDown("move_up") then moveY = moveY - 1 end
if input:isDown("move_down") then moveY = moveY + 1 end

-- Normalizza diagonale
if moveX ~= 0 and moveY ~= 0 then
    local len = math.sqrt(moveX*moveX + moveY*moveY)
    moveX, moveY = moveX/len, moveY/len
end

player.x = player.x + moveX * speed * dt
player.y = player.y + moveY * speed * dt
```

### Movimento Analogico con Fallback Digitale

```lua
local moveX = input:getAxis("move_horizontal")
local moveY = input:getAxis("move_vertical")

-- Se nessun input analogico, usa digitale
if math.abs(moveX) < 0.1 and math.abs(moveY) < 0.1 then
    if input:isDown("move_left") then moveX = -1 end
    if input:isDown("move_right") then moveX = 1 end
    if input:isDown("move_up") then moveY = -1 end
    if input:isDown("move_down") then moveY = 1 end
end
```

### Charged Attack

```lua
if input:isDown("attack") then
    local charge = input:getHoldDuration("attack")
    ui:showChargeBar(charge)
end

if input:isReleased("attack") then
    local power = math.min(input:getHoldDuration("attack"), 2.0)
    player:attackWithPower(power)
end
```

### Mouse Aiming

```lua
local mx, my = input:getMousePosition()
local angle = math.atan2(my - player.y, mx - player.x)
player.aimAngle = angle
```

### Drag & Drop

```lua
if input:isPressed("select") then
    local mx, my = input:getMousePosition()
    selectedItem = findItemAt(mx, my)
end

if input:isDragging() and selectedItem then
    local dx, dy = input:getDragDelta()
    selectedItem.x = selectedItem.startX + dx
    selectedItem.y = selectedItem.startY + dy
end

if input:isReleased("select") then
    if selectedItem then
        dropItem(selectedItem)
        selectedItem = nil
    end
end
```

### Menu Rebinding UI

```lua
function RebindButton:onClick()
    ui:showMessage("Press a key for " .. self.actionName)
    
    input:startRebind(self.actionName, "keyboard", function(success, key)
        if success then
            self.label = key
            saveBindings()
        end
        ui:hideMessage()
    end)
end
```

### Save/Load Bindings

```lua
function saveBindings()
    local data = input:exportBindings()
    local json = Game.utils.json.encode(data)
    love.filesystem.write("bindings.json", json)
end

function loadBindings()
    local content = love.filesystem.read("bindings.json")
    if content then
        local data = Game.utils.json.decode(content)
        input:importBindings(data)
    end
end
```

## Input Types Reference

### Keyboard Keys

Vedi: https://love2d.org/wiki/KeyConstant

Comuni: `space`, `return`, `escape`, `tab`, `backspace`, `up`, `down`, `left`, `right`, `lshift`, `rshift`, `lctrl`, `rctrl`, `lalt`, `ralt`, `a`-`z`, `0`-`9`, `f1`-`f12`

### Mouse Buttons

- `1` = Left
- `2` = Right  
- `3` = Middle
- `4`, `5` = Extra buttons

### Gamepad Buttons

Vedi: https://love2d.org/wiki/GamepadButton

`a`, `b`, `x`, `y`, `back`, `guide`, `start`, `leftstick`, `rightstick`, `leftshoulder`, `rightshoulder`, `dpup`, `dpdown`, `dpleft`, `dpright`

### Gamepad Axes

Vedi: https://love2d.org/wiki/GamepadAxis

`leftx`, `lefty`, `rightx`, `righty`, `triggerleft`, `triggerright`

## Troubleshooting

### "isPressed non funziona"

Assicurati di chiamare `update(dt)` PRIMA di controllare e `lateUpdate()` DOPO la game logic.

### "Azione non risponde"

Verifica che il contesto contenente l'azione sia attivo con `isContextActive()`.

### "Gamepad non rilevato"

Connetti il gamepad prima di avviare il gioco, oppure gestisci `love.joystickadded`.

### "Rebind cattura tasti sbagliati"

Durante il rebind, tutti gli input normali sono ignorati. Solo il tipo specificato viene catturato.

## Estensioni Future

### Multiplayer

Il sistema è predisposto per multiplayer:

```lua
-- Futuro API
input:isPressed("jump", 1)  -- player 1
input:isPressed("jump", 2)  -- player 2
```

### Combo System

Estensibile con un sistema combo che traccia sequenze di input.

### Input Recording

Per replay, si può estendere per registrare tutti gli input.
```

## Dipendenze
- Tutte le Card precedenti

## Completamento

Questa è l'ultima card. Dopo questa, il sistema Input Handler è completo e documentato.
