# Card 09: Input Defaults Config

> Configurazione centralizzata dei binding e contesti default.

## Stato
- [ ] Implementazione
- [ ] Test
- [ ] Review

## File
`src/constants/input_defaults.lua`

## Descrizione

File di configurazione che definisce tutti i binding default e i contesti. Unico punto da modificare per customizzare gli input del gioco.

## Struttura

```lua
---@class InputDefaultsConfig
---@field actions table<string, InputActionConfig>
---@field contexts table<string, string[]>
---@field settings InputHandlerSettings

---@class InputActionConfig
---@field keyboard? string
---@field mouse? number
---@field mouseWheel? "up"|"down"|"left"|"right"
---@field gamepadButton? string
---@field gamepadAxis? string
---@field axisDirection? number
---@field axisThreshold? number

return {
    -- Definizione azioni
    actions = { ... },
    
    -- Raggruppamento in contesti
    contexts = { ... },
    
    -- Settings globali
    settings = { ... },
}
```

## Implementazione Completa

```lua
--[[
    Input Defaults Configuration
    
    Definisce tutte le azioni di input e i loro binding default.
    Modifica questo file per customizzare i controlli del gioco.
    
    Input Types:
    - keyboard: nome tasto LÖVE (https://love2d.org/wiki/KeyConstant)
    - mouse: numero bottone (1=left, 2=right, 3=middle, 4/5=extra)
    - mouseWheel: "up", "down", "left", "right"
    - gamepadButton: nome bottone (https://love2d.org/wiki/GamepadButton)
    - gamepadAxis: nome asse (https://love2d.org/wiki/GamepadAxis)
    - axisDirection: -1 o 1 (direzione per trasformare axis in boolean)
    - axisThreshold: 0-1 (soglia per axis, default 0.5)
]]

local InputDefaults = {}

--------------------------------------------------
-- Actions
--------------------------------------------------

InputDefaults.actions = {
    -----------------------
    -- Movement (Gameplay)
    -----------------------
    move_up = {
        keyboard = "w",
        gamepadAxis = "lefty",
        axisDirection = -1,
    },
    move_down = {
        keyboard = "s",
        gamepadAxis = "lefty",
        axisDirection = 1,
    },
    move_left = {
        keyboard = "a",
        gamepadAxis = "leftx",
        axisDirection = -1,
    },
    move_right = {
        keyboard = "d",
        gamepadAxis = "rightx",
        axisDirection = 1,
    },
    
    -- Alternative arrow keys (stesso contesto, binding diversi)
    move_up_alt = {
        keyboard = "up",
    },
    move_down_alt = {
        keyboard = "down",
    },
    move_left_alt = {
        keyboard = "left",
    },
    move_right_alt = {
        keyboard = "right",
    },
    
    -----------------------
    -- Actions (Gameplay)
    -----------------------
    jump = {
        keyboard = "space",
        gamepadButton = "a",
    },
    
    shoot = {
        keyboard = "x",
        mouse = 1,
        gamepadButton = "rightshoulder",
    },
    
    interact = {
        keyboard = "e",
        gamepadButton = "x",
    },
    
    dash = {
        keyboard = "lshift",
        gamepadButton = "b",
    },
    
    -----------------------
    -- Camera (Gameplay)
    -----------------------
    aim_axis_x = {
        gamepadAxis = "rightx",
    },
    aim_axis_y = {
        gamepadAxis = "righty",
    },
    
    zoom_in = {
        mouseWheel = "up",
        gamepadButton = "rightstick",
    },
    zoom_out = {
        mouseWheel = "down",
    },
    
    -----------------------
    -- System
    -----------------------
    pause = {
        keyboard = "escape",
        gamepadButton = "start",
    },
    
    -----------------------
    -- Menu Navigation
    -----------------------
    confirm = {
        keyboard = "return",
        gamepadButton = "a",
    },
    
    cancel = {
        keyboard = "escape",
        gamepadButton = "b",
    },
    
    navigate_up = {
        keyboard = "up",
        gamepadButton = "dpup",
        gamepadAxis = "lefty",
        axisDirection = -1,
    },
    
    navigate_down = {
        keyboard = "down",
        gamepadButton = "dpdown",
        gamepadAxis = "lefty",
        axisDirection = 1,
    },
    
    navigate_left = {
        keyboard = "left",
        gamepadButton = "dpleft",
        gamepadAxis = "leftx",
        axisDirection = -1,
    },
    
    navigate_right = {
        keyboard = "right",
        gamepadButton = "dpright",
        gamepadAxis = "leftx",
        axisDirection = 1,
    },
    
    -----------------------
    -- Pause Menu
    -----------------------
    unpause = {
        keyboard = "escape",
        gamepadButton = "start",
    },
    
    quit_to_menu = {
        keyboard = "q",
        gamepadButton = "back",
    },
    
    -----------------------
    -- Dialogue
    -----------------------
    dialogue_advance = {
        keyboard = "space",
        mouse = 1,
        gamepadButton = "a",
    },
    
    dialogue_skip = {
        keyboard = "escape",
        gamepadButton = "b",
    },
    
    -----------------------
    -- Debug (only in debug mode)
    -----------------------
    debug_toggle = {
        keyboard = "f1",
    },
    
    debug_reload = {
        keyboard = "f5",
    },
}

--------------------------------------------------
-- Contexts
--------------------------------------------------

InputDefaults.contexts = {
    -- Gioco attivo
    gameplay = {
        "move_up", "move_down", "move_left", "move_right",
        "move_up_alt", "move_down_alt", "move_left_alt", "move_right_alt",
        "jump", "shoot", "interact", "dash",
        "aim_axis_x", "aim_axis_y",
        "zoom_in", "zoom_out",
        "pause",
    },
    
    -- Menu principale / schermate menu
    menu = {
        "confirm", "cancel",
        "navigate_up", "navigate_down", "navigate_left", "navigate_right",
    },
    
    -- Overlay pausa (può essere sopra gameplay)
    pause = {
        "unpause", "quit_to_menu",
        "navigate_up", "navigate_down",
        "confirm", "cancel",
    },
    
    -- Dialoghi
    dialogue = {
        "dialogue_advance", "dialogue_skip",
    },
    
    -- Debug overlay
    debug = {
        "debug_toggle", "debug_reload",
    },
}

--------------------------------------------------
-- Settings
--------------------------------------------------

InputDefaults.settings = {
    axisThreshold = 0.5,      -- soglia default per axis → boolean
    dragThreshold = 5,        -- pixel per iniziare drag
}

return InputDefaults
```

