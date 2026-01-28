---@class Colors
---@field button ButtonColors
---@field text TextColors
---@field debug DebugColors

---@class ButtonColors
---@field normal table
---@field hovered table
---@field pressed table
---@field disabled table
---@field border table

---@class TextColors
---@field primary table
---@field secondary table

---@class DebugColors
---@field hitbox table
---@field center table
---@field velocity table

local Colors = {
    button = {
        normal = { 0.3, 0.3, 0.3, 1 },
        hovered = { 0.4, 0.4, 0.4, 1 },
        pressed = { 0.2, 0.2, 0.2, 1 },
        disabled = { 0.2, 0.2, 0.2, 0.5 },
        border = { 0.5, 0.5, 0.5, 1 }
    },
    text = {
        primary = { 1, 1, 1, 1 },
        secondary = { 0.7, 0.7, 0.7, 1 }
    },
    debug = {
        hitbox = { 0, 1, 0, 0.5 },
        center = { 1, 1, 0, 1 },
        velocity = { 1, 0, 1, 0.7 }
    }
}

return Colors
