local Game = {}

function Game:initialize()
    Game.logger = require("src.logger")
    Game.debug = require("src.debug")

    Game.scenes = require("src.scenes.init")
    Game.constants = require("src.constants.init")
    Game.systems = require("src.systems.init")
    Game.utils = require("src.utils.init")
    Game.ui = require("src.ui.init")

    Game.scenes:initialize()
    Game.constants:initialize()
    Game.systems:initialize()
    Game.utils:initialize()
    Game.ui:initialize()

    Game.debug:load()

    Game.logger.info("Game Started!")
end 

function Game.load()
    -- Initialize game systems, scenes and stuff here
    Game:initialize()
end

function Game.update(dt)
    -- Update game state here
end

function Game.draw()
    -- Render game here
    Game.debug:draw()
end

function Game.keypressed(key)
    -- Handle other keypresses here
    Game.debug:keypressed(key)
end

return Game
