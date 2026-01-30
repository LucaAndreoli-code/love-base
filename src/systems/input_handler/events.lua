--[[
    InputHandler Event Capture

    LÖVE callback handlers.
    Mixin that adds event capture methods to InputHandler.
]]
local Logger = require("src.logger")

--- Adds event capture methods to InputHandler
---@param InputHandler table  The InputHandler class to extend
return function(InputHandler)
    --- Keyboard pressed
    ---@param key string
    ---@param scancode string
    ---@param isrepeat boolean
    function InputHandler:keypressed(key, scancode, isrepeat)
        if isrepeat then return end -- ignore auto-repeat

        -- Rebind mode: capture this key
        if self._rebind.active and self._rebind.inputType == "keyboard" then
            -- Escape to cancel
            if key == "escape" then
                self:cancelRebind()
            else
                self:_completeRebind(key)
            end
            return -- don't process as normal input
        end

        self._rawInputs["key:" .. key] = true
    end

    --- Keyboard released
    ---@param key string
    ---@param scancode string
    function InputHandler:keyreleased(key, scancode)
        self._rawInputs["key:" .. key] = false
    end

    --- Mouse button pressed
    ---@param x number
    ---@param y number
    ---@param button number
    ---@param istouch boolean
    function InputHandler:mousepressed(x, y, button, istouch)
        if self._rebind.active and self._rebind.inputType == "mouse" then
            self:_completeRebind(button)
            return
        end

        self._rawInputs["mouse:" .. button] = true

        -- Start drag tracking
        self.mouse.drag.button = button
        self.mouse.drag.startX = x
        self.mouse.drag.startY = y
        self.mouse.drag.active = false -- becomes true when threshold is exceeded
    end

    --- Mouse button released
    ---@param x number
    ---@param y number
    ---@param button number
    ---@param istouch boolean
    function InputHandler:mousereleased(x, y, button, istouch)
        self._rawInputs["mouse:" .. button] = false

        -- End drag if it was this button
        if self.mouse.drag.button == button then
            self.mouse.drag.active = false
            self.mouse.drag.button = nil
        end
    end

    --- Mouse movement
    ---@param x number
    ---@param y number
    ---@param dx number
    ---@param dy number
    function InputHandler:mousemoved(x, y, dx, dy)
        self.mouse.x = x
        self.mouse.y = y
        self.mouse.dx = dx
        self.mouse.dy = dy

        -- Check drag threshold
        if self.mouse.drag.button and not self.mouse.drag.active then
            local distX = math.abs(x - self.mouse.drag.startX)
            local distY = math.abs(y - self.mouse.drag.startY)
            if distX > self.settings.dragThreshold or distY > self.settings.dragThreshold then
                self.mouse.drag.active = true
            end
        end
    end

    --- Mouse wheel
    ---@param x number
    ---@param y number
    function InputHandler:wheelmoved(x, y)
        self.mouse.scroll.x = x
        self.mouse.scroll.y = y

        -- Wheel as action (for one frame)
        if y > 0 then
            self._rawInputs["mouse:wheel:up"] = true
        elseif y < 0 then
            self._rawInputs["mouse:wheel:down"] = true
        end
        if x > 0 then
            self._rawInputs["mouse:wheel:right"] = true
        elseif x < 0 then
            self._rawInputs["mouse:wheel:left"] = true
        end
    end

    --- Gamepad button pressed
    ---@param joystick love.Joystick
    ---@param button string
    function InputHandler:gamepadpressed(joystick, button)
        -- Only the active gamepad
        if joystick ~= self._activeGamepad then return end

        if self._rebind.active and self._rebind.inputType == "gamepadButton" then
            self:_completeRebind(button)
            return
        end

        self._rawInputs["pad:" .. button] = true
    end

    --- Gamepad button released
    ---@param joystick love.Joystick
    ---@param button string
    function InputHandler:gamepadreleased(joystick, button)
        if joystick ~= self._activeGamepad then return end
        self._rawInputs["pad:" .. button] = false
    end

    --- Gamepad axis (called continuously, not just on change)
    ---@param joystick love.Joystick
    ---@param axis string
    ---@param value number
    function InputHandler:gamepadaxis(joystick, axis, value)
        if joystick ~= self._activeGamepad then return end
        -- Store raw value, will be processed in update
        self._rawInputs["axis:" .. axis] = value
    end
end
