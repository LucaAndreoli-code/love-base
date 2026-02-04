local Logger = require("src.logger")

local Constants = {}

function Constants:load()
    Constants.inputDefaults = require("src.constants.input.input_defaults")
    Logger.info("Input defaults loaded", "Constants")

    Constants.inputSpritesMap = require("src.constants.input.input_sprites_map")
    Logger.info("Input sprites map loaded", "Constants")

    Constants.audioDefaults = require("src.constants.audio_defaults")
    Logger.info("Audio defaults loaded", "Constants")

    Logger.info("Done!", "Constants")
end

return Constants
