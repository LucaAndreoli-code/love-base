local Game = require("src.init")

function love.load()
    Game.load()
end

function love.update(dt)
    if arg and arg[2] == "--debug" then
        require("libs.lurker.lurker").update()
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
    Game.input:keypressed(key, scancode, isrepeat)
    Game.keypressed(key)
end

function love.keyreleased(key, scancode)
    Game.input:keyreleased(key, scancode)
end

function love.mousepressed(x, y, button, istouch)
    Game.input:mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    Game.input:mousereleased(x, y, button, istouch)
end

function love.mousemoved(x, y, dx, dy)
    Game.input:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    Game.input:wheelmoved(x, y)
end

function love.gamepadpressed(joystick, button)
    Game.input:gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    Game.input:gamepadreleased(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    Game.input:gamepadaxis(joystick, axis, value)
end

function love.joystickadded(joystick)
    Game.input:joystickAdded(joystick)
end

function love.joystickremoved(joystick)
    Game.input:joystickRemoved(joystick)
end
