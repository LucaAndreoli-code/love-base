---Axis handling for InputHandler
---@module input_handler.axis

local Utils = require("src.systems.input_handler.utils")

local Axis = {}

---Apply deadzone to an axis value
---@param self InputHandler
---@param value number Raw axis value (-1 to 1)
---@return number Processed value with deadzone applied
function Axis.applyDeadzone(self, value)
    if math.abs(value) < self.deadzone then
        return 0
    end
    -- Rescale so edge of deadzone = 0, full tilt = 1/-1
    local sign = value > 0 and 1 or -1
    return sign * (math.abs(value) - self.deadzone) / (1 - self.deadzone)
end

---Returns the axis value from -1 to 1
---@param self InputHandler
---@param Queries table Query functions module
---@param axisName string Axis name ("horizontal", "vertical")
---@return number
function Axis.getAxis(self, Queries, axisName)
    local axisDef = self.axes[axisName]
    if not axisDef then
        return 0
    end

    if self.activeDevice == "keyboard" then
        -- Keyboard: discrete -1, 0, or 1
        local negHeld = Queries.isKeyboardHeld(self, axisDef.negative)
        local posHeld = Queries.isKeyboardHeld(self, axisDef.positive)

        if negHeld and not posHeld then
            return -1
        elseif posHeld and not negHeld then
            return 1
        else
            return 0
        end
    else
        -- Gamepad: analog value with deadzone
        if not self.gamepad then
            return 0
        end

        -- Get the axis name from the positive binding (e.g., "leftx+" -> "leftx")
        local posBinding = self.bindings[axisDef.positive]
        if not posBinding or not posBinding.gamepad then
            return 0
        end

        local axisId, _ = Utils.parseGamepadBinding(posBinding.gamepad)
        local rawValue = self.gamepadAxisValues[axisId] or 0
        return Axis.applyDeadzone(self, rawValue)
    end
end

return Axis
