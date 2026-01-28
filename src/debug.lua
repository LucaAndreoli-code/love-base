local Logger = require("src.logger")

local Debug = {
    active = false,
    enabled = false
}

function Debug:load()
    -- Enable debug features only with --debug flag
    if arg and arg[2] == "--debug" then
        self.enabled = true
        Logger.debug("Debug mode enabled. Starting debugger...")
        local success, lldebugger = pcall(require, "lldebugger")
        if success and lldebugger then
            lldebugger.start()
        else
            Logger.warning("lldebugger not available")
        end
    end
end

function Debug:draw()
    if not self.enabled or not self.active then return end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("DEBUG (F1)", 10, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
end

function Debug:keypressed(key)
    if not self.enabled then return end

    if key == "f1" then
        self:toggle()
    end
end

function Debug:toggle()
    self.active = not self.active
    Logger.debug("Debug overlay " .. (self.active and "ON" or "OFF"))
end

return Debug
