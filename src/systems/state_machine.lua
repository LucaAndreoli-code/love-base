local Logger = require("src.logger")

---@class StateCallbacks
---@field enter? fun(params?: table)
---@field exit? fun(params?: table)
---@field update? fun(dt: number)
---@field draw? fun()
---@field pause? fun()
---@field resume? fun(params?: table)

---@class StateMachine
---@field states table<string, StateCallbacks>
---@field stack string[]
local StateMachine = {}
StateMachine.__index = StateMachine

---Creates a new StateMachine
---@return StateMachine
function StateMachine.new()
    local self = setmetatable({}, StateMachine)
    self.states = {}
    self.stack = {}
    Logger.debug("StateMachine created", "StateMachine")
    return self
end

---Registers a state with its callbacks
---@param name string State name
---@param callbacks StateCallbacks State callbacks (all optional)
function StateMachine:addState(name, callbacks)
    self.states[name] = callbacks or {}
    Logger.debug("State added: " .. name, "StateMachine")
end

---Sets the current state, clearing the stack
---@param name string State name
---@param params? table Parameters to pass to exit and enter
function StateMachine:setState(name, params)
    if not self.states[name] then
        Logger.error("State not found: " .. name, "StateMachine")
        return
    end

    local oldName = self:getState()

    -- Call exit on current state if exists
    if oldName then
        local oldState = self.states[oldName]
        if oldState and oldState.exit then
            oldState.exit(params)
        end
    end

    -- Clear stack and set new state
    self.stack = { name }

    -- Call enter on new state
    local newState = self.states[name]
    if newState and newState.enter then
        newState.enter(params)
    end

    if oldName then
        Logger.debug(string.format("State changed: %s -> %s", oldName, name), "StateMachine")
    else
        Logger.debug("State set: " .. name, "StateMachine")
    end
end

---Pushes a new state onto the stack
---@param name string State name
---@param params? table Parameters to pass to pause and enter
function StateMachine:pushState(name, params)
    if not self.states[name] then
        Logger.error("State not found: " .. name, "StateMachine")
        return
    end

    -- Call pause on current state if exists
    local currentName = self:getState()
    if currentName then
        local currentState = self.states[currentName]
        if currentState and currentState.pause then
            currentState.pause()
        end
    end

    -- Push new state
    table.insert(self.stack, name)

    -- Call enter on new state
    local newState = self.states[name]
    if newState and newState.enter then
        newState.enter(params)
    end

    Logger.debug(string.format("State pushed: %s (stack size: %d)", name, #self.stack), "StateMachine")
end

---Pops the current state from the stack
---@param params? table Parameters to pass to exit and resume
function StateMachine:popState(params)
    if #self.stack == 0 then
        Logger.warning("Cannot pop: stack empty", "StateMachine")
        return
    end

    local currentName = self.stack[#self.stack]

    -- Call exit on current state
    local currentState = self.states[currentName]
    if currentState and currentState.exit then
        currentState.exit(params)
    end

    -- Remove from stack
    table.remove(self.stack)

    Logger.debug(string.format("State popped: %s (stack size: %d)", currentName, #self.stack), "StateMachine")

    -- Call resume on new top state if exists
    local newTopName = self:getState()
    if newTopName then
        local newTopState = self.states[newTopName]
        if newTopState and newTopState.resume then
            newTopState.resume(params)
        end
    end
end

---Returns the current state name (top of stack)
---@return string|nil
function StateMachine:getState()
    if #self.stack == 0 then
        return nil
    end
    return self.stack[#self.stack]
end

---Updates the current state
---@param dt number Delta time
function StateMachine:update(dt)
    local currentName = self:getState()
    if not currentName then
        return
    end

    local currentState = self.states[currentName]
    if currentState and currentState.update then
        currentState.update(dt)
    end
end

---Draws all states in the stack (bottom to top for layering)
function StateMachine:draw()
    for _, name in ipairs(self.stack) do
        local state = self.states[name]
        if state and state.draw then
            state.draw()
        end
    end
end

return StateMachine
