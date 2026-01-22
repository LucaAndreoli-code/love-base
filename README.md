# Love2D Base Template

Modular template for Love2D projects with scalable structure and "init aggregator" pattern for clean namespace.

## Structure

```
love-base/
├── assets/
│   ├── data/          # Data files (JSON, Lua tables, presets)
│   ├── font/          # Custom fonts
│   ├── sounds/        # Sound effects and music
│   └── sprites/       # Sprite sheets and images
├── shaders/           # GLSL shaders
├── src/
│   ├── constants/     # Centralized configurations (colors, sizes, speeds)
│   │   └── init.lua   # Constants aggregator
│   ├── scenes/        # Game scenes (menu, game, pause, gameover)
│   │   └── init.lua   # Scenes aggregator
│   ├── systems/       # Core systems (state machine, input handler, asset manager)
│   │   └── init.lua   # Systems aggregator
│   ├── ui/            # Reusable UI components (button, slider, panel, HUD)
│   │   └── init.lua   # UI aggregator
│   ├── utils/         # Utility functions (math, string, table helpers)
│   │   └── init.lua   # Utils aggregator
│   └── init.lua       # Master loader (loads all modules)
│   └── logger.lua     # 4-level logger
├── conf.lua           # Love2D configuration (window, modules, identity)
└── main.lua           # Minimal entry point
└── build.lua          # Configuration file for love-build (https://github.com/ellraiser/love-build)

## Architecture

### Init Aggregator Pattern

Each main module has an `init.lua` that aggregates and exposes submodules. This pattern:
- Creates a clean and hierarchical namespace
- Allows centralized loading
- Avoids global name collisions

**Example `src/systems/init.lua`:**
```lua
local Systems = {}

Systems.stateMachine = require("src.systems.state_machine")
Systems.input = require("src.systems.input_handler")
Systems.assets = require("src.systems.asset_manager")

function Systems:initialize()
    -- Centralized init in correct order
    self.stateMachine:init()
    self.input:init()
    self.assets:init()
end

return Systems
```

**Example `src/init.lua` (master loader):**
```lua
local Game = {}

Game.constants = require("src.constants.init")
Game.scenes = require("src.scenes.init")
Game.systems = require("src.systems.init")
Game.ui = require("src.ui.init")
Game.utils = require("src.utils.init")

return Game
```

**Usage:**
```lua
local Logger = require("src.logger")

function love.load()
    Game = require("src.init")  -- Load everything at once
    Game.systems:initialize()
    
    -- Clean and hierarchical access
    Logger.info("Game started", "main")
    Game.systems.stateMachine:change("menu")
end
```

### Core Modules

#### `constants/`
Centralizes all configuration variables:
- Color palette
- Window/grid dimensions
- Movement speeds
- Margins and spacing

**Avoid:**
```lua
player.speed = 200  -- Scattered variable in code
love.graphics.setColor(0.2, 0.6, 1.0)  -- Hardcoded color
```

**Better:**
```lua
player.speed = Game.constants.game.playerSpeed
love.graphics.setColor(Game.constants.colors.primary)
```

#### `systems/`
Fundamental architectural systems reusable across projects:

**`state_machine.lua`** - Scene/state management
- Registers scenes by name
- Manages transitions between scenes
- Calls `enter()`/`exit()` when changing scene
- Routes `update()`/`draw()` to active scene

**`input_handler.lua`** - Centralized input
- Handles keyboard/mouse/gamepad
- Allows key rebinding
- Separates input from game logic

**`asset_manager.lua`** - Resource loading
- Cache for images/fonts/sounds
- Lazy loading or preload
- Avoids duplicates in memory

#### `logger.lua` (directly in `src/`)
Logging system used everywhere. Located in `src/logger.lua` instead of `systems/` for shorter and direct access:
```lua
local Logger = require("src.logger")
Logger.info("Message", "source")
```

#### `scenes/`
Isolated game scenes with standard interface:

```lua
-- Scene interface
local Scene = {}

function Scene:enter()
    -- Setup when entering the scene
end

function Scene:exit()
    -- Cleanup when exiting
end

function Scene:update(dt)
    -- Update logic
end

function Scene:draw()
    -- Rendering
end

function Scene:keypressed(key)
    -- Input handling
end

