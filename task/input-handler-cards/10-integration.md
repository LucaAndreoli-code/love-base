# Card 10: Integration

> Integrazione nel template: init aggregator, main.lua, e flusso completo.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File da Modificare
- `src/systems/init.lua`
- `src/constants/init.lua`
- `main.lua`

## Init Aggregator Updates

### `src/systems/init.lua`

```lua
return {
    -- Existing
    entity = require("src.systems.entity"),
    entityManager = require("src.systems.entity_manager"),
    stateMachine = require("src.systems.state_machine"),
    
    -- New: Input System
    inputAction = require("src.systems.input_action"),
    inputState = require("src.systems.input_state"),
    inputContext = require("src.systems.input_context"),
    inputHandler = require("src.systems.input_handler"),
}
```

### `src/constants/init.lua`

```lua
return {
    -- Existing...
    
    -- New
    inputDefaults = require("src.constants.input_defaults"),
}
```

## main.lua Integration

```lua
local Game = require("src.init")

-- Singleton input handler
local input

function love.load()
    -- Logger setup
    Game.logger.setLevel(arg[2] == "--debug" and "DEBUG" or "INFO")
    Game.logger.info("Game starting", "Main")
    
    -- Input Handler setup
    input = Game.systems.inputHandler.new(Game.constants.inputDefaults.settings)
    Game.systems.inputHandler.setupFromDefaults(input, Game.constants.inputDefaults)
    
    -- Carica binding salvati (se esistono)
    local bindingsData = love.filesystem.read("bindings.json")
    if bindingsData then
        local success, data = pcall(function()
            return Game.utils.json.decode(bindingsData)
        end)
        if success and data then
            input:importBindings(data)
            Game.logger.info("Loaded saved bindings", "Main")
        end
    end
    
    -- Salva default per reset
    input:saveAsDefault()
    
    -- Debug context sempre attivo in debug mode
    if arg[2] == "--debug" then
        input:pushContext("debug")
    end
    
    -- Contesto iniziale
    input:setContext("menu")
    
    -- ... resto del setup
end

--------------------------------------------------
-- Update
--------------------------------------------------

function love.update(dt)
    -- Input update PRIMA di tutto
    input:update(dt)
    
    -- Debug controls (se debug context attivo)
    if input:isPressed("debug_toggle") then
        Game.debug.toggle()
    end
    
    -- Game logic...
    -- (state machine, entities, etc.)
    
    -- Input late update DOPO tutto
    input:lateUpdate()
end

--------------------------------------------------
-- Draw
--------------------------------------------------

function love.draw()
    -- ... game rendering
    
    -- Debug overlay
    if Game.debug.isVisible() then
        Game.debug.draw()
    end
end

--------------------------------------------------
-- Input Callbacks
--------------------------------------------------

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

--------------------------------------------------
-- Focus
--------------------------------------------------

function love.focus(focused)
    if not focused then
        -- Quando la finestra perde focus, LÖVE genera keyreleased
        -- ma possiamo forzare un clear per sicurezza
        -- input:clearAllStates()  -- opzionale
    end
end
```

## Accesso Globale vs Parametro

Due approcci per accedere all'input handler nelle scene/sistemi:

### Approccio 1: Parametro (Consigliato)

```lua
-- In scene
function GameScene:update(dt, input)
    if input:isPressed("jump") then
        self.player:jump()
    end
end

-- In main.lua
function love.update(dt)
    input:update(dt)
    currentScene:update(dt, input)
    input:lateUpdate()
end
```

### Approccio 2: Game.input Singleton

```lua
-- In src/init.lua
local Game = {
    -- modules...
    input = nil,  -- sarà settato in love.load
}

-- In main.lua
function love.load()
    Game.input = Game.systems.inputHandler.new(...)
end

-- In scene
function GameScene:update(dt)
    if Game.input:isPressed("jump") then
        self.player:jump()
    end
end
```

## Integrazione con StateMachine

Se usi StateMachine per le scene, passa input nei callback:

```lua
-- Setup
local sm = Game.systems.stateMachine.new()

sm:addState("menu", {
    enter = function(params)
        input:setContext("menu")
    end,
    update = function(dt)
        if input:isPressed("confirm") then
            sm:setState("gameplay")
        end
    end,
})

sm:addState("gameplay", {
    enter = function(params)
        input:setContext("gameplay")
    end,
    update = function(dt)
        if input:isPressed("pause") then
            sm:pushState("pause")
        end
        -- game logic...
    end,
})

sm:addState("pause", {
    enter = function(params)
        input:pushContext("pause")
    end,
    exit = function(params)
        input:popContext("pause")
    end,
    update = function(dt)
        if input:isPressed("unpause") then
            sm:popState()
        end
    end,
})
```

## Esempio Scene Completa

```lua
-- src/scenes/game_scene.lua
local Game = require("src.init")

local GameScene = {}
GameScene.__index = GameScene

function GameScene.new()
    local self = setmetatable({}, GameScene)
    self.player = nil
    self.entities = Game.systems.entityManager.new()
    return self
end

function GameScene:enter(params, input)
    input:setContext("gameplay")
    
    -- Setup player
    self.player = Game.systems.entity.new({
        x = 400,
        y = 300,
        tags = { player = true },
    })
    self.entities:add(self.player)
end

function GameScene:update(dt, input)
    -- Movement
    local moveX, moveY = 0, 0
    
    if input:isDown("move_left") then moveX = moveX - 1 end
    if input:isDown("move_right") then moveX = moveX + 1 end
    if input:isDown("move_up") then moveY = moveY - 1 end
    if input:isDown("move_down") then moveY = moveY + 1 end
    
    -- Gamepad override
    local axisX = input:getAxis("move_right") - input:getAxis("move_left")
    local axisY = input:getAxis("move_down") - input:getAxis("move_up")
    if math.abs(axisX) > 0.1 then moveX = axisX end
    if math.abs(axisY) > 0.1 then moveY = axisY end
    
    self.player.vx = moveX * 200
    self.player.vy = moveY * 200
    
    -- Jump
    if input:isPressed("jump") then
        self:playerJump()
    end
    
    -- Shoot (with mouse aim)
    if input:isPressed("shoot") then
        local mx, my = input:getMousePosition()
        self:playerShoot(mx, my)
    end
    
    -- Pause
    if input:isPressed("pause") then
        return "push", "pause"  -- segnala a chi chiama di pushare pause
    end
    
    -- Update entities
    self.entities:update(dt)
end

function GameScene:draw()
    self.entities:draw()
end

return GameScene
```

## Checklist Integration

- [ ] `src/systems/init.lua` aggiornato con tutti i moduli input
- [ ] `src/constants/init.lua` aggiornato con inputDefaults
- [ ] `main.lua` crea e configura InputHandler
- [ ] Tutti i callback LÖVE collegati
- [ ] Contesto iniziale settato
- [ ] Debug context opzionale
- [ ] Load/save binding implementato
- [ ] Scene usano input via parametro o singleton

## Dipendenze
- Tutte le Card precedenti (01-09)

## Prossima Card
→ Card 11: Tests
