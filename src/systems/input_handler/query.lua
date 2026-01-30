--[[
    InputHandler Query API

    Update loop and state queries.
    Mixin that adds query methods to InputHandler.
]]

local InputState = require("src.systems.input_handler.input_state")
local Logger = require("src.logger")

--- Adds query methods to InputHandler
---@param InputHandler table  The InputHandler class to extend
return function(InputHandler)
    --- Determines which input triggered an action (for logging)
    ---@private
    ---@param action InputAction
    ---@return string  input type description
    function InputHandler:_getActiveInputType(action)
        if action.keyboard and self._rawInputs["key:" .. action.keyboard] then
            return "keyboard:" .. action.keyboard
        end
        if action.mouse and self._rawInputs["mouse:" .. action.mouse] then
            return "mouse:" .. action.mouse
        end
        if action.mouseWheel and self._rawInputs["mouse:wheel:" .. action.mouseWheel] then
            return "wheel:" .. action.mouseWheel
        end
        if action.gamepadButton and self._rawInputs["pad:" .. action.gamepadButton] then
            return "gamepad:" .. action.gamepadButton
        end
        if action.gamepadAxis then
            local axisValue = self._rawInputs["axis:" .. action.gamepadAxis] or 0
            local threshold = action.axisThreshold or self.settings.axisThreshold
            if math.abs(axisValue) > threshold then
                return "axis:" .. action.gamepadAxis
            end
        end
        return "unknown"
    end

    --- Called every frame in love.update(dt)
    ---@param dt number
    function InputHandler:update(dt)
        -- Update mouse position (even without movement)
        self.mouse.x, self.mouse.y = love.mouse.getPosition()

        -- Process each action in active contexts
        for contextName, active in pairs(self.activeContexts) do
            if active then
                local context = self.contexts[contextName]
                if context then
                    for actionName, action in pairs(context:getActions()) do
                        local isDown = self:_isActionDown(action)

                        -- Create state if it doesn't exist
                        if not self.states[actionName] then
                            self.states[actionName] = InputState.new()
                        end

                        self.states[actionName]:update(isDown, dt)

                        -- Debug log for transitions
                        local inputType = self:_getActiveInputType(action)
                        if self.states[actionName].pressed then
                            Logger.debug("[Input] Action " .. actionName .. " pressed " .. inputType)
                        elseif self.states[actionName].released then
                            Logger.debug("[Input] Action " .. actionName .. " released " .. inputType)
                        end
                    end
                end
            end
        end
    end

    --- Checks if an action is currently down based on raw inputs
    ---@private
    ---@param action InputAction
    ---@return boolean
    function InputHandler:_isActionDown(action)
        -- Keyboard
        if action.keyboard then
            if self._rawInputs["key:" .. action.keyboard] then
                return true
            end
        end

        -- Mouse button
        if action.mouse then
            if self._rawInputs["mouse:" .. action.mouse] then
                return true
            end
        end

        -- Mouse wheel (treated as instant press)
        if action.mouseWheel then
            if self._rawInputs["mouse:wheel:" .. action.mouseWheel] then
                return true
            end
        end

        -- Gamepad button
        if action.gamepadButton then
            if self._rawInputs["pad:" .. action.gamepadButton] then
                return true
            end
        end

        -- Gamepad axis (with threshold and direction)
        if action.gamepadAxis then
            local axisValue = self._rawInputs["axis:" .. action.gamepadAxis] or 0
            local threshold = action.axisThreshold or self.settings.axisThreshold
            local direction = action.axisDirection or 1

            if direction > 0 then
                return axisValue > threshold
            else
                return axisValue < -threshold
            end
        end

        return false
    end

    --- Called at end of frame for reset
    function InputHandler:lateUpdate()
        -- Reset mouse delta (accumulated during frame)
        self.mouse.dx = 0
        self.mouse.dy = 0

        -- Reset scroll (it's a one-shot event)
        self.mouse.scroll.x = 0
        self.mouse.scroll.y = 0

        -- Reset wheel raw inputs
        self._rawInputs["mouse:wheel:up"] = nil
        self._rawInputs["mouse:wheel:down"] = nil
        self._rawInputs["mouse:wheel:left"] = nil
        self._rawInputs["mouse:wheel:right"] = nil
    end

    --- Action is pressed (includes first frame)
    ---@param actionName string
    ---@return boolean
    function InputHandler:isDown(actionName)
        local state = self.states[actionName]
        return state and state.down or false
    end

    --- Action was just pressed (only first frame)
    ---@param actionName string
    ---@return boolean
    function InputHandler:isPressed(actionName)
        local state = self.states[actionName]
        return state and state.pressed or false
    end

    --- Action was just released (only first frame)
    ---@param actionName string
    ---@return boolean
    function InputHandler:isReleased(actionName)
        local state = self.states[actionName]
        return state and state.released or false
    end

    --- How long the action has been held pressed
    ---@param actionName string
    ---@return number  seconds, 0 if not pressed
    function InputHandler:getHoldDuration(actionName)
        local state = self.states[actionName]
        return state and state.downDuration or 0
    end

    --- Axis value for an axis-based action
    ---@param actionName string
    ---@return number  -1 to 1, 0 if not found
    function InputHandler:getAxis(actionName)
        -- Search for action in active contexts
        for contextName, active in pairs(self.activeContexts) do
            if active then
                local context = self.contexts[contextName]
                if context then
                    local action = context:getAction(actionName)
                    if action and action.gamepadAxis then
                        return self._rawInputs["axis:" .. action.gamepadAxis] or 0
                    end
                end
            end
        end
        return 0
    end

    --- Gets mouse position
    ---@return number x
    ---@return number y
    function InputHandler:getMousePosition()
        return self.mouse.x, self.mouse.y
    end

    --- Gets mouse scroll this frame
    ---@return number scrollX
    ---@return number scrollY
    function InputHandler:getMouseScroll()
        return self.mouse.scroll.x, self.mouse.scroll.y
    end

    --- Checks if dragging
    ---@return boolean
    function InputHandler:isDragging()
        return self.mouse.drag.active
    end

    --- Gets drag delta from start
    ---@return number dx
    ---@return number dy
    function InputHandler:getDragDelta()
        if not self.mouse.drag.active then
            return 0, 0
        end
        return self.mouse.x - self.mouse.drag.startX,
            self.mouse.y - self.mouse.drag.startY
    end

    --- Gets drag start position
    ---@return number startX
    ---@return number startY
    function InputHandler:getDragStart()
        return self.mouse.drag.startX, self.mouse.drag.startY
    end

    --- Gets mouse delta this frame
    ---@return number dx
    ---@return number dy
    function InputHandler:getMouseDelta()
        return self.mouse.dx, self.mouse.dy
    end
end
