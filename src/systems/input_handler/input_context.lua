--[[
    InputContext

    Groups a set of actions that are active together.
    Allows logical separation of inputs by game state.

    Examples of contexts:
    - gameplay: move, jump, shoot, pause
    - menu: confirm, cancel, navigate
    - pause: unpause, quit_to_menu
    - dialogue: advance, skip
]]

---@class InputContext
---@field name string
---@field actions table<string, InputAction>  actionName → InputAction

local InputContext = {}
InputContext.__index = InputContext

--- Creates a new context
---@param name string
---@return InputContext
function InputContext.new(name)
    local self = setmetatable({}, InputContext)

    self.name = name
    self.actions = {}

    return self
end

--- Adds an action to the context
---@param action InputAction
function InputContext:addAction(action)
    self.actions[action.name] = action
end

--- Removes an action from the context
---@param actionName string
---@return boolean  true if removed
function InputContext:removeAction(actionName)
    if self.actions[actionName] then
        self.actions[actionName] = nil
        return true
    end
    return false
end

--- Checks if the context contains an action
---@param actionName string
---@return boolean
function InputContext:hasAction(actionName)
    return self.actions[actionName] ~= nil
end

--- Gets an action by name
---@param actionName string
---@return InputAction|nil
function InputContext:getAction(actionName)
    return self.actions[actionName]
end

--- Gets all actions
---@return table<string, InputAction>
function InputContext:getActions()
    return self.actions
end

--- Counts the actions in the context
---@return number
function InputContext:count()
    local count = 0
    for _ in pairs(self.actions) do
        count = count + 1
    end
    return count
end

return InputContext
