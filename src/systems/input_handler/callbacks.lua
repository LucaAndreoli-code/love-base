---Callback methods for InputHandler
---@module input_handler.callbacks

local Logger = require("src.logger")

local Callbacks = {}

---Called when a keyboard key is pressed
---@param self InputHandler
---@param key string
function Callbacks.onKeyPressed(self, key)
    local action = self:getActionForInput(key, "keyboard")
    Logger.debug(string.format("Key pressed: '%s' -> action: %s", key, action or "none"), "InputHandler")

    table.insert(self.eventQueue, {
        type = "pressed",
        device = "keyboard",
        key = key
    })

    if self.activeDevice ~= "keyboard" then
        Logger.debug("Active device changed: " .. self.activeDevice .. " -> keyboard", "InputHandler")
        self.activeDevice = "keyboard"
    end
end

---Called when a keyboard key is released
---@param self InputHandler
---@param key string
function Callbacks.onKeyReleased(self, key)
    local action = self:getActionForInput(key, "keyboard")
    Logger.debug(string.format("Key released: '%s' -> action: %s", key, action or "none"), "InputHandler")

    table.insert(self.eventQueue, {
        type = "released",
        device = "keyboard",
        key = key
    })
end

---Called when a gamepad button is pressed
---@param self InputHandler
---@param _joystick love.Joystick
---@param button string
function Callbacks.onGamepadPressed(self, _joystick, button)
    local action = self:getActionForInput(button, "gamepad")
    Logger.debug(string.format("Gamepad pressed: '%s' -> action: %s", button, action or "none"), "InputHandler")

    table.insert(self.eventQueue, {
        type = "pressed",
        device = "gamepad",
        key = button
    })

    if self.activeDevice ~= "gamepad" then
        Logger.debug("Active device changed: " .. self.activeDevice .. " -> gamepad", "InputHandler")
        self.activeDevice = "gamepad"
    end
end

---Called when a gamepad button is released
---@param self InputHandler
---@param _joystick love.Joystick
---@param button string
function Callbacks.onGamepadReleased(self, _joystick, button)
    local action = self:getActionForInput(button, "gamepad")
    Logger.debug(string.format("Gamepad released: '%s' -> action: %s", button, action or "none"), "InputHandler")

    table.insert(self.eventQueue, {
        type = "released",
        device = "gamepad",
        key = button
    })
end

---Called when a gamepad axis moves (for device detection)
---@param self InputHandler
---@param _joystick love.Joystick
---@param _axis string
---@param value number
function Callbacks.onGamepadAxis(self, _joystick, _axis, value)
    -- Switch to gamepad if significant axis movement
    if math.abs(value) > self.deadzone and self.activeDevice ~= "gamepad" then
        Logger.debug("Active device changed: " .. self.activeDevice .. " -> gamepad", "InputHandler")
        self.activeDevice = "gamepad"
    end
end

return Callbacks
