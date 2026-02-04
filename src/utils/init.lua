local Logger = require("src.logger")

local Utils = {}

function Utils:load()
    Utils.collision = require("src.utils.collision")
    Logger.info("Collision utils loaded", "Utils")

    Utils.math = require("src.utils.math")
    Logger.info("Math utils loaded", "Utils")

    Logger.info("Done!", "Utils")
end

return Utils
