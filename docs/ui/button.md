# Button

Clickable UI button component with hover and press states. Uses center-based coordinates for consistency with the Entity system.

## Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `x` | number | 0 | X position (center) |
| `y` | number | 0 | Y position (center) |
| `width` | number | 100 | Button width |
| `height` | number | 40 | Button height |
| `text` | string | "" | Button label |
| `onClick` | function? | nil | Callback when clicked |

## Methods

### Button.new(config)

Creates a new Button instance.

```lua
Button.new(config) -> Button
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `config` | table | Configuration table |
| `config.x` | number? | X position (center) |
| `config.y` | number? | Y position (center) |
| `config.width` | number? | Button width |
| `config.height` | number? | Button height |
| `config.text` | string? | Button label |
| `config.onClick` | function? | Callback on click |

**Returns:** `Button` - New button instance

---

### Button:update(dt)

Updates button state (hover, press detection, click handling).

```lua
Button:update(dt) -> nil
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `dt` | number | Delta time (unused, for interface consistency) |

**Returns:** `nil`

**Note:** Click is triggered on mouse release while hovering (not on press).

---

### Button:draw()

Draws the button with appropriate visual state.

```lua
Button:draw() -> nil
```

**Returns:** `nil`

Uses colors from `Game.constants.colors.button`:
- `normal`: Default state
- `hovered`: Mouse over button
- `pressed`: Mouse down on button
- `border`: Button outline

---

### Button:isHovered()

Returns whether the mouse is currently over the button.

```lua
Button:isHovered() -> boolean
```

**Returns:** `boolean` - `true` if mouse is over button

---

### Button:isPressed()

Returns whether the button is currently being pressed.

```lua
Button:isPressed() -> boolean
```

**Returns:** `boolean` - `true` if mouse is down over button

---

### Button:containsPoint(px, py)

Checks if a point is inside the button bounds.

```lua
Button:containsPoint(px, py) -> boolean
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `px` | number | Point X coordinate |
| `py` | number | Point Y coordinate |

**Returns:** `boolean` - `true` if point is inside button

## Examples

### Basic button

```lua
local Game = require("src.init")

local button

function love.load()
    Game.load()

    button = Game.ui.button.new({
        x = 640,
        y = 360,
        width = 200,
        height = 50,
        text = "Click Me",
        onClick = function()
            print("Button clicked!")
        end
    })
end

function love.update(dt)
    button:update(dt)
end

function love.draw()
    button:draw()
end
```

### Multiple buttons

```lua
local buttons = {}

function love.load()
    Game.load()

    buttons.play = Game.ui.button.new({
        x = 640,
        y = 300,
        text = "Play",
        onClick = function()
            startGame()
        end
    })

    buttons.quit = Game.ui.button.new({
        x = 640,
        y = 380,
        text = "Quit",
        onClick = function()
            love.event.quit()
        end
    })
end

function love.update(dt)
    for _, btn in pairs(buttons) do
        btn:update(dt)
    end
end

function love.draw()
    for _, btn in pairs(buttons) do
        btn:draw()
    end
end
```

### Checking button state

```lua
function love.update(dt)
    button:update(dt)

    if button:isHovered() then
        -- Show tooltip or change cursor
    end

    if button:isPressed() then
        -- Visual feedback during press
    end
end
```

### Integration with StateMachine

```lua
local function createMenuState(stateMachine)
    local playButton

    return {
        enter = function()
            playButton = Game.ui.button.new({
                x = 640,
                y = 360,
                text = "Play",
                onClick = function()
                    stateMachine:setState("game")
                end
            })
        end,

        update = function(dt)
            playButton:update(dt)
        end,

        draw = function()
            playButton:draw()
        end
    }
end
```

## Colors

Button uses colors from `Game.constants.colors`:

```lua
colors = {
    button = {
        normal = { 0.3, 0.3, 0.3, 1 },
        hovered = { 0.4, 0.4, 0.4, 1 },
        pressed = { 0.2, 0.2, 0.2, 1 },
        border = { 0.5, 0.5, 0.5, 1 }
    },
    text = {
        primary = { 1, 1, 1, 1 }
    }
}
```

To customize colors globally, modify `src/constants/colors.lua`.

## Notes

- **Mouse only**: Currently supports mouse input only. Keyboard navigation (Tab, Enter) planned for future InputHandler integration.
- **Center-based coordinates**: `x, y` represents the button center, consistent with Entity system.
- **Click on release**: Click callback fires on mouse release, not press. This allows users to cancel a click by moving away before releasing.
- **No logging**: Button does not log to keep UI lightweight. Add logging in onClick callbacks if needed.
