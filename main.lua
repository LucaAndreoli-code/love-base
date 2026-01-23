if arg and arg[2] == "--debug" then
    require("libs.lick.lick")
end

local Game = require("src.init")

function love.load()
    Game.load()
end

function love.update(dt)
    Game.update(dt)
end

function love.draw()
    Game.draw()
end

function love.keypressed(key)
    Game.keypressed(key)
end
