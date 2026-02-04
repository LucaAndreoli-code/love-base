--[[
    InputHandler Rebinding

    Runtime rebinding and serialization.
    Mixin that adds rebinding methods to InputHandler.
]]

local Logger = require("src.logger")

--- Adds rebinding methods to InputHandler
---@param InputHandler table  The InputHandler class to extend
return function(InputHandler)
    --- Changes binding for an action
    ---@param actionName string
    ---@param inputType "keyboard"|"mouse"|"gamepadButton"|"gamepadAxis"
    ---@param value string|number  key, button, or axis
    ---@param contextName? string  if nil, searches all contexts
    ---@return boolean  true if found and modified
    function InputHandler:setBinding(actionName, inputType, value, contextName)
        local action = self:_findAction(actionName, contextName)
        if not action then
            Logger.warning("Cannot set binding: action not found: " .. actionName, "InputHandler")
            return false
        end

        -- Validate inputType
        local validTypes = { keyboard = true, mouse = true, gamepadButton = true, gamepadAxis = true }
        if not validTypes[inputType] then return false end

        action[inputType] = value
        Logger.debug(string.format("Binding set: %s.%s = %s", actionName, inputType, tostring(value)), "InputHandler")
        return true
    end

    --- Gets current binding
    ---@param actionName string
    ---@param inputType "keyboard"|"mouse"|"gamepadButton"|"gamepadAxis"
    ---@param contextName? string
    ---@return string|number|nil
    function InputHandler:getBinding(actionName, inputType, contextName)
        local action = self:_findAction(actionName, contextName)
        if not action then return nil end
        return action[inputType]
    end

    --- Finds an action in contexts
    ---@private
    function InputHandler:_findAction(actionName, contextName)
        if contextName then
            local context = self.contexts[contextName]
            return context and context:getAction(actionName)
        end

        -- Search all contexts
        for _, context in pairs(self.contexts) do
            local action = context:getAction(actionName)
            if action then return action end
        end
        return nil
    end

    --- Enters rebind mode
    ---@param actionName string
    ---@param inputType "keyboard"|"mouse"|"gamepadButton"  no axis in rebind mode
    ---@param callback? fun(success: boolean, newValue: string|number|nil)
    function InputHandler:startRebind(actionName, inputType, callback)
        local action = self:_findAction(actionName)
        if not action then
            Logger.warning("Cannot rebind: action not found: " .. actionName, "InputHandler")
            if callback then callback(false, nil) end
            return
        end

        Logger.info("Rebind started for: " .. actionName, "InputHandler")

        self._rebind = {
            active = true,
            actionName = actionName,
            inputType = inputType,
            callback = callback,
            originalAction = action:clone(), -- backup
        }
    end

    --- Cancels ongoing rebind
    function InputHandler:cancelRebind()
        if not self._rebind.active then return end

        Logger.debug("Rebind cancelled", "InputHandler")

        -- Restore backup if needed
        if self._rebind.callback then
            self._rebind.callback(false, nil)
        end

        self:_clearRebind()
    end

    --- Checks if in rebind mode
    ---@return boolean
    function InputHandler:isRebinding()
        return self._rebind.active
    end

    --- Info about ongoing rebind
    ---@return { actionName: string, inputType: string }|nil
    function InputHandler:getRebindInfo()
        if not self._rebind.active then return nil end
        return {
            actionName = self._rebind.actionName,
            inputType = self._rebind.inputType,
        }
    end

    ---@private
    function InputHandler:_clearRebind()
        self._rebind = {
            active = false,
            actionName = nil,
            inputType = nil,
            callback = nil,
            originalAction = nil,
        }
    end

    --- Called internally when an input is captured during rebind
    ---@private
    function InputHandler:_completeRebind(value)
        if not self._rebind.active then return end

        local success = self:setBinding(
            self._rebind.actionName,
            self._rebind.inputType,
            value
        )

        if self._rebind.callback then
            self._rebind.callback(success, value)
        end

        self:_clearRebind()
    end

    --- Exports all bindings (for saving)
    ---@return table
    function InputHandler:exportBindings()
        local data = {
            version = 1, -- for future migrations
            contexts = {}
        }

        for contextName, context in pairs(self.contexts) do
            data.contexts[contextName] = {}
            for actionName, action in pairs(context:getActions()) do
                data.contexts[contextName][actionName] = action:serialize()
            end
        end

        return data
    end

    --- Imports bindings (from loading)
    ---@param data table
    function InputHandler:importBindings(data)
        if not data or not data.contexts then return end

        -- Versioning for future migrations
        local version = data.version or 1

        for contextName, actions in pairs(data.contexts) do
            local context = self.contexts[contextName]
            if context then
                for actionName, actionData in pairs(actions) do
                    local existingAction = context:getAction(actionName)
                    if existingAction then
                        -- Update only bindings, keep the rest
                        existingAction.keyboard = actionData.keyboard
                        existingAction.mouse = actionData.mouse
                        existingAction.gamepadButton = actionData.gamepadButton
                        existingAction.gamepadAxis = actionData.gamepadAxis
                        existingAction.axisDirection = actionData.axisDirection
                        existingAction.axisThreshold = actionData.axisThreshold
                    end
                end
            end
        end
    end

    --- Saves current state as default (call after initial setup)
    function InputHandler:saveAsDefault()
        self._defaultBindings = self:exportBindings()
    end

    --- Resets an action to default
    ---@param actionName string
    ---@param contextName? string
    function InputHandler:resetBinding(actionName, contextName)
        if not self._defaultBindings then return end

        local action = self:_findAction(actionName, contextName)
        if not action then return end

        -- Find default
        for ctxName, actions in pairs(self._defaultBindings.contexts) do
            if actions[actionName] then
                local default = actions[actionName]
                action.keyboard = default.keyboard
                action.mouse = default.mouse
                action.gamepadButton = default.gamepadButton
                action.gamepadAxis = default.gamepadAxis
                break
            end
        end
    end

    --- Resets all bindings to default
    function InputHandler:resetAllBindings()
        if self._defaultBindings then
            self:importBindings(self._defaultBindings)
        end
    end
end
