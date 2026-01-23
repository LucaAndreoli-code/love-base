local Logger = require("src.logger")
local Debug = {
    active = false,
    debuggerEnabled = false,
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

function Debug:draw()
    if not self.active then return end
    love.graphics.print("Debug Mode Active", 10, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 10, 30)
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
