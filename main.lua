local Game = require("src.init")
--local moonshine = require 'libs.moonshine'
--local effect

-- Setup Lurker for Hot Reloading
local lurker
if arg and arg[2] == "--debug" then
    lurker = require("libs.lurker.lurker")
    lurker.postswap = function(f)
        -- Reload Game implementation
        Game = require("src.init")
        -- Re-initialize Game to rebuild systems and components
        -- Note: This resets the game state. For state preservation,
        -- a specific state migration strategy is needed.
        if Game.load then Game.load() end
        if Game.logger then Game.logger.info("[Lurker] Hot swapped: " .. f) end
    end
end

function love.load()
    Game.load()
end

function love.update(dt)
    if lurker then
        lurker.update()
    end

    Game.update(dt)

    -- Late update at end of frame
    Game.lateUpdate()
end

function love.draw()
    Game.draw()
end

--------------------------------------------------
-- Input Callbacks (delegate to Game.input)
--------------------------------------------------

function love.keypressed(key, scancode, isrepeat)
    -- Guard against reload race conditions
    if Game.keypressed then
        Game.keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    if Game.input then
        Game.input:keyreleased(key, scancode)
    end
end

function love.mousepressed(x, y, button, istouch)
    if Game.input then
        Game.input:mousepressed(x, y, button, istouch)
    end
end

function love.mousereleased(x, y, button, istouch)
    if Game.input then
        Game.input:mousereleased(x, y, button, istouch)
    end
end

function love.mousemoved(x, y, dx, dy)
    if Game.input then
        Game.input:mousemoved(x, y, dx, dy)
    end
end

function love.wheelmoved(x, y)
    if Game.input then
        Game.input:wheelmoved(x, y)
    end
end

function love.gamepadpressed(joystick, button)
    if Game.input then
        Game.input:gamepadpressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    if Game.input then
        Game.input:gamepadreleased(joystick, button)
    end
end

function love.gamepadaxis(joystick, axis, value)
    if Game.input then
        Game.input:gamepadaxis(joystick, axis, value)
    end
end

function love.joystickadded(joystick)
    if Game.input then
        Game.input:joystickAdded(joystick)
    end
end

function love.joystickremoved(joystick)
    if Game.input then
        Game.input:joystickRemoved(joystick)
    end
end