return Scene
```

Each scene is completely independent. The state machine manages transitions.

#### `ui/`
Reusable UI components across different scenes:

**When to use `ui/`:**
- Button used in menu + pause + gameover → `ui/button.lua`
- HUD used only in gameplay → Can be in `scenes/game.lua` or `ui/hud.lua`
- Slider used in settings → `ui/slider.lua`

**Component pattern:**
```lua
-- ui/button.lua
local Button = {}
Button.__index = Button

function Button.new(x, y, width, height, text, onClick)
    local self = setmetatable({}, Button)
    -- ...
    return self
end

function Button:update()
    -- Update logic
end

function Button:draw()
    -- Rendering
end

function Button:mousepressed(x, y, button)
    -- Input handling
end

return Button
```

#### `utils/`
Generic reusable helper functions:

```lua
-- utils/math.lua
local MathUtils = {}

function MathUtils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function MathUtils.lerp(a, b, t)
    return a + (b - a) * t
end

function MathUtils.distance(x1, y1, x2, y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

return MathUtils
```

### Logger System

Logging system with 4 severity levels and colored output.

**Levels:**
- `DEBUG` (1): Detailed information, only with `--debug` flag
- `INFO` (2): General information, always visible
- `WARNING` (3): Warnings, always visible
- `ERROR` (4): Critical errors, always visible

**Usage:**
```lua
local Logger = require("src.logger")

-- With source tag to identify origin
Logger.debug("Player position: 100, 200", "entities/player")
Logger.info("Level loaded successfully", "scenes/game")
Logger.warning("Low memory", "systems/assets")
Logger.error("Failed to load texture", "systems/assets")
```

**Output format:**
```
[14:32:15] INFO [scenes/game]: Level loaded successfully
[14:32:16] WARNING [systems/assets]: Low memory
[14:32:17] ERROR [systems/assets]: Failed to load texture
```

**ANSI colors in terminal:**
- DEBUG: Cyan (`\27[36m`)
- INFO: Green (`\27[32m`)
- WARNING: Yellow (`\27[33m`)
- ERROR: Red (`\27[31m`)

**Minimum level configuration:**
```lua
local Logger = require("src.logger")

-- Show only WARNING and ERROR
Logger.setLevel(Logger.LEVELS.WARNING)

-- Disable all
Logger.disable()

-- Enable all
Logger.enable()
```

**`--debug` flag:**
The logger automatically checks for the `--debug` flag in arguments:
```bash
love .              # currentLevel = INFO (default)
love . --debug      # currentLevel = DEBUG (if launched via VSCODE)
```

Logger implementation:
```lua
local function checkDebugMode()
    if arg then
        for i, v in ipairs(arg) do
            if v == "--debug" then
                return true
            end
        end
    end
    return false
end

Logger.currentLevel = checkDebugMode() and Logger.LEVELS.DEBUG or Logger.LEVELS.INFO
```

### When to Add Modules

**Present from the start in template:**
- `constants/` - Always useful even for small projects
- `systems/` - Logger and base architecture
- `utils/` - Common helpers
- `scenes/` - Even a simple game has at least menu + game
- `ui/` - For reusable components

**Add when needed:**
- `entities/` - When you have 3+ types of game objects with similar logic
  - Player, Enemy, Bullet, Powerup, etc.
  - Useful for factory pattern and object pooling
- Submodules in `systems/` as needed
  - State machine when you have 2+ scenes
  - Asset manager when you have many resources
  - Input handler for key rebinding

**Practical rule:**
If you copy/paste the same type of code 3 times → extract into a dedicated module.

## Run

```bash
# Normal development (shows INFO, WARNING, ERROR)
love .

# With debug logging (also shows DEBUG - ONLY VIA VSCODE with Lua Local Debugger)
love . --debug
```

## VS Code Debug

`.vscode/launch.json` configuration:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "type": "lua-local",
            "request": "launch",
            "name": "Run LÖVE",
            "program": {
                "command": "love"
            },
            "args": ["."]
        },
        {
            "type": "lua-local",
            "request": "launch",
            "name": "Debug LÖVE",
            "program": {
                "command": "love"
            },
            "args": [".", "--debug"]
        }
    ]
}
```

Requires extension: **Local Lua Debugger** (tomblind)
F5 to launch, breakpoints work on variable assignments and function starts.