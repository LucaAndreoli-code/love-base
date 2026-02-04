--[[
    InputHandler Context Management

    Context registration and switching.
    Mixin that adds context methods to InputHandler.
]]

local Logger = require("src.logger")

--- Adds context management methods to InputHandler
---@param InputHandler table  The InputHandler class to extend
return function(InputHandler)
    --- Registers a context
    ---@param context InputContext
    function InputHandler:addContext(context)
        self.contexts[context.name] = context
    end

    --- Removes a registered context
    ---@param name string
    ---@return boolean  true if removed
    function InputHandler:removeContext(name)
        if self.contexts[name] then
            self.contexts[name] = nil
            self.activeContexts[name] = nil
            return true
        end
        return false
    end

    --- Gets a context by name
    ---@param name string
    ---@return InputContext|nil
    function InputHandler:getContext(name)
        return self.contexts[name]
    end

    --- Activates ONLY this context (deactivates all others)
    --- Typical use: switch between menu and gameplay
    ---@param name string
    function InputHandler:setContext(name)
        -- Verify context exists
        if not self.contexts[name] then
            Logger.warning("Context not found: " .. name, "InputHandler")
            return
        end

        -- Clean all states when fully switching context
        for _, state in pairs(self.states) do
            state:clear()
        end

        -- Deactivate all, activate only this one
        self.activeContexts = {}
        self.activeContexts[name] = true

        -- Create states for actions of the new context
        self:_createStatesForContext(name)
        Logger.debug("Context set: " .. name, "InputHandler")
    end

    --- Adds a context to the active set (stack-like)
    --- Typical use: open pause over gameplay
    ---@param name string
    function InputHandler:pushContext(name)
        if not self.contexts[name] then
            Logger.warning("Cannot push unknown context: " .. name, "InputHandler")
            return
        end

        -- Consume pressed/released states to prevent same-frame triggers
        -- (preserves _wasDown so key-still-down won't re-trigger pressed)
        for _, state in pairs(self.states) do
            state:consume()
        end

        self.activeContexts[name] = true
        self:_createStatesForContext(name)
        Logger.debug("Context pushed: " .. name, "InputHandler")
    end

    --- Removes a context from the active set
    --- Typical use: close pause, return to gameplay
    ---@param name string
    function InputHandler:popContext(name)
        -- Consume pressed/released states to prevent same-frame triggers
        for _, state in pairs(self.states) do
            state:consume()
        end

        self.activeContexts[name] = nil
        Logger.debug("Context popped: " .. name, "InputHandler")
    end

    --- Checks if a context is active
    ---@param name string
    ---@return boolean
    function InputHandler:isContextActive(name)
        return self.activeContexts[name] == true
    end

    --- Gets list of active contexts
    ---@return table<string>
    function InputHandler:getActiveContexts()
        local result = {}
        for name, active in pairs(self.activeContexts) do
            if active then
                table.insert(result, name)
            end
        end
        return result
    end

    --- Deactivates all contexts
    function InputHandler:clearContexts()
        self.activeContexts = {}
        for _, state in pairs(self.states) do
            state:clear()
        end
        Logger.debug("All contexts cleared", "InputHandler")
    end
end
