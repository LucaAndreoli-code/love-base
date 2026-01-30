--[[
    InputPrompts

    Manages input prompt sprites with automatic device switching.
    Shows the correct icon (keyboard/gamepad) based on the last input used.
]]

---@class InputPrompts
---@field device "keyboard"|"xbox"     Current active device
---@field sprites table                Loaded sprites cache
---@field basePath string              Base path for sprite assets
---@field inputHandler InputHandler    Reference to input handler
---@field onInput function|nil         Callback for input events (inputType, inputValue, pressed)

local InputPrompts = {}
InputPrompts.__index = InputPrompts

local spriteMap = require("src.constants.input_sprites_map")

--- Creates a new InputPrompts instance
---@param inputHandler InputHandler
---@return InputPrompts
function InputPrompts.new(inputHandler)
    local self = setmetatable({}, InputPrompts)

    self.device = "keyboard"
    self.sprites = {
        keyboard = {},
        xbox = {},
    }
    self.basePath = "assets/sprites/input"
    self.inputHandler = inputHandler

    -- Hook into InputHandler for device detection
    self:_hookDeviceDetection()

    return self
end

--- Hooks into InputHandler to detect device changes
---@private
function InputPrompts:_hookDeviceDetection()
    if not self.inputHandler then return end

    -- Store original callbacks
    local originalKeypressed = self.inputHandler.keypressed
    local originalKeyreleased = self.inputHandler.keyreleased
    local originalGamepadpressed = self.inputHandler.gamepadpressed
    local originalGamepadreleased = self.inputHandler.gamepadreleased
    local originalMousepressed = self.inputHandler.mousepressed
    local originalMousereleased = self.inputHandler.mousereleased

    local prompts = self

    -- Wrap keypressed
    self.inputHandler.keypressed = function(handler, key, scancode, isrepeat)
        prompts:setDevice("keyboard")
        prompts:_notifyInput("keyboard", key, true)
        return originalKeypressed(handler, key, scancode, isrepeat)
    end

    -- Wrap keyreleased
    self.inputHandler.keyreleased = function(handler, key, scancode)
        prompts:_notifyInput("keyboard", key, false)
        return originalKeyreleased(handler, key, scancode)
    end

    -- Wrap gamepadpressed
    self.inputHandler.gamepadpressed = function(handler, joystick, button)
        prompts:setDevice("xbox")
        prompts:_notifyInput("xbox", button, true)
        return originalGamepadpressed(handler, joystick, button)
    end

    -- Wrap gamepadreleased
    self.inputHandler.gamepadreleased = function(handler, joystick, button)
        prompts:_notifyInput("xbox", button, false)
        return originalGamepadreleased(handler, joystick, button)
    end

    -- Wrap mousepressed
    self.inputHandler.mousepressed = function(handler, x, y, button, istouch, presses)
        prompts:setDevice("keyboard")
        prompts:_notifyInput("mouse", button, true)
        return originalMousepressed(handler, x, y, button, istouch, presses)
    end

    -- Wrap mousereleased
    self.inputHandler.mousereleased = function(handler, x, y, button, istouch, presses)
        prompts:_notifyInput("mouse", button, false)
        return originalMousereleased(handler, x, y, button, istouch, presses)
    end
end

--- Notifies registered callback of input events
---@private
---@param inputType string
---@param inputValue string|number
---@param pressed boolean
function InputPrompts:_notifyInput(inputType, inputValue, pressed)
    if self.onInput then
        self.onInput(inputType, inputValue, pressed)
    end
end

--- Sets the current device
---@param device "keyboard"|"xbox"
function InputPrompts:setDevice(device)
    if self.device ~= device then
        self.device = device
    end
end

--- Gets the current device
---@return "keyboard"|"xbox"
function InputPrompts:getDevice()
    return self.device
end

--- Loads a sprite for a specific input
---@private
---@param device string
---@param spriteName string
---@return love.Image|nil
function InputPrompts:_loadSprite(device, spriteName)
    if not spriteName then return nil end

    -- Check cache
    if self.sprites[device][spriteName] then
        return self.sprites[device][spriteName]
    end

    -- Build path
    local path = string.format("%s/%s/Default/%s.png", self.basePath, device, spriteName)

    -- Try to load
    local success, image = pcall(love.graphics.newImage, path)
    if success then
        self.sprites[device][spriteName] = image
        return image
    end

    return nil
end

--- Gets sprite for a raw input (key name or button name)
---@param inputType "keyboard"|"xbox"|"mouse"
---@param inputValue string|number  Key name, button name, or mouse button number
---@param outline? boolean  If true, get the outline (unpressed) version
---@return love.Image|nil
function InputPrompts:getSpriteForInput(inputType, inputValue, outline)
    local map = spriteMap[inputType]
    if not map then return nil end

    local spriteName = map[inputValue]
    if not spriteName then return nil end

    -- Add outline suffix if requested
    if outline then
        spriteName = spriteName .. "_outline"
    end

    local device = inputType == "mouse" and "keyboard" or inputType
    return self:_loadSprite(device, spriteName)
end

--- Gets sprite for an action based on current device
---@param actionName string
---@return love.Image|nil
function InputPrompts:getSpriteForAction(actionName)
    if not self.inputHandler then return nil end

    -- Find action in active contexts
    for contextName, active in pairs(self.inputHandler.activeContexts) do
        if active then
            local context = self.inputHandler.contexts[contextName]
            if context then
                local action = context:getAction(actionName)
                if action then
                    return self:_getSpriteFromAction(action)
                end
            end
        end
    end

    return nil
end

--- Gets sprite from an action based on current device
---@private
---@param action InputAction
---@return love.Image|nil
function InputPrompts:_getSpriteFromAction(action)
    if self.device == "keyboard" then
        -- Try keyboard first, then mouse
        if action.keyboard then
            return self:getSpriteForInput("keyboard", action.keyboard)
        elseif action.mouse then
            return self:getSpriteForInput("mouse", action.mouse)
        end
    else
        -- Try gamepad
        if action.gamepadButton then
            return self:getSpriteForInput("xbox", action.gamepadButton)
        end
    end

    return nil
end

--- Draws a prompt for an action
---@param actionName string
---@param x number
---@param y number
---@param scale? number
function InputPrompts:draw(actionName, x, y, scale)
    scale = scale or 1

    local sprite = self:getSpriteForAction(actionName)
    if sprite then
        love.graphics.draw(sprite, x, y, 0, scale, scale)
    end
end

--- Draws a prompt for a raw input
---@param inputType "keyboard"|"xbox"|"mouse"
---@param inputValue string|number
---@param x number
---@param y number
---@param scale? number
function InputPrompts:drawInput(inputType, inputValue, x, y, scale)
    scale = scale or 1

    local sprite = self:getSpriteForInput(inputType, inputValue)
    if sprite then
        love.graphics.draw(sprite, x, y, 0, scale, scale)
    end
end

--- Gets the binding text for an action (for fallback display)
---@param actionName string
---@return string
function InputPrompts:getBindingText(actionName)
    if not self.inputHandler then return "" end

    for contextName, active in pairs(self.inputHandler.activeContexts) do
        if active then
            local context = self.inputHandler.contexts[contextName]
            if context then
                local action = context:getAction(actionName)
                if action then
                    if self.device == "keyboard" then
                        return action.keyboard or ""
                    else
                        return action.gamepadButton or ""
                    end
                end
            end
        end
    end

    return ""
end

return InputPrompts
