local Logger = require("src.logger")

local Utils = {}

function Utils:load()
    Utils.collision = require('src.utils.collision')
    Logger.info("[Utils] Collision utils loaded")

    Utils.math = require('src.utils.math')
    Logger.info("[Utils] Math utils loaded")

    Logger.info("[Utils] Utils!")
end

return Utils
