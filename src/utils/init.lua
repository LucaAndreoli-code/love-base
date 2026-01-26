local Logger = require("src.logger")

local Utils = {}

function Utils:load()
    Utils.collision = require('src.utils.collision')
    Logger.info("[UI] Collision utils loaded")

    Utils.math = require('src.utils.math')
    Logger.info("[UI] Math utils loaded")

    Logger.info("[UI] Utils!")
end

return Utils
