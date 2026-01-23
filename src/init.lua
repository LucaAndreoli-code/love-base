local Logger = require("src.logger")
local Debug = require("src.debug")

local Game = {}

Game.scenes = require("src.scenes.init")
Game.constants = require("src.constants.init")
Game.systems = require("src.systems.init")
Game.utils = require("src.utils.init")
Game.ui = require("src.ui.init")

function Game.load()
    Debug:load()
    Logger.info("Game started!")
    -- Initialize game systems and scenes here
end

function Game.update(dt)
    -- Update game state here
end

function Game.draw()
    Debug:draw()
    -- Render game here
end

function Game.keypressed(key)
    Debug:keypressed(key)
    -- Handle other keypresses here
end

return Game
