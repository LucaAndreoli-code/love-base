local Logger = require("src.logger")
local Debug = {
    active = false,
    debuggerEnabled = false,
    lastInput = nil,   -- { type = "keyboard"|"xbox"|"mouse", value = "w"|1, pressed = true }
    inputHistory = {}, -- Keep last few inputs for display
    maxHistory = 1,
    prompts = nil,     -- Reference to InputPrompts (set via init)
}

if arg and arg[2] == "--debug" then
    Debug.debuggerEnabled = true
end

function Debug:load()
    if Debug.debuggerEnabled then
        Logger.debug("Debug mode enabled. Starting debugger...")
        local success, lldebugger = pcall(require, "lldebugger")
        if success and lldebugger then
            lldebugger.start()
        else
            Logger.warning("lldebugger not available")
        end
    end
end

--- Initialize with InputPrompts reference and register callback
---@param prompts InputPrompts
function Debug:init(prompts)
    self.prompts = prompts

    -- Register callback for input events
    prompts.onInput = function(inputType, inputValue, pressed)
        self:onInput(inputType, inputValue, pressed)
    end
end

--- Called when any input is detected
---@param inputType "keyboard"|"xbox"|"mouse"
---@param inputValue string|number
---@param pressed boolean
function Debug:onInput(inputType, inputValue, pressed)
    -- Early return if debug not active (skip unnecessary work)
    if not self.active then return end

    self.lastInput = {
        type = inputType,
        value = inputValue,
        pressed = pressed,
    }

    -- Add to history when pressed (avoid duplicates)
    if pressed then
        -- Remove if already in history
        for i, input in ipairs(self.inputHistory) do
            if input.value == inputValue then
                table.remove(self.inputHistory, i)
                break
            end
        end

        -- Add to front
        table.insert(self.inputHistory, 1, {
            type = inputType,
            value = inputValue,
            pressed = true,
        })

        -- Trim to max
        while #self.inputHistory > self.maxHistory do
            table.remove(self.inputHistory)
        end
    else
        -- Update pressed state in history
        for _, input in ipairs(self.inputHistory) do
            if input.value == inputValue then
                input.pressed = false
                break
            end
        end
    end
end

function Debug:draw()
    if not self.active then return end
    if not self.prompts then return end

    -- Top info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Debug Mode Active", 10, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
    love.graphics.print("Device: " .. self.prompts:getDevice(), 10, 50)

    Debug:drawInput()
end

function Debug:drawInput()
    local screenH = love.graphics.getHeight()
    local iconSize = 48
    local padding = 10
    local startX = padding
    local startY = screenH - iconSize - padding

    for i, input in ipairs(self.inputHistory) do
        local x = startX + (i - 1) * (iconSize + 5)
        local y = startY

        -- Get sprite (outline if not pressed)
        local sprite = self.prompts:getSpriteForInput(input.type, input.value, not input.pressed)

        if sprite then
            -- Draw with slight transparency if not pressed
            if input.pressed then
                love.graphics.setColor(1, 1, 1, 1)
            else
                love.graphics.setColor(1, 1, 1, 0.5)
            end

            local scale = iconSize / sprite:getWidth()
            love.graphics.draw(sprite, x, y, 0, scale, scale)
        else
            -- Fallback: draw text
            love.graphics.setColor(1, 1, 1, input.pressed and 1 or 0.5)
            love.graphics.print(tostring(input.value), x, y)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Debug:keypressed(key)
    if key == "f1" then
        self:toggle()
    end
end

function Debug:toggle()
    if not self.debuggerEnabled then return end
    self.active = not self.active
    Logger.debug("Debug mode " .. (self.active and "ON" or "OFF"))
end

return Debug
