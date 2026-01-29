---Query functions for InputHandler state
---@module input_handler.queries

local Logger = require("src.logger")
local Utils = require("src.systems.input_handler.utils")

local Queries = {}

---Get the action name for a given key/button and device
---@param self InputHandler
---@param key string The key or button
---@param device "keyboard"|"gamepad"
---@return string|nil action The action name, or nil if not bound
function Queries.getActionForInput(self, key, device)
    for action, binding in pairs(self.bindings) do
        local boundKeys = binding[device]
        if boundKeys then
            if type(boundKeys) == "string" then
                -- Single key binding
                if boundKeys == key then
                    return action
                end
                -- Check for axis-style gamepad bindings (e.g., "leftx-" matches "leftx")
                if device == "gamepad" and boundKeys:match("^" .. key .. "[%-%+]$") then
                    return nil -- Axis bindings don't trigger pressed/released
                end
            elseif type(boundKeys) == "table" then
                -- Multiple key bindings
                for _, boundKey in ipairs(boundKeys) do
                    if boundKey == key then
                        return action
                    end
                end
            end
        end
    end
    return nil
end

---Check if a keyboard key is held for an action
---@param self InputHandler
---@param action string
---@return boolean
function Queries.isKeyboardHeld(self, action)
    local binding = self.bindings[action]
    if not binding or not binding.keyboard then
        Logger.debug(string.format("isKeyboardHeld: '%s' no keyboard binding", action), "InputHandler")
        return false
    end

    local keys = binding.keyboard
    if type(keys) == "string" then
        keys = { keys }
    end

    for _, key in ipairs(keys) do
        local isDown = love.keyboard.isDown(key)
        if isDown then
            Logger.debug(string.format("isKeyboardHeld: '%s' key '%s' is DOWN", action, key), "InputHandler")
            return true
        end
    end
    return false
end

---Check if a gamepad button/axis is held for an action
---@param self InputHandler
---@param action string
---@return boolean
function Queries.isGamepadHeld(self, action)
    if not self.gamepad then
        return false
    end

    local binding = self.bindings[action]
    if not binding or not binding.gamepad then
        return false
    end

    local name, direction = Utils.parseGamepadBinding(binding.gamepad)

    if direction then
        -- Axis binding (e.g., "leftx-")
        local axisValue = self.gamepadAxisValues[name] or 0
        if direction < 0 then
            return axisValue < -self.deadzone
        else
            return axisValue > self.deadzone
        end
    else
        -- Button binding
        return self.gamepad:isGamepadDown(name)
    end
end

---Returns true if the action is currently held down
---@param self InputHandler
---@param action string Action name
---@return boolean
function Queries.isHeld(self, action)
    if not self.bindings[action] then
        return false
    end

    return Queries.isKeyboardHeld(self, action) or Queries.isGamepadHeld(self, action)
end

---Returns true only on the frame the action was pressed
---@param self InputHandler
---@param action string Action name
---@return boolean
function Queries.isPressed(self, action)
    local actionState = self.state[action]
    if not actionState then
        return false
    end
    return actionState.pressed
end

---Returns true only on the frame the action was released
---@param self InputHandler
---@param action string Action name
---@return boolean
function Queries.isReleased(self, action)
    local actionState = self.state[action]
    if not actionState then
        return false
    end
    return actionState.released
end

---Returns true if the action was pressed within the specified time window
---@param self InputHandler
---@param action string Action name
---@param seconds number Time window in seconds
---@return boolean
function Queries.wasPressedWithin(self, action, seconds)
    local actionState = self.state[action]
    if not actionState then
        return false
    end

    local now = love.timer.getTime()
    return (now - actionState.lastPressedAt) <= seconds
end

return Queries