## Helper per Setup

Funzione per inizializzare InputHandler dai defaults:

```lua
-- In src/systems/input_handler.lua o come utility separata

--- Inizializza InputHandler con la configurazione default
---@param handler InputHandler
---@param defaults table  -- InputDefaults
function InputHandler.setupFromDefaults(handler, defaults)
    local InputAction = require("src.systems.input_action")
    local InputContext = require("src.systems.input_context")
    
    -- Crea tutte le azioni
    local actions = {}
    for actionName, config in pairs(defaults.actions) do
        config.name = actionName
        actions[actionName] = InputAction.new(config)
    end
    
    -- Crea contesti e assegna azioni
    for contextName, actionNames in pairs(defaults.contexts) do
        local context = InputContext.new(contextName)
        
        for _, actionName in ipairs(actionNames) do
            if actions[actionName] then
                context:addAction(actions[actionName]:clone())
            else
                Game.logger.warning(
                    "Action '" .. actionName .. "' not found for context '" .. contextName .. "'",
                    "InputHandler"
                )
            end
        end
        
        handler:addContext(context)
    end
    
    -- Salva come default per reset
    handler:saveAsDefault()
end
```

## Uso in main.lua

```lua
local Game = require("src.init")

local input

function love.load()
    -- Crea handler con settings
    input = Game.systems.inputHandler.new(Game.constants.inputDefaults.settings)
    
    -- Setup da defaults
    Game.systems.inputHandler.setupFromDefaults(input, Game.constants.inputDefaults)
    
    -- Carica eventuali binding salvati
    local savedBindings = loadBindingsFromFile()
    if savedBindings then
        input:importBindings(savedBindings)
    end
    
    -- Imposta contesto iniziale
    input:setContext("menu")
end
```

## Convenzioni Naming

| Tipo | Convenzione | Esempio |
|------|-------------|---------|
| Movement | `move_{direction}` | `move_up`, `move_left` |
| Actions | Verbo semplice | `jump`, `shoot`, `dash` |
| Axis | `{what}_axis_{x/y}` | `aim_axis_x` |
| Navigation | `navigate_{direction}` | `navigate_up` |
| System | Descrittivo | `pause`, `quit_to_menu` |
| Alternatives | `{base}_alt` | `move_up_alt` |

## Note di Design

### Azioni Duplicate tra Contesti

Nota che alcune azioni (es: `navigate_up`) esistono in più contesti. Quando copi l'azione con `clone()`, ogni contesto ha la sua copia indipendente. Questo permette:

1. Stesso nome, stesso default
2. Rebinding indipendente per contesto (se voluto)
3. Codice gameplay che usa sempre lo stesso nome

### Axis vs Digitale

Per il movimento, definiamo sia versioni digitali (`move_up`) che axis (`gamepadAxis = "lefty"`). Il gameplay code può:

```lua
-- Approccio 1: solo digitale
if input:isDown("move_up") then moveY = -1 end

-- Approccio 2: preferisci analogico
local moveY = input:getAxis("move_up")  -- ritorna valore axis se disponibile
if moveY == 0 then
    if input:isDown("move_up") then moveY = -1 end
end
```

## Init Aggregator Update

`src/constants/init.lua`:
```lua
return {
    -- existing...
    inputDefaults = require("src.constants.input_defaults"),
}
```

## Dipendenze
- Card 01: InputAction
- Card 03: InputContext
- Card 04: InputHandler Core

## Prossima Card
→ Card 10: Integration
