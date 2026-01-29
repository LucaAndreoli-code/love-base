---Default bindings and axes for InputHandler
---@module input_handler.defaults

local Defaults = {}

---Default action bindings
---@type table<string, ActionBinding>
Defaults.bindings = {
    jump = {
        keyboard = "space",
        gamepad = "a"
    },
    left = {
        keyboard = "a",
        gamepad = "leftx-"
    },
    right = {
        keyboard = "d",
        gamepad = "leftx+"
    },
    up = {
        keyboard = "w",
        gamepad = "lefty-"
    },
    down = {
        keyboard = "s",
        gamepad = "lefty+"
    },
    attack = {
        keyboard = "j",
        gamepad = "x"
    },
    dash = {
        keyboard = { "k", "lshift" },
        gamepad = "rightshoulder"
    },
    pause = {
        keyboard = "escape",
        gamepad = "start"
    }
}

---Default axis definitions
---@type table<string, AxisDefinition>
Defaults.axes = {
    horizontal = {
        negative = "left",
        positive = "right"
    },
    vertical = {
        negative = "up",
        positive = "down"
    }
}

return Defaults
