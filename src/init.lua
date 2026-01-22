local Logger = require("src.logger")
local Game = {}

Game.scenes = require("src.scenes.init")
Game.constants = require("src.constants.init")
Game.systems = require("src.systems.init")
Game.utils = require("src.utils.init")
Game.ui = require("src.ui.init")

function Game.load()
    if Logger.currentLevel == Logger.LEVELS.DEBUG then
        require("lldebugger").start()
    end
    Logger.info("Starting Love2D game...")
end

return Game
