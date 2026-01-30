--[[
    InputAction

    Represents a single game action (e.g., "jump", "shoot") with its bindings
    for each input type. Pure data structure with no state logic.
]]



local InputAction = {}
InputAction.__index = InputAction

---@class InputAction
---@field name string                    Unique identifier ("jump", "shoot")
---@field keyboard string|nil            Keyboard key ("space", "w", "escape")
---@field mouse number|nil               Mouse button (1=left, 2=right, 3=middle)
---@field mouseWheel string|nil          "up" | "down" | nil
---@field gamepadButton string|nil       Gamepad button ("a", "b", "start", "rightshoulder")
---@field gamepadAxis string|nil         Gamepad axis ("leftx", "lefty", "rightx", "righty")
---@field axisDirection number|nil       Axis direction: -1 or 1 (for transforming axis to pressed)
---@field axisThreshold number           Threshold for axis→pressed (default 0.5)

--- Creates a new InputAction
---@param config table
---@return InputAction
function InputAction.new(config)
    local self = setmetatable({}, InputAction)

    self.name = config.name
    self.keyboard = config.keyboard
    self.mouse = config.mouse
    self.mouseWheel = config.mouseWheel
    self.gamepadButton = config.gamepadButton
    self.gamepadAxis = config.gamepadAxis
    self.axisDirection = config.axisDirection
    self.axisThreshold = config.axisThreshold or 0.5

    return self
end

--- Clones the action (for rebinding without mutating original)
---@return InputAction
function InputAction:clone()
    return InputAction.new({
        name = self.name,
        keyboard = self.keyboard,
        mouse = self.mouse,
        mouseWheel = self.mouseWheel,
        gamepadButton = self.gamepadButton,
        gamepadAxis = self.gamepadAxis,
        axisDirection = self.axisDirection,
        axisThreshold = self.axisThreshold,
    })
end

--- Checks if the action has at least one valid binding
---@return boolean
function InputAction:hasBinding()
    return self.keyboard ~= nil
        or self.mouse ~= nil
        or self.mouseWheel ~= nil
        or self.gamepadButton ~= nil
        or self.gamepadAxis ~= nil
end

--- Returns a serializable representation (for save/load)
---@return table
function InputAction:serialize()
    return {
        name = self.name,
        keyboard = self.keyboard,
        mouse = self.mouse,
        mouseWheel = self.mouseWheel,
        gamepadButton = self.gamepadButton,
        gamepadAxis = self.gamepadAxis,
        axisDirection = self.axisDirection,
        axisThreshold = self.axisThreshold,
    }
end

--- Creates InputAction from serialized data
---@param data table
---@return InputAction
function InputAction.deserialize(data)
    return InputAction.new(data)
end

return InputAction
