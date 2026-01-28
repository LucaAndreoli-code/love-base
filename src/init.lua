local Game = {}

function Game.load()
    Game.logger = require("src.logger")
    Game.debug = require("src.debug")

    Game.scenes = require("src.scenes.init")
    Game.constants = require("src.constants.init")
    Game.systems = require("src.systems.init")
    Game.utils = require("src.utils.init")
    Game.ui = require("src.ui.init")

    Game.scenes:load()
    Game.constants:load()
    Game.systems:load()
    Game.utils:load()
    Game.ui:load()
    Game.debug:load()

    Game.logger.info("[Game] Game Started!")
end

function Game.update(dt)
    -- Update game state here
end

function Game.draw()
    -- Render game here
    Game.debug:draw()
end

function Game.keypressed(key)
    Game.debug:keypressed(key)
end

return Game
