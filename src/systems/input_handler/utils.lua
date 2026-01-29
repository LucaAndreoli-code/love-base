---Utility functions for InputHandler
---@module input_handler.utils

local Utils = {}

---Deep copy a table
---@param t table
---@return table
function Utils.deepCopy(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Utils.deepCopy(v)
    end
    return copy
end

---Merge custom bindings into defaults
---@param defaults table
---@param custom table
---@return table
function Utils.mergeBindings(defaults, custom)
    local result = Utils.deepCopy(defaults)
    for action, binding in pairs(custom) do
        result[action] = Utils.deepCopy(binding)
    end
    return result
end

---Parse a gamepad binding to get axis name and direction
---@param binding string e.g., "leftx-" or "a"
---@return string name Axis or button name
---@return number|nil direction -1 for negative, 1 for positive, nil for button
function Utils.parseGamepadBinding(binding)
    local axis, direction = binding:match("^(%w+)([%-%+])$")
    if axis and direction then
        return axis, direction == "-" and -1 or 1
    end
    return binding, nil
end

return Utils
