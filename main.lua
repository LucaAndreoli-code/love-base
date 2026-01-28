local Game

function love.load()
    Game = require("src.init")
    Game.load()
end

function love.update(dt)
    if arg and arg[2] == "--debug" then
        require("libs.lurker.lurker").update()
    end
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    Game.keypressed(key)
end
