local Game

function love.load()
    Game = require("src.init")
    Game.load()

    -- Create global input handler instance
    Game.systems.input = Game.systems.inputHandler.new()
end

function love.update(dt)
    -- Update input handler first
    if Game.systems.input then
        Game.systems.input:update()
    end

    if arg and arg[2] == "--debug" then
        require("libs.lurker.lurker").update()
    end
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    if Game.systems.input then
        Game.systems.input:_onKeyPressed(key)
    end
    Game.keypressed(key)
end

function love.keyreleased(key)
    if Game.systems.input then
        Game.systems.input:_onKeyReleased(key)
    end
end

function love.gamepadpressed(joystick, button)
    if Game.systems.input then
        Game.systems.input:_onGamepadPressed(joystick, button)
    end
end

function love.gamepadreleased(joystick, button)
    if Game.systems.input then
        Game.systems.input:_onGamepadReleased(joystick, button)
    end
end

function love.gamepadaxis(joystick, axis, value)
    if Game.systems.input then
        Game.systems.input:_onGamepadAxis(joystick, axis, value)
    end
end
