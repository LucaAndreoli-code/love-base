local Logger = require("src.logger")

local Constants = {}

function Constants:load()
    Constants.inputDefaults = require("src.constants.input_defaults")
    Logger.info("[Constants] Input defaults loaded")

    Constants.inputSpritesMap = require("src.constants.input_sprites_map")
    Logger.info("[Constants] Input sprites map loaded")

    Logger.info("[Constants] Done!")
end

return Constants
