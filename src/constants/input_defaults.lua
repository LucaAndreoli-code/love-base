--[[
    Input Defaults Configuration

    Defines all input actions and their default bindings.
    Modify this file to customize game controls.

    Input Types:
    - keyboard: LÖVE key name (https://love2d.org/wiki/KeyConstant)
    - mouse: button number (1=left, 2=right, 3=middle, 4/5=extra)
    - mouseWheel: "up", "down", "left", "right"
    - gamepadButton: button name (https://love2d.org/wiki/GamepadButton)
    - gamepadAxis: axis name (https://love2d.org/wiki/GamepadAxis)
    - axisDirection: -1 or 1 (direction to transform axis to boolean)
    - axisThreshold: 0-1 (threshold for axis, default 0.5)
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
        gamepadAxis = "leftx",
        axisDirection = 1,
    },

    -- Alternative arrow keys (same context, different bindings)
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
    -- Active game
    gameplay = {
        "move_up", "move_down", "move_left", "move_right",
        "move_up_alt", "move_down_alt", "move_left_alt", "move_right_alt",
        "jump", "shoot", "interact", "dash",
        "aim_axis_x", "aim_axis_y",
        "zoom_in", "zoom_out",
        "pause",
    },

    -- Main menu / menu screens
    menu = {
        "confirm", "cancel",
        "move_up", "move_down", "move_left", "move_right",
    },

    -- Pause overlay (can be over gameplay)
    pause = {
        "unpause", "quit_to_menu",
        "navigate_up", "navigate_down",
        "confirm", "cancel",
    },

    -- Dialogues
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
    axisThreshold = 0.5, -- default threshold for axis → boolean
    dragThreshold = 5,   -- pixels to start drag
}

return InputDefaults
